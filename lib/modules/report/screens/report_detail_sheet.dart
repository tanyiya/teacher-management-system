import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../app_theme.dart';
import '../models/report.dart';
import '../services/report_service.dart';

class ReportDetailSheet extends StatefulWidget {
  final FacilityReport report;
  final ReportService svc;

  const ReportDetailSheet({Key? key, required this.report, required this.svc})
      : super(key: key);

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  late String _status;
  late String _priority;
  late TextEditingController _notesCtrl;
  bool _saving = false;

  static const _statuses = [
    'Submitted (Pending)',
    'Under Review',
    'Action Taken',
    'Resolved',
  ];
  static const _priorities = ['Low', 'Medium', 'High'];

  String _toStoredStatus(String display) {
    if (display == 'Submitted (Pending)') return 'Submitted';
    return display;
  }

  String _toDisplayStatus(String stored) {
    if (stored == 'Submitted') return 'Submitted (Pending)';
    return stored;
  }

  @override
  void initState() {
    super.initState();
    _status = _toDisplayStatus(widget.report.status);
    _priority = widget.report.priority;
    _notesCtrl = TextEditingController(text: widget.report.managementNotes);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // ── FIX: pass teacherId and category for notification ──
      await widget.svc.updateReport(
        reportId: widget.report.id,
        status: _toStoredStatus(_status),
        managementNotes: _notesCtrl.text.trim(),
        priority: _priority,
        teacherId: widget.report.teacherId,
        category: widget.report.category,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report updated. Teacher has been notified.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseId = '#${widget.report.id.substring(0, 8).toUpperCase()}';
    final timestamp =
        DateFormat('MMM d, yyyy, h:mm a').format(widget.report.createdAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CASE ID: $caseId',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.report.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Reporter info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8E8E5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('REPORTED BY',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade400,
                                      letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              Text(
                                widget.report.teacherName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1A1A1A)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('TIMESTAMP',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade400,
                                    letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            Text(
                              timestamp,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF1A1A1A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Teacher statement
                  _SectionLabel('TEACHER STATEMENT'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E0DD)),
                    ),
                    child: Text(
                      widget.report.description.isEmpty
                          ? '—'
                          : widget.report.description,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                          height: 1.5),
                    ),
                  ),

                  // Photo evidence
                  if (widget.report.photoUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionLabel('PHOTO EVIDENCE'),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.report.photoUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    color: Colors.grey.shade400, size: 36),
                                const SizedBox(height: 8),
                                Text('Image unavailable',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Admin controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8E8E5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADMINISTRATIVE ACTION CONTROLS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('REPORT STATUS',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade400,
                                          letterSpacing: 0.8)),
                                  const SizedBox(height: 6),
                                  _ActionDropdown<String>(
                                    value: _status,
                                    items: _statuses,
                                    onChanged: (v) =>
                                        setState(() => _status = v ?? _status),
                                    highlightValue: 'Action Taken',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PRIORITY LEVEL',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade400,
                                          letterSpacing: 0.8)),
                                  const SizedBox(height: 6),
                                  _ActionDropdown<String>(
                                    value: _priority,
                                    items: _priorities,
                                    onChanged: (v) => setState(
                                        () => _priority = v ?? _priority),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                "Add management notes (e.g., 'Disciplinary action taken', 'Hazard removed'). These notes will notify and update the teacher.",
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                height: 1.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD8D8D5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD8D8D5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: AppTheme.primaryColor),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Submit button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Color(0xFFF0EFEC))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saving
                        ? Colors.grey.shade300
                        : const Color(0xFF2D6A4F),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'UPDATING AND NOTIFYING...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'UPDATE & NOTIFY TEACHER',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade400,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ActionDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final T? highlightValue;

  const _ActionDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.highlightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D0CD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A)),
          selectedItemBuilder: (context) => items
              .map((item) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item.toString(),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A))),
                  ))
              .toList(),
          items: items.map((item) {
            final isHighlighted = item == highlightValue;
            return DropdownMenuItem<T>(
              value: item,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: isHighlighted
                    ? BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(
                  item.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isHighlighted
                        ? Colors.white
                        : const Color(0xFF1A1A1A),
                    fontWeight: isHighlighted
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}