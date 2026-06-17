import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app_theme.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import 'report_detail_sheet.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _svc = ReportService();
  String _filterStatus = 'All Statuses';
  String _filterCategory = 'All Categories';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FacilityReport>>(
      stream: _svc.getReports(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];

        // KPI counts
        final pending = all.where((r) => r.status == 'Submitted').length;
        final critical = all
            .where((r) => r.priority == 'High' && r.status != 'Resolved')
            .length;
        final resolved = all.where((r) => r.status == 'Resolved').length;

        // Build category list
        final categories = [
          'All Categories',
          ...{...all.map((r) => r.category)}
        ];
        final statuses = [
          'All Statuses',
          'Submitted',
          'Under Review',
          'Action Taken',
          'Resolved'
        ];

        // Filtered list
        final filtered = all.where((r) {
          final matchStatus = _filterStatus == 'All Statuses' ||
              r.status == _filterStatus;
          final matchCat = _filterCategory == 'All Categories' ||
              r.category == _filterCategory;
          return matchStatus && matchCat;
        }).toList();

        return Container(
          color: const Color(0xFFF2F1EE),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────
              Container(
                color: const Color(0xFFF2F1EE),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FACULTY SAFETY & INCIDENTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Incidents Inbox',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── KPI Cards ──────────────────────────────────
                    Row(
                      children: [
                        _KpiCard(
                          label: 'PENDING\nAUDITS',
                          value: '$pending',
                          icon: LucideIcons.clipboardList,
                          valueColor: const Color(0xFF1A1A1A),
                          iconColor: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          label: 'CRITICAL\nALERTS',
                          value: '$critical',
                          icon: LucideIcons.clock,
                          valueColor: critical > 0
                              ? Colors.red.shade300
                              : Colors.red.shade200,
                          iconColor: Colors.red.shade200,
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          label: 'RESOLVED\n(TOTAL)',
                          value: '$resolved',
                          icon: LucideIcons.checkCircle,
                          valueColor: resolved > 0
                              ? Colors.blue.shade400
                              : Colors.blue.shade200,
                          iconColor: Colors.blue.shade200,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Filter Box ─────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8E8E5)),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INBOX QUERY FILTER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade500,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('STATUS FILTER',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade500,
                                            letterSpacing: 0.8)),
                                    const SizedBox(height: 6),
                                    _FilterDropdown(
                                      value: _filterStatus,
                                      items: statuses,
                                      onChanged: (v) => setState(
                                          () => _filterStatus = v ?? 'All Statuses'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CATEGORY FILTER',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade500,
                                            letterSpacing: 0.8)),
                                    const SizedBox(height: 6),
                                    _FilterDropdown(
                                      value: _filterCategory,
                                      items: categories,
                                      onChanged: (v) => setState(
                                          () => _filterCategory =
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

              // ── Reports Directory ──────────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Text(
                          'REPORTS DIRECTORY (${filtered.length})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Column headers
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('REPORT DETAILS',
                                  style: _colHeaderStyle()),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('SUBMITTED\nBY',
                                  style: _colHeaderStyle()),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('PRIORITY',
                                  style: _colHeaderStyle()),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('C\nS',
                                  style: _colHeaderStyle()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFF0EFEC)),

                      // List
                      Expanded(
                        child: snapshot.connectionState ==
                                ConnectionState.waiting
                            ? const Center(
                                child: CircularProgressIndicator())
                            : filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.inbox,
                                            size: 40,
                                            color: Colors.grey.shade300),
                                        const SizedBox(height: 10),
                                        Text('No reports found',
                                            style: TextStyle(
                                                color:
                                                    Colors.grey.shade400,
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
                                            color: Color(0xFFF0EFEC)),
                                    itemBuilder: (_, i) =>
                                        _ReportRow(
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

  TextStyle _colHeaderStyle() => TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade400,
        letterSpacing: 0.6,
      );
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color valueColor, iconColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E5)),
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
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
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
    // Ensure value is valid
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8D8D5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1A1A1A),
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
    final priorityColor = report.priority == 'High'
        ? Colors.red
        : report.priority == 'Medium'
            ? Colors.orange
            : Colors.green;

    final statusInfo = _statusInfo(report.status);

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ReportDetailSheet(report: report, svc: svc),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority color bar + title
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: priorityColor,
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
                            fontSize: 13,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          report.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Submitted by
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.teacherName,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                  ),
                  Text(
                    DateFormat('M/d/yy').format(report.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // Priority
            Expanded(
              flex: 2,
              child: Text(
                report.priority.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: priorityColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Status initial badge
            Expanded(
              flex: 1,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusInfo.shortLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusInfo.color,
                  ),
                  textAlign: TextAlign.center,
                ),
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
        return _StatusMeta('Under Review', 'UR', Colors.orange);
      case 'Action Taken':
        return _StatusMeta('Action Taken', 'AT', Colors.blue);
      case 'Resolved':
        return _StatusMeta('Resolved', 'RV', Colors.green);
      default:
        return _StatusMeta('Submitted', 'SB', Colors.grey);
    }
  }
}

class _StatusMeta {
  final String label, shortLabel;
  final Color color;
  _StatusMeta(this.label, this.shortLabel, this.color);
}