import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/leave_service.dart';
import '../../teachers/models/teacher.dart';
import '../models/leave.dart' hide TeacherRecord; 
import '../../../core/services/cloudinary_service.dart';

class LeaveSpec {
  final String type;
  final String name;
  final int quota;
  final bool docRequired;
  final String docLabel;

  LeaveSpec({
    required this.type,
    required this.name,
    required this.quota,
    required this.docRequired,
    required this.docLabel,
  });
}

final List<LeaveSpec> leaveSpecs = [
  LeaveSpec(type: 'annual', name: 'Annual Leave', quota: 8, docRequired: false, docLabel: 'None (Optional Remarks)'),
  LeaveSpec(type: 'medical', name: 'Medical Leave (MC)', quota: 14, docRequired: true, docLabel: 'Medical Certificate from clinic/hospital'),
  LeaveSpec(type: 'unpaid', name: 'Unpaid Leave', quota: 8, docRequired: true, docLabel: 'Justification letter/document'),
  LeaveSpec(type: 'maternity', name: 'Maternity Leave', quota: 98, docRequired: true, docLabel: 'Hospital admission / Certified medical report'),
  LeaveSpec(type: 'marriage', name: 'Marriage Leave', quota: 5, docRequired: true, docLabel: 'Marriage certificate / Wedding invitation'),
  LeaveSpec(type: 'compassionate', name: 'Compassionate Leave', quota: 2, docRequired: true, docLabel: 'Death certificate / Official notice'),
  LeaveSpec(type: 'umrah', name: 'Umrah Leave', quota: 14, docRequired: true, docLabel: 'Travel itinerary / Flight booking'),
  LeaveSpec(type: 'haji', name: 'Haji Leave', quota: 40, docRequired: true, docLabel: 'Official pilgrim allocation letter'),
  LeaveSpec(type: 'birthday', name: 'Birthday Leave', quota: 1, docRequired: false, docLabel: 'None (Can be utilized anytime)'),
  LeaveSpec(type: 'halfday', name: 'Half Day Leave', quota: 2, docRequired: false, docLabel: 'None (Quota resets monthly)')
];

class LeaveScreen extends StatefulWidget {
  final TeacherRecord teacher;

  const LeaveScreen({Key? key, required this.teacher}) : super(key: key);

  @override
  _LeaveScreenState createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final LeaveService _leaveService = LeaveService();
  List<LeaveRecord> _leavesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeLeaves();
  }

  void _subscribeLeaves() {
    _leaveService.getLeaves(teacherId: widget.teacher.id).listen((leaves) {
      if (mounted) {
        setState(() {
          _leavesList = leaves;
          _isLoading = false;
        });
      }
    }, onError: (err) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Map<String, double> getLeaveBalance(LeaveType type) {
    final spec = leaveSpecs.firstWhere((s) => s.type == type.dbValue, orElse: () => leaveSpecs[0]);
    final quota = type == LeaveType.halfday ? 2.0 : spec.quota.toDouble();

    // Calculate Taken (Approved)
    double approvedDays = 0.0;
    if (type == LeaveType.halfday) {
      final currentMonthStr = DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM
      approvedDays = _leavesList
          .where((l) => l.type == LeaveType.halfday && l.status == 'approved' && l.startDate.substring(0, 7) == currentMonthStr)
          .fold(0.0, (sum, l) => sum + l.duration);
    } else {
      approvedDays = _leavesList
          .where((l) => l.type == type && l.status == 'approved')
          .fold(0.0, (sum, l) => sum + l.duration);
    }

    // Calculate Pending
    double pendingDays = 0.0;
    if (type == LeaveType.halfday) {
      final currentMonthStr = DateTime.now().toIso8601String().substring(0, 7);
      pendingDays = _leavesList
          .where((l) => l.type == LeaveType.halfday && l.status == 'pending' && l.startDate.substring(0, 7) == currentMonthStr)
          .fold(0.0, (sum, l) => sum + l.duration);
    } else {
      pendingDays = _leavesList
          .where((l) => l.type == type && l.status == 'pending')
          .fold(0.0, (sum, l) => sum + l.duration);
    }

    final remaining = (quota - approvedDays - pendingDays).clamp(0.0, double.infinity);

    return {
      'quota': quota,
      'taken': approvedDays,
      'pending': pendingDays,
      'remaining': remaining,
    };
  }

  void _openApplyLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => ApplyLeaveDialog(
        teacher: widget.teacher,
        onSubmitted: () {
          // Handled via stream auto-sync
        },
        getLeaveBalance: getLeaveBalance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text(
          'LEAVE BALANCE & QUOTAS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Color(0xFF1E241E),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E241E)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5A6B5A)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Employee Leave Quotas',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2C3E2C)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'APPLY AND TRACK LEAVES AGAINST ALLOCATED QUOTAS',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF8A9A8A)),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _openApplyLeaveDialog,
                          icon: const Icon(Icons.add, size: 14, color: Colors.white),
                          label: const Text(
                            'APPLY LEAVE',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A6B5A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            elevation: 0,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quotas Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.35,
                      ),
                      itemCount: leaveSpecs.length,
                      itemBuilder: (context, index) {
                        final spec = leaveSpecs[index];
                        final type = LeaveTypeExtension.fromDbValue(spec.type);
                        final balance = getLeaveBalance(type);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9ECE9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      spec.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1E241E)),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7F5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      spec.docRequired ? 'Doc Required' : 'No Doc',
                                      style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Color(0xFF7A8A7A)),
                                    ),
                                  )
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${balance['remaining']!.toInt()}',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF5A6B5A)),
                                      ),
                                      Text(
                                        ' / ${balance['quota']!.toInt()} left',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8A9A8A)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('TAKEN: ${balance['taken']!.toInt()}d', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF7A897A))),
                                  Text('PENDING: ${balance['pending']!.toInt()}d', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF7A897A))),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // History Section Header
                    const Row(
                      children: [
                        Icon(Icons.notes, size: 16, color: Color(0xFF5A6B5A)),
                        SizedBox(width: 6),
                        Text(
                          'APPLICATION HISTORY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF1E241E)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // History List
                    if (_leavesList.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8F7),
                          border: Border.all(color: const Color(0xFFECEEEC), style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: const Column(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 36, color: Color(0xFFB0BCB0)),
                            SizedBox(height: 8),
                            Text(
                              'NO APPLICATIONS FILED YET',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF7A8A7A)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'If you apply for leave, your application status will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 8, color: Color(0xFF8A9A8A)),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _leavesList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final leave = _leavesList[index];
                          final spec = leaveSpecs.firstWhere((s) => s.type == leave.type.dbValue, orElse: () => leaveSpecs[0]);

                          Color statusColor;
                          Color statusBg;
                          switch (leave.status) {
                            case 'approved':
                              statusColor = const Color(0xFF2E7D32);
                              statusBg = const Color(0xFFE8F5E9);
                              break;
                            case 'rejected':
                              statusColor = const Color(0xFFC62828);
                              statusBg = const Color(0xFFFFEBEE);
                              break;
                            default:
                              statusColor = const Color(0xFFEF6C00);
                              statusBg = const Color(0xFFFFF3E0);
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE9ECE9)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  // Accent color bar
                                  Container(
                                    width: 4,
                                    color: const Color(0xFF5A6B5A).withValues(alpha: 0.7),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                spec.name.toUpperCase(),
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF5A6B5A)),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                child: Text(
                                                  leave.status.toUpperCase(),
                                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5),
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Date Period: ${leave.startDate} ${leave.endDate != leave.startDate ? "to ${leave.endDate}" : ""}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E241E)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Duration: ${leave.duration == 0.5 ? "0.5 days (Half Day)" : "${leave.duration.toInt()} day(s)"}',
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF5A6B5A)),
                                          ),
                                          if (leave.remarks != null && leave.remarks!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF7F8F7),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFECEEEC)),
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              width: double.infinity,
                                              child: Text(
                                                '“${leave.remarks}”',
                                                style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Color(0xFF5A5A5A)),
                                              ),
                                            )
                                          ],
                                          if (leave.documentUrl != null && leave.documentUrl!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF5A6B5A).withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.cloud_done, size: 10, color: Color(0xFF5A6B5A)),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      leave.documentName ?? 'Attached File',
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF5A6B5A), decoration: TextDecoration.underline),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                          if (leave.principalNotes != null && leave.principalNotes!.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            const Divider(height: 1, color: Color(0xFFECEEEC)),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'PRINCIPAL FEEDBACK',
                                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF904060)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '“${leave.principalNotes}”',
                                              style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Color(0xFF7A7A7A)),
                                            )
                                          ]
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ApplyLeaveDialog extends StatefulWidget {
  final TeacherRecord teacher;
  final VoidCallback onSubmitted;
  final Map<String, double> Function(LeaveType) getLeaveBalance;

  const ApplyLeaveDialog({
    Key? key,
    required this.teacher,
    required this.onSubmitted,
    required this.getLeaveBalance,
  }) : super(key: key);

  @override
  _ApplyLeaveDialogState createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends State<ApplyLeaveDialog> {
  final _leaveService = LeaveService();
  final _remarksController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LeaveType _selectedType = LeaveType.annual;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  
  // Variables for native file picking
  Uint8List? _fileBytes;
  String? _documentName;
  String? _errorMessage;
  bool _isSubmitting = false;

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: true, 
      );

      if (result != null) {
        setState(() {
          _documentName = result.files.single.name;
          
          if (result.files.single.bytes != null) {
            _fileBytes = result.files.single.bytes;
          } else if (result.files.single.path != null) {
            _fileBytes = File(result.files.single.path!).readAsBytesSync();
          }
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
    });

    final spec = leaveSpecs.firstWhere((s) => s.type == _selectedType.dbValue, orElse: () => leaveSpecs.first);
    
    // Duration
    double duration = 1.0;
    if (_selectedType != LeaveType.halfday) {
      if (_startDate.isAfter(_endDate)) {
        setState(() {
          _errorMessage = "Start date can't be after end date.";
        });
        return;
      }
      final diff = _endDate.difference(_startDate).inDays;
      duration = (diff + 1).toDouble();
    } else {
      duration = 0.5;
    }

    // Balance check
    final balance = widget.getLeaveBalance(_selectedType);
    if (duration > (balance['remaining'] ?? 0.0)) {
      setState(() {
        _errorMessage = 'Insufficient leave balance. You request $duration d but only have ${balance['remaining']} d remaining.';
      });
      return;
    }

    // Document validation
    if (spec.docRequired && (_documentName == null || _fileBytes == null)) {
      setState(() {
        _errorMessage = 'Supporting document is mandatory for ${spec.name}. Please browse and attach a file.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? finalDocumentUrl;
      
      // Upload file to Cloudinary if one is selected
      if (_fileBytes != null && _documentName != null) {
        finalDocumentUrl = await CloudinaryService.uploadFile(
          _fileBytes!, 
          _documentName!,
          folder: 'leave-documents',
        );

        if (finalDocumentUrl == null) {
          setState(() {
            _errorMessage = 'Failed to upload document to Cloudinary.';
            _isSubmitting = false;
          });
          return;
        }
      }

      final leaveRecord = LeaveRecord(
        id: '',
        teacherId: widget.teacher.id,
        teacherName: widget.teacher.fullName,
        startDate: _startDate.toIso8601String().substring(0, 10),
        endDate: _selectedType == LeaveType.halfday 
            ? _startDate.toIso8601String().substring(0, 10)
            : _endDate.toIso8601String().substring(0, 10),
        duration: duration,
        type: _selectedType,
        status: 'pending',
        documentUrl: finalDocumentUrl, 
        documentName: _documentName,
        remarks: _remarksController.text,
      );

      await _leaveService.applyLeave(leaveRecord);
      widget.onSubmitted();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Submission failed: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = leaveSpecs.firstWhere((s) => s.type == _selectedType.dbValue, orElse: () => leaveSpecs.first);

    return AlertDialog(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPLY FOR LEAVE',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Color(0xFF1E241E)),
          ),
          SizedBox(height: 2),
          Text(
            'FILL OUT SECURE LEAVE RECORD FORM',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF8A9A8A)),
          )
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 9, color: Color(0xFFC62828), fontWeight: FontWeight.bold),
                  ),
                ),

              // Type Selector
              DropdownButtonFormField<LeaveType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'LEAVE TYPE',
                  labelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF7A8A7A)),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 11, color: Color(0xFF1E241E), fontWeight: FontWeight.bold),
                items: leaveSpecs.map((s) {
                  final type = LeaveTypeExtension.fromDbValue(s.type);
                  final bal = widget.getLeaveBalance(type);
                  return DropdownMenuItem<LeaveType>(
                    value: type,
                    child: Text('${s.name} (${bal['remaining']!.toInt()} left)'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                      _documentName = null;
                      _fileBytes = null; 
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Start Date Selector
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('START DATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF7A8A7A))),
                subtitle: Text(
                  '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E241E)),
                ),
                trailing: const Icon(Icons.calendar_month, color: Color(0xFF5A6B5A)),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selected != null) {
                    setState(() {
                      _startDate = selected;
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = selected;
                      }
                    });
                  }
                },
              ),

              // End Date Selector (Omit for Half Day)
              if (_selectedType != LeaveType.halfday) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('END DATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF7A8A7A))),
                  subtitle: Text(
                    '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E241E)),
                  ),
                  trailing: const Icon(Icons.calendar_month, color: Color(0xFF5A6B5A)),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      setState(() {
                        _endDate = selected;
                      });
                    }
                  },
                ),
              ],
              const Divider(),

              // Remarks
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'REMARKS (OPTIONAL)',
                  labelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF7A8A7A)),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 14),

              // Mandatory Documentation Check
              if (spec.docRequired) ...[
                const Text(
                  'SUPPORTING DOCUMENT REQUIREMENT',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF904060)),
                ),
                const SizedBox(height: 2),
                Text(
                  spec.docLabel,
                  style: const TextStyle(fontSize: 8, color: Color(0xFF8A9A8A)),
                ),
                const SizedBox(height: 8),

                if (_documentName != null)
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF5A6B5A).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_documentName!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _documentName = null;
                              _fileBytes = null;
                            });
                          },
                        )
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.upload_file, size: 14),
                    label: const Text('BROWSE / ATTACH SUPPORTING DOCUMENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A6B5A),
                      side: const BorderSide(color: Color(0xFF5A6B5A)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  )
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('CANCEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF7A8A7A))),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A6B5A), elevation: 0),
          child: _isSubmitting
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('SUBMIT APPLICATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
        )
      ],
    );
  }
}