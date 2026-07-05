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
          backgroundColor: const Color(0xFFF5F5F3),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth >= 900
                    ? 520.0
                    : constraints.maxWidth - 32;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: maxWidth.clamp(320.0, 520.0)),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8E6E1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              offset: const Offset(0, 8),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                              constraints.maxWidth < 420 ? 20 : 32),
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
                                  const SizedBox(height: 18),
                                  OutlinedButton.icon(
                                    onPressed: appState.isLoading
                                        ? null
                                        : () => setState(
                                            () => _showManualForm = true),
                                    icon: const Icon(LucideIcons.userPlus,
                                        size: 18),
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
          TextFormField(
            controller: _emailController,
            enabled: !appState.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
              LengthLimitingTextInputFormatter(254),
            ],
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(LucideIcons.mail),
            ),
            validator: _validateEmail,
            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            enabled: !appState.isLoading,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            inputFormatters: [
              LengthLimitingTextInputFormatter(128),
            ],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(LucideIcons.lock),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: appState.isLoading
                    ? null
                    : () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff),
              ),
            ),
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submitLogin(appState),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: appState.isLoading
                  ? null
                  : () => _showForgotPasswordDialog(appState),
              child: const Text('Forgot Password?'),
            ),
          ),
          CheckboxListTile(
            value: _rememberMe,
            onChanged: appState.isLoading
                ? null
                : (value) => setState(() => _rememberMe = value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Remember Me'),
            subtitle:
                const Text('Save this account for quick login on this device.'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: appState.isLoading ? null : () => _submitLogin(appState),
            icon: appState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.logIn, size: 18),
            label: Text(appState.isLoading ? 'Signing In...' : 'Sign In'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed:
                appState.isLoading ? null : () => context.push('/register'),
            child: const Text('Register as Teacher'),
          ),
          if (appState.rememberedAccounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: appState.isLoading
                  ? null
                  : () => setState(() => _showManualForm = false),
              child: const Text('Back to remembered accounts'),
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
              title: const Text('Reset Password'),
              content: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  enabled: !isSending,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    LengthLimitingTextInputFormatter(254),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(LucideIcons.mail),
                  ),
                  validator: _validateEmail,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false))
                            return;
                          setDialogState(() => isSending = true);
                          final error = await appState.sendPasswordReset(
                            _sanitizeEmail(controller.text),
                            notifyLoading: false,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop(error ?? '');
                        },
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
    if (_dangerousPayload.hasMatch(email))
      return 'Enter a valid email address.';
    if (!_emailRegExp.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password.';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (password.length > 128)
      return 'Password must be 128 characters or fewer.';
    if (password.trim() != password)
      return 'Password cannot start or end with spaces.';
    if (_dangerousPayload.hasMatch(password))
      return 'Password contains unsupported content.';
    return null;
  }

  String _sanitizeEmail(String value) => value.trim().toLowerCase();

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isRestoring});

  final bool isRestoring;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: 'Genius Aqil secure sign in',
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.shieldCheck,
              size: 36,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'GENIUS AQIL',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          isRestoring
              ? 'Restoring secure session...'
              : 'Sign in with your school account',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textLightColor),
        ),
        if (isRestoring) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(minHeight: 3),
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
        Text(
          'Quick Login',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...accounts.map(
          (account) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: const Color(0xFFF9F9F7),
              borderRadius: BorderRadius.circular(8),
              child: ListTile(
                enabled: !isBusy,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.12),
                  backgroundImage: account.profileImageUrl.isEmpty
                      ? null
                      : NetworkImage(account.profileImageUrl),
                  child: account.profileImageUrl.isEmpty
                      ? Text(
                          account.initial,
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Text(
                  account.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${account.email}\n${account.role.toUpperCase()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                onTap: () => onSelect(account),
                trailing: IconButton(
                  tooltip: 'Remove account',
                  onPressed: isBusy ? null : () => onRemove(account.uid),
                  icon: const Icon(LucideIcons.x, size: 18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
