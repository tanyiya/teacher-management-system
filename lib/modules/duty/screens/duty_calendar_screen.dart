// // Display Calendar
// // Handle Scrolling
// // Open Dity Detail

// import 'package:flutter/material.dart';

// class DutyScheduleScreen extends StatefulWidget {
//   const DutyScheduleScreen({super.key});

//   @override
//   State<DutyScheduleScreen> createState() => _DutyScheduleScreenState();
// }

// class _DutyScheduleScreenState extends State<DutyScheduleScreen> {
//   static const double _hourHeight = 72;
//   static const double _timeWidth = 64;
//   static const double _columnWidth = 220;
//   static const int _startHour = 6;
//   static const int _hourCount = 14;

//   @override
//   Widget build(BuildContext context) {
//     final user = context.watch<AppStateProvider>().currentUser;
//     final provider = context.watch<DutyProvider>();
//     if (provider.currentTeacherId != user?.id ||
//         provider.currentTeacherName != user?.fullName ||
//         provider.userRole != _roleFromUser(user)) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//         context.read<DutyProvider>().setUser(
//               teacherId: user?.id,
//               teacherName: user?.fullName,
//               role: user?.role ?? 'teacher',
//             );
//       });
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xfff7f8fb),
//       appBar: AppBar(
//         title: const Text('Duty Management'),
//         actions: [
//           IconButton(
//             tooltip: provider.viewMode == DutyViewMode.calendar
//                 ? 'List view'
//                 : 'Calendar view',
//             onPressed: provider.toggleViewMode,
//             icon: Icon(provider.viewMode == DutyViewMode.calendar
//                 ? Icons.view_agenda_outlined
//                 : Icons.calendar_month),
//           ),
//           if (provider.isPrincipal)
//             IconButton(
//               tooltip: 'Filters',
//               onPressed: () => _showFilters(context, provider),
//               icon: const Icon(Icons.filter_list),
//             ),
//         ],
//       ),
//       floatingActionButton: provider.isPrincipal
//           ? FloatingActionButton(
//               onPressed: () => _showDutyEditor(context),
//               child: const Icon(Icons.add),
//             )
//           : null,
//       body: Column(
//         children: [
//           _TopBar(
//               onAddLocation: provider.isPrincipal &&
//                       provider.groupingMode == DutyGroupingMode.location
//                   ? () => _showAddLocation(context)
//                   : null),
//           if (provider.error != null)
//             MaterialBanner(
//               content: Text(provider.error!),
//               actions: [
//                 TextButton(
//                     onPressed:
//                         ScaffoldMessenger.of(context).hideCurrentMaterialBanner,
//                     child: const Text('Dismiss')),
//               ],
//             ),
//           Expanded(
//             child: provider.isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : provider.viewMode == DutyViewMode.calendar
//                     ? _CalendarGrid(
//                         onOpen: _showDutyDetail, onEdit: _showDutyEditor)
//                     : _DutyList(
//                         onOpen: _showDutyDetail,
//                         onEdit: _showDutyEditor,
//                         onComplete: _completeTask,
//                         onSwap: _showSwapDialog),
//           ),
//         ],
//       ),
//     );
//   }
// }


// class _CalendarGrid extends StatefulWidget {
//   const _CalendarGrid({required this.onOpen, required this.onEdit});

//   final void Function(BuildContext context, Duty duty) onOpen;
//   final void Function(BuildContext context, {Duty? duty}) onEdit;

//   @override
//   State<_CalendarGrid> createState() => _CalendarGridState();
// }

// class _CalendarGridState extends State<_CalendarGrid> {
//   final _horizontalHeader = ScrollController();
//   final _horizontalBody = ScrollController();
//   final _verticalTime = ScrollController();
//   final _verticalBody = ScrollController();
//   bool _syncingHorizontal = false;
//   bool _syncingVertical = false;

//   @override
//   void initState() {
//     super.initState();
//     _horizontalHeader
//         .addListener(() => _syncHorizontal(_horizontalHeader, _horizontalBody));
//     _horizontalBody
//         .addListener(() => _syncHorizontal(_horizontalBody, _horizontalHeader));
//     _verticalTime
//         .addListener(() => _syncVertical(_verticalTime, _verticalBody));
//     _verticalBody
//         .addListener(() => _syncVertical(_verticalBody, _verticalTime));
//   }

//   void _syncHorizontal(ScrollController source, ScrollController target) {
//     if (_syncingHorizontal || !source.hasClients || !target.hasClients) return;
//     _syncingHorizontal = true;
//     target.jumpTo(source.offset.clamp(0, target.position.maxScrollExtent));
//     _syncingHorizontal = false;
//   }

//   void _syncVertical(ScrollController source, ScrollController target) {
//     if (_syncingVertical || !source.hasClients || !target.hasClients) return;
//     _syncingVertical = true;
//     target.jumpTo(source.offset.clamp(0, target.position.maxScrollExtent));
//     _syncingVertical = false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<DutyProvider>();
//     final columns = provider.groupingMode == DutyGroupingMode.location
//         ? provider.locations
//             .map((location) => _ColumnMeta(location.id, location.name))
//             .toList()
//         : provider.teachers
//             .map((teacher) => _ColumnMeta(teacher.id, teacher.fullName))
//             .toList();
//     if (columns.isEmpty) {
//       return const Center(
//           child: Text('No locations or teachers available yet.'));
//     }

//     final contentWidth = columns.length * _DutyScheduleScreenState._columnWidth;
//     const contentHeight = _DutyScheduleScreenState._hourCount *
//         _DutyScheduleScreenState._hourHeight;

//     return Column(
//       children: [
//         SizedBox(
//           height: 48,
//           child: Row(
//             children: [
//               Container(
//                 width: _DutyScheduleScreenState._timeWidth,
//                 alignment: Alignment.center,
//                 decoration: BoxDecoration(
//                     border: Border.all(color: const Color(0xffe5e7eb)),
//                     color: Colors.white),
//                 child: const Icon(Icons.schedule_outlined, size: 18),
//               ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   controller: _horizontalHeader,
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: columns
//                         .map((column) => Container(
//                               width: _DutyScheduleScreenState._columnWidth,
//                               height: 48,
//                               alignment: Alignment.center,
//                               decoration: BoxDecoration(
//                                   border: Border.all(
//                                       color: const Color(0xffe5e7eb)),
//                                   color: Colors.white),
//                               child: Text(column.label,
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.w700)),
//                             ))
//                         .toList(),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: Row(
//             children: [
//               SizedBox(
//                 width: _DutyScheduleScreenState._timeWidth,
//                 child: SingleChildScrollView(
//                   controller: _verticalTime,
//                   child: const _TimeColumn(height: contentHeight),
//                 ),
//               ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   controller: _horizontalBody,
//                   scrollDirection: Axis.horizontal,
//                   child: SingleChildScrollView(
//                     controller: _verticalBody,
//                     child: SizedBox(
//                       width: contentWidth,
//                       height: contentHeight,
//                       child: Stack(
//                         children: [
//                           _CalendarBodyBackground(columns: columns),
//                           ...provider.duties.expand((duty) =>
//                               _blocksForDuty(context, provider, duty, columns)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Iterable<Widget> _blocksForDuty(BuildContext context, DutyProvider provider,
//       Duty duty, List<_ColumnMeta> columns) {
//     final ids = provider.groupingMode == DutyGroupingMode.location
//         ? duty.locations.map((e) => e.id)
//         : duty.teacherIds;
//     return ids.map((id) {
//       final index = columns.indexWhere((column) => column.id == id);
//       if (index < 0) return const SizedBox.shrink();
//       final top = (duty.timeStart.toMinutes() -
//               _DutyScheduleScreenState._startHour * 60) *
//           (_DutyScheduleScreenState._hourHeight / 60);
//       final height = ((duty.timeEnd.toMinutes() - duty.timeStart.toMinutes()) *
//               (_DutyScheduleScreenState._hourHeight / 60))
//           .clamp(40, 240)
//           .toDouble();
//       final color = provider.groupingMode == DutyGroupingMode.location
//           ? provider.colorForTeacher(
//               duty.teacherIds.isEmpty ? duty.id : duty.teacherIds.first)
//           : provider.colorForLocation(
//               duty.locations.isEmpty ? duty.id : duty.locations.first.id);
//       return Positioned(
//         top: top.clamp(0, double.infinity).toDouble(),
//         left: index * _DutyScheduleScreenState._columnWidth + 8,
//         width: _DutyScheduleScreenState._columnWidth - 16,
//         height: height,
//         child: InkWell(
//           onTap: () => widget.onOpen(context, duty),
//           borderRadius: BorderRadius.circular(8),
//           child: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//                 color: color, borderRadius: BorderRadius.circular(8)),
//             child: LayoutBuilder(
//               builder: (_, constraints) {
//                 final compact = constraints.maxHeight < 64;
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                             child: Text(duty.title,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 12))),
//                         if (provider.isPrincipal)
//                           InkWell(
//                             onTap: () => widget.onEdit(context, duty: duty),
//                             child: const Icon(Icons.edit_outlined,
//                                 color: Colors.white, size: 16),
//                           ),
//                       ],
//                     ),
//                     if (!compact) ...[
//                       const SizedBox(height: 2),
//                       Flexible(
//                           child: Text(
//                               duty.teacherIds
//                                   .map((id) => duty.teacherNames[id] ?? id)
//                                   .join(', '),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                   color: Colors.white, fontSize: 11))),
//                       Flexible(
//                           child: Text(
//                               duty.locations.map((e) => e.name).join(', '),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                   color: Colors.white70, fontSize: 11))),
//                     ],
//                   ],
//                 );
//               },
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _horizontalHeader.dispose();
//     _horizontalBody.dispose();
//     _verticalTime.dispose();
//     _verticalBody.dispose();
//     super.dispose();
//   }
// }

// class _CalendarBodyBackground extends StatelessWidget {
//   const _CalendarBodyBackground({required this.columns});

//   final List<_ColumnMeta> columns;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         ...List.generate(_DutyScheduleScreenState._hourCount, (index) {
//           return Row(
//             children: [
//               ...columns.map((_) => Container(
//                     width: _DutyScheduleScreenState._columnWidth,
//                     height: _DutyScheduleScreenState._hourHeight,
//                     decoration: BoxDecoration(
//                         border: Border.all(color: const Color(0xffe5e7eb)),
//                         color: Colors.white),
//                   )),
//             ],
//           );
//         }),
//       ],
//     );
//   }
// }

// class _TimeColumn extends StatelessWidget {
//   const _TimeColumn({required this.height});

//   final double height;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: height,
//       child: Column(
//         children: List.generate(_DutyScheduleScreenState._hourCount, (index) {
//           final hour = _DutyScheduleScreenState._startHour + index;
//           return Container(
//             width: _DutyScheduleScreenState._timeWidth,
//             height: _DutyScheduleScreenState._hourHeight,
//             alignment: Alignment.topCenter,
//             decoration: BoxDecoration(
//                 border: Border.all(color: const Color(0xffe5e7eb)),
//                 color: Colors.white),
//             child: Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child:
//                   Text(_formatHour(hour), style: const TextStyle(fontSize: 11)),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }

// class _ColumnMeta {
//   final String id;
//   final String label;

//   const _ColumnMeta(this.id, this.label);
// }
