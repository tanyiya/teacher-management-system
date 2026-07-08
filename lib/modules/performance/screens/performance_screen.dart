import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

import '../../../app_theme.dart';
import '../../../providers/app_state_provider.dart';
import '../../teachers/models/teacher.dart';
import '../models/performance.dart';
import '../providers/performance_provider.dart';

class PerformanceScreen extends StatefulWidget {
  final TeacherRecord user;
  const PerformanceScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  late TextEditingController _reasonController;
  late TextEditingController _categoryController;
  late TextEditingController _criterionController;
  bool _hasFetched = false;
  double _scoreDelta = 0;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _categoryController = TextEditingController();
    _criterionController = TextEditingController();
  }

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
    final performanceProvider = Provider.of<PerformanceProvider>(context);
    final currentUser = appState.currentUser;
    final isPrincipal = currentUser?.role.toLowerCase() == 'principal';

    if (!_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        performanceProvider.fetchTeacherPerformance(widget.user.id);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (isPrincipal) ...[
            _buildAddPerformanceLogForm(context, currentUser!),
            const SizedBox(height: 24),
            _buildKpiCalculationSection(context, performanceProvider, currentUser),
            const SizedBox(height: 32),
            _buildPerformanceTrends(performanceProvider),
            const SizedBox(height: 32),
            _buildRecentLogs(performanceProvider),
          ] else
            _buildTeacherOverview(performanceProvider),
        ],
      ),
    );
  }

  // ─── Teacher overview ───────────────────────────────────────────────────────

  Widget _buildTeacherOverview(PerformanceProvider provider) {
    final teacher = provider.selectedTeacherRecord ?? widget.user;
    final kpi = provider.yearlyKpi;
    final trendFactor = kpi?.trendFactor ?? 1.0;
    final activeMonths = provider.performanceLogs
        .where((log) => log.timestamp.year == DateTime.now().year)
        .map((log) => log.timestamp.month)
        .toSet()
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCards(
          score: teacher.currentScore,
          activeMonths: activeMonths,
          warningsCount: provider.warnings.length,
          trendFactor: trendFactor,
        ),
        const SizedBox(height: 24),
        _buildPerformanceTrends(provider),
        const SizedBox(height: 24),
        _buildYearlyKpiCard(kpi),
        const SizedBox(height: 24),
        _buildTeacherMonthlySummary(provider),
        const SizedBox(height: 24),
        _buildNotificationsCard(provider),
        const SizedBox(height: 24),
        _buildWarningsCard(provider),
      ],
    );
  }

  Widget _buildSummaryCards({
    required int score,
    required int activeMonths,
    required int warningsCount,
    required double trendFactor,
  }) {
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
          _summaryCard('Warnings', warningsCount.toString(),
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

  Widget _buildYearlyKpiCard(YearlyKpiRecord? kpi) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: kpi == null
            ? const Text('No yearly KPI calculated yet for this year.',
                style: TextStyle(color: Colors.grey))
            : Column(
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
                      _infoChip('Final', kpi.finalScore.toStringAsFixed(2)),
                      _infoChip('Average',
                          kpi.averageMonthlyScore.toStringAsFixed(2)),
                      _infoChip('Status', kpi.status),
                    ],
                  ),
                  if (kpi.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(kpi.notes,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(PerformanceProvider provider) {
    final notifications = provider.notifications.take(5).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              const Text('No notifications yet.',
                  style: TextStyle(color: Colors.grey))
            else
              Column(
                children: notifications
                    .map((n) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(LucideIcons.bell,
                              color: AppTheme.primaryColor),
                          title: Text(n.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${n.timestamp.month}/${n.timestamp.day}/${n.timestamp.year}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsCard(PerformanceProvider provider) {
    final warnings = provider.warnings.take(5).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Warnings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (warnings.isEmpty)
              const Text('No warnings recorded.',
                  style: TextStyle(color: Colors.grey))
            else
              Column(
                children: warnings
                    .map((w) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(LucideIcons.alertTriangle,
                              color: Colors.orange),
                          title: Text(w.warningType,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1),
                          subtitle: Text(
                            '${w.createdAt.month}/${w.createdAt.day}/${w.createdAt.year}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Principal-only sections ──────────────────────────────────────────────────

  Widget _buildAddPerformanceLogForm(BuildContext context, TeacherRecord principal) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Performance Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                hintText: 'e.g., Excellent attendance, Late submission',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                hintText: 'e.g., Attendance, Academic, Conduct',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _criterionController,
              decoration: const InputDecoration(
                labelText: 'Criterion',
                border: OutlineInputBorder(),
                hintText: 'e.g., Professional Development, Punctuality',
              ),
            ),
            const SizedBox(height: 12),
            _buildScoreSlider(),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _scoreDelta == 0
                  ? null
                  : () => _submitPerformanceLog(context, principal),
              child: const Text('Apply Score'),
            ),
          ],
        ),
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
                  style: TextStyle(
                    color: value > 0
                        ? Colors.green
                        : value < 0
                            ? Colors.red
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          Slider(
            value: _scoreDelta,
            min: -5,
            max: 5,
            divisions: 10,
            label: label,
            onChanged: (value) =>
                setState(() => _scoreDelta = value.roundToDouble()),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('-5 Deduction',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('0', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('+5 Merit',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitPerformanceLog(BuildContext context, TeacherRecord principal) async {
    if (_reasonController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _criterionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final performanceProvider = Provider.of<PerformanceProvider>(context, listen: false);

    final log = PerformanceLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teacherId: widget.user.id,
      principalId: principal.id,
      amount: _scoreDelta,
      reason: _reasonController.text,
      category: _categoryController.text,
      criterion: _criterionController.text,
      severity: 'Normal',
      timestamp: DateTime.now(),
    );

    try {
      await performanceProvider.addPerformanceLog(log);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Performance log added successfully')),
      );
      _reasonController.clear();
      _categoryController.clear();
      _criterionController.clear();
      setState(() {
        _scoreDelta = 0;
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildKpiCalculationSection(
    BuildContext context,
    PerformanceProvider performanceProvider,
    TeacherRecord principal,
  ) {
    final currentYear = DateTime.now().year;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.primaryColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Run KPI Calculation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Calculate annual KPI scores for all teachers. This will aggregate performance logs and generate yearly KPI records.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => _runKpiCalculation(context, performanceProvider, principal, currentYear),
              child: const Text('Run KPI for Current Year'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runKpiCalculation(BuildContext context, PerformanceProvider performanceProvider, TeacherRecord principal, int year) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Calculating KPI scores for all teachers...'),
              const SizedBox(height: 8),
              Text('Year: $year', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );

    try {
      await performanceProvider.runAllKPIForYear(year, principal.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KPI calculation completed successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildRecentLogs(PerformanceProvider performanceProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Performance Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (performanceProvider.performanceLogs.isEmpty)
              const Center(child: Text('No performance logs yet.', style: TextStyle(color: Colors.grey)))
            else
              Column(
                children: performanceProvider.performanceLogs
                    .take(5)
                    .map((log) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          title: Text(log.reason, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${log.category} • ${log.criterion}'),
                          trailing: Text(
                            '${log.amount > 0 ? '+' : ''}${log.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: log.amount > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Shared: performance trend chart ─────────────────────────────────────────

  Widget _buildPerformanceTrends(PerformanceProvider performanceProvider) {
    final monthlyScores = performanceProvider.monthlyScores;
    final spots = monthlyScores.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // Scale the Y axis to the actual data range instead of a fixed 0-100,
    // which squashed small merit/deduction deltas (e.g. -7 to +3) into an
    // unreadable flat line near the bottom of the chart.
    final values = monthlyScores.values.toList();
    final rawMin = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final rawMax = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final span = (rawMax - rawMin).abs();
    final padding = span == 0 ? 5.0 : (span * 0.25).clamp(2.0, double.infinity);
    // Always include zero in the visible range so merits/deductions read
    // clearly against a neutral baseline.
    final minY = (rawMin < 0 ? rawMin : 0) - padding;
    final maxY = (rawMax > 0 ? rawMax : 0) + padding;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Monthly merit/deduction totals for the current year',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0EFEC)),
              ),
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: const Color(0xFFF0EFEC),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (val, meta) => Text(
                          val.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (val, meta) => Text(
                          'M${val.toInt()}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: Colors.grey.shade400,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ],
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                        final v = spot.y;
                        return LineTooltipItem(
                          '${v > 0 ? '+' : ''}${v.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList(),
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
                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Teacher-facing monthly summary ──────────────────────────────────────────

  Widget _buildTeacherMonthlySummary(PerformanceProvider performanceProvider) {
    final logs = performanceProvider.performanceLogs;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Performance Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Only monthly aggregated KPI data is shown. Tap a month for details.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final tileWidth = constraints.maxWidth < 520
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  final monthLogs = _logsForMonth(logs, month);
                  final total = monthLogs.fold<double>(
                      0, (sum, log) => sum + log.amount);
                  final average =
                      monthLogs.isEmpty ? 0.0 : total / monthLogs.length;
                  final trend = _monthTrend(logs, month);
                  final hasLogs = monthLogs.isNotEmpty;

                  return SizedBox(
                    width: tileWidth,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: hasLogs
                          ? () => _showMonthlySummaryDialog(
                                month, monthLogs, total, average, trend)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: monthLogs.isEmpty
                              ? AppTheme.ambientOffWhite
                              : Colors.white,
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
                                    monthLogs.isEmpty
                                        ? 'No summary record'
                                        : 'Total ${total > 0 ? '+' : ''}${total.toStringAsFixed(0)} · Avg ${average.toStringAsFixed(1)} · $trend',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              monthLogs.isEmpty
                                  ? '-'
                                  : '${total > 0 ? '+' : ''}${total.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: total >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }

  void _showMonthlySummaryDialog(
    int month,
    List<PerformanceLog> monthLogs,
    double total,
    double average,
    String trend,
  ) {
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
                        _infoChip('Total',
                            '${total > 0 ? '+' : ''}${total.toStringAsFixed(0)}'),
                        _infoChip('Average', average.toStringAsFixed(1)),
                        _infoChip('Trend', trend),
                        _infoChip('Entries', monthLogs.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Categories affected',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...monthLogs.map((log) {
                      final isPositive = log.amount >= 0;
                      final color = isPositive ? Colors.green : Colors.red;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isPositive
                              ? LucideIcons.plusCircle
                              : LucideIcons.minusCircle,
                          color: color,
                        ),
                        title: Text(log.category),
                        subtitle: Text(log.criterion),
                        trailing: Text(
                          '${log.amount > 0 ? '+' : ''}${log.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PerformanceLog> _logsForMonth(List<PerformanceLog> logs, int month) {
    final year = DateTime.now().year;
    return logs
        .where((log) => log.timestamp.year == year && log.timestamp.month == month)
        .toList();
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

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return 'M$month';
    return months[month - 1];
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