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
  String _severity = 'Normal';
  String _isPositive = 'true';

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
          _buildRecentLogs(),
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
                  child: DropdownButtonFormField<String>(
                    initialValue: _isPositive,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'true', child: Text('+ Merit')),
                      DropdownMenuItem(value: 'false', child: Text('- Deduction')),
                    ],
                    onChanged: (value) => setState(() => _isPositive = value ?? 'true'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => _submitPerformanceLog(context, principal),
              child: const Text('Add Performance Log'),
            ),
          ],
        ),
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

    final isPositive = _isPositive == 'true';
    final performanceProvider = Provider.of<PerformanceProvider>(context, listen: false);
    final amount = performanceProvider.scoreForSeverity(
      _severity,
      isPositive: isPositive,
    );

    final log = PerformanceLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teacherId: widget.user.id,
      principalId: principal.id,
      amount: amount,
      reason: _reasonController.text,
      category: _categoryController.text,
      criterion: _criterionController.text,
      severity: _severity,
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
        _severity = 'Normal';
        _isPositive = 'true';
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
                      spots: const [
                        FlSpot(1, 75), FlSpot(2, 78), FlSpot(3, 82),
                        FlSpot(4, 80), FlSpot(5, 85), FlSpot(6, 85),
                      ],
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
}
