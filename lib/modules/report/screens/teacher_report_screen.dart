import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app_theme.dart';
import '../models/report.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _svc = ReportService();
  String _filterStatus = 'All';
  String _filterCategory = 'All';

  static const _statuses = [
    'All', 'Submitted', 'Under Review', 'Action Taken', 'Resolved'
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FacilityReport>>(
      stream: _svc.getReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data ?? [];
        final categories = ['All', ...{...all.map((r) => r.category)}];

        final filtered = all.where((r) {
          final matchStatus =
              _filterStatus == 'All' || r.status == _filterStatus;
          final matchCat =
              _filterCategory == 'All' || r.category == _filterCategory;
          return matchStatus && matchCat;
        }).toList();

        // KPI counts
        final pending =
            all.where((r) => r.status == 'Submitted').length;
        final critical = all
            .where((r) =>
                r.priority == 'High' &&
                r.status != 'Resolved')
            .length;
        final now = DateTime.now();
        final resolvedMonth = all
            .where((r) =>
                r.status == 'Resolved' &&
                r.lastUpdated.month == now.month &&
                r.lastUpdated.year == now.year)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KPI cards ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _KpiCard(
                      label: 'Pending',
                      value: '$pending',
                      color: Colors.orange,
                      icon: LucideIcons.clock),
                  const SizedBox(width: 10),
                  _KpiCard(
                      label: 'Critical',
                      value: '$critical',
                      color: Colors.red,
                      icon: LucideIcons.alertTriangle),
                  const SizedBox(width: 10),
                  _KpiCard(
                      label: 'Resolved',
                      value: '$resolvedMonth',
                      color: Colors.green,
                      icon: LucideIcons.checkCircle),
                ],
              ),
            ),

            // ── Filters ────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterDropdown(
                      value: _filterStatus,
                      items: _statuses,
                      hint: 'Status',
                      onChanged: (v) =>
                          setState(() => _filterStatus = v ?? 'All'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterDropdown(
                      value: _filterCategory,
                      items: categories,
                      hint: 'Category',
                      onChanged: (v) =>
                          setState(() => _filterCategory = v ?? 'All'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Report list ────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.inbox,
                              size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          Text('No reports match this filter',
                              style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => _AdminReportTile(
                        report: filtered[i],
                        svc: _svc,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
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
  final String hint;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown(
      {required this.value,
      required this.items,
      required this.hint,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF0EFEC)),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFF5F5F3)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: AppTheme.textColor),
          items: items
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Admin Report Tile ─────────────────────────────────────────────────────────

class _AdminReportTile extends StatelessWidget {
  final FacilityReport report;
  final ReportService svc;
  const _AdminReportTile({required this.report, required this.svc});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(report.status);
    final priorityColor = report.priority == 'High'
        ? Colors.red
        : report.priority == 'Medium'
            ? Colors.orange
            : Colors.green;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0EFEC)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            // Top bar with priority color indicator
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(report.category,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusInfo.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(statusInfo.label,
                            style: TextStyle(
                                color: statusInfo.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.user,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(report.teacherName,
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(width: 12),
                      Icon(LucideIcons.clock,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                          DateFormat('d MMM, h:mm a').format(report.createdAt),
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textMuted)),
                  if (report.photoUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.paperclip,
                            size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('Photo attached',
                            style: TextStyle(
                                fontSize: 11, color: Colors.blue.shade600)),
                      ],
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

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _ReportDetailScreen(report: report, svc: svc)),
    );
  }

  _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'Under Review':
        return _StatusInfo('Under Review', Colors.orange);
      case 'Action Taken':
        return _StatusInfo('Action Taken', Colors.blue);
      case 'Resolved':
        return _StatusInfo('Resolved', Colors.green);
      default:
        return _StatusInfo('Submitted', Colors.grey);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  _StatusInfo(this.label, this.color);
}

// ── Report Detail Screen (Principal) ─────────────────────────────────────────

class _ReportDetailScreen extends StatefulWidget {
  final FacilityReport report;
  final ReportService svc;
  const _ReportDetailScreen({required this.report, required this.svc});

  @override
  State<_ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<_ReportDetailScreen> {
  late String _status;
  late String _priority;
  late TextEditingController _notesCtrl;
  bool _saving = false;

  static const _statuses = [
    'Submitted', 'Under Review', 'Action Taken', 'Resolved'
  ];
  static const _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _status = widget.report.status;
    _priority = widget.report.priority;
    _notesCtrl =
        TextEditingController(text: widget.report.managementNotes);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.svc.updateReport(
        reportId: widget.report.id,
        status: _status,
        managementNotes: _notesCtrl.text.trim(),
        priority: _priority,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Report updated & teacher notified.'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        title: const Text('Report Detail',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppTheme.textColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Info Card ────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.report.category,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _InfoRow(
                    icon: LucideIcons.user,
                    label: 'Reported by',
                    value: widget.report.teacherName),
                const SizedBox(height: 4),
                _InfoRow(
                    icon: LucideIcons.calendar,
                    label: 'Date',
                    value: DateFormat('d MMMM yyyy, h:mm a')
                        .format(widget.report.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Description ──────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Text(widget.report.description,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Photo ────────────────────────────────────────────────
          if (widget.report.photoUrl.isNotEmpty) ...[
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Evidence Photo',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(widget.report.photoUrl,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Action Panel ─────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Update Status',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),

                // Status selector
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statuses.map((s) {
                    final info = _statusColor(s);
                    final sel = _status == s;
                    return ChoiceChip(
                      label: Text(s,
                          style: TextStyle(
                              color: sel ? Colors.white : info,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      selected: sel,
                      selectedColor: info,
                      backgroundColor: info.withOpacity(0.1),
                      onSelected: (_) => setState(() => _status = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Priority selector
                const Text('Priority',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: _priorities.map((p) {
                    final sel = _priority == p;
                    final color = p == 'High'
                        ? Colors.red
                        : p == 'Medium'
                            ? Colors.orange
                            : Colors.green;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? color.withOpacity(0.12)
                                : const Color(0xFFF5F5F3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: sel ? color : Colors.transparent,
                                width: sel ? 1.5 : 1),
                          ),
                          child: Center(
                            child: Text(p,
                                style: TextStyle(
                                    color: sel ? color : AppTheme.textMuted,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Management notes
                const Text('Management Notes',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Called technician to fix the issue...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFFF0EFEC))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFFF0EFEC))),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F3),
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(LucideIcons.send,
                            color: Colors.white, size: 18),
                    label: Text(
                        _saving
                            ? 'Saving...'
                            : 'Update & Notify Teacher',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Under Review':
        return Colors.orange;
      case 'Action Taken':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0EFEC))),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}