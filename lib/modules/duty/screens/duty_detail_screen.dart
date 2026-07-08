Navigator.push(
 context,
 MaterialPageRoute(
   builder: (_) => DutyDetailScreen(duty: duty),
 ),
);

Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.viewMode == DutyViewMode.calendar
                    ? _CalendarGrid(
                        onOpen: _showDutyDetail, onEdit: _showDutyEditor)
                    : _DutyList(
                        onOpen: _showDutyDetail,
                        onEdit: _showDutyEditor,
                        onComplete: _completeTask,
                        onSwap: _showSwapDialog),
          ),



  void _showDutyDetail(BuildContext context, Duty duty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final provider = sheetContext.watch<DutyProvider>();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(duty.title,
                          style: Theme.of(context).textTheme.headlineSmall)),
                  if (provider.isPrincipal)
                    IconButton(
                      tooltip: 'Edit duty',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showDutyEditor(context, duty: duty);
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                ],
              ),
              Text(
                  '${DateFormat.yMMMd().format(duty.date)}  ${duty.timeStart} - ${duty.timeEnd}'),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Locations and teachers',
                children: duty.locations
                    .map((location) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.place_outlined),
                          title: Text(location.name),
                          subtitle:
                              Text(duty.teacherLabelForLocation(location.id)),
                        ))
                    .toList(),
              ),
              _InfoSection(
                title: 'Tasks',
                children: duty.tasks
                    .map((task) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: task.photoUrl == null
                              ? Icon(task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(task.photoUrl!,
                                      width: 44, height: 44, fit: BoxFit.cover),
                                ),
                          title: Text(task.name),
                          subtitle: Text(task.isCompleted
                              ? 'Completed ${task.completedAt == null ? '' : DateFormat.jm().format(task.completedAt!)}'
                              : 'Pending proof photo'),
                          trailing: !task.isCompleted &&
                                  provider.canCompleteTask(duty)
                              ? IconButton(
                                  tooltip: 'Capture proof',
                                  onPressed: () =>
                                      _completeTask(context, duty, task),
                                  icon: const Icon(Icons.photo_camera_outlined),
                                )
                              : null,
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
