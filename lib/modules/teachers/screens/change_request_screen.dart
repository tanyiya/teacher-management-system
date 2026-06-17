import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app_theme.dart';
import '../../../core/services/cloudinary_service.dart';
import '../models/change_request.dart';
import '../models/teacher.dart';
import '../services/teacher_service.dart';

class ChangeRequestScreen extends StatefulWidget {
  final TeacherRecord teacher;
  const ChangeRequestScreen({super.key, required this.teacher});

  @override
  State<ChangeRequestScreen> createState() => _ChangeRequestScreenState();
}

class _ChangeRequestScreenState extends State<ChangeRequestScreen> {
  static const _fields = [
    ('fullName', 'Full Name'),
    ('icNumber', 'IC Number'),
    ('gender', 'Gender'),
    ('dob', 'Date of Birth'),
  ];

  static const _genderOptions = ['Male', 'Female'];

  final _formKey = GlobalKey<FormState>();
  final _service = TeacherService();

  String _selectedField = 'fullName';
  final _newValueCtrl = TextEditingController();
  String? _genderValue;

  PlatformFile? _supportingDoc;
  bool _isSubmitting = false;
  bool _submitted = false;

  String get _currentValue {
    switch (_selectedField) {
      case 'fullName':
        return widget.teacher.fullName;
      case 'icNumber':
        return widget.teacher.icNumber;
      case 'gender':
        return widget.teacher.gender;
      case 'dob':
        return widget.teacher.dob;
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _newValueCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedField = value;
      _newValueCtrl.clear();
      _genderValue = null;
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > 5 * 1024 * 1024) {
      _showSnack('File too large. Maximum size is 5 MB.', isError: true);
      return;
    }
    setState(() => _supportingDoc = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supportingDoc == null) {
      _showSnack('Please attach a supporting document.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String docUrl = '';
      if (_supportingDoc!.bytes != null) {
        docUrl = await CloudinaryService.uploadFile(
              _supportingDoc!.bytes!,
              _supportingDoc!.name,
              folder: 'change-requests/${widget.teacher.id}',
            ) ??
            '';
      }

      final newValue = _selectedField == 'gender' ? (_genderValue ?? '') : _newValueCtrl.text.trim();

      final request = ChangeRequest(
        id: '${widget.teacher.id}_${_selectedField}_${DateTime.now().millisecondsSinceEpoch}',
        teacherId: widget.teacher.id,
        teacherName: widget.teacher.fullName,
        field: _selectedField,
        oldValue: _currentValue,
        newValue: newValue,
        documentUrl: docUrl,
        submittedAt: DateTime.now().toIso8601String(),
      );

      await _service.submitChangeRequest(request)
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) _showSnack('Submission failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
    return Scaffold(
      backgroundColor: AppTheme.canvasBase,
      appBar: AppBar(
        title: const Text('Request Identity Change'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.checkCircle, size: 36, color: Colors.green.shade600),
            ),
            const SizedBox(height: 20),
            const Text('Request Submitted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Your change request has been sent to the administrator for review.\nYou will be notified once a decision is made.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(LucideIcons.info, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Identity information can only be changed by submitting a request with valid supporting documents. The administrator will review and approve or reject your request.',
                        style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Field selector
                _sectionLabel('Field to Change'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedField,
                  decoration: _deco('Select identity field'),
                  items: _fields
                      .map((f) => DropdownMenuItem(value: f.$1, child: Text(f.$2)))
                      .toList(),
                  onChanged: _onFieldChanged,
                ),
                const SizedBox(height: 20),

                // Current value
                _sectionLabel('Current Value'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasBase,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.subtleGrayBoundary),
                  ),
                  child: Text(
                    _currentValue.isNotEmpty ? _currentValue : '—',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 20),

                // New value
                _sectionLabel('New Value'),
                const SizedBox(height: 8),
                if (_selectedField == 'gender')
                  DropdownButtonFormField<String>(
                    value: _genderValue,
                    decoration: _deco('Select gender'),
                    items: _genderOptions
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    validator: (v) => v == null ? 'Please select a gender' : null,
                    onChanged: (v) => setState(() => _genderValue = v),
                  )
                else
                  TextFormField(
                    controller: _newValueCtrl,
                    decoration: _deco(_selectedField == 'dob'
                        ? 'New date (YYYY-MM-DD)'
                        : 'Enter new value'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'This field is required';
                      if (_selectedField == 'fullName' && RegExp(r'\d').hasMatch(v)) {
                        return 'Name cannot contain numbers';
                      }
                      if (_selectedField == 'icNumber' &&
                          !RegExp(r'^\d{6}-\d{2}-\d{4}$').hasMatch(v.trim())) {
                        return 'IC must be in format YYMMDD-SS-NNNN';
                      }
                      if (_selectedField == 'dob') {
                        try {
                          final d = DateTime.parse(v.trim());
                          if (d.isAfter(DateTime.now())) return 'Date of birth cannot be in the future';
                        } catch (_) {
                          return 'Enter a valid date (YYYY-MM-DD)';
                        }
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 24),

                // Supporting document
                _sectionLabel('Supporting Document'),
                const SizedBox(height: 4),
                const Text(
                  'Attach a clear copy of a valid document that supports this change (e.g., updated MyKad, deed poll, birth certificate).',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickDocument,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _supportingDoc != null
                            ? AppTheme.primaryColor
                            : AppTheme.subtleGrayBoundary,
                        style: BorderStyle.solid,
                      ),
                      color: _supportingDoc != null
                          ? AppTheme.primaryColor.withValues(alpha: 0.05)
                          : AppTheme.canvasBase,
                    ),
                    child: _supportingDoc == null
                        ? const Column(children: [
                            Icon(LucideIcons.upload, color: AppTheme.textMuted),
                            SizedBox(height: 6),
                            Text('Tap to select file',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            Text('PDF, JPG, PNG — max 5 MB',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          ])
                        : Row(children: [
                            const Icon(LucideIcons.fileCheck, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_supportingDoc!.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () => setState(() => _supportingDoc = null),
                            ),
                          ]),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Request'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      );
}
