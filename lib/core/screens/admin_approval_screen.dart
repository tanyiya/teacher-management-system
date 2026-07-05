import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../app_theme.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBase,
      appBar: AppBar(
        title: const Text('Pending Approvals'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('status', isEqualTo: 'Pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.checkCircle,
                      size: 48, color: AppTheme.primaryActive),
                  const SizedBox(height: 16),
                  Text(
                    'No pending approvals',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              return _ApprovalCard(docId: docId, data: data);
            },
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _ApprovalCard({required this.docId, required this.data});

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  bool _isProcessing = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      // Map displayed status to stored status values used by login validation
      final lower = newStatus.toString().toLowerCase();
      final userStatus = lower == 'approved' ? 'active' : 'inactive';
      final verificationStatus = lower == 'approved' ? 'approved' : 'rejected';

      // Update users doc (auth metadata)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.docId)
          .set({
        'status': userStatus,
        'isActive': userStatus == 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update/create the teacher profile so teacher lists reflect approval
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(widget.docId)
          .set({
        'status': userStatus,
        'verificationStatus': verificationStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration ${newStatus.toLowerCase()}')),
        );
      }
      setState(() => _isProcessing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['fullName'] ?? 'Unknown';
    final email = widget.data['email'] ?? 'Unknown';
    final phone = widget.data['phoneNumber'] ?? 'Unknown';
    final ic = widget.data['icNumber'] ?? 'Unknown';
    final Timestamp? createdAt = widget.data['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? '${createdAt.toDate().year}-${createdAt.toDate().month.toString().padLeft(2, '0')}-${createdAt.toDate().day.toString().padLeft(2, '0')}'
        : 'Unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryActive.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppTheme.primaryActive),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        email,
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _InfoRow(
                icon: LucideIcons.creditCard, label: 'IC Number', value: ic),
            const SizedBox(height: 8),
            _InfoRow(icon: LucideIcons.phone, label: 'Phone', value: phone),
            const SizedBox(height: 8),
            _InfoRow(
                icon: LucideIcons.calendar,
                label: 'Registered',
                value: dateStr),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _updateStatus('Rejected'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _updateStatus('Approved'),
                    icon: const Icon(LucideIcons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
