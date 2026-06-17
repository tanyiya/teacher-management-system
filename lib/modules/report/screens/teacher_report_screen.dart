// swtich to report history

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app_theme.dart';
import '../../../modules/teachers/models/teacher.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import 'create_report_screen.dart';

class TeacherReportScreen extends StatefulWidget {
  final TeacherRecord user;
  const TeacherReportScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<TeacherReportScreen> createState() => _TeacherReportScreenState();
}

class _TeacherReportScreenState extends State<TeacherReportScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dayStr =
        DateFormat('EEEE, d MMMM').format(today).toUpperCase();
    final score = widget.user.currentScore;

    return Container(
      color: const Color(0xFFF2F1EE),
      child: Column(
        children: [
          // ── Profile header ──────────────────────────────────────
          Container(
            color: const Color(0xFFF2F1EE),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dayStr,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                            widget.user.fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(LucideIcons.user,
                          color: Colors.grey.shade400, size: 22),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFE8E8E5)),
                        ),
                        child: const Icon(Icons.logout,
                            size: 18, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${score}% COMPLETE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'FACULTY SAFETY & SUPPORT',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Incident Reporting',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Tab Switcher ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<List<FacilityReport>>(
              stream: ReportService().getMyReports(widget.user.id),
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
                        onTap: () =>
                            setState(() => _showHistory = false),
                      ),
                      _TabButton(
                        label:
                            'Report History${count > 0 ? ' ($count)' : ''}',
                        selected: _showHistory,
                        onTap: () =>
                            setState(() => _showHistory = true),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ── Content ────────────────────────────────────────────
          Expanded(
            child: _showHistory
                ? _HistoryTab(user: widget.user)
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
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
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
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── File a Report Tab ─────────────────────────────────────────────────────────

class _FileReportTab extends StatelessWidget {
  final TeacherRecord user;
  const _FileReportTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Big action card
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreateReportScreen(user: user)),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E8E5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.alertTriangle,
                        color: Colors.red.shade400, size: 24),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Submit an Incident Report',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Report any safety concern, misconduct, facility damage, or staff conflict. Your report goes directly to the principal.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'File a Report →',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.shieldCheck,
                    size: 18, color: Colors.blue.shade600),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All reports are confidential and reviewed by the principal only.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Report History Tab ────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final TeacherRecord user;
  const _HistoryTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FacilityReport>>(
      stream: ReportService().getMyReports(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.fileText,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No reports submitted yet.',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14)),
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
                      Text(
                        report.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SUBMITTED: ${DateFormat('MMM d, yyyy, h:mm a').format(report.createdAt).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusInfo.color.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusInfo.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusInfo.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: priorityColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        '${report.priority.toUpperCase()} PRIORITY',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: priorityColor.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4),
            ),
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
                    Icon(LucideIcons.messageSquare,
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                            color:
                                statusInfo.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusInfo.color
                                    .withOpacity(0.3))),
                        child: Text(statusInfo.label.toUpperCase(),
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
                        color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const Divider(height: 28),
                  Text(report.description,
                      style: const TextStyle(
                          fontSize: 14, height: 1.5)),
                  if (report.photoUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(report.photoUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover),
                    ),
                  ],
                  if (report.managementNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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