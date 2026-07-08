
  void _showSwapDialog(BuildContext context, Duty duty) async {
    final provider = context.read<DutyProvider>();
    final ids = await provider.eligibleSwapTeacherIds(duty);
    if (!context.mounted) return;
    String? fromTeacherId =
        duty.teacherIds.isNotEmpty ? duty.teacherIds.first : null;
    String? selectedId = ids.isNotEmpty ? ids.first : null;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Request swap'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${duty.title}\n${duty.timeStart} - ${duty.timeEnd}\n${duty.locations.map((e) => e.name).join(', ')}'),
              const SizedBox(height: 16),
              if (provider.isPrincipal)
                DropdownButtonFormField<String>(
                  initialValue: fromTeacherId,
                  decoration:
                      const InputDecoration(labelText: 'Replace teacher'),
                  items: duty.teacherIds
                      .map((id) => DropdownMenuItem(
                          value: id, child: Text(duty.teacherNames[id] ?? id)))
                      .toList(),
                  onChanged: (value) => setState(() => fromTeacherId = value),
                ),
              if (provider.isPrincipal) const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration:
                    const InputDecoration(labelText: 'Eligible teacher'),
                items: ids
                    .map((id) => DropdownMenuItem(
                          value: id,
                          child: Text(provider.teachers
                              .firstWhere((t) => t.id == id,
                                  orElse: () => _fallbackTeacher(id))
                              .fullName),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: selectedId == null
                  ? null
                  : () async {
                      await provider.requestSwap(duty, selectedId!,
                          fromTeacherId: fromTeacherId);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    },
              child: Text(provider.isPrincipal ? 'Swap now' : 'Request'),
            ),
          ],
        ),
      ),
    );
  }
