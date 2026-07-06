// TEACHER SCREEN
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../modules/teachers/models/teacher.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../../../core/services/cloudinary_service.dart';

const List<String> kReportCategories = [
  'Sexual Harassment Report',
  'Bullying Report (Physical/Emotional/Social Media)',
  'Conflict Between Staff Report',
  'SOP Violation Report',
  'Workload Stress Report',
  'Teacher Misconduct Report',
  'Facility Maintenance Report',
  'Teaching Material Shortage Report',
  'Safety Hazard Report',
  'IT/System Problem Report',
];

class TeacherReportScreen extends StatefulWidget {
  final TeacherRecord user;
  const TeacherReportScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<TeacherReportScreen> createState() => _TeacherReportScreenState();
}

class _TeacherReportScreenState extends State<TeacherReportScreen> {
  bool _showHistory = false;
  late final Stream<List<FacilityReport>> _myReportsStream;

  @override
  void initState() {
    super.initState();
    _myReportsStream = ReportService().getMyReports(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1EE),
      // ── Clean AppBar with only back arrow ──────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F1EE),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8E8E5)),
            ),
            child: const Icon(Icons.arrow_back,
                size: 18, color: Color(0xFF1A1A1A)),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page title only ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCHOOL SAFETY & SUPPORT',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Incident Reporting',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Tab Switcher ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<List<FacilityReport>>(
              stream: _myReportsStream,
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E5)),
                  ),
                  child: Row(
                    children: [
                      _TabButton(
                        label: 'File a Report',
                        selected: !_showHistory,
                        onTap: () => setState(() => _showHistory = false),
                      ),
                      _TabButton(
                        label: 'Report History ($count)',
                        selected: _showHistory,
                        onTap: () => setState(() => _showHistory = true),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ── Content ───────────────────────────────────────
          Expanded(
            child: _showHistory
                ? _HistoryTab(stream: _myReportsStream)
                : _FileReportTab(user: widget.user),
          ),
        ],
      ),
    );
  }
}

// ── Tab Button ────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [],
            border: selected
                ? Border.all(color: const Color(0xFFE0E0DD))
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey.shade500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── File a Report Tab ─────────────────────────────────────────────────────────

class _FileReportTab extends StatefulWidget {
  final TeacherRecord user;
  const _FileReportTab({required this.user});

  @override
  State<_FileReportTab> createState() => _FileReportTabState();
}

class _FileReportTabState extends State<_FileReportTab> {
  final _descCtrl = TextEditingController();
  String _selectedCategory = kReportCategories.first;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isSubmitting = false;

  final ReportService _svc = ReportService();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1600);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a description.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.grey.shade400, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('Submit Incident Report?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to finalize and submit this incident report to the administration? This will notify school leadership immediately.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE0E0DD)),
                        ),
                        child: const Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A1A))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8FA888),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Yes, Submit',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final report = FacilityReport(
        id: '',
        teacherId: widget.user.id,
        teacherName: widget.user.fullName,
        category: _selectedCategory,
        description: _descCtrl.text.trim(),
        priority: 'Low',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await _svc.submitReport(
        report,
        imageBytes: _imageBytes,
        fileName: _imageName,
      );

      if (!mounted) return;

      setState(() {
        _descCtrl.clear();
        _selectedCategory = kReportCategories.first;
        _imageBytes = null;
        _imageName = null;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error submitting: $e'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E8E5)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                const _FieldLabel('SELECT REPORT CATEGORY'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFD8D8D5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(
                          Icons.keyboard_arrow_down, size: 20),
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w500),
                      items: kReportCategories
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: const TextStyle(
                                      fontSize: 14))))
                          .toList(),
                      onChanged: (v) => setState(() =>
                          _selectedCategory =
                              v ?? _selectedCategory),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const _FieldLabel('DESCRIPTION'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFD8D8D5)),
                  ),
                  child: TextField(
                    controller: _descCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText:
                          'Provide specific details of the incident, including dates, locations, and any direct impact...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          height: 1.5),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Photo
                const _FieldLabel('ATTACH PHOTO/EVIDENCE'),
                const SizedBox(height: 10),

                if (_imageBytes != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imageBytes!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _imageBytes = null;
                            _imageName = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius:
                                    BorderRadius.circular(20)),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFD8D8D5)),
                      ),
                      child: Center(
                        child: Text('Change Photo',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      // Gallery button
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _pickImage(ImageSource.gallery),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F6),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      const Color(0xFFE0E0DD)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.upload_file,
                                    size: 26,
                                    color: Colors.grey.shade500),
                                const SizedBox(height: 8),
                                Text('From Gallery',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 13,
                                        color:
                                            Colors.grey.shade700)),
                                const SizedBox(height: 4),
                                Text(
                                    'Drag-and-drop or\nselect',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.grey.shade400,
                                        height: 1.4)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Camera button — disabled on web
                      Expanded(
                        child: GestureDetector(
                          onTap: kIsWeb
                              ? null
                              : () =>
                                  _pickImage(ImageSource.camera),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 22),
                            decoration: BoxDecoration(
                              color: kIsWeb
                                  ? Colors.grey.shade100
                                  : const Color(0xFFF8F8F6),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      const Color(0xFFE0E0DD)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 26,
                                    color: kIsWeb
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Take Photo',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 13,
                                        color: kIsWeb
                                            ? Colors.grey.shade300
                                            : Colors
                                                .grey.shade500)),
                                const SizedBox(height: 4),
                                Text(
                                    kIsWeb
                                        ? 'Not available\non web'
                                        : 'Use device\ncamera',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.grey.shade400,
                                        height: 1.4)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit button
          GestureDetector(
            onTap: _isSubmitting ? null : _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _isSubmitting
                    ? Colors.grey.shade300
                    : const Color(0xFFDDE5D8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white),
                    )
                  else
                    Icon(Icons.description_outlined,
                        size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Text(
                    _isSubmitting
                        ? 'SUBMITTING...'
                        : 'SUBMIT INCIDENT REPORT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: _isSubmitting
                          ? Colors.grey.shade500
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Report History Tab ────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final Stream<List<FacilityReport>> stream;
  const _HistoryTab({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FacilityReport>>(
      stream: stream,
      builder: (context, snapshot) {
        // Show loading only on first load
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error if any
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 40, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load reports.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No reports submitted yet.',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('Your submitted reports will appear here.',
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: reports.length,
          itemBuilder: (_, i) => _HistoryCard(report: reports[i]),
        );
      },
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final FacilityReport report;
  const _HistoryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(report.status);
    final priorityColor = report.priority == 'High'
        ? Colors.red
        : report.priority == 'Medium'
            ? Colors.orange
            : Colors.green;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.category,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      Text(
                        'SUBMITTED: ${DateFormat('MMM d, yyyy, h:mm a').format(report.createdAt).toUpperCase()}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                statusInfo.color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusInfo.label.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusInfo.color,
                            letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: priorityColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '${report.priority.toUpperCase()} PRIORITY',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: priorityColor.withValues(alpha: 0.7),
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4)),
            if (report.photoUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.image_outlined,
                      size: 13, color: Colors.blue.shade400),
                  const SizedBox(width: 4),
                  Text('Photo attached',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade400,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
            if (report.managementNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.message_outlined,
                        size: 12, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Management: ${report.managementNotes}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final statusInfo = _statusInfo(report.status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(report.category,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: statusInfo.color
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                                color: statusInfo.color
                                    .withValues(alpha: 0.3))),
                        child: Text(
                            statusInfo.label.toUpperCase(),
                            style: TextStyle(
                                color: statusInfo.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d MMMM yyyy, h:mm a')
                        .format(report.createdAt),
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13),
                  ),
                  const Divider(height: 28),
                  Text(report.description,
                      style: const TextStyle(
                          fontSize: 14, height: 1.5)),
                  if (report.photoUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        report.photoUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.grey.shade400,
                                size: 36),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (report.managementNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius:
                              BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Management Response',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                  fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(report.managementNotes,
                              style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusMeta _statusInfo(String status) {
    switch (status) {
      case 'Under Review':
        return _StatusMeta('Under Review', Colors.orange);
      case 'Action Taken':
        return _StatusMeta('Action Taken', Colors.blue);
      case 'Resolved':
        return _StatusMeta('Resolved', Colors.green);
      default:
        return _StatusMeta('Submitted', Colors.grey);
    }
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  _StatusMeta(this.label, this.color);
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.9,
        decoration: TextDecoration.none,
      ),
    );
  }
}