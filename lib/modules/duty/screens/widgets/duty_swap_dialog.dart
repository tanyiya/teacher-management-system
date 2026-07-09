import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/duty_assignment.dart';
import '../../models/duty_swap.dart';
import '../../providers/duty_provider.dart';
import '../../providers/duty_swap_provider.dart';
import '../../utils/duty_time_utils.dart';

class DutySwapDialog extends StatefulWidget {
  const DutySwapDialog({super.key, required this.assignment});

  final DutyAssignment assignment;

  @override
  State<DutySwapDialog> createState() => _DutySwapDialogState();
}

class _DutySwapDialogState extends State<DutySwapDialog> {
  String? _fromTeacherId;
  String? _selectedTeacherId;
  List<String> _eligibleIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fromTeacherId =
        widget.assignment.teacherIds.isNotEmpty ? widget.assignment.teacherIds.first : null;
    _loadEligible();
  }

  Future<void> _loadEligible() async {
    final swapProvider = context.read<DutySwapProvider>();
    final dutyProvider = context.read<DutyProvider>();
    final ids = await swapProvider.eligibleSwapTeacherIds(
      assignment: widget.assignment,
      dutyProvider: dutyProvider,
    );
    if (!mounted) return;
    setState(() {
      _eligibleIds = ids;
      _selectedTeacherId = ids.isNotEmpty ? ids.first : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dutyProvider = context.watch<DutyProvider>();
    final canSwap =
        DutyTimeUtils.canStillSwap(widget.assignment.date, widget.assignment.timeStart);

    return AlertDialog(
      title: const Text('Request swap'),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.assignment.dutyNameSnapshot}\n'
                  '${widget.assignment.timeStart} - ${widget.assignment.timeEnd}\n'
                  '${widget.assignment.locationNameSnapshot}',
                ),
                const SizedBox(height: 16),
                if (!canSwap)
                  const Text(
                    'Swaps can only be requested up to 30 minutes before '
                    'the duty starts.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                if (dutyProvider.isPrincipal)
                  DropdownButtonFormField<String>(
                    initialValue: _fromTeacherId,
                    decoration: const InputDecoration(labelText: 'Replace teacher'),
                    items: widget.assignment.teacherIds
                        .map((id) => DropdownMenuItem(
                              value: id,
                              child: Text(_nameFor(widget.assignment, id)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _fromTeacherId = v),
                  ),
                if (dutyProvider.isPrincipal) const SizedBox(height: 12),
                if (_eligibleIds.isEmpty)
                  const Text('No eligible teachers found for this time slot.')
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTeacherId,
                    decoration: const InputDecoration(labelText: 'Eligible teacher'),
                    items: _eligibleIds
                        .map((id) => DropdownMenuItem(
                              value: id,
                              child: Text(
                                dutyProvider.teachers
                                    .firstWhere((t) => t.id == id)
                                    .fullName,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTeacherId = v),
                  ),
              ],
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: (!canSwap || _selectedTeacherId == null || _fromTeacherId == null)
              ? null
              : () async {
                  final swapProvider = context.read<DutySwapProvider>();
                  final replacement =
                      dutyProvider.teachers.firstWhere((t) => t.id == _selectedTeacherId);
                  await swapProvider.requestSwap(
                    assignment: widget.assignment,
                    currentTeacherId: _fromTeacherId!,
                    replacementTeacherId: _selectedTeacherId!,
                    replacementTeacherNameSnapshot: replacement.fullName,
                    requestedById: dutyProvider.currentUserId ?? '',
                    requestedByNameSnapshot:
                        dutyProvider.isPrincipal ? 'Principal' : replacement.fullName,
                    requesterType: dutyProvider.isPrincipal
                        ? DutySwapRequesterType.admin
                        : DutySwapRequesterType.teacher,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
          child: Text(dutyProvider.isPrincipal ? 'Swap now' : 'Request'),
        ),
      ],
    );
  }

  String _nameFor(DutyAssignment assignment, String id) {
    final index = assignment.teacherIds.indexOf(id);
    return index >= 0 && index < assignment.teacherNameSnapshots.length
        ? assignment.teacherNameSnapshots[index]
        : id;
  }
}