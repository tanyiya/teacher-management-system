import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/leave_service.dart';
import '../../teachers/models/teacher.dart';
import '../models/leave.dart' hide TeacherRecord; 
import '../../../core/services/cloudinary_service.dart';
import '../../../app_theme.dart'; // Make sure this path is correct for your project

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

    double approvedDays = 0.0;
    if (type == LeaveType.halfday) {
      final currentMonthStr = DateTime.now().toIso8601String().substring(0, 7);
      approvedDays = _leavesList
          .where((l) => l.type == LeaveType.halfday && l.status == 'approved' && l.startDate.substring(0, 7) == currentMonthStr)
          .fold(0.0, (sum, l) => sum + l.duration);
    } else {
      approvedDays = _leavesList
          .where((l) => l.type == type && l.status == 'approved')
          .fold(0.0, (sum, l) => sum + l.duration);
    }

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
        onSubmitted: () {},
        getLeaveBalance: getLeaveBalance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Pulling the dynamic theme

    return Scaffold(
      backgroundColor: AppTheme.canvasBase,
      appBar: AppBar(
        title: Text(
          'LEAVE BALANCE & QUOTAS',
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: AppTheme.textCore),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Employee Leave Quotas',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'APPLY AND TRACK LEAVES AGAINST ALLOCATED QUOTAS',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 8, 
                                  fontWeight: FontWeight.bold, 
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _openApplyLeaveDialog,
                          icon: const Icon(Icons.add, size: 14, color: Colors.white),
                          label: const Text(
                            'APPLY LEAVE',
                            style: TextStyle(
                              fontSize: 9, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 1.0, 
                              color: Colors.white
                            ),
                          ),
                          // Retaining slight custom styling just for this specific button shape
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            elevation: 0,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quotas Grid matching the tall cards
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        // ✨ CHANGED: Increased from 0.88 to 1.15 to make the boxes shorter and neater
                        childAspectRatio: 1.15, 
                      ),
                      itemCount: leaveSpecs.length,
                      itemBuilder: (context, index) {
                        final spec = leaveSpecs[index];
                        final type = LeaveTypeExtension.fromDbValue(spec.type);
                        final balance = getLeaveBalance(type);

                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.subtleGrayBoundary),
                          ),
                          // ✨ CHANGED: Reduced padding slightly to fit the tighter box
                          padding: const EdgeInsets.all(10), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      spec.name,
                                      maxLines: 2,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 11, // ✨ CHANGED: Slightly smaller title 
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.canvasBase,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      spec.docRequired ? 'Doc Required' : 'No Doc',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 7, 
                                        fontWeight: FontWeight.w900,
                                      ),
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
                                        style: theme.textTheme.displayMedium?.copyWith(
                                          fontSize: 24, // ✨ CHANGED: Reduced number size so it fits perfectly
                                          fontWeight: FontWeight.w900, 
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                      Text(
                                        ' / ${balance['quota']!.toInt()} left',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 9, 
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TAKEN: ${balance['taken']!.toInt()}d', 
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 8, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    'PENDING: ${balance['pending']!.toInt()}d', 
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 8, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // History Section Header
                    Row(
                      children: [
                        Icon(Icons.notes, size: 16, color: AppTheme.textCore),
                        const SizedBox(width: 6),
                        Text(
                          'APPLICATION HISTORY',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 11, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 1.2,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // History List matching the design
                    if (_leavesList.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.ambientOffWhite,
                          border: Border.all(color: AppTheme.subtleGrayBoundary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 36, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            Text(
                              'NO APPLICATIONS FILED YET',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9, 
                                fontWeight: FontWeight.w900, 
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _leavesList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final leave = _leavesList[index];

                          Color statusColor;
                          Color statusBg;
                          switch (leave.status) {
                            case 'approved':
                              statusColor = Colors.green.shade700;
                              statusBg = Colors.green.shade50;
                              break;
                            case 'rejected':
                              statusColor = Colors.red.shade700;
                              statusBg = Colors.red.shade50;
                              break;
                            default:
                              statusColor = Colors.orange.shade700;
                              statusBg = Colors.orange.shade50;
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.subtleGrayBoundary),
                              // Optional slight shadow similar to screenshot
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  // Accent color bar on the left
                                  Container(
                                    width: 4,
                                    color: AppTheme.subtleGrayBoundary,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                leave.type.name.toUpperCase(),
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontSize: 11, 
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Text(
                                                  leave.status.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 8, 
                                                    fontWeight: FontWeight.w900, 
                                                    color: statusColor, 
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          RichText(
                                            text: TextSpan(
                                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                                              children: [
                                                const TextSpan(text: 'Date Period: ', style: TextStyle(fontWeight: FontWeight.w800)),
                                                TextSpan(text: '${leave.startDate} ${leave.endDate != leave.startDate ? "to ${leave.endDate}" : ""}'),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Duration: ${leave.duration == 0.5 ? "0.5 days (Half Day)" : "${leave.duration.toInt()} day(s)"}',
                                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                          ),
                                          
                                          // Remarks Grey Box
                                          if (leave.remarks != null && leave.remarks!.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppTheme.ambientOffWhite,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppTheme.subtleGrayBoundary, width: 0.5),
                                              ),
                                              padding: const EdgeInsets.all(10),
                                              width: double.infinity,
                                              child: Text(
                                                '“${leave.remarks}”',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  fontSize: 10, 
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            )
                                          ],

                                          // Attachment Pill
                                          if (leave.documentUrl != null && leave.documentUrl!.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppTheme.canvasBase,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.cloud_download, size: 12, color: AppTheme.textMuted),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      leave.documentName ?? 'Attached File',
                                                      overflow: TextOverflow.ellipsis,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        fontSize: 9, 
                                                        fontWeight: FontWeight.bold, 
                                                        decoration: TextDecoration.underline,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )
                                          ],

                                          if (leave.principalNotes != null && leave.principalNotes!.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            const Divider(height: 1),
                                            const SizedBox(height: 8),
                                            Text(
                                              'PRINCIPAL FEEDBACK',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontSize: 8, 
                                                fontWeight: FontWeight.w900, 
                                                letterSpacing: 0.8, 
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '“${leave.principalNotes}”',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontSize: 10, 
                                                fontStyle: FontStyle.italic,
                                              ),
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

    final balance = widget.getLeaveBalance(_selectedType);
    if (duration > (balance['remaining'] ?? 0.0)) {
      setState(() {
        _errorMessage = 'Insufficient leave balance. You request $duration d but only have ${balance['remaining']} d remaining.';
      });
      return;
    }

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
    final theme = Theme.of(context);
    final spec = leaveSpecs.firstWhere((s) => s.type == _selectedType.dbValue, orElse: () => leaveSpecs.first);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPLY FOR LEAVE',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 14, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'FILL OUT SECURE LEAVE RECORD FORM',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 8, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 0.5,
            ),
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
                  decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 9, color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                  ),
                ),

              DropdownButtonFormField<LeaveType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'LEAVE TYPE',
                  labelStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w900),
                  border: const OutlineInputBorder(),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
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

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('START DATE', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w900)),
                subtitle: Text(
                  '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(Icons.calendar_month, color: theme.primaryColor),
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

              if (_selectedType != LeaveType.halfday) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('END DATE', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w900)),
                  subtitle: Text(
                    '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.calendar_month, color: theme.primaryColor),
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

              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'REMARKS (OPTIONAL)',
                  labelStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w900),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 14),

              if (spec.docRequired) ...[
                Text(
                  'SUPPORTING DOCUMENT REQUIREMENT',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 8, 
                    fontWeight: FontWeight.w900, 
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  spec.docLabel,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 8),
                ),
                const SizedBox(height: 8),

                if (_documentName != null)
                  Container(
                    decoration: BoxDecoration(color: AppTheme.canvasBase, borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_documentName!, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 9, fontWeight: FontWeight.bold) ?? const TextStyle())),
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
                    label: const Text('BROWSE / ATTACH', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
                    style: OutlinedButton.styleFrom(
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
          child: Text('CANCEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('SUBMIT APPLICATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
        )
      ],
    );
  }
}