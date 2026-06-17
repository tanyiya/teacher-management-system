import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../app_theme.dart';
import '../../../providers/app_state_provider.dart';
import '../../teachers/models/teacher.dart';
import '../models/performance.dart';
import '../providers/performance_provider.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({Key? key}) : super(key: key);

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  final _reasonController = TextEditingController();
  final _categoryController = TextEditingController();
  final _criterionController = TextEditingController();

  bool _hasBootstrapped = false;
  bool _isPositive = true;
  String _severity = 'Normal';
  String _severityFilter = 'All';
  String? _selectedTeacherId;

  @override
  void dispose() {
    _reasonController.dispose();
    _categoryController.dispose();
    _criterionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final provider = Provider.of<PerformanceProvider>(context);
    final user = appState.currentUser;

    if (user != null && !_hasBootstrapped) {
      _hasBootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (user.role.toLowerCase() == 'principal') {
          provider.fetchTeachers();
        } else {
          provider.fetchTeacherPerformance(user.id);
        }
      });
    }

    if (user == null) {
      return const Center(child: Text('No signed-in user found.'));
    }

    final isPrincipal = user.role.toLowerCase() == 'principal';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPrincipal ? 'Performance KPI Controls' : 'My KPI Dashboard',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (isPrincipal)
            _buildPrincipalView(context, provider, user)
          else
            _buildTeacherView(provider),
        ],
      ),
    );
  }

  Widget _buildPrincipalView(
    BuildContext context,
    PerformanceProvider provider,
    TeacherRecord principal,
  ) {
    final teachers = provider.teachers;
    TeacherRecord? selectedTeacher = provider.selectedTeacher;
    for (final teacher in teachers) {
      if (selectedTeacher == null && teacher.id == _selectedTeacherId) {
        selectedTeacher = teacher;
        break;
      }
    }

    if (provider.selectedTeacherId == null && teachers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || provider.selectedTeacherId != null) return;
        setState(() => _selectedTeacherId = teachers.first.id);
        provider.selectTeacher(teachers.first.id);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeacherSelector(provider, teachers),
        const SizedBox(height: 16),
        if (provider.isLoading && teachers.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (teachers.isEmpty)
          const Text('No teachers found.', style: TextStyle(color: Colors.grey))
        else ...[
          _buildAdminSummary(selectedTeacher, provider),
          const SizedBox(height: 16),
          _buildAddLogForm(context, provider, principal),
          const SizedBox(height: 16),
          _buildRunKpiPanel(context, provider, principal),
          const SizedBox(height: 16),
          _buildTeacherOverviewDashboard(provider),
          const SizedBox(height: 16),
          _buildAuditLogs(provider),
        ],
      ],
    );
  }

  Widget _buildTeacherView(PerformanceProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopSummary(provider, null),
        const SizedBox(height: 16),
        _buildMonthlyChart(provider),
        const SizedBox(height: 16),
        _buildYearlyKpiSection(provider),
        const SizedBox(height: 16),
        _buildPerformanceLogsSection(provider),
        const SizedBox(height: 16),
        _buildNotificationsSection(provider),
        const SizedBox(height: 16),
        _buildWarningsSection(provider),
      ],
    );
  }

  Widget _buildTeacherSelector(
    PerformanceProvider provider,
    List<TeacherRecord> teachers,
  ) {
    return _panel(
      child: DropdownButtonFormField<String>(
        initialValue: provider.selectedTeacherId ?? _selectedTeacherId,
        decoration: const InputDecoration(
          labelText: 'Teacher',
          border: OutlineInputBorder(),
          prefixIcon: Icon(LucideIcons.user),
        ),
        items: teachers
            .map((teacher) => DropdownMenuItem(
                  value: teacher.id,
                  child: Text(teacher.fullName.isEmpty ? teacher.username : teacher.fullName),
                ))
            .toList(),
        onChanged: (teacherId) {
          if (teacherId == null) return;
          setState(() => _selectedTeacherId = teacherId);
          provider.selectTeacher(teacherId);
        },
      ),
    );
  }

  Widget _buildAdminSummary(
    TeacherRecord? teacher,
    PerformanceProvider provider,
  ) {
    return _buildTopSummary(provider, teacher);
  }

  Widget _buildAddLogForm(
    BuildContext context,
    PerformanceProvider provider,
    TeacherRecord principal,
  ) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Performance Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _criterionController,
                  decoration: const InputDecoration(
                    labelText: 'Criterion',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _severity,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Minor', child: Text('Minor')),
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Major', child: Text('Major')),
                    DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                  ],
                  onChanged: (value) => setState(() => _severity = value ?? 'Normal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(LucideIcons.plusCircle),
                      label: Text('Merit'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(LucideIcons.x),
                      label: Text('Deduction'),
                    ),
                  ],
                  selected: {_isPositive},
                  onSelectionChanged: (values) {
                    setState(() => _isPositive = values.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (provider.selectedTeacherId ?? _selectedTeacherId) == null
                ? null
                : () => _submitPerformanceLog(context, provider, principal),
            icon: const Icon(LucideIcons.check),
            label: Text(
              'Save ${provider.scoreForSeverity(_severity, isPositive: _isPositive).toStringAsFixed(0)} pts',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPerformanceLog(
    BuildContext context,
    PerformanceProvider provider,
    TeacherRecord principal,
  ) async {
    if (_reasonController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty ||
        _criterionController.text.trim().isEmpty ||
        (provider.selectedTeacherId ?? _selectedTeacherId) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all log fields.')),
      );
      return;
    }

    final log = PerformanceLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teacherId: provider.selectedTeacherId ?? _selectedTeacherId!,
      principalId: principal.id,
      amount: provider.scoreForSeverity(_severity, isPositive: _isPositive),
      reason: _reasonController.text.trim(),
      category: _categoryController.text.trim(),
      criterion: _criterionController.text.trim(),
      severity: _severity,
      timestamp: DateTime.now(),
    );

    try {
      await provider.addPerformanceLog(log);
      if (!context.mounted) return;
      _reasonController.clear();
      _categoryController.clear();
      _criterionController.clear();
      setState(() {
        _severity = 'Normal';
        _isPositive = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Performance log saved.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Widget _buildRunKpiPanel(
    BuildContext context,
    PerformanceProvider provider,
    TeacherRecord principal,
  ) {
    final currentYear = DateTime.now().year;

    return _panel(
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Run yearly KPI calculation for all teachers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton.icon(
            onPressed: provider.isLoading
                ? null
                : () => _runKpiCalculation(context, provider, principal, currentYear),
            icon: const Icon(LucideIcons.barChart2),
            label: Text('$currentYear'),
          ),
        ],
      ),
    );
  }

  Future<void> _runKpiCalculation(
    BuildContext context,
    PerformanceProvider provider,
    TeacherRecord principal,
    int year,
  ) async {
    try {
      await provider.runAllKPIForYear(year, principal.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KPI calculation completed for $year.')),
      );
      if (_selectedTeacherId != null) {
        provider.fetchTeacherPerformance(_selectedTeacherId!);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Widget _buildTeacherOverviewDashboard(PerformanceProvider provider) {
    final teacher = provider.selectedTeacher;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Teacher Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (teacher == null)
            const Text('Select a teacher to view performance details.', style: TextStyle(color: Colors.grey))
          else ...[
            Text(
              teacher.fullName.isNotEmpty ? teacher.fullName : teacher.username,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Current score: ${teacher.currentScore}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                _metric('Logs', provider.performanceLogs.length.toString()),
                _metric('Warnings', provider.warnings.length.toString()),
                _metric('Notes', provider.notifications.length.toString()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Rating: ${provider.yearlyKpi?.rating ?? 'Pending'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status: ${provider.yearlyKpi?.status ?? 'Pending'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditLogs(PerformanceProvider provider) {
    final logs = _severityFilter == 'All'
        ? provider.performanceLogs
        : provider.performanceLogs
            .where((log) => log.severity == _severityFilter)
            .toList();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Audit Logs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: _severityFilter,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Minor', child: Text('Minor')),
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Major', child: Text('Major')),
                    DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                  ],
                  onChanged: (value) => setState(() => _severityFilter = value ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLogList(logs, limit: 12),
        ],
      ),
    );
  }

  Widget _buildTopSummary(PerformanceProvider provider, TeacherRecord? teacher) {
    final currentScore = teacher?.currentScore ??
        provider.performanceLogs.fold<double>(0, (sum, log) => sum + log.amount).round();
    final trendFactor = provider.yearlyKpi?.trendFactor ?? 1;

    return Row(
      children: [
        _summaryTile('Score', currentScore.toString(), LucideIcons.barChart2, _scoreColor(currentScore)),
        const SizedBox(width: 12),
        _summaryTile('Logs', provider.performanceLogs.length.toString(), LucideIcons.list, AppTheme.primaryColor),
        const SizedBox(width: 12),
        _summaryTile('Warnings', provider.warnings.length.toString(), LucideIcons.alertTriangle, Colors.orange),
        const SizedBox(width: 12),
        _summaryTile(_trendLabel(trendFactor), _trendValue(trendFactor), _trendIcon(trendFactor), _trendColor(trendFactor)),
      ],
    );
  }

  Widget _summaryTile(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.subtleGrayBoundary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(PerformanceProvider provider) {
    final spots = provider.monthlyScores.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly KPI Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: 12,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? const [FlSpot(1, 0), FlSpot(12, 0)] : spots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyKpiSection(PerformanceProvider provider) {
    final kpi = provider.yearlyKpi;
    if (kpi == null) {
      return _panel(
        child: const Text('No yearly KPI has been calculated for this year.'),
      );
    }

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Yearly KPI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Chip(
                backgroundColor: _ratingColor(kpi.rating),
                label: Text(kpi.rating,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric('Final', kpi.finalScore.toStringAsFixed(2)),
              _metric('Average', kpi.averageMonthlyScore.toStringAsFixed(2)),
              _metric('Status', kpi.status),
            ],
          ),
          if (kpi.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(kpi.notes, style: const TextStyle(color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.ambientOffWhite,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceLogsSection(PerformanceProvider provider) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildLogList(provider.performanceLogs, limit: 6),
        ],
      ),
    );
  }

  Widget _buildLogList(List<PerformanceLog> logs, {required int limit}) {
    if (logs.isEmpty) {
      return const Text('No performance logs yet.', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: logs.take(limit).map((log) {
        final color = log.amount >= 0 ? Colors.green : Colors.red;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(log.amount >= 0 ? LucideIcons.plusCircle : LucideIcons.x, color: color),
          title: Text(log.reason, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${log.category} • ${log.criterion} • ${log.severity}'),
          trailing: Text(
            '${log.amount > 0 ? '+' : ''}${log.amount.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationsSection(PerformanceProvider provider) {
    return _recordList(
      title: 'Notifications',
      emptyText: 'No notifications yet.',
      items: provider.notifications
          .take(5)
          .map((notification) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.bell, color: AppTheme.primaryColor),
                title: Text(notification.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(notification.message),
              ))
          .toList(),
    );
  }

  Widget _buildWarningsSection(PerformanceProvider provider) {
    return _recordList(
      title: 'Warnings',
      emptyText: 'No warnings recorded yet.',
      items: provider.warnings
          .take(5)
          .map((warning) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.alertTriangle, color: Colors.orange),
                title: Text(warning.message,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${warning.issuedBy} • ${warning.severity}'),
              ))
          .toList(),
    );
  }

  Widget _recordList({
    required String title,
    required String emptyText,
    required List<Widget> items,
  }) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(emptyText, style: const TextStyle(color: Colors.grey))
          else
            Column(children: items),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.subtleGrayBoundary),
      ),
      child: child,
    );
  }

  Color _scoreColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  Color _trendColor(double trendFactor) {
    if (trendFactor > 1.05) return Colors.green;
    if (trendFactor < 0.95) return Colors.red;
    return Colors.amber;
  }

  IconData _trendIcon(double trendFactor) {
    if (trendFactor > 1.05) return LucideIcons.barChart2;
    if (trendFactor < 0.95) return LucideIcons.alertTriangle;
    return LucideIcons.check;
  }

  String _trendLabel(double trendFactor) {
    if (trendFactor > 1.05) return 'Improving';
    if (trendFactor < 0.95) return 'Declining';
    return 'Stable';
  }

  String _trendValue(double trendFactor) {
    return '${trendFactor.toStringAsFixed(1)}x';
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.amber;
      case 'D':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
