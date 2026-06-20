import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/models/app_user.dart';
import '../core/models/remembered_account.dart';
import '../core/repositories/user_repository.dart';
import '../core/services/auth_service.dart';
import '../modules/teachers/models/teacher.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider({
    AuthService? authService,
    UserRepository? userRepository,
    FlutterSecureStorage? secureStorage,
  })  : _authService = authService ?? AuthService(),
        _userRepository = userRepository ?? UserRepository(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _authSub = _authService.authStateChanges.listen((user) {
      if (user == null && _currentUser != null) {
        _appUser = null;
        _currentUser = null;
        notifyListeners();
      }
    });
    initializeSession();
  }

  static const String _rememberedAccountsKey = 'remembered_accounts_v1';

  final AuthService _authService;
  final UserRepository _userRepository;
  final FlutterSecureStorage _secureStorage;
  StreamSubscription<User?>? _authSub;

  AppUser? _appUser;
  TeacherRecord? _currentUser;
  List<RememberedAccount> _rememberedAccounts = const [];
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _sessionMessage;

  AppUser? get appUser => _appUser;
  TeacherRecord? get currentUser => _currentUser;
  List<RememberedAccount> get rememberedAccounts => List.unmodifiable(_rememberedAccounts);
  bool get isLoading => _isLoading;
  bool get isLoggingOut => _isLoggingOut;
  bool get isAuthenticated => _currentUser != null;
  String? get sessionMessage => _sessionMessage;

  Future<void> initializeSession() async {
    _setLoading(true);
    try {
      _rememberedAccounts = await _loadRememberedAccounts();
      final firebaseUser = _authService.currentFirebaseUser;
      if (firebaseUser == null) {
        _clearSessionOnly();
        return;
      }

      await _authService.reloadCurrentUser();
      final refreshedUser = _authService.currentFirebaseUser;
      if (refreshedUser == null) {
        _clearSessionOnly(message: 'Your session has expired. Please sign in again.');
        return;
      }

      final appUser = await _userRepository.ensureUserForFirebase(refreshedUser);
      final validationError = _userRepository.validateUserForLogin(appUser);
      if (validationError != null) {
        await _authService.signOut();
        _clearSessionOnly(message: validationError);
        return;
      }

      _appUser = appUser;
      _currentUser = await _userRepository.getDashboardUser(appUser!);
    } on FirebaseAuthException catch (e, stack) {
      debugPrint('Session restore failed: ${e.code}');
      debugPrint('$stack');
      await _authService.signOut();
      _clearSessionOnly(message: 'Your session has expired. Please sign in again.');
    } catch (e, stack) {
      debugPrint('Session restore failed: $e');
      debugPrint('$stack');
      _clearSessionOnly(message: 'Unable to restore your session. Please sign in again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    _setLoading(true);
    _sessionMessage = null;
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _authService.signIn(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        await _authService.signOut();
        return 'Unable to sign in. Please try again.';
      }

      final appUser = await _userRepository.ensureUserForFirebase(firebaseUser);
      final validationError = _userRepository.validateUserForLogin(appUser);
      if (validationError != null) {
        await _authService.signOut();
        return validationError;
      }

      _appUser = appUser;
      _currentUser = await _userRepository.getDashboardUser(appUser!);
      await _userRepository.updateLastLogin(appUser.uid);

      if (rememberMe) {
        await rememberAccount(appUser, password: password);
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e, stack) {
      debugPrint('Login failed: ${e.code}');
      debugPrint('$stack');
      return _authService.friendlyAuthError(e);
    } catch (e, stack) {
      debugPrint('Login failed: $e');
      debugPrint('$stack');
      return 'Unable to sign in. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> sendPasswordReset(String email, {bool notifyLoading = true}) async {
    if (notifyLoading) _setLoading(true);
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final account = await _userRepository.getUserByEmail(normalizedEmail);
      if (account == null) return 'Email address not found.';

      await _authService.sendPasswordResetEmail(normalizedEmail);
      return null;
    } on FirebaseAuthException catch (e, stack) {
      debugPrint('Password reset failed: ${e.code}');
      debugPrint('$stack');
      if (e.code == 'network-request-failed') {
        return 'Unable to send reset email. Check connection.';
      }
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        return 'Email address not found.';
      }
      return 'Unable to send reset email. Check connection.';
    } catch (e, stack) {
      debugPrint('Password reset failed: $e');
      debugPrint('$stack');
      return 'Unable to send reset email. Check connection.';
    } finally {
      if (notifyLoading) _setLoading(false);
    }
  }

  Future<void> rememberAccount(AppUser user, {String? password}) async {
    // Persist account metadata. If the AppUser is missing an email or
    // display name, try to resolve them from the repository so the
    // remembered list shows a sensible label.
    var resolvedEmail = user.email.trim();
    var resolvedName = user.fullName.trim();
    if (resolvedEmail.isEmpty) {
      try {
        final lookup = await _userRepository.getEmailForUid(user.uid);
        if (lookup != null && lookup.trim().isNotEmpty) resolvedEmail = lookup.trim();
      } catch (_) {}
    }
    if (resolvedName.isEmpty && resolvedEmail.isNotEmpty) {
      // Use local-part of email as display name when no full name available.
      resolvedName = resolvedEmail.contains('@') ? resolvedEmail.split('@').first : resolvedEmail;
    }

    final remembered = RememberedAccount(
      uid: user.uid,
      displayName: resolvedName,
      email: resolvedEmail,
      profileImageUrl: user.profileImage,
      role: user.role,
    );
    final next = [
      remembered,
      ..._rememberedAccounts.where((account) => account.uid != user.uid),
    ];
    _rememberedAccounts = next;
    await _saveRememberedAccounts(next);
    // Persist password securely (only when provided)
    if (password != null && password.isNotEmpty) {
      await _secureStorage.write(key: 'remembered_account_password_${user.uid}', value: password);
    }
    notifyListeners();
  }

  Future<void> removeRememberedAccount(String uid) async {
    _rememberedAccounts = _rememberedAccounts.where((account) => account.uid != uid).toList();
    await _saveRememberedAccounts(_rememberedAccounts);
    try {
      await _secureStorage.delete(key: 'remembered_account_password_$uid');
    } catch (_) {}
    notifyListeners();
  }

  /// Attempts to sign in using a stored password for the given remembered account.
  /// Returns null on success or an error message on failure.
  Future<String?> quickLogin(RememberedAccount account) async {
    _setLoading(true);
    try {
      final firebaseUser = _authService.currentFirebaseUser;
      if (firebaseUser != null && firebaseUser.uid == account.uid) {
        await _authService.reloadCurrentUser();
        final refreshedUser = _authService.currentFirebaseUser;
        if (refreshedUser == null || refreshedUser.uid != account.uid) {
          return 'Saved session expired. Sign in once with Remember Me enabled.';
        }

        final appUser = await _userRepository.ensureUserForFirebase(refreshedUser);
        final validationError = _userRepository.validateUserForLogin(appUser);
        if (validationError != null) {
          await _authService.signOut();
          return validationError;
        }

        _appUser = appUser;
        _currentUser = await _userRepository.getDashboardUser(appUser!);
        await _userRepository.updateLastLogin(appUser.uid);
        await rememberAccount(appUser);
        notifyListeners();
        return null;
      }
    } on FirebaseAuthException catch (e, stack) {
      debugPrint('Quick login session restore failed: ${e.code}');
      debugPrint('$stack');
      await _authService.signOut();
    } catch (e, stack) {
      debugPrint('Quick login session restore failed: $e');
      debugPrint('$stack');
    } finally {
      _setLoading(false);
    }

    // Validate saved email before attempting sign-in. If invalid, try to
    // resolve a current email for the UID from Firestore (teachers/users).
    var email = account.email.trim();
    final emailReg = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (email.isEmpty || !emailReg.hasMatch(email)) {
      try {
        final resolved = await _userRepository.getEmailForUid(account.uid);
        if (resolved != null && emailReg.hasMatch(resolved.trim())) {
          email = resolved.trim();
        } else {
          return 'Saved account has an invalid email address. Sign in manually.';
        }
      } catch (_) {
        return 'Saved account has an invalid email address. Sign in manually.';
      }
    }

    final stored = await _secureStorage.read(key: 'remembered_account_password_${account.uid}');
    if (stored == null || stored.isEmpty) {
      return 'Quick login is not available for ${account.username}. Sign in once with Remember Me enabled.';
    }
    return await login(email: email, password: stored, rememberMe: true);
  }

  Future<bool> hasStoredPassword(String uid) async {
    final stored = await _secureStorage.read(key: 'remembered_account_password_$uid');
    return stored != null && stored.isNotEmpty;
  }

  Future<void> logout() async {
    _isLoggingOut = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } catch (e, stack) {
      debugPrint('Logout failed: $e');
      debugPrint('$stack');
    } finally {
      _clearSessionOnly();
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  void updateCurrentUser(TeacherRecord teacher) {
    _currentUser = teacher;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (_appUser == null) return;
    _currentUser = await _userRepository.getDashboardUser(_appUser!);
    notifyListeners();
  }

  String homeRouteForCurrentUser() {
    String rawRole = '';
    if (_appUser != null && _appUser!.role.toString().trim().isNotEmpty) {
      rawRole = _appUser!.role;
    } else if (_currentUser != null && _currentUser!.role.toString().trim().isNotEmpty) {
      rawRole = _currentUser!.role;
    }
    final role = rawRole.toString().trim().toLowerCase();
    try {
      debugPrint('homeRouteForCurrentUser: _appUser.role=${_appUser?.role} _currentUser.role=${_currentUser?.role} chosenRaw="$rawRole" normalized=$role');
    } catch (_) {}
    if (role == 'admin' || role == 'principal') return '/principal';
    return '/teacher';
  }

  void consumeSessionMessage() {
    _sessionMessage = null;
  }

  Future<List<RememberedAccount>> _loadRememberedAccounts() async {
    final raw = await _secureStorage.read(key: _rememberedAccountsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => RememberedAccount.fromJson(Map<String, dynamic>.from(item)))
        .where((account) => account.uid.isNotEmpty && account.email.isNotEmpty)
        .toList();
  }

  Future<void> _saveRememberedAccounts(List<RememberedAccount> accounts) {
    return _secureStorage.write(
      key: _rememberedAccountsKey,
      value: jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }

  void _clearSessionOnly({String? message}) {
    _appUser = null;
    _currentUser = null;
    _sessionMessage = message;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
