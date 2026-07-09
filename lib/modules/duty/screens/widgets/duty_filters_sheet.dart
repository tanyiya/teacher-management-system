import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/duty_provider.dart';
import '../../providers/duty_location_provider.dart';
import '../../providers/duty_schedule_provider.dart';

class DutyFiltersSheet extends StatelessWidget {
  const DutyFiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<DutyScheduleProvider>();
    final dutyProvider = context.watch<DutyProvider>();
    final locationProvider = context.watch<DutyLocationProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<DutyGroupingMode>(
            segments: const [
              ButtonSegment(
                value: DutyGroupingMode.location,
                label: Text('Locations'),
                icon: Icon(Icons.place_outlined),
              ),
              ButtonSegment(
                value: DutyGroupingMode.teacher,
                label: Text('Teachers'),
                icon: Icon(Icons.people_outline),
              ),
            ],
            selected: {schedule.groupingMode},
            onSelectionChanged: (v) => schedule.setGroupingMode(v.first),
          ),
          const SizedBox(height: 12),
          // Teachers default to seeing only their own duties; this is the
          // opt-in to see everyone else's too. Not shown for the principal,
          // who already sees everyone by default.
          if (!dutyProvider.isPrincipal)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show all teachers'),
              subtitle: const Text('Off shows only your own duties'),
              value: schedule.showAllTeachers,
              onChanged: (_) => schedule.toggleShowAllTeachers(),
            ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String?>(
            initialValue: schedule.teacherFilterId,
            decoration: const InputDecoration(labelText: 'Teacher'),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(dutyProvider.isPrincipal ? 'All teachers' : 'My duties'),
              ),
              ...dutyProvider.activeTeachers
                  .map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))),
            ],
            onChanged: schedule.setTeacherFilter,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: schedule.locationFilterId,
            decoration: const InputDecoration(labelText: 'Venue'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All venues')),
              ...locationProvider.activeLocations
                  .map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))),
            ],
            onChanged: schedule.setLocationFilter,
          ),
        ],
      ),
    );
  }
}