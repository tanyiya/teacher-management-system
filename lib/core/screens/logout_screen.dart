import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state_provider.dart';
import '../../app_theme.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({Key? key}) : super(key: key);

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _performLogout();
  }

  Future<void> _performLogout() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    await appState.logout();
    if (!mounted) return;
    setState(() => _done = true);
    // navigate to login
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              _done
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                        SizedBox(height: 8),
                        Text('Logged out', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(width: 48, height: 48, child: CircularProgressIndicator()),
                        SizedBox(height: 8),
                        Text('Signing out...'),
                      ],
                    ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
