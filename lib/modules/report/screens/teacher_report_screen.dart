// TEACHER SCREEN
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../modules/teachers/models/teacher.dart';
import '../../../app_theme.dart';
import '../models/report.dart';
import '../services/report_service.dart';

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
  // When true, the screen opens directly on the Report History tab instead
  // of the default "File a Report" tab. Used when a notification about an
  // updated report status is tapped.
  final bool showHistory;
  const TeacherReportScreen({Key? key, required this.user, this.showHistory = false}) : super(key: key);

  @override
  State<TeacherReportScreen> createState() => _TeacherReportScreenState();
}

class _TeacherReportScreenState extends State<TeacherReportScreen> {
  late bool _showHistory = widget.showHistory;

  // Used ONLY for the tab badge count. _HistoryTab owns its own separate stream.
  late final Stream<List<FacilityReport>> _countStream;

  @override
  void initState() {
    super.initState();
    _countStream = ReportService().getMyReports(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBase,
      // ── Clean AppBar with only back arrow ──────────────────
      appBar: AppBar(
        backgroundColor: AppTheme.canvasBase,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.subtleGrayBoundary),
            ),
            child: const Icon(Icons.arrow_back,
                size: 18, color: AppTheme.schoolDarkBlue),
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
                  'TADIKA AQIL MIQAIL',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.schoolBlue.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Incident Reporting',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.schoolDarkBlue,
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
              stream: _countStream,
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.subtleGrayBoundary),
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
                ? _HistoryTab(userId: widget.user.id)
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
            color: selected ? AppTheme.schoolBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: AppTheme.schoolBlue.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [],
            border: selected
                ? Border.all(color: AppTheme.schoolBlue.withValues(alpha: 0.2))
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
                    ? Colors.white
                    : AppTheme.textMuted,
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
                decoration: const BoxDecoration(
                  color: AppTheme.schoolLightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.schoolBlue, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('Submit Incident Report?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.schoolDarkBlue)),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to finalize and submit this incident report to the administration? This will notify school leadership immediately.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
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
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.subtleGrayBoundary),
                        ),
                        child: const Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppTheme.textCore)),
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
                          color: AppTheme.schoolBlue,
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
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.subtleGrayBoundary),
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
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.subtleGrayBoundary),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(
                          Icons.keyboard_arrow_down, size: 20, color: AppTheme.schoolBlue),
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textCore,
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
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.subtleGrayBoundary),
                  ),
                  child: TextField(
                    controller: _descCtrl,
                    maxLines: 5,
                    style: const TextStyle(color: AppTheme.textCore),
                    decoration: InputDecoration(
                      hintText:
                          'Provide specific details of the incident, including dates, locations, and any direct impact...',
                      hintStyle: TextStyle(
                          color: AppTheme.textMuted.withValues(alpha: 0.6),
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
                                color: Colors.black.withValues(alpha: 0.6),
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
                            color: AppTheme.subtleGrayBoundary),
                      ),
                      child: const Center(
                        child: Text('Change Photo',
                            style: TextStyle(
                                color: AppTheme.schoolBlue,
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
                              color: AppTheme.ambientOffWhite,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.subtleGrayBoundary),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.upload_file,
                                    size: 26,
                                    color: AppTheme.schoolBlue),
                                const SizedBox(height: 8),
                                const Text('From Gallery',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.textCore)),
                                const SizedBox(height: 4),
                                Text(
                                    'Drag-and-drop or\nselect',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted.withValues(alpha: 0.8),
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
                                  ? AppTheme.canvasBase
                                  : AppTheme.ambientOffWhite,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.subtleGrayBoundary),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 26,
                                    color: kIsWeb
                                        ? AppTheme.textMuted.withValues(alpha: 0.3)
                                        : AppTheme.schoolBlue.withValues(alpha: 0.8)),
                                const SizedBox(height: 8),
                                Text('Take Photo',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 13,
                                        color: kIsWeb
                                            ? AppTheme.textMuted.withValues(alpha: 0.4)
                                            : AppTheme.textCore)),
                                const SizedBox(height: 4),
                                Text(
                                    kIsWeb
                                        ? 'Not available\non web'
                                        : 'Use device\ncamera',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted.withValues(alpha: 0.8),
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
                    ? AppTheme.subtleGrayBoundary
                    : AppTheme.schoolOrange,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isSubmitting ? [] : [
                  BoxShadow(
                    color: AppTheme.schoolOrange.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
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
                          color: AppTheme.schoolBlue),
                    )
                  else
                    const Icon(Icons.description_outlined,
                        size: 18, color: Colors.white),
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
                          ? AppTheme.textMuted
                          : Colors.white,
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

class _HistoryTab extends StatefulWidget {
  final String userId;
  const _HistoryTab({required this.userId});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  late final Stream<List<FacilityReport>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = ReportService().getMyReports(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FacilityReport>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

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
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined,
                    size: 48, color: AppTheme.subtleGrayBoundary),
                const SizedBox(height: 12),
                Text('No reports submitted yet.',
                    style: TextStyle(
                        color: AppTheme.textCore,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('Your submitted reports will appear here.',
                    style: TextStyle(
                        color: AppTheme.textMuted,
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
        ? const Color(0xFFD32F2F)
        : report.priority == 'Medium'
            ? AppTheme.schoolOrange
            : AppTheme.schoolBlue;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.subtleGrayBoundary),
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
                              color: AppTheme.schoolDarkBlue)),
                      const SizedBox(height: 4),
                      Text(
                        'SUBMITTED: ${DateFormat('MMM d, yyyy, h:mm a').format(report.createdAt).toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
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
                            color: statusInfo.color.withValues(alpha: 0.3)),
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
                            color: priorityColor.withValues(alpha: 0.9),
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
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textCore,
                    height: 1.4)),
            if (report.photoUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.image_outlined,
                      size: 13, color: AppTheme.schoolBlue),
                  const SizedBox(width: 4),
                  Text('Photo attached',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.schoolBlue,
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
                  color: AppTheme.schoolLightBlue.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.message_outlined,
                        size: 12, color: AppTheme.schoolDarkBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Management: ${report.managementNotes}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.schoolDarkBlue,
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
                      color: AppTheme.subtleGrayBoundary,
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
                                color: AppTheme.schoolDarkBlue)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: statusInfo.color.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                                color: statusInfo.color.withValues(alpha: 0.3))),
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
                    style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13),
                  ),
                  const Divider(height: 28, color: AppTheme.subtleGrayBoundary),
                  Text(report.description,
                      style: const TextStyle(
                          color: AppTheme.textCore,
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
                          color: AppTheme.canvasBase,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: AppTheme.textMuted,
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
                          color: AppTheme.schoolLightBlue.withValues(alpha: 0.4),
                          borderRadius:
                              BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Management Response',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.schoolDarkBlue,
                                  fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(report.managementNotes,
                              style: const TextStyle(
                                  color: AppTheme.schoolDarkBlue,
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
        return _StatusMeta('Under Review', AppTheme.schoolOrange);
      case 'Action Taken':
        return _StatusMeta('Action Taken', AppTheme.schoolOrange);
      case 'Resolved':
        return _StatusMeta('Resolved', const Color(0xFF2E7D32));
      default:
        return _StatusMeta('Submitted', AppTheme.schoolBlue);
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
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 0.9,
        decoration: TextDecoration.none,
      ),
    );
  }
}