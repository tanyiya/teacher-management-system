import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../models/remembered_account.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _showManualForm = true;

  static final RegExp _emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _dangerousPayload = RegExp(
    r'(<[^>]*>|javascript:|data:text|[\x00-\x08\x0B\x0C\x0E-\x1F])',
    caseSensitive: false,
  );
  static const Set<String> _weakPasswords = {
    'password',
    'password1',
    'password123',
    '12345678',
    '123456789',
    'qwerty123',
    'admin1234',
    'letmein123',
    'welcome123',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppStateProvider>();
      if (appState.isAuthenticated) {
        context.go(appState.homeRouteForCurrentUser());
      } else {
        final message = appState.sessionMessage;
        if (message != null) {
          _showSnack(message);
          appState.consumeSessionMessage();
        }
        if (appState.rememberedAccounts.isNotEmpty) {
          setState(() => _showManualForm = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        if (appState.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go(appState.homeRouteForCurrentUser());
          });
        }

        return Scaffold(
          backgroundColor: AppTheme.canvasBase,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth >= 900
                    ? 500.0
                    : constraints.maxWidth - 32;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: maxWidth.clamp(320.0, 500.0)),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.subtleGrayBoundary),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.schoolBlue.withValues(alpha: 0.08),
                              offset: const Offset(0, 12),
                              blurRadius: 32,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                              constraints.maxWidth < 420 ? 24 : 36),
                          child: FocusTraversalGroup(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Header(
                                    isRestoring: appState.isLoading &&
                                        !appState.isAuthenticated),
                                if (appState.rememberedAccounts.isNotEmpty &&
                                    !_showManualForm) ...[
                                  const SizedBox(height: 28),
                                  _RememberedAccountsList(
                                    accounts: appState.rememberedAccounts,
                                    isBusy: appState.isLoading,
                                    onSelect: _selectRememberedAccount,
                                    onRemove: (uid) =>
                                        appState.removeRememberedAccount(uid),
                                  ),
                                  const SizedBox(height: 20),
                                  OutlinedButton.icon(
                                    onPressed: appState.isLoading
                                        ? null
                                        : () => setState(
                                            () => _showManualForm = true),
                                    icon: const Icon(LucideIcons.userPlus,
                                        size: 18),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.schoolBlue, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    label: const Text('Use Another Account'),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 28),
                                  _buildLoginForm(appState),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(AppStateProvider appState) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            enabled: !appState.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            style: const TextStyle(color: AppTheme.textCore),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
              LengthLimitingTextInputFormatter(254),
            ],
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(LucideIcons.mail, color: AppTheme.schoolBlue),
            ),
            validator: _validateEmail,
            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 18),
          
          // Password field
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            enabled: !appState.isLoading,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            style: const TextStyle(color: AppTheme.textCore),
            inputFormatters: [
              LengthLimitingTextInputFormatter(128),
            ],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(LucideIcons.lock, color: AppTheme.schoolBlue),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: appState.isLoading
                    ? null
                    : () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ),
            ),
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submitLogin(appState),
          ),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: appState.isLoading
                  ? null
                  : () => _showForgotPasswordDialog(appState),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.schoolOrange,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              child: const Text('Forgot Password?', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 4),

          // Remember Me
          Container(
            decoration: BoxDecoration(
              color: AppTheme.ambientOffWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.subtleGrayBoundary),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: CheckboxListTile(
              value: _rememberMe,
              activeColor: AppTheme.schoolBlue,
              onChanged: appState.isLoading
                  ? null
                  : (value) => setState(() => _rememberMe = value ?? false),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Remember Me', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textCore)),
              subtitle: Text('Save this account for quick login on this device.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted.withValues(alpha: 0.8))),
            ),
          ),
          const SizedBox(height: 24),
          
          // Sign In Button
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: appState.isLoading ? null : () => _submitLogin(appState),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.schoolBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: appState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.logIn, size: 18),
              label: Text(
                appState.isLoading ? 'Signing In...' : 'Sign In',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Register Button
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed:
                  appState.isLoading ? null : () => context.push('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.schoolOrange,
                side: const BorderSide(color: AppTheme.schoolOrange, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Register as Teacher', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          
          if (appState.rememberedAccounts.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: appState.isLoading
                  ? null
                  : () => setState(() => _showManualForm = false),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
              ),
              child: const Text('Back to remembered accounts', 
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitLogin(AppStateProvider appState) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    TextInput.finishAutofillContext();
    final error = await appState.login(
      email: _sanitizeEmail(_emailController.text),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
      return;
    }
    context.go(appState.homeRouteForCurrentUser());
  }

  void _selectRememberedAccount(RememberedAccount account) {
    final appState = context.read<AppStateProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _showManualForm = false;
        _rememberMe = true;
      });

      final error = await appState.quickLogin(account);
      if (!mounted) return;
      if (error != null) {
        _showSnack(error);
        return;
      }

      context.go(appState.homeRouteForCurrentUser());
    });
  }

  Future<void> _showForgotPasswordDialog(AppStateProvider appState) async {
    final controller = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var isSending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Reset Password', 
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.schoolDarkBlue)),
              content: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  enabled: !isSending,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  style: const TextStyle(color: AppTheme.textCore),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    LengthLimitingTextInputFormatter(254),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(LucideIcons.mail, color: AppTheme.schoolBlue),
                  ),
                  validator: _validateEmail,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                FilledButton.icon(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setDialogState(() => isSending = true);
                          final error = await appState.sendPasswordReset(
                            _sanitizeEmail(controller.text),
                            notifyLoading: false,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop(error ?? '');
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.schoolBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.send, size: 18),
                  label: Text(isSending ? 'Sending...' : 'Send Reset Email'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    if (!mounted || result == null) return;
    _showSnack(result.isEmpty ? 'Password reset email sent.' : result);
  }

  String? _validateEmail(String? value) {
    final email = _sanitizeEmail(value ?? '');
    if (email.isEmpty) return 'Enter your email address.';
    if (email.length > 254) return 'Email address is too long.';
    if (_dangerousPayload.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    if (!_emailRegExp.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password.';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (password.length > 128) {
      return 'Password must be 128 characters or fewer.';
    }
    if (password.trim() != password) {
      return 'Password cannot start or end with spaces.';
    }
    if (_dangerousPayload.hasMatch(password)) {
      return 'Password contains unsupported content.';
    }
    return null;
  }

  String _sanitizeEmail(String value) => value.trim().toLowerCase();

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.schoolDarkBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isRestoring});

  final bool isRestoring;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tadika Aqil Miqail logo container ─────────────────────────
        Semantics(
          label: 'Genius Aqil secure sign in',
          child: Container(
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.subtleGrayBoundary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.schoolBlue.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.jpeg',
                fit: BoxFit.cover,
                // Fallback icon if logo image asset is not configured or loaded yet
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.schoolLightBlue,
                    child: const Icon(
                      LucideIcons.bookOpen,
                      size: 40,
                      color: AppTheme.schoolBlue,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // School Name
        Text(
          'GENIUS AQIL',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppTheme.schoolDarkBlue,
              ),
        ),
        const SizedBox(height: 12),
        
        Text(
          isRestoring
              ? 'Restoring secure session...'
              : 'Sign in with your school account',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textLightColor, fontSize: 13),
        ),
        
        if (isRestoring) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: AppTheme.schoolLightBlue,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.schoolBlue),
          ),
        ],
      ],
    );
  }
}

class _RememberedAccountsList extends StatelessWidget {
  const _RememberedAccountsList({
    required this.accounts,
    required this.isBusy,
    required this.onSelect,
    required this.onRemove,
  });

  final List<RememberedAccount> accounts;
  final bool isBusy;
  final ValueChanged<RememberedAccount> onSelect;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quick Login',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.schoolDarkBlue,
          ),
        ),
        const SizedBox(height: 12),
        ...accounts.map(
          (account) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppTheme.ambientOffWhite,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                enabled: !isBusy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.subtleGrayBoundary),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.schoolLightBlue,
                  backgroundImage: account.profileImageUrl.isEmpty
                      ? null
                      : NetworkImage(account.profileImageUrl),
                  child: account.profileImageUrl.isEmpty
                      ? Text(
                          account.initial,
                          style: const TextStyle(
                              color: AppTheme.schoolDarkBlue,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Text(
                  account.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: AppTheme.textCore,
                      fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${account.email}\n${account.role.toUpperCase()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
                isThreeLine: true,
                onTap: () => onSelect(account),
                trailing: IconButton(
                  tooltip: 'Remove account',
                  onPressed: isBusy ? null : () => onRemove(account.uid),
                  icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.textMuted),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
