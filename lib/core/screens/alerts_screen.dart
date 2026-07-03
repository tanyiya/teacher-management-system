import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../app_theme.dart';
import '../../modules/teachers/models/teacher.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class AlertsScreen extends StatelessWidget {
  final TeacherRecord user;
  // Called whenever a notification is tapped so the host screen (admin or
  // teacher dashboard) can decide where to navigate based on notif.type —
  // e.g. a change request opens the teacher's case, a document alert opens
  // the teacher's own Profile tab. Null when this screen has nowhere to send
  // the tap (not expected in practice, but keeps this widget decoupled).
  final void Function(AlertNotification notif)? onNotificationTap;
  const AlertsScreen({Key? key, required this.user, this.onNotificationTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final svc = NotificationService();

    return StreamBuilder<List<AlertNotification>>(
      stream: svc.getNotifications(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data ?? [];

        if (all.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.bellOff, size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 12),
                Text('No notifications', style: TextStyle(color: AppTheme.textMuted)),
              ],
            ),
          );
        }

        final unreadCount = all.where((n) => !n.isRead).length;
        final today = DateUtils.dateOnly(DateTime.now());
        final todayItems = all.where((n) => DateUtils.dateOnly(n.timestamp) == today).toList();
        final earlierItems = all.where((n) => DateUtils.dateOnly(n.timestamp) != today).toList();

        return Column(
          children: [
            // Header bar with mark-all button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    '$unreadCount unread',
                    style: TextStyle(
                      fontSize: 13,
                      color: unreadCount > 0 ? AppTheme.primaryColor : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: () => svc.markAllAsRead(user.id),
                      icon: const Icon(LucideIcons.checkCheck, size: 16),
                      label: const Text('Mark all read'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  if (todayItems.isNotEmpty) ...[
                    _sectionHeader('Today'),
                    ...todayItems.map((n) => _NotifTile(notif: n, svc: svc, onTap: onNotificationTap)),
                  ],
                  if (earlierItems.isNotEmpty) ...[
                    _sectionHeader('Earlier'),
                    ...earlierItems.map((n) => _NotifTile(notif: n, svc: svc, onTap: onNotificationTap)),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AlertNotification notif;
  final NotificationService svc;
  final void Function(AlertNotification notif)? onTap;
  const _NotifTile({required this.notif, required this.svc, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => svc.deleteNotification(notif.id),
      child: InkWell(
        onTap: (notif.isRead && onTap == null)
            ? null
            : () {
                if (!notif.isRead) svc.markAsRead(notif.id);
                onTap?.call(notif);
              },
        child: Container(
        color: notif.isRead ? Colors.transparent : AppTheme.primaryColor.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _typeColor(notif.type).withValues(alpha: 0.12),
              child: Icon(_typeIcon(notif.type), size: 18, color: _typeColor(notif.type)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.message,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notif.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),    // Container
      ),    // InkWell
    );      // Dismissible
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'document_verified':
        return LucideIcons.fileCheck;
      case 'document_rejected':
        return LucideIcons.fileX;
      case 'record_approved':
        return LucideIcons.userCheck;
      case 'record_rejected':
        return LucideIcons.userX;
      case 'change_approved':
      case 'change_rejected':
        return LucideIcons.clipboardList;
      case 'training':
      case 'broadcast':
        return LucideIcons.bookOpen;
      case 'duty':
      case 'swap_request':
      case 'swap_approved':
        return LucideIcons.calendarDays;
      case 'kpi':
        return LucideIcons.barChart2;
      case 'warning':
        return LucideIcons.alertTriangle;
      case 'leave':
        return LucideIcons.calendarOff;
      case 'change_request':
      case 'admin':
        return LucideIcons.shieldAlert;
      default:
        return LucideIcons.bell;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'document_verified':
      case 'record_approved':
      case 'change_approved':
        return Colors.green;
      case 'document_rejected':
      case 'record_rejected':
      case 'change_rejected':
        return Colors.red;
      case 'training':
      case 'broadcast':
        return Colors.indigo;
      case 'duty':
      case 'swap_request':
      case 'swap_approved':
        return Colors.teal;
      case 'kpi':
        return Colors.orange;
      case 'warning':
        return Colors.deepOrange;
      case 'leave':
        return Colors.purple;
      case 'change_request':
      case 'admin':
        return Colors.deepPurple;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatTime(DateTime dt) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.dateOnly(dt) == today) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('d MMM, h:mm a').format(dt);
  }
}
