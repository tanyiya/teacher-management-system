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

  static const Map<String, List<String>> _categoryCriteria = {
    'Attendance and Punctuality': [
      'Arrives at school on time',
      'Comes prepared before class starts',
      'Follow attendance procedures',
      'Submit leave application properly',
      'Has good attendance record',
    ],
    'Classroom Management': [
      'Classroom is clean and organised',
      'Students are well managed',
      'Learning corners are updated',
      'Safety rules are followed',
      'Students line up properly',
    ],
    'Teaching Performance': [
      'Lesson plan prepared on time',
      'Lesson plan submitted on time',
      'Teaching follows lesson plan (Sandbox)',
      'Uses teaching aid effectively',
      'Explains lesson clearly',
      'Students are engaged during class',
    ],
    'Student Development': [
      'Tracks student progress',
      'Help weak students',
      'Encourages student participation',
      'Maintains student discipline positively',
      'Gives motivation and encouragement',
    ],
    'Documentation and Record Keeping': [
      'Students file updated',
      'Attendance records complete',
      'Assessment record submitted on time',
      'Portfolio/student’s work organised',
    ],
    'Communication and Professionalism': [
      'Speaks politely to students, parents and colleagues',
      'Responds professionally in WhatsApp groups',
      'Works well with team members',
      'Accept feedback positively',
      'Maintains professional appearance',
    ],
    'Task & Duty Responsibility': [
      'Follow assembly duty schedules',
      'Follow cleaning duty schedule',
      'Completes arrival and dismissal duty',
      'Helps during school events',
    ],
    'Creativity and Initiative': [
      'Creates attractive teaching materials',
      'Gives new activity ideas',
      'Participates in school improvement',
      'Decorate classroom creatively',
      'Takes initiative without waiting for instruction',
    ],
    'Training and Self Development': [
      'Attend required training (minimum 3 per year)',
      'Applies knowledge from training',
      'Shares learning with team',
      'Improves teaching skills',
    ],
    'Discipline and SOP Compliance': [
      'Follow school SOP',
      'Uses appropriate language',
      'Follow dress code',
      'Maintains confidentiality',
      'Uses social media professionally',
    ],
  };

  late String _selectedCategory;
  late String _selectedCriterion;
  bool _hasBootstrapped = false;
  bool _isPositive = true;
  String _severity = 'Normal';

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryCriteria.keys.first;
    _selectedCriterion = _categoryCriteria[_selectedCategory]!.first;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final provider = Provider.of<PerformanceProvider>(context);
    final user = appState.currentUser;

    // Bootstrap once after first frame so provider is already listening
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

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      isPrincipal ? 'Performance KPI Controls' : 'My KPI Dashboard',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isPrincipal) _buildRefreshButton(provider),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.error != null) _buildErrorBanner(provider.error!),
              if (isPrincipal)
                _buildPrincipalView(context, provider, user)
              else
                _buildTeacherView(provider),
            ],
          ),
        ),
      );
    });
  }

  // ─── Principal view ──────────────────────────────────────────────────────────

  Widget _buildPrincipalView(
    BuildContext context,
    PerformanceProvider provider,
    TeacherRecord principal,
  ) {
    final teachers = provider.teachers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teacher selector + refresh on same row, but wrapped safely
        _buildSelectorRow(provider, teachers),
        const SizedBox(height: 16),

        if (provider.isLoading && teachers.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (teachers.isEmpty)
          const Text('No teachers found.',
              style: TextStyle(color: Colors.grey))
        else ...[
          _buildAdminSummaryCards(provider),
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

  /// Selector row: dropdown expands, refresh button fixed width — no overflow.
  Widget _buildSelectorRow(
      PerformanceProvider provider, List<TeacherRecord> teachers) {
    return _buildTeacherSelector(provider, teachers);
  }

  // ─── Teacher selector ─────────────────────────────────────────────────────────

  Widget _buildTeacherSelector(
      PerformanceProvider provider, List<TeacherRecord> teachers) {
    // Use provider.teachers directly — do NOT use a separate StreamBuilder.
    // A StreamBuilder here creates a second Firestore listener whose data races
    // against the provider list, causing "value not in items" assertion failures.
    if (teachers.isEmpty) {
      return _panel(
        child: const Text('Loading teachers…',
            style: TextStyle(color: Colors.grey)),
      );
    }

    // Guarantee the selected ID is actually in the list
    final currentId = teachers.any((t) => t.id == provider.selectedTeacherId)
        ? provider.selectedTeacherId
        : teachers.first.id;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Teacher',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentId,
            isExpanded: true, // prevents text overflow inside dropdown
            decoration: const InputDecoration(
              labelText: 'Select Teacher',
              border: OutlineInputBorder(),
              prefixIcon: Icon(LucideIcons.user),
            ),
            items: teachers
                .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        t.fullName.isNotEmpty ? t.fullName : t.username,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (id) {
              if (id == null) return;
              provider.selectTeacher(id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(PerformanceProvider provider) {
    return SizedBox(
      width: 44,
      height: 44,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        onPressed: provider.isLoading ? null : () => provider.refreshAll(),
        child: provider.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(LucideIcons.refreshCcw, size: 20),
      ),
    );
  }

  // ─── Summary cards (principal) ────────────────────────────────────────────────

  Widget _buildAdminSummaryCards(PerformanceProvider provider) {
    final teacher = provider.selectedTeacher;
    final score = teacher?.currentScore ?? 0;
    final trendFactor = provider.yearlyKpi?.trendFactor ?? 1.0;

    // Use a Row with fixed-width cards instead of Expanded inside Wrap.
    // Expanded inside Wrap causes RenderFlex overflow crashes.
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 36) / 4;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _summaryCard('Score', score.toString(), LucideIcons.barChart2,
              _scoreColor(score), cardWidth),
          _summaryCard('Logs', provider.performanceLogs.length.toString(),
              LucideIcons.list, AppTheme.primaryColor, cardWidth),
          _summaryCard('Warnings', provider.warnings.length.toString(),
              LucideIcons.alertTriangle, Colors.orange, cardWidth),
          _summaryCard(_trendLabel(trendFactor), _trendValue(trendFactor),
              _trendIcon(trendFactor), _trendColor(trendFactor), cardWidth),
        ],
      );
    });
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: Container(
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
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ─── Add log form ─────────────────────────────────────────────────────────────

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
              hintText: 'e.g. Excellent lesson delivery',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categoryCriteria.keys
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (category) {
              if (category == null) return;
              setState(() {
                _selectedCategory = category;
                _selectedCriterion = _categoryCriteria[category]!.first;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCriterion,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Criterion',
              border: OutlineInputBorder(),
            ),
            items: _categoryCriteria[_selectedCategory]!
                .map((criterion) => DropdownMenuItem(
                      value: criterion,
                      child: Text(criterion),
                    ))
                .toList(),
            onChanged: (criterion) {
              if (criterion == null) return;
              setState(() => _selectedCriterion = criterion);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _severity,
            isExpanded: true,
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
            onChanged: (v) => setState(() => _severity = v ?? 'Normal'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _isPositive = true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isPositive ? AppTheme.primaryColor : Colors.grey[200],
                    foregroundColor: _isPositive ? Colors.white : Colors.black,
                  ),
                  child: const Text('Add Merit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _isPositive = false),
                  style: FilledButton.styleFrom(
                    backgroundColor: !_isPositive ? AppTheme.primaryColor : Colors.grey[200],
                    foregroundColor: !_isPositive ? Colors.white : Colors.black,
                  ),
                  child: const Text('Add Deduction'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: provider.selectedTeacherId == null
                  ? null
                  : () => _submitPerformanceLog(context, provider, principal),
              icon: const Icon(LucideIcons.check),
              label: Text(
                'Save ${provider.scoreForSeverity(_severity, isPositive: _isPositive).toStringAsFixed(0)} pts',
              ),
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
    final reason = _reasonController.text.trim();
    final category = _selectedCategory;
    final criterion = _selectedCriterion;

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    final log = PerformanceLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teacherId: provider.selectedTeacherId!,
      principalId: principal.id,
      amount: provider.scoreForSeverity(_severity, isPositive: _isPositive),
      reason: reason,
      category: category,
      criterion: criterion,
      severity: _severity,
      timestamp: DateTime.now(),
    );

    try {
      await provider.addPerformanceLog(log);
      if (!context.mounted) return;
      _reasonController.clear();
      setState(() {
        _selectedCategory = _categoryCriteria.keys.first;
        _selectedCriterion = _categoryCriteria[_selectedCategory]!.first;
        _severity = 'Normal';
        _isPositive = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Performance log saved.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ─── Run KPI panel ────────────────────────────────────────────────────────────

  Widget _buildRunKpiPanel(
    BuildContext context,
    PerformanceProvider provider,
    TeacherRecord principal,
  ) {
    final currentYear = DateTime.now().year;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yearly KPI Calculation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Aggregates all performance logs for every teacher and writes yearly KPI records.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () => _runKpiCalculation(
                      context, provider, principal, currentYear),
              icon: const Icon(LucideIcons.barChart2),
              label: Text('Calculate KPI for $currentYear'),
            ),
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
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ─── Teacher overview dashboard ───────────────────────────────────────────────

  Widget _buildTeacherOverviewDashboard(PerformanceProvider provider) {
    final teacher = provider.selectedTeacher;
    final kpi = provider.yearlyKpi;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selected Teacher Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (teacher == null)
            const Text('Select a teacher above.',
                style: TextStyle(color: Colors.grey))
          else ...[
            Row(
              children: [
                const Icon(LucideIcons.user, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teacher.fullName.isNotEmpty
                        ? teacher.fullName
                        : teacher.username,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Current score: ${teacher.currentScore}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _infoCard(
                    'Logs', provider.performanceLogs.length.toString()),
                _infoCard(
                    'Warnings', provider.warnings.length.toString()),
                _infoCard(
                    'Notifications', provider.notifications.length.toString()),
                _infoCard('KPI Rating', kpi?.rating ?? '—'),
                _infoCard('KPI Status', kpi?.status ?? 'Pending'),
                if (kpi != null)
                  _infoCard(
                      'Final Score', kpi.finalScore.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 16),
            _buildMonthlyChart(provider),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(PerformanceProvider provider) {
    final spots = provider.monthlyScores.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Score Trend',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: 12,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots.isEmpty
                      ? const [FlSpot(1, 0), FlSpot(12, 0)]
                      : spots,
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
    );
  }

  // ─── Audit logs ───────────────────────────────────────────────────────────────

  Widget _buildAuditLogs(PerformanceProvider provider) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audit Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Filters in a horizontal scroll to avoid overflow on narrow screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterDropdown<int>(
                  label: 'Month',
                  value: provider.selectedMonthFilter,
                  items: provider.monthNames.asMap().entries.map((e) {
                    return DropdownMenuItem(
                        value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (v) => provider.updateFilters(month: v),
                ),
                const SizedBox(width: 12),
                _filterDropdown<String>(
                  label: 'Severity',
                  value: provider.selectedSeverityFilter,
                  items: provider.severityOptions
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => provider.updateFilters(severity: v),
                ),
                const SizedBox(width: 12),
                _filterDropdown<String>(
                  label: 'Category',
                  value: provider.selectedCategoryFilter,
                  items: provider.categoryOptions
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => provider.updateFilters(category: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildLogList(provider.filteredPerformanceLogs, limit: 12),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  // ─── Teacher (non-principal) view ─────────────────────────────────────────────

  Widget _buildTeacherView(PerformanceProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeacherSummaryCards(provider),
        const SizedBox(height: 16),
        _panel(child: _buildMonthlyChart(provider)),
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

  Widget _buildTeacherSummaryCards(PerformanceProvider provider) {
    final score = provider.performanceLogs
        .fold<double>(0, (s, l) => s + l.amount)
        .round();
    final trendFactor = provider.yearlyKpi?.trendFactor ?? 1.0;

    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 36) / 4;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _summaryCard('Score', score.toString(), LucideIcons.barChart2,
              _scoreColor(score), cardWidth),
          _summaryCard('Logs', provider.performanceLogs.length.toString(),
              LucideIcons.list, AppTheme.primaryColor, cardWidth),
          _summaryCard('Warnings', provider.warnings.length.toString(),
              LucideIcons.alertTriangle, Colors.orange, cardWidth),
          _summaryCard(_trendLabel(trendFactor), _trendValue(trendFactor),
              _trendIcon(trendFactor), _trendColor(trendFactor), cardWidth),
        ],
      );
    });
  }

  Widget _buildYearlyKpiSection(PerformanceProvider provider) {
    final kpi = provider.yearlyKpi;
    if (kpi == null) {
      return _panel(
        child: const Text('No yearly KPI calculated yet for this year.',
            style: TextStyle(color: Colors.grey)),
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
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Chip(
                backgroundColor: _ratingColor(kpi.rating),
                label: Text(kpi.rating,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _infoCard('Final', kpi.finalScore.toStringAsFixed(2)),
              _infoCard(
                  'Average', kpi.averageMonthlyScore.toStringAsFixed(2)),
              _infoCard('Status', kpi.status),
            ],
          ),
          if (kpi.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(kpi.notes,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceLogsSection(PerformanceProvider provider) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Performance Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildLogList(provider.performanceLogs, limit: 6),
        ],
      ),
    );
  }

  Widget _buildLogList(List<PerformanceLog> logs, {required int limit}) {
    if (logs.isEmpty) {
      return const Text('No performance logs yet.',
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: logs.take(limit).map((log) {
        final isPositive = log.amount >= 0;
        final color = isPositive ? Colors.green : Colors.red;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
              isPositive ? LucideIcons.plusCircle : LucideIcons.minusCircle,
              color: color),
          title: Text(log.reason,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${log.category} · ${log.criterion} · ${log.severity}'),
          trailing: Text(
            '${log.amount > 0 ? '+' : ''}${log.amount.toStringAsFixed(0)}',
            style:
                TextStyle(color: color, fontWeight: FontWeight.bold),
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
          .map((n) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.bell,
                    color: AppTheme.primaryColor),
                title: Text(n.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(n.message),
              ))
          .toList(),
    );
  }

  Widget _buildWarningsSection(PerformanceProvider provider) {
    return _recordList(
      title: 'Warnings',
      emptyText: 'No warnings recorded.',
      items: provider.warnings
          .take(5)
          .map((w) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.alertTriangle,
                    color: Colors.orange),
                title: Text(w.message,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${w.issuedBy} · ${w.severity}'),
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
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(emptyText, style: const TextStyle(color: Colors.grey))
          else
            Column(children: items),
        ],
      ),
    );
  }

  // ─── Shared widgets ───────────────────────────────────────────────────────────

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

  Widget _infoCard(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.ambientOffWhite,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 18, color: Colors.red),
            onPressed: () =>
                Provider.of<PerformanceProvider>(context, listen: false)
                    .clearError(),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  Color _scoreColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  Color _trendColor(double f) {
    if (f > 1.05) return Colors.green;
    if (f < 0.95) return Colors.red;
    return Colors.amber;
  }

  IconData _trendIcon(double f) {
    if (f > 1.05) return LucideIcons.trendingUp;
    if (f < 0.95) return LucideIcons.trendingDown;
    return LucideIcons.minus;
  }

  String _trendLabel(double f) {
    if (f > 1.05) return 'Improving';
    if (f < 0.95) return 'Declining';
    return 'Stable';
  }

  String _trendValue(double f) => '${f.toStringAsFixed(1)}x';

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'A': return Colors.green;
      case 'B': return Colors.lightGreen;
      case 'C': return Colors.amber;
      case 'D': return Colors.orange;
      default:  return Colors.red;
    }
  }
}