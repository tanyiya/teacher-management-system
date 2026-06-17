import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../providers/performance_provider.dart';
import '../../../app_theme.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({Key? key}) : super(key: key);

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  bool _hasFetched = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final performanceProvider = Provider.of<PerformanceProvider>(context);
    final user = appState.currentUser;

    if (user != null && !_hasFetched) {
      performanceProvider.fetchTeacherPerformance(user.id);
      _hasFetched = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KPI Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;

              Widget buildCard({required String title, required List<Widget> children}) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...children,
                      ],
                    ),
                  ),
                );
              }

              final pointAllocator = buildCard(
                title: 'Point Allocator',
                children: [
                  const DropdownMenu<String>(dropdownMenuEntries: [
                    DropdownMenuEntry(value: '1', label: 'Select Teacher...'),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Points: +5'),
                  Slider(value: 5, min: -30, max: 10, onChanged: (v) {}),
                  const SizedBox(height: 16),
                  const TextField(decoration: InputDecoration(labelText: 'Remarks', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () {}, child: const Text('Allocate Points')),
                ],
              );

              final warningDispatcher = buildCard(
                title: 'Warnings Dispatcher',
                children: [
                  const DropdownMenu<String>(dropdownMenuEntries: [
                    DropdownMenuEntry(value: '1', label: 'Select Teacher...'),
                  ]),
                  const SizedBox(height: 16),
                  const DropdownMenu<String>(dropdownMenuEntries: [
                    DropdownMenuEntry(value: 'verbal', label: 'Verbal Warning'),
                    DropdownMenuEntry(value: 'written', label: 'Written Warning'),
                  ]),
                  const SizedBox(height: 16),
                  const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Message', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: () {},
                    child: const Text('Dispatch Warning'),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    pointAllocator,
                    const SizedBox(height: 24),
                    warningDispatcher,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: pointAllocator),
                  const SizedBox(width: 24),
                  Expanded(child: warningDispatcher),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}