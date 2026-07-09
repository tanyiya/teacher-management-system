import 'package:flutter/material.dart';

class DutyDateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const DutyDateSelector({
    super.key,
    required this.date,
    required this.onChanged,
  });

  Future<void> _pickDate(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _pickDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month),
              const SizedBox(width: 12),
              Text('${date.day}/${date.month}/${date.year}'),
              const Spacer(),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}