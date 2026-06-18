import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state_provider.dart';
import '../../modules/teachers/models/teacher.dart';
import '../../modules/teachers/services/teacher_service.dart';
import '../../app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TeacherService _db = TeacherService();
  bool _isCampusStaff = true;

  // ---------- Debug Start ----------
  @override
  void initState() {
    super.initState();
    _db.getTeachers().listen((users) {
      print('Users fetched: ${users.length}');
      for (var u in users) {
        print('  - ${u.fullName} (${u.role})');
      }
    }, onError: (e) {
      print('Stream error: $e');
    });
  }
   // ---------- Debug End ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3), // Ambient off-white
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF0EFEC)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Welcome Illustration Placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  'GENIUS AQIL',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your profile to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLightColor,
                      ),
                ),
                const SizedBox(height: 32),

                // Role Toggler Segment Control
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isCampusStaff = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isCampusStaff
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _isCampusStaff
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Teachers',
                                style: TextStyle(
                                  fontWeight: _isCampusStaff
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _isCampusStaff
                                      ? AppTheme.textColor
                                      : AppTheme.textLightColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isCampusStaff = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isCampusStaff
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !_isCampusStaff
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontWeight: !_isCampusStaff
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: !_isCampusStaff
                                      ? AppTheme.textColor
                                      : AppTheme.textLightColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // User List
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF0EFEC)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StreamBuilder<List<TeacherRecord>>(
                    stream: _db.getTeachers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No users found. Ensure database is seeded."));
                      }

                      final users = snapshot.data!;
                      final filteredUsers = users.where((u) {
                        if (_isCampusStaff) {
                          return u.role.toLowerCase() != 'principal' && u.role.toLowerCase() != 'admin';
                        } else {
                          return u.role.toLowerCase() == 'principal' || u.role.toLowerCase() == 'admin';
                        }
                      }).toList();

                      if (filteredUsers.isEmpty) {
                        return const Center(child: Text("No users found for this role."));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(user, index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(TeacherRecord user, int index) {
    return InkWell(
      onTap: () async {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        await appState.loginAs(user);
        
        if (!mounted) return;
        
        if (user.role.toLowerCase() == 'principal' || user.role.toLowerCase() == 'admin') {
          context.go('/principal');
        } else {
          context.go('/teacher');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textLightColor, size: 20),
          ],
        ),
      ).animate().fade(delay: (50 * index).ms).slideX(begin: 0.1, end: 0),
    );
  }
}
