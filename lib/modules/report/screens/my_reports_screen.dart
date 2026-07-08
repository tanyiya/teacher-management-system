// PRINCIPAL SCREEN
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../app_theme.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import 'report_detail_sheet.dart';

class ReportScreen extends StatefulWidget {
  final String? initialReportId;
  const ReportScreen({Key? key, this.initialReportId}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _svc = ReportService();
  String _filterStatus = 'All Statuses';
  String _filterCategory = 'All Categories';

  @override
  void initState() {
    super.initState();
    if (widget.initialReportId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openReportById(widget.initialReportId!));
    }
  }

  Future<void> _openReportById(String id) async {
    final report = await _svc.getReportById(id);
    if (report == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportDetailSheet(report: report, svc: _svc),
    );
  }

  // ── Sort: pending/in-progress first, resolved last ────────
  List<FacilityReport> _sortReports(List<FacilityReport> list) {
    const priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
    const statusOrder = {'Submitted': 0, 'Under Review': 1, 'Action Taken': 2};

    final pending = list
        .where((r) => r.status != 'Resolved')
        .toList()
      ..sort((a, b) {
        // 1️⃣ Priority: High → Medium → Low
        final aPriority = priorityOrder[a.priority] ?? 3;
        final bPriority = priorityOrder[b.priority] ?? 3;
        if (aPriority != bPriority) return aPriority.compareTo(bPriority);

        // 2️⃣ Status: Submitted → Under Review → Action Taken
        final aStatus = statusOrder[a.status] ?? 3;
        final bStatus = statusOrder[b.status] ?? 3;
        if (aStatus != bStatus) return aStatus.compareTo(bStatus);

        // 3️⃣ Date: newest first
        return b.createdAt.compareTo(a.createdAt);
      });

    final resolved = list
        .where((r) => r.status == 'Resolved')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return [...pending, ...resolved];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FacilityReport>>(
      stream: _svc.getReports(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];

        final pending = all.where((r) => r.status == 'Submitted').length;
        final inProgress = all
            .where(
                (r) => r.status != 'Resolved' && r.status != 'Submitted')
            .length;
        final resolved = all.where((r) => r.status == 'Resolved').length;

        final categories = [
          'All Categories',
          ...{...all.map((r) => r.category)}
        ];
        final statuses = [
          'All Statuses',
          'Submitted',
          'Under Review',
          'Action Taken',
          'Resolved',
        ];

        // Filter then sort
        final filtered = _sortReports(all.where((r) {
          final matchStatus = _filterStatus == 'All Statuses' ||
              r.status == _filterStatus;
          final matchCat = _filterCategory == 'All Categories' ||
              r.category == _filterCategory;
          return matchStatus && matchCat;
        }).toList());

        return Container(
          color: AppTheme.canvasBase,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: AppTheme.canvasBase,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TADIKA AQIL MIQAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.schoolBlue.withOpacity(0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Incidents Inbox',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.schoolDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _KpiCard(
                          label: 'PENDING\nAUDITS',
                          value: '$pending',
                          icon: LucideIcons.clipboardList,
                          valueColor: AppTheme.schoolDarkBlue,
                          iconColor: AppTheme.schoolBlue.withOpacity(0.5),
                          bgColor: AppTheme.schoolLightBlue.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          label: 'IN\nPROGRESS',
                          value: '$inProgress',
                          icon: LucideIcons.clock,
                          valueColor: AppTheme.schoolOrange,
                          iconColor: AppTheme.schoolOrange.withOpacity(0.6),
                          bgColor: AppTheme.schoolLightOrange,
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          label: 'RESOLVED\n(TOTAL)',
                          value: '$resolved',
                          icon: LucideIcons.checkCircle,
                          valueColor: const Color(0xFF2E7D32),
                          iconColor: const Color(0xFF81C784),
                          bgColor: const Color(0xFFE8F5E9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.subtleGrayBoundary),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INBOX QUERY FILTER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('STATUS FILTER',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textMuted,
                                            letterSpacing: 0.8)),
                                    const SizedBox(height: 6),
                                    _FilterDropdown(
                                      value: _filterStatus,
                                      items: statuses,
                                      onChanged: (v) => setState(() =>
                                          _filterStatus =
                                              v ?? 'All Statuses'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('CATEGORY FILTER',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textMuted,
                                            letterSpacing: 0.8)),
                                    const SizedBox(height: 6),
                                    _FilterDropdown(
                                      value: _filterCategory,
                                      items: categories,
                                      onChanged: (v) => setState(() =>
                                          _filterCategory =
                                              v ?? 'All Categories'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // ── Reports Directory ─────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.subtleGrayBoundary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Text(
                          'REPORTS DIRECTORY (${filtered.length})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Column headers ────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('REPORT DETAILS',
                                  style: _colHeaderStyle()),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text('SUBMITTED BY',
                                    textAlign: TextAlign.center,
                                    style: _colHeaderStyle()),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text('PRIORITY',
                                    textAlign: TextAlign.center,
                                    style: _colHeaderStyle()),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text('STATUS',
                                    textAlign: TextAlign.center,
                                    style: _colHeaderStyle()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(
                          height: 1, color: AppTheme.subtleGrayBoundary),

                      Expanded(
                        child: snapshot.connectionState ==
                                ConnectionState.waiting
                            ? const Center(
                                child: CircularProgressIndicator())
                            : filtered.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.inbox,
                                            size: 40,
                                            color: AppTheme.subtleGrayBoundary),
                                        const SizedBox(height: 10),
                                        Text('No reports found',
                                            style: TextStyle(
                                                color: AppTheme.textMuted,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(
                                            height: 1,
                                            color: AppTheme.subtleGrayBoundary),
                                    itemBuilder: (_, i) => _ReportRow(
                                      report: filtered[i],
                                      svc: _svc,
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  TextStyle _colHeaderStyle() => const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 0.6,
      );
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color valueColor, iconColor, bgColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.subtleGrayBoundary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                  ),
                ),
                Icon(icon, size: 14, color: iconColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: valueColor,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Dropdown ───────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.subtleGrayBoundary),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.schoolBlue),
          style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textCore,
              fontWeight: FontWeight.w500),
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Report Row ────────────────────────────────────────────────────────────────

class _ReportRow extends StatelessWidget {
  final FacilityReport report;
  final ReportService svc;

  const _ReportRow({required this.report, required this.svc});

  @override
  Widget build(BuildContext context) {
    final priorityInfo = _priorityInfo(report.priority);
    final statusInfo = _statusInfo(report.status);

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ReportDetailSheet(report: report, svc: svc),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Report details + left bar ─────────────────
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 44,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: statusInfo.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.textCore,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Submitted by — centered ───────────────────
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      report.teacherName,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textCore),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('d/M/yy').format(report.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // ── Priority — centered, colored chip ─────────
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityInfo.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priorityInfo.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityInfo.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // ── Status — centered, full label, no truncate ──
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusInfo.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusInfo.badgeText,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Priority with color ───────────────────────────────────
  _PriorityInfo _priorityInfo(String priority) {
    switch (priority) {
      case 'High':
        return _PriorityInfo(
          label: 'High',
          color: const Color(0xFFD32F2F),
          bg: const Color(0xFFFFEBEE),
        );
      case 'Medium':
        return _PriorityInfo(
          label: 'Medium',
          color: AppTheme.schoolOrange,
          bg: AppTheme.schoolLightOrange,
        );
      default: // Low
        return _PriorityInfo(
          label: 'Low',
          color: AppTheme.schoolBlue,
          bg: AppTheme.schoolLightBlue,
        );
    }
  }

  // ── Status colors ─────────────────────────────────────────
  _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'Resolved':
        return _StatusInfo(
          label: 'Resolved',
          color: const Color(0xFF2E7D32),
          badgeBg: const Color(0xFFE8F5E9),
          badgeText: const Color(0xFF2E7D32),
        );
      case 'Under Review':
        return _StatusInfo(
          label: 'Under Review',
          color: AppTheme.schoolOrange,
          badgeBg: AppTheme.schoolLightOrange,
          badgeText: const Color(0xFFC75D00),
        );
      case 'Action Taken':
        return _StatusInfo(
          label: 'Action Taken',
          color: AppTheme.schoolOrange,
          badgeBg: AppTheme.schoolLightOrange,
          badgeText: const Color(0xFFC75D00),
        );
      default: // Submitted
        return _StatusInfo(
          label: 'Pending',
          color: AppTheme.schoolBlue,
          badgeBg: AppTheme.schoolLightBlue,
          badgeText: AppTheme.schoolDarkBlue,
        );
    }
  }
}

class _PriorityInfo {
  final String label;
  final Color color, bg;
  _PriorityInfo({required this.label, required this.color, required this.bg});
}

class _StatusInfo {
  final String label;
  final Color color, badgeBg, badgeText;
  _StatusInfo({
    required this.label,
    required this.color,
    required this.badgeBg,
    required this.badgeText,
  });
}