import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_state_provider.dart';
import '../providers/duty_schedule_provider.dart';
import '../providers/duty_provider.dart';
import '../providers/duty_assignment_provider.dart';
import 'duty_calendar_screen.dart';
import 'duty_list_screen.dart';
import 'widgets/duty_date_selector.dart';
import 'widgets/duty_editor_dialog.dart';
import 'widgets/duty_filters_sheet.dart';
import '../seeds/duty_seeder.dart';

class DutyScheduleScreen extends StatefulWidget {
  const DutyScheduleScreen({super.key});

  @override
  State<DutyScheduleScreen> createState() => _DutyScheduleScreenState();
}

class _DutyScheduleScreenState extends State<DutyScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStateProvider>().currentUser;
    final role = _isPrincipalRole(user?.role) ? 'principal' : 'teacher';

    // Keep every duty-related provider in sync with the signed-in user.
    // (Same pattern the old screen used, just fanned out to more providers
    // now that duty data is split across them.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DutyProvider>().setUser(userId: user?.id, role: role);
      context
          .read<DutyAssignmentProvider>()
          .setUser(userId: user?.id, role: role);
    });

    final schedule = context.watch<DutyScheduleProvider>();
    final dutyProvider = context.watch<DutyProvider>();
    final assignmentProvider = context.watch<DutyAssignmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duty Management'),
        actions: [
          IconButton(
            tooltip: schedule.viewMode == DutyViewMode.calendar
                ? 'List view'
                : 'Calendar view',
            onPressed: schedule.toggleViewMode,
            icon: Icon(
              schedule.viewMode == DutyViewMode.calendar
                  ? Icons.view_agenda_outlined
                  : Icons.calendar_month,
            ),
          ),
          IconButton(
            tooltip: 'Filters',
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => const DutyFiltersSheet(),
            ),
            icon: const Icon(Icons.filter_list),
          ),

          IconButton(
            tooltip: 'Seed Duty Data',
            onPressed: () async {
              await DutySeeder.seedFirestore();
            },
            icon: const Icon(Icons.data_object),
          ),
        ],
      ),
      floatingActionButton: dutyProvider.isPrincipal
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const DutyEditorDialog(),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Shared by both views -- previously only the list screen had a
          // date control, which is why the calendar view had no way to
          // change dates at all.
          DutyDateSelector(
            date: assignmentProvider.selectedDate,
            onChanged: (date) =>
                context.read<DutyAssignmentProvider>().setDate(date),
          ),
          Expanded(
            child: dutyProvider.error != null
                ? Center(child: Text(dutyProvider.error!))
                : schedule.viewMode == DutyViewMode.calendar
                    ? const DutyCalendarScreen()
                    : const DutyListScreen(),
          ),
        ],
      ),
    );
  }
}

bool _isPrincipalRole(String? role) {
  final normalized = role?.toLowerCase() ?? 'teacher';
  return normalized == 'principal' || normalized == 'admin';
}