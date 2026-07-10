import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/duty_swap.dart';
import '../../providers/duty_swap_provider.dart';
import '../../utils/duty_time_utils.dart';

/// Shows swaps awaiting this teacher's approval, with Accept/Reject
/// actions. Renders nothing if there's nothing pending, so it's safe to
/// drop into a screen unconditionally.
class DutySwapRequestsSection extends StatelessWidget {
  const DutySwapRequestsSection({super.key, required this.teacherId});

  final String? teacherId;

  @override
  Widget build(BuildContext context) {
    final teacherId = this.teacherId;
    if (teacherId == null || teacherId.isEmpty) return const SizedBox.shrink();

    final swaps = context.watch<DutySwapProvider>().pendingApprovalsFor(teacherId);
    if (swaps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Swap Requests',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...swaps.map((swap) => _SwapRequestCard(swap: swap)),
        ],
      ),
    );
  }
}

class _SwapRequestCard extends StatelessWidget {
  const _SwapRequestCard({required this.swap});

  final DutySwap swap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              swap.dutyNameSnapshot,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '${DutyTimeUtils.weekdayName(swap.date.weekday)}, '
              '${swap.date.day}/${swap.date.month}/${swap.date.year}  '
              '${swap.timeStart} - ${swap.timeEnd}  •  ${swap.locationNameSnapshot}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              '${swap.currentTeacherNameSnapshot} wants to swap this duty with you',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      context.read<DutySwapProvider>().rejectSwap(swap.id),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () =>
                      context.read<DutySwapProvider>().approveSwapById(swap.id),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}