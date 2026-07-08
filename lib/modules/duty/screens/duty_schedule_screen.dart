// Entry Point
// Only handle swithcing between calendat/list

import 'package:flutter/material.dart';

class DutyScheduleScreen extends StatelessWidget {
  const DutyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final provider = context.watch<DutyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duty Management'),
        
        // actions: [
        //   IconButton(
        //     onPressed: provider.toggleViewMode,
        //     icon: Icon(
        //       provider.viewMode == DutyViewMode.calendar
        //           ? Icons.view_agenda
        //           : Icons.calendar_month,
        //     ),
        //   ),
        // ],
      ),
      // floatingActionButton: provider.isPrincipal
      //     ? FloatingActionButton(
      //         onPressed: () {
      //           showDialog(
      //             context: context,
      //             builder: (_) => const DutyEditorScreen(),
      //           );
      //         },
      //         child: const Icon(Icons.add),
      //       )
      //     : null,
      // body: provider.viewMode == DutyViewMode.calendar
      //     ? const DutyCalendarScreen()
      //     : const DutyListScreen(),
    );
  }
}