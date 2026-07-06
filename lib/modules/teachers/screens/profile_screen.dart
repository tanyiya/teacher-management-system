import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

import '../../../app_theme.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../providers/app_state_provider.dart';
import '../models/teacher.dart';
import '../services/ocr_service.dart';
import '../services/teacher_service.dart';
import 'change_request_screen.dart';

class ProfileScreen extends StatefulWidget {
  final TeacherRecord user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TeacherService();

  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _emergencyNameCtrl;
  late final TextEditingController _emergencyNumCtrl;
  String? _maritalStatus;

  bool _isSaving = false;
  String? _uploadingDocKey;

  static const _maritalOptions = ['Single', 'Married', 'Divorced', 'Widowed'];

  @override
  void initState() {
    super.initState();
    _initControllers(widget.user);
  }

  void _initControllers(TeacherRecord u) {
    _phoneCtrl = TextEditingController(text: u.phoneNumber);
    _emailCtrl = TextEditingController(text: u.email);
    _addressCtrl = TextEditingController(text: u.address);
    _emergencyNameCtrl = TextEditingController(text: u.emergencyContactName);
    _emergencyNumCtrl = TextEditingController(text: u.emergencyContactNumber);
    _maritalStatus = _maritalOptions.contains(u.maritalStatus) ? u.maritalStatus : null;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyNumCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    // Capture provider before async gap to avoid BuildContext warning.
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    try {
      await _service.updateTeacherProfile(widget.user.id, {
        'phoneNumber': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'maritalStatus': _maritalStatus ?? '',
        'emergencyContactName': _emergencyNameCtrl.text.trim(),
        'emergencyContactNumber': _emergencyNumCtrl.text.trim(),
      }).timeout(const Duration(seconds: 3), onTimeout: () {});
      // Update provider directly from the values we just saved.
      // Do NOT call refreshCurrentUser() — it reads from the Firestore SDK
      // local cache which is empty (we use REST for reads), so it would
      // return a partial document and wipe the user's identity fields.
      appState.updateCurrentUser(widget.user.copyWith(
        phoneNumber: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        maritalStatus: _maritalStatus ?? widget.user.maritalStatus,
        emergencyContactName: _emergencyNameCtrl.text.trim(),
        emergencyContactNumber: _emergencyNumCtrl.text.trim(),
      ));
      if (mounted) _showSnack('Profile updated successfully.', isError: false);
    } catch (_) {
      if (mounted) _showSnack('Failed to save. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadDocument(String docKey, String docName) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final ext = (file.extension ?? '').toLowerCase();

    if (!['pdf', 'jpg', 'jpeg', 'png'].contains(ext)) {
      _showSnack('Invalid file type. Only PDF, JPG, PNG are allowed.', isError: true);
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      _showSnack('File too large. Maximum size is 5 MB.', isError: true);
      return;
    }

    if (file.bytes == null || file.bytes!.isEmpty) {
      _showSnack('Could not read file data. Please try again.', isError: true);
      return;
    }

    setState(() => _uploadingDocKey = docKey);

    try {
      // OCR check (no-op on Android/Windows stub — see ocr_service.dart)
      final ocrWarnings = await OcrService.validateDocument(
        imagePath: file.path,
        docType: docKey,
        teacherName: widget.user.fullName,
        icNumber: widget.user.icNumber,
        dob: widget.user.dob,
      );

      if (ocrWarnings.isNotEmpty && mounted) {
        final proceed = await _showOcrWarningDialog(ocrWarnings);
        if (proceed != true) {
          setState(() => _uploadingDocKey = null);
          return;
        }
      }

      final url = await CloudinaryService.uploadFile(
        file.bytes!,
        file.name,
        folder: 'teacher-documents/${widget.user.id}',
      );

      if (url == null) throw Exception('Upload failed');

      await _service.updateDocumentStatus(
        widget.user.id,
        docKey,
        'uploaded',
        url: url,
        ocrWarnings: ocrWarnings,
      );

      // Optimistic UI update — reflect the new status locally so the teacher
      // sees "Pending Review" immediately without waiting for a stream re-read.
      final updatedDocs =
          Map<String, DocumentRecord>.from(widget.user.documents);
      if (updatedDocs.containsKey(docKey)) {
        updatedDocs[docKey] = updatedDocs[docKey]!.copyWith(
          status: 'uploaded',
          url: url,
          uploadedAt: DateTime.now().toIso8601String(),
          rejectionReason: '',
        );
      }
      appState.updateCurrentUser(
          widget.user.copyWith(documents: updatedDocs));

      if (mounted) _showSnack('$docName uploaded successfully.', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingDocKey = null);
    }
  }

  Future<bool?> _showOcrWarningDialog(List<String> warnings) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Document Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The following inconsistencies were detected:'),
            const SizedBox(height: 10),
            ...warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Icon(LucideIcons.alertTriangle, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(child: Text(w, style: const TextStyle(fontSize: 13))),
                  ]),
                )),
            const SizedBox(height: 10),
            const Text('Do you still want to upload this document?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Upload Anyway')),
        ],
      ),
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // widget.user is kept up-to-date by the provider (optimistic updates on
    // profile save and document upload). Using it directly means any
    // updateCurrentUser() call immediately reflects here without needing a
    // stream re-read that would lag behind or show stale SDK cache data.
    final teacher = widget.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(teacher),
              const SizedBox(height: 20),
              _buildVerificationBanner(teacher),
              const SizedBox(height: 20),
              _buildIdentitySection(teacher),
              const SizedBox(height: 20),
              _buildPersonalInfoSection(),
              const SizedBox(height: 20),
              _buildDocumentsSection(teacher),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(TeacherRecord t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              t.fullName.isNotEmpty ? t.fullName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.fullName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(t.role.toUpperCase(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: t.completionProgress / 100,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text('Profile ${t.completionProgress}% complete',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Verification banner ────────────────────────────────────────────────────

  Widget _buildVerificationBanner(TeacherRecord t) {
    late Color bg, border, textColor;
    late IconData icon;
    late String message;

    switch (t.verificationStatus) {
      case 'approved':
        bg = Colors.green.shade50;
        border = Colors.green.shade200;
        textColor = Colors.green.shade800;
        icon = LucideIcons.checkCircle;
        message = 'Your record has been approved by the administrator.';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        border = Colors.red.shade200;
        textColor = Colors.red.shade800;
        icon = LucideIcons.xCircle;
        message = t.verificationRejectionReason.isNotEmpty
            ? 'Your record was rejected: ${t.verificationRejectionReason}'
            : 'Your record was rejected. Please resubmit your documents.';
        break;
      default:
        bg = Colors.amber.shade50;
        border = Colors.amber.shade200;
        textColor = Colors.amber.shade900;
        icon = LucideIcons.clock;
        message = 'Your record is pending review. Ensure all documents are submitted.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: textColor),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(color: textColor, fontSize: 13))),
      ]),
    );
  }

  // ── Identity (read-only) ───────────────────────────────────────────────────

  Widget _buildIdentitySection(TeacherRecord t) {
    return _Card(
      title: 'Identity Information',
      trailing: OutlinedButton.icon(
        icon: const Icon(LucideIcons.pencil, size: 14),
        label: const Text('Request Change', style: TextStyle(fontSize: 13)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChangeRequestScreen(teacher: t)),
        ),
      ),
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Icon(LucideIcons.lock, size: 14, color: AppTheme.textMuted),
            SizedBox(width: 6),
            Text('These fields cannot be edited directly.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ]),
        ),
        _rowFields([
          _ReadField('Full Name', t.fullName),
          _ReadField('IC Number', t.icNumber),
        ]),
        const SizedBox(height: 12),
        _rowFields([
          _ReadField('Gender', t.gender),
          _ReadField('Date of Birth', t.dob),
        ]),
      ]),
    );
  }

  Widget _rowFields(List<Widget> children) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const SizedBox(width: 12));
      items.add(Expanded(child: children[i]));
    }
    return Row(children: items);
  }

  // ── Personal info (editable) ───────────────────────────────────────────────

  Widget _buildPersonalInfoSection() {
    return _Card(
      title: 'Personal Information',
      child: Form(
        key: _formKey,
        child: Column(children: [
          _rowFields([
            _Field('Contact Number', _phoneCtrl,
                validator: _validatePhone, keyboard: TextInputType.phone),
            _Field('Email Address', _emailCtrl,
                validator: _validateEmail, keyboard: TextInputType.emailAddress),
          ]),
          const SizedBox(height: 14),
          _Field('Residential Address', _addressCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
              maxLines: 2),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _maritalStatus,
            decoration: _fieldDeco('Marital Status'),
            items: _maritalOptions
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            validator: (v) => v == null ? 'Please select marital status' : null,
            onChanged: (v) => setState(() => _maritalStatus = v),
          ),
          const SizedBox(height: 14),
          _rowFields([
            _Field('Emergency Contact Person', _emergencyNameCtrl,
                validator: _validateName),
            _Field('Emergency Contact Number', _emergencyNumCtrl,
                validator: _validatePhone, keyboard: TextInputType.phone),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Documents ──────────────────────────────────────────────────────────────

  Widget _buildDocumentsSection(TeacherRecord t) {
    const docs = [
      ('myKad', 'Copy of Identification Card (MyKad)'),
      ('passportPhoto', 'Passport Photo'),
      ('resume', 'Resume / CV'),
      ('academicCertificates', 'Latest Academic Certificates'),
      ('medicalReport', 'Medical Check Up Report'),
      ('bankStatement', 'Bank Statement Header'),
    ];

    return _Card(
      title: 'Supporting Documents',
      subtitle: 'Accepted formats: PDF, JPG, PNG  •  Max 5 MB per file',
      child: Column(
        children: docs
            .map((d) => _DocumentCard(
                  docKey: d.$1,
                  docName: d.$2,
                  record: t.documents[d.$1],
                  isUploading: _uploadingDocKey == d.$1,
                  onUpload: () => _uploadDocument(d.$1, d.$2),
                ))
            .toList(),
      ),
    );
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final clean = v.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (!RegExp(r'^\d{8,15}$').hasMatch(clean)) return 'Enter a valid phone number';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.]+$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    if (RegExp(r'\d').hasMatch(v)) return 'Name cannot contain numbers';
    return null;
  }
}

// ── Shared card wrapper ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  const _Card({required this.title, required this.child, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.subtleGrayBoundary),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppTheme.subtleGrayBoundary),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

// ── Read-only info tile ────────────────────────────────────────────────────────

class _ReadField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.canvasBase,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.subtleGrayBoundary),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '—',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: value.isNotEmpty ? AppTheme.textCore : AppTheme.textMuted,
          ),
        ),
      ]),
    );
  }
}

// ── Editable text field ────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final int maxLines;
  const _Field(this.label, this.controller,
      {this.validator, this.keyboard, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: _fieldDeco(label),
    );
  }
}

InputDecoration _fieldDeco(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppTheme.canvasBase,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.subtleGrayBoundary)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.subtleGrayBoundary)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

// ── Document card ──────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final String docKey;
  final String docName;
  final DocumentRecord? record;
  final bool isUploading;
  final VoidCallback onUpload;
  const _DocumentCard({
    required this.docKey,
    required this.docName,
    required this.record,
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final status = record?.status ?? 'empty';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = LucideIcons.checkCircle;
        statusLabel = 'Verified';
        break;
      case 'uploaded':
        statusColor = Colors.blue;
        statusIcon = LucideIcons.clock;
        statusLabel = 'Pending Review';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = LucideIcons.xCircle;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = AppTheme.textMuted;
        statusIcon = LucideIcons.fileX;
        statusLabel = 'Not Uploaded';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.canvasBase,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: status == 'rejected'
              ? Colors.red.shade200
              : AppTheme.subtleGrayBoundary,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Row 1: icon + full-width name
        Row(children: [
          Icon(LucideIcons.fileText, size: 15, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(docName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 8),
        // Row 2: status chip + spacer + upload button
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(statusIcon, size: 11, color: statusColor),
              const SizedBox(width: 4),
              Text(statusLabel,
                  style: TextStyle(
                      fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ]),
          ),
          const Spacer(),
          SizedBox(
            height: 32,
            child: isUploading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : OutlinedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(LucideIcons.upload, size: 13),
                    label: Text(
                      status == 'empty' ? 'Upload' : 'Re-upload',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
          ),
        ]),

        // Rejection reason
        if (status == 'rejected' && (record?.rejectionReason ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 26),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(LucideIcons.alertCircle, size: 13, color: Colors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  record!.rejectionReason,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ]),
          ),

        // OCR warnings
        if ((record?.ocrWarnings ?? []).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: record!.ocrWarnings
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(children: [
                          const Icon(LucideIcons.alertTriangle, size: 12, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(w,
                                  style: const TextStyle(fontSize: 11, color: Colors.orange))),
                        ]),
                      ))
                  .toList(),
            ),
          ),

        // Upload date
        if ((record?.uploadedAt ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 26),
            child: Text(
              'Uploaded: ${_formatDate(record!.uploadedAt)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
