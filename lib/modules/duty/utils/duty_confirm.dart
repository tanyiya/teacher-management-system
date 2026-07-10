import 'package:flutter/material.dart';

/// Shows a confirm/cancel dialog and returns `true` only if the person
/// tapped confirm. Used before any principal-initiated action that deletes
/// or updates duty data, since those changes propagate broadly (e.g. an
/// edit touches every upcoming assignment generated from that duty).
Future<bool> showDutyConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: Colors.red)
              : null,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}