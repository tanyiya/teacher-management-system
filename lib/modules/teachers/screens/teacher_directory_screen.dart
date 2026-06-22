import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_theme.dart';
import '../../../providers/app_state_provider.dart';
import '../models/change_request.dart';
import '../models/teacher.dart';
import '../services/teacher_service.dart';

class TeacherDirectoryScreen extends StatefulWidget {
  const TeacherDirectoryScreen({super.key});

  @override
  State<TeacherDirectoryScreen> createState() => _TeacherDirectoryScreenState();
}

class _TeacherDirectoryScreenState extends State<TeacherDirectoryScreen>
    with SingleTickerProviderStateMixin {
  final _service = TeacherService();
  final _searchCtrl = TextEditingController();

  TeacherRecord? _selected;
  String _statusFilter = 'All';
  String _searchQuery = '';
  late TabController _tabCtrl;

  static const _filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeacherRecord>>(
      stream: _service.getTeachers(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('Error loading teachers: ${snap.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!
            .where((t) => t.role != 'principal' && t.role != 'admin')
            .toList();

        final filtered = _filter(all);

        return LayoutBuilder(
          builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 660;
            if (wide) {
              return _buildWide(all, filtered);
            } else {
              return _buildNarrow(all, filtered);
            }
          },
        );
      },
    );
  }

  // ── Layouts ───────────────────────────────────────────────────────────────

  Widget _buildWide(List<TeacherRecord> all, List<TeacherRecord> filtered) {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: _buildList(all, filtered),
        ),
        const VerticalDivider(width: 1, color: AppTheme.subtleGrayBoundary),
        Expanded(
          child: _selected == null
              ? _buildEmptyDetail()
              : StreamBuilder<TeacherRecord?>(
                  stream: _service.getTeacherStream(_selected!.id),
                  builder: (ctx, snap) {
                    final t = snap.data ?? _selected!;
                    return _buildDetail(t);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNarrow(List<TeacherRecord> all, List<TeacherRecord> filtered) {
    return _buildList(all, filtered);
  }

  // ── Teacher list panel ────────────────────────────────────────────────────

  Widget _buildList(List<TeacherRecord> all, List<TeacherRecord> filtered) {
    return Column(
      children: [
        _buildListHeader(all),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No teachers found.', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppTheme.subtleGrayBoundary),
                  itemBuilder: (ctx, i) => _buildListTile(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildListHeader(List<TeacherRecord> all) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats
          Row(children: [
            _statChip('Total', all.length, Colors.grey),
            const SizedBox(width: 8),
            _statChip('Pending', all.where((t) => t.verificationStatus == 'pending').length, Colors.amber),
            const SizedBox(width: 8),
            _statChip('Approved', all.where((t) => t.verificationStatus == 'approved').length, Colors.green),
            const SizedBox(width: 8),
            _statChip('Rejected', all.where((t) => t.verificationStatus == 'rejected').length, Colors.red),
          ]),
          const SizedBox(height: 12),
          // Search
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name or email…',
              prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppTheme.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 14),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.canvasBase,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.subtleGrayBoundary)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.subtleGrayBoundary)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
          const SizedBox(height: 8),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final active = _statusFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(f, style: TextStyle(fontSize: 12, color: active ? Colors.white : AppTheme.textCore)),
                    selected: active,
                    onSelected: (_) => setState(() => _statusFilter = f),
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.canvasBase,
                    showCheckmark: false,
                    side: const BorderSide(color: AppTheme.subtleGrayBoundary),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$count $label', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildListTile(TeacherRecord t) {
    final isSelected = _selected?.id == t.id;
    return InkWell(
      onTap: () {
        setState(() => _selected = t);
        _tabCtrl.index = 0;
        // On narrow: open bottom sheet
        if (MediaQuery.of(context).size.width <= 660) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              builder: (_, ctrl) => StreamBuilder<TeacherRecord?>(
                stream: _service.getTeacherStream(t.id),
                builder: (ctx, snap) => _buildDetail(snap.data ?? t),
              ),
            ),
          );
        }
      },
      child: Container(
        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.06) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            child: Text(t.fullName.isNotEmpty ? t.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(t.email,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('Profile ${t.completionProgress}%',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ]),
          ),
          const SizedBox(width: 8),
          _verificationBadge(t.verificationStatus, small: true),
        ]),
      ),
    );
  }

  // ── Detail panel ──────────────────────────────────────────────────────────

  Widget _buildEmptyDetail() {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.users, size: 40, color: AppTheme.subtleGrayBoundary),
        SizedBox(height: 12),
        Text('Select a teacher to view details',
            style: TextStyle(color: AppTheme.textMuted)),
      ]),
    );
  }

  Widget _buildDetail(TeacherRecord t) {
    final adminName = Provider.of<AppStateProvider>(context, listen: false).currentUser?.fullName ?? '';

    return Column(
      children: [
        // Detail header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: avatar + name/role
              Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: Text(t.fullName.isNotEmpty ? t.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('${t.role} • ${t.email}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              // Row 2: badge + completion + action buttons
              Row(children: [
                _verificationBadge(t.verificationStatus),
                const SizedBox(width: 8),
                Text('${t.completionProgress}%',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const Spacer(),
                if (t.verificationStatus != 'approved')
                  TextButton.icon(
                    icon: const Icon(LucideIcons.checkCircle, size: 13),
                    label: const Text('Approve', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () => _approveRecord(t),
                  ),
                if (t.verificationStatus != 'rejected')
                  TextButton.icon(
                    icon: const Icon(LucideIcons.xCircle, size: 13),
                    label: const Text('Reject', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () => _rejectRecord(t),
                  ),
              ]),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabCtrl,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primaryColor,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'Documents'),
                  Tab(text: 'Change Requests'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.subtleGrayBoundary),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildProfileTab(t, adminName),
              _buildDocumentsTab(t),
              _buildChangeRequestsTab(t, adminName),
            ],
          ),
        ),
      ],
    );
  }

  // ── Profile tab ───────────────────────────────────────────────────────────

  Widget _buildProfileTab(TeacherRecord t, String adminName) {
    final fields = [
      ('Full Name', t.fullName),
      ('IC Number', t.icNumber),
      ('Gender', t.gender),
      ('Date of Birth', t.dob),
      ('Email', t.email),
      ('Phone Number', t.phoneNumber),
      ('Address', t.address),
      ('Marital Status', t.maritalStatus),
      ('Emergency Contact', t.emergencyContactName),
      ('Emergency Number', t.emergencyContactNumber),
      ('Role', t.role),
      ('Status', t.status),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Teacher Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.pencil, size: 13),
            label: const Text('Edit', style: TextStyle(fontSize: 12)),
            onPressed: () => _showEditDialog(t),
          ),
        ]),
        const SizedBox(height: 14),
        if (t.verificationRejectionReason.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(LucideIcons.alertCircle, size: 14, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Rejection reason: ${t.verificationRejectionReason}',
                    style: const TextStyle(fontSize: 12, color: Colors.red)),
              ),
            ]),
          ),
        // Two-column auto-height layout (GridView fixed-aspect-ratio causes overflow on phones)
        Column(
          children: [
            for (var i = 0; i < fields.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _infoTile(fields[i].$1, fields[i].$2)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: i + 1 < fields.length
                          ? _infoTile(fields[i + 1].$1, fields[i + 1].$2)
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ]),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.canvasBase,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.subtleGrayBoundary),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '—',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: value.isNotEmpty ? AppTheme.textCore : AppTheme.textMuted,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ]),
    );
  }

  // ── Documents tab ─────────────────────────────────────────────────────────

  Widget _buildDocumentsTab(TeacherRecord t) {
    const docDefs = [
      ('myKad', 'Copy of Identification Card (MyKad)'),
      ('passportPhoto', 'Passport Photo'),
      ('resume', 'Resume / CV'),
      ('academicCertificates', 'Latest Academic Certificates'),
      ('medicalReport', 'Medical Check Up Report'),
      ('bankStatement', 'Bank Statement Header'),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Document Verification',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Review and verify each supporting document.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 14),
        ...docDefs.map((d) => _adminDocCard(t, d.$1, d.$2)),
      ],
    );
  }

  Widget _adminDocCard(TeacherRecord t, String docKey, String docName) {
    final rec = t.documents[docKey];
    final status = rec?.status ?? 'empty';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        statusLabel = 'Verified';
        break;
      case 'uploaded':
        statusColor = Colors.blue;
        statusLabel = 'Pending Review';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = AppTheme.textMuted;
        statusLabel = 'Not Uploaded';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.subtleGrayBoundary),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(LucideIcons.file, size: 15, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
              child: Text(docName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusLabel,
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
          ),
        ]),

        if ((rec?.rejectionReason ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 23),
            child: Text(rec!.rejectionReason,
                style: const TextStyle(fontSize: 11, color: Colors.red)),
          ),

        if (status == 'uploaded' || status == 'verified') ...[
          const SizedBox(height: 10),
          Row(children: [
            if ((rec?.url ?? '').isNotEmpty)
              TextButton.icon(
                icon: const Icon(LucideIcons.externalLink, size: 13),
                label: const Text('View', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  final uri = Uri.tryParse(rec!.url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open file. No app available to view this type.')),
                      );
                    }
                  }
                },
              ),
            const Spacer(),
            // Verify and Reject are only relevant while the doc is pending review.
            if (status == 'uploaded') ...[
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.checkCircle, size: 13),
                label: const Text('Verify', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                onPressed: () => _verifyDoc(t, docKey),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.xCircle, size: 13),
                label: const Text('Reject', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _rejectDoc(t, docKey, docName),
              ),
            ],
          ]),
        ],
      ]),
    );
  }

  // ── Change requests tab ───────────────────────────────────────────────────

  Widget _buildChangeRequestsTab(TeacherRecord t, String adminName) {
    return StreamBuilder<List<ChangeRequest>>(
      stream: _service.getChangeRequestsForTeacher(t.id),
      builder: (ctx, snap) {
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Text('No change requests.',
                style: TextStyle(color: AppTheme.textMuted)),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Identity Change Requests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 14),
            ...requests.map((r) => _changeRequestCard(r, adminName)),
          ],
        );
      },
    );
  }

  Widget _changeRequestCard(ChangeRequest r, String adminName) {
    Color statusColor;
    switch (r.status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.amber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.subtleGrayBoundary),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${r.fieldLabel} Change',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(r.status.toUpperCase(),
                style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        _reqRow('From', r.oldValue),
        _reqRow('To', r.newValue),
        _reqRow('Submitted', _formatDate(r.submittedAt)),
        if (r.status == 'rejected' && r.rejectionReason.isNotEmpty)
          _reqRow('Reason', r.rejectionReason),
        if (r.status == 'pending') ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.checkCircle, size: 13),
              label: const Text('Approve', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
              onPressed: () => _approveChangeRequest(r, adminName),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.xCircle, size: 13),
              label: const Text('Reject', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _rejectChangeRequest(r, adminName),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _reqRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  // ── Admin actions ─────────────────────────────────────────────────────────

  // Optimistically update _selected so the UI reflects changes immediately
  // without waiting for the gRPC stream (which may be blocked on Android).
  void _applyDocStatus(TeacherRecord t, String docKey, String status, {String reason = ''}) {
    if (!mounted || _selected?.id != t.id) return;
    final docs = Map<String, DocumentRecord>.from(t.documents);
    if (docs.containsKey(docKey)) {
      docs[docKey] = docs[docKey]!.copyWith(status: status, rejectionReason: reason);
    }
    setState(() => _selected = t.copyWith(documents: docs));
  }

  void _applyVerificationStatus(TeacherRecord t, String status, {String reason = ''}) {
    if (!mounted || _selected?.id != t.id) return;
    setState(() => _selected = t.copyWith(
      verificationStatus: status,
      verificationRejectionReason: reason,
    ));
  }

  Future<void> _approveRecord(TeacherRecord t) async {
    final ok = await _confirmDialog('Approve Record',
        'Approve ${t.fullName}\'s record? This confirms all submitted information is verified.');
    if (ok != true) return;
    try {
      await _service.updateVerificationStatus(t.id, 'approved')
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      _applyVerificationStatus(t, 'approved');
      _showSnack('Record approved.', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', isError: true);
    }
  }

  Future<void> _rejectRecord(TeacherRecord t) async {
    final reason = await _reasonDialog('Reject Record', 'Enter the reason for rejection:');
    if (reason == null) return;
    try {
      await _service.updateVerificationStatus(t.id, 'rejected', rejectionReason: reason)
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      _applyVerificationStatus(t, 'rejected', reason: reason);
      _showSnack('Record rejected.', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', isError: true);
    }
  }

  Future<void> _verifyDoc(TeacherRecord t, String docKey) async {
    try {
      await _service.updateDocumentStatus(t.id, docKey, 'verified')
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      _applyDocStatus(t, docKey, 'verified');
      _showSnack('Document verified.', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', isError: true);
    }
  }

  Future<void> _rejectDoc(TeacherRecord t, String docKey, String docName) async {
    final reason = await _reasonDialog('Reject Document', 'Enter the reason for rejecting "$docName":');
    if (reason == null) return;
    try {
      await _service.updateDocumentStatus(t.id, docKey, 'rejected', rejectionReason: reason)
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      _applyDocStatus(t, docKey, 'rejected', reason: reason);
      _showSnack('Document rejected.', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', isError: true);
    }
  }

  Future<void> _approveChangeRequest(ChangeRequest r, String adminName) async {
    final ok = await _confirmDialog('Approve Change Request',
        'Approve changing ${r.fieldLabel} from "${r.oldValue}" to "${r.newValue}"?');
    if (ok != true) return;
    try {
      await _service.reviewChangeRequest(r.id, r.teacherId, r.field, r.newValue, true,
          reviewedBy: adminName)
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      _showSnack('Change request approved.', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', isError: true);
    }
  }

  Future<void> _rejectChangeRequest(ChangeRequest r, String adminName) async {
    final reason = await _reasonDialog('Reject Change Request', 'Enter the reason for rejection:');
    if (reason == null) return;
    try {
      await _service.reviewChangeRequest(r.id, r.teacherId, r.field, r.newValue, false,
          rejectionReason: reason, reviewedBy: adminName)
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      _showSnack('Change request rejected.', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', isError: true);
    }
  }

  Future<void> _showEditDialog(TeacherRecord t) async {
    await showDialog(
      context: context,
      builder: (ctx) => _EditTeacherDialog(teacher: t, service: _service),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<bool?> _confirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
  }

  Future<String?> _reasonDialog(String title, String hint) {
    // Do not dispose ctrl here — the dialog may still be animating out when
    // this function returns, so the TextField is still subscribed to the
    // controller. Disposing early triggers '_dependents.isEmpty' assertion.
    // The controller is a short-lived local and will be GC'd automatically.
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<TeacherRecord> _filter(List<TeacherRecord> all) {
    return all.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.fullName.toLowerCase().contains(_searchQuery) ||
          t.email.toLowerCase().contains(_searchQuery);
      final matchesStatus = _statusFilter == 'All' ||
          t.verificationStatus.toLowerCase() == _statusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _verificationBadge(String status, {bool small = false}) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        icon = LucideIcons.checkCircle;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        icon = LucideIcons.xCircle;
        break;
      default:
        color = Colors.amber;
        label = 'Pending';
        icon = LucideIcons.clock;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: small ? 10 : 12, color: color),
        SizedBox(width: small ? 3 : 4),
        Text(label,
            style: TextStyle(
                fontSize: small ? 10 : 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Admin Edit Dialog ─────────────────────────────────────────────────────────

class _EditTeacherDialog extends StatefulWidget {
  final TeacherRecord teacher;
  final TeacherService service;
  const _EditTeacherDialog({required this.teacher, required this.service});

  @override
  State<_EditTeacherDialog> createState() => _EditTeacherDialogState();
}

class _EditTeacherDialogState extends State<_EditTeacherDialog> {
  late final Map<String, TextEditingController> _ctrls;
  String? _gender;
  String? _maritalStatus;
  String? _role;
  bool _saving = false;

  static const _genders = ['Male', 'Female'];
  static const _maritalOptions = ['Single', 'Married', 'Divorced', 'Widowed'];
  static const _roles = ['teacher', 'principal', 'admin'];

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    _ctrls = {
      'fullName': TextEditingController(text: t.fullName),
      'icNumber': TextEditingController(text: t.icNumber),
      'dob': TextEditingController(text: t.dob),
      'address': TextEditingController(text: t.address),
      'phoneNumber': TextEditingController(text: t.phoneNumber),
      'email': TextEditingController(text: t.email),
      'emergencyContactName': TextEditingController(text: t.emergencyContactName),
      'emergencyContactNumber': TextEditingController(text: t.emergencyContactNumber),
    };
    _gender = _genders.contains(t.gender) ? t.gender : null;
    _maritalStatus = _maritalOptions.contains(t.maritalStatus) ? t.maritalStatus : null;
    _role = _roles.contains(t.role) ? t.role : 'teacher';
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final fields = <String, dynamic>{
        'gender': _gender ?? '',
        'maritalStatus': _maritalStatus ?? '',
        'role': _role ?? 'teacher',
      };
      for (final e in _ctrls.entries) {
        fields[e.key] = e.value.text.trim();
      }
      // Timeout after 3 s — on Android the gRPC backend may be unreachable
      // and Firestore blocks the Future while retrying. The write is already
      // queued in the local cache and will sync when connectivity is restored.
      await widget.service
          .adminUpdateTeacher(widget.teacher.id, fields)
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      // Close the dialog even on error so the user is not stuck.
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit — ${widget.teacher.fullName}'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _tf('Full Name', 'fullName'),
            _tf('IC Number', 'icNumber'),
            _tf('Date of Birth (YYYY-MM-DD)', 'dob'),
            _dropdown('Gender', _gender, _genders, (v) => setState(() => _gender = v)),
            _tf('Phone Number', 'phoneNumber'),
            _tf('Email', 'email'),
            _tf('Address', 'address'),
            _dropdown('Marital Status', _maritalStatus, _maritalOptions,
                (v) => setState(() => _maritalStatus = v)),
            _tf('Emergency Contact Name', 'emergencyContactName'),
            _tf('Emergency Contact Number', 'emergencyContactNumber'),
            _dropdown('Role', _role, _roles, (v) => setState(() => _role = v)),
            const SizedBox(height: 8),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _tf(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _ctrls[key],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
