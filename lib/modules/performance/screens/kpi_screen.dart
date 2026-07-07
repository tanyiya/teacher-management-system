import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

import '../../../app_theme.dart';
import '../../../providers/app_state_provider.dart';
import '../../teachers/models/teacher.dart';
import '../models/performance.dart';
import '../providers/performance_provider.dart';
import '../utils/performance_constants.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({Key? key}) : super(key: key);

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  final _reasonController = TextEditingController();
  final _warningReasonController = TextEditingController();
  final _warningNotesController = TextEditingController();
  String _warningType = warningTypes.first;

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
  double _scoreDelta = 0;
  String _severity = 'Normal';

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryCriteria.keys.first;
    _selectedCriterion = _categoryCriteria[_selectedCategory]!.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppStateProvider>(context);
    final provider = Provider.of<PerformanceProvider>(context, listen: false);
    final user = appState.currentUser;
    if (user == null) return;

    final isPrincipal = user.role.toLowerCase() == 'principal';
    if (isPrincipal) {
      if (provider.teachers.isEmpty) {
        provider.fetchTeachers();
      }
    } else {
      if (provider.selectedTeacherId != user.id) {
        provider.fetchTeacherPerformance(user.id);
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _warningReasonController.dispose();
    _warningNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final provider = Provider.of<PerformanceProvider>(context);
    final user = appState.currentUser;

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
          _buildWarningIssuancePanel(context, provider, principal),
          const SizedBox(height: 16),
          _buildRunKpiPanel(context, provider, principal),
          const SizedBox(height: 16),
          _buildKpiLeaderboard(context, provider),
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
            initialValue: currentId,
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
            initialValue: _selectedCategory,
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
            initialValue: _selectedCriterion,
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
            initialValue: _severity,
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
          _buildScoreSlider(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: provider.selectedTeacherId == null || _scoreDelta == 0
                  ? null
                  : () => _submitPerformanceLog(context, provider, principal),
              icon: const Icon(LucideIcons.check),
              label: const Text('Apply Score'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSlider() {
    final value = _scoreDelta.round();
    final label = value == 0
        ? '0 No change'
        : value > 0
            ? '+$value Merit'
            : '$value Deduction';
    final color = value > 0
        ? Colors.green
        : value < 0
            ? Colors.red
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.ambientOffWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.subtleGrayBoundary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Performance Score',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _scoreDelta,
            min: -5,
            max: 5,
            divisions: 10,
            label: label,
            onChanged: (value) => setState(() => _scoreDelta = value.roundToDouble()),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('-5 Deduction', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('0', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('+5 Merit', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
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
      amount: _scoreDelta,
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
        _scoreDelta = 0;
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
        initialValue: value,
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
        _buildMonthlySummarySection(provider),
        const SizedBox(height: 16),
        _buildNotificationsSection(provider),
        const SizedBox(height: 16),
        _buildWarningsSection(provider),
      ],
    );
  }

  Widget _buildTeacherSummaryCards(PerformanceProvider provider) {
    final score = provider.selectedTeacherRecord?.currentScore ?? provider.performanceLogs
        .fold<double>(0, (s, l) => s + l.amount)
        .round();
    final trendFactor = provider.yearlyKpi?.trendFactor ?? 1.0;
    final activeMonths = provider.performanceLogs
        .where((log) => log.timestamp.year == DateTime.now().year)
        .map((log) => log.timestamp.month)
        .toSet()
        .length;

    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 36) / 4;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _summaryCard('Score', score.toString(), LucideIcons.barChart2,
              _scoreColor(score), cardWidth),
          _summaryCard('Active Months', activeMonths.toString(),
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

  Widget _buildMonthlySummarySection(PerformanceProvider provider) {
    final currentYear = DateTime.now().year;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Monthly Performance Summary',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Text(currentYear.toString(),
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Monthly summaries are aggregated. Individual evaluation records are restricted to admin.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth < 520
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(12, (index) {
                final month = index + 1;
                final logs = _logsForMonth(provider.performanceLogs, month);
                final total = logs.fold<double>(0, (sum, log) => sum + log.amount);
                final average = logs.isEmpty ? 0.0 : total / logs.length;
                final hasLogs = logs.isNotEmpty;
                final trend = _monthTrend(provider.performanceLogs, month);

                return SizedBox(
                  width: width,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: hasLogs
                        ? () => _showMonthlySummaryDialog(
                              context,
                              month,
                              logs,
                              provider.performanceLogs,
                            )
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: hasLogs ? Colors.white : AppTheme.ambientOffWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.subtleGrayBoundary),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_monthName(month),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  hasLogs
                                      ? 'Total ${total > 0 ? '+' : ''}${total.toStringAsFixed(0)} · Avg ${average.toStringAsFixed(1)} · $trend'
                                      : 'No summary record',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            hasLogs
                                ? '${total > 0 ? '+' : ''}${total.toStringAsFixed(0)}'
                                : '-',
                            style: TextStyle(
                              color: total >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  List<PerformanceLog> _logsForMonth(List<PerformanceLog> logs, int month) {
    final year = DateTime.now().year;
    return logs
        .where((log) => log.timestamp.year == year && log.timestamp.month == month)
        .toList();
  }

  void _showMonthlySummaryDialog(
    BuildContext context,
    int month,
    List<PerformanceLog> logs,
    List<PerformanceLog> allLogs,
  ) {
    final total = logs.fold<double>(0, (sum, log) => sum + log.amount);
    final average = logs.isEmpty ? 0.0 : total / logs.length;
    final trend = _monthTrend(allLogs, month);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${_monthName(month)} Summary',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _infoCard('Month', _monthName(month)),
                        _infoCard('Monthly Total',
                            '${total > 0 ? '+' : ''}${total.toStringAsFixed(0)}'),
                        _infoCard('Monthly Average', average.toStringAsFixed(1)),
                        _infoCard('Trend', trend),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                subtitle: Text(
                  '${n.timestamp.month}/${n.timestamp.day}/${n.timestamp.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildWarningsSection(PerformanceProvider provider) {
    final warnings = provider.warnings;
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Warnings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (warnings.length > 5)
                TextButton(
                  onPressed: () => _showAllWarningRecords(context, provider),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (warnings.isEmpty)
            const Text('No warnings recorded.',
                style: TextStyle(color: Colors.grey))
          else
            Column(
              children: warnings.take(5).map((w) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.alertTriangle,
                      color: Colors.orange),
                  title: Text(w.warningType,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  subtitle: Text(
                    '${w.createdAt.month}/${w.createdAt.day}/${w.createdAt.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showAllWarningRecords(
    BuildContext context,
    PerformanceProvider provider,
  ) {
    final warnings = provider.warnings;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 560,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('All Warning Records',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: warnings.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No warnings recorded.'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: warnings.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final warning = warnings[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(LucideIcons.alertTriangle,
                                color: Colors.orange),
                            title: Text(warning.warningType,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                            subtitle: Text(
                              '${warning.createdAt.month}/${warning.createdAt.day}/${warning.createdAt.year}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildWarningIssuancePanel(
    BuildContext context,
    PerformanceProvider provider,
    TeacherRecord principal,
  ) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Issue Manual Warning',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _warningType,
            decoration: const InputDecoration(
              labelText: 'Warning Type',
              border: OutlineInputBorder(),
            ),
            items: warningTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _warningType = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _warningReasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
              hintText: 'Describe why the warning is issued',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _warningNotesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
              hintText: 'Optional details for the teacher record',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(LucideIcons.alertTriangle),
              label: const Text('Issue Warning'),
              onPressed: provider.selectedTeacherId == null
                  ? null
                  : () => _issueWarning(context, provider, principal),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _issueWarning(
    BuildContext context,
    PerformanceProvider provider,
    TeacherRecord principal,
  ) async {
    if (_warningReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a warning reason.')),
      );
      return;
    }

    final warning = WarningRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teacherId: provider.selectedTeacherId!,
      issuedBy: principal.id,
      createdAt: DateTime.now(),
      warningType: _warningType,
      reason: _warningReasonController.text.trim(),
      notes: _warningNotesController.text.trim(),
    );

    try {
      await provider.addWarningRecord(warning);
      if (!context.mounted) return;
      _warningReasonController.clear();
      _warningNotesController.clear();
      setState(() {
        _warningType = warningTypes.first;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warning issued successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error issuing warning: $e')),
      );
    }
  }

  // ─── KPI leaderboard ──────────────────────────────────────────────────────────

  /// Only records that resolve to a currently-existing teacher should ever
  /// be displayed. Records left behind by deleted/renamed teacher accounts
  /// are orphaned and are filtered out here rather than shown with a raw
  /// teacherId as a fallback "name".
  List<YearlyKpiRecord> _validKpiRecords(PerformanceProvider provider) {
    final validIds = provider.teachers.map((t) => t.id).toSet();
    return provider.yearlyKpis
        .where((record) => validIds.contains(record.teacherId))
        .toList();
  }

  Widget _buildKpiLeaderboard(
      BuildContext context, PerformanceProvider provider) {
    final records = _validKpiRecords(provider);
    final orphanedCount = provider.yearlyKpis.length - records.length;

    if (records.isEmpty) {
      return _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('KPI Leaderboard',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (orphanedCount > 0)
                  _buildCleanupButton(context, provider, orphanedCount),
              ],
            ),
            const SizedBox(height: 12),
            const Text('No KPI records available for this year yet.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('KPI Leaderboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  if (orphanedCount > 0)
                    _buildCleanupButton(context, provider, orphanedCount),
                  TextButton(
                    onPressed: () =>
                        _showAllKpiRecords(context, provider, records),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: records.take(5).map((record) {
              final teacherName = provider.teachers
                  .firstWhere((t) => t.id == record.teacherId)
                  .fullName;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(record.rating),
                ),
                title: Text(teacherName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Score: ${record.finalScore.toStringAsFixed(1)}'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Small icon button that confirms with the principal, then deletes
  /// orphaned performance_logs / warnings / notifications / yearly_kpis
  /// records whose teacherId no longer matches a real teacher.
  Widget _buildCleanupButton(
    BuildContext context,
    PerformanceProvider provider,
    int orphanedCount,
  ) {
    return IconButton(
      tooltip: 'Clean up $orphanedCount orphaned record(s)',
      icon: provider.isCleaningUp
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(LucideIcons.trash2, size: 20, color: Colors.grey),
      onPressed: provider.isCleaningUp
          ? null
          : () => _confirmAndCleanupOrphanedRecords(context, provider),
    );
  }

  Future<void> _confirmAndCleanupOrphanedRecords(
    BuildContext context,
    PerformanceProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clean up orphaned records?'),
        content: const Text(
          'This permanently deletes performance logs, warnings, notifications, '
          'and KPI records left behind by teacher accounts that no longer exist. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final deletedCount = await provider.cleanupOrphanedRecords();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed $deletedCount orphaned record(s).')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cleaning up records: $e')),
      );
    }
  }

  void _showAllKpiRecords(
    BuildContext context,
    PerformanceProvider provider,
    List<YearlyKpiRecord> records,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 560,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('All Teacher KPI Records',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No KPI records available.'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final teacherName = provider.teachers
                              .firstWhere((t) => t.id == record.teacherId)
                              .fullName;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              teacherName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Text(
                              'Score: ${record.finalScore.toStringAsFixed(1)} · Rating: ${record.rating} · Status: ${record.status}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
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

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return 'Month $month';
    return months[month - 1];
  }

  String _monthTrend(List<PerformanceLog> logs, int month) {
    if (month <= 1) return 'Stable';
    final currentLogs = _logsForMonth(logs, month);
    final previousLogs = _logsForMonth(logs, month - 1);
    if (currentLogs.isEmpty || previousLogs.isEmpty) return 'Stable';

    final currentTotal =
        currentLogs.fold<double>(0, (sum, log) => sum + log.amount);
    final previousTotal =
        previousLogs.fold<double>(0, (sum, log) => sum + log.amount);

    if (currentTotal > previousTotal) return 'Improving';
    if (currentTotal < previousTotal) return 'Declining';
    return 'Stable';
  }

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