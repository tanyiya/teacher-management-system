import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
          const Text('Performance Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (isPrincipal) ...[
            _buildAddPerformanceLogForm(context, currentUser!),
            const SizedBox(height: 24),
            _buildKpiCalculationSection(context, currentUser),
            const SizedBox(height: 32),
          ],
          _buildPerformanceTrends(),
          const SizedBox(height: 32),
          if (isPrincipal) _buildRecentLogs() else _buildTeacherMonthlySummary(),
        ],
      ),
    );
  }

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

  Widget _buildKpiCalculationSection(BuildContext context, TeacherRecord principal) {
    final performanceProvider = Provider.of<PerformanceProvider>(context, listen: false);
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

  Widget _buildPerformanceTrends() {
    final performanceProvider = Provider.of<PerformanceProvider>(context);
    final spots = performanceProvider.monthlyScores.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0EFEC)),
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) => Text('M${val.toInt()}'),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots.isEmpty
                          ? const [FlSpot(1, 0), FlSpot(12, 0)]
                          : spots,
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogs() {
    final performanceProvider = Provider.of<PerformanceProvider>(context);

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

  Widget _buildTeacherMonthlySummary() {
    final performanceProvider = Provider.of<PerformanceProvider>(context);
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
              'Only monthly aggregated KPI data is shown.',
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

                  return SizedBox(
                    width: tileWidth,
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
                  );
                }),
              );
            }),
          ],
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
}
