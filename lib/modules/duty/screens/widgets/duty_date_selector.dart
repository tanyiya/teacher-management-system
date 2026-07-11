import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/duty_assignment_provider.dart';
import '../../utils/duty_time_utils.dart';

/// Date control for the schedule screen: chevrons to step a day at a time,
/// plus a tap on the main body to open a full calendar picker. The picker
/// is bounded to one month before / one week after today, and greys out
/// any day in that range with no duties scheduled (the currently selected
/// day stays selectable even if it happens to be empty, since it has to
/// satisfy `initialDate` or `showDatePicker` throws).
class DutyDateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const DutyDateSelector({
    super.key,
    required this.date,
    required this.onChanged,
  });

  DateTime get _today {
    final now = DutyTimeUtils.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _minDate {
    final t = _today;
    return DateTime(t.year, t.month - 1, t.day);
  }

  DateTime get _maxDate => _today.add(const Duration(days: 7));

  Future<void> _pickDate(BuildContext context) async {
    final provider = context.read<DutyAssignmentProvider>();
    final minDate = _minDate;
    final maxDate = _maxDate;

    final availableDates = await provider.datesWithAssignments(
      from: minDate,
      to: maxDate,
    );
    // The currently selected day must stay pickable even if it has no
    // duties, or `showDatePicker` throws (initialDate has to satisfy the
    // predicate).
    final selectableDates = {...availableDates, DateTime(date.year, date.month, date.day)};

    if (!context.mounted) return;

    final result = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: minDate,
      lastDate: maxDate,
      selectableDayPredicate: (day) =>
          selectableDates.contains(DateTime(day.year, day.month, day.day)),
    );
    if (result != null) onChanged(result);
  }

  bool get _canGoBack => date.isAfter(_minDate);
  bool get _canGoForward => date.isBefore(_maxDate);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _canGoBack ? () => onChanged(date.subtract(const Duration(days: 1))) : null,
          ),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, size: 18),
                    const SizedBox(width: 10),
                    Text(DutyTimeUtils.formatDate(date)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right),
            onPressed:
                _canGoForward ? () => onChanged(date.add(const Duration(days: 1))) : null,
          ),
        ],
      ),
    );
  }
}