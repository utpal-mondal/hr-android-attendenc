import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_config.dart';
import '../data/api/office_api_client.dart';
import '../models/enums.dart';

/// Session + local preference state.
///
/// Two modes:
/// * **API mode** (`ApiConfig.useApi`): [login]/[restoreSession]/[signOut] talk
///   to the Laravel backend via [OfficeApi]; the role is derived from the
///   roles returned by the server.
/// * **Demo mode**: [roleForEmail]/[signIn] behave as before with mock data.
class AuthController extends ChangeNotifier {
  AuthController({OfficeApi? api}) : _api = api;

  final OfficeApi? _api;

  /// The API client when in API mode (for screens that need it, e.g. forgot
  /// password). Null in demo mode.
  OfficeApi? get api => _api;

  /// True when the app is backed by the real API rather than mock data.
  bool get isApiMode => _api != null;

  /// The authenticated API user (name, email, roles, permissions, staff).
  AppUser? get user => _api?.currentUser;

  UserRole? role;
  bool onboardingSeen = false;

  // User preferences, saved on the device (see [loadPreferences]).
  bool rememberMe = true;
  bool pushNotifications = true;
  bool emailAlerts = true;
  bool attendanceReminders = true;
  String language = 'English';
  double textScale = 1.0;

  static const _kOnboarding = 'pref.onboardingSeen';
  static const _kRemember = 'pref.rememberMe';
  static const _kPush = 'pref.pushNotifications';
  static const _kEmail = 'pref.emailAlerts';
  static const _kReminders = 'pref.attendanceReminders';
  static const _kLanguage = 'pref.language';
  static const _kTextScale = 'pref.textScale';

  Future<void>? _prefsLoad;

  /// Reads saved preferences (once; later calls return the same future).
  /// Missing or unreadable storage simply keeps the defaults.
  Future<void> loadPreferences() => _prefsLoad ??= _loadPreferences();

  Future<void> _loadPreferences() async {
    try {
      final p = await SharedPreferences.getInstance();
      onboardingSeen = p.getBool(_kOnboarding) ?? onboardingSeen;
      rememberMe = p.getBool(_kRemember) ?? rememberMe;
      pushNotifications = p.getBool(_kPush) ?? pushNotifications;
      emailAlerts = p.getBool(_kEmail) ?? emailAlerts;
      attendanceReminders = p.getBool(_kReminders) ?? attendanceReminders;
      language = p.getString(_kLanguage) ?? language;
      textScale = p.getDouble(_kTextScale) ?? textScale;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthController.loadPreferences failed: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kOnboarding, onboardingSeen);
      await p.setBool(_kRemember, rememberMe);
      await p.setBool(_kPush, pushNotifications);
      await p.setBool(_kEmail, emailAlerts);
      await p.setBool(_kReminders, attendanceReminders);
      await p.setString(_kLanguage, language);
      await p.setDouble(_kTextScale, textScale);
    } catch (e) {
      debugPrint('AuthController.savePreferences failed: $e');
    }
  }

  bool get isLoggedIn => role != null;

  static const demoPassword = 'Demo@123';

  /// Seed account for each demo tile (API mode). Password is `password`.
  String seedEmailFor(UserRole r) => switch (r) {
        UserRole.employee => ApiConfig.seedAccounts['employee']!,
        UserRole.manager => ApiConfig.seedAccounts['manager']!,
        UserRole.hr => ApiConfig.seedAccounts['hr']!,
      };

  /// Maps the server's role names onto the app's three shells.
  static UserRole roleOf(AppUser user) {
    if (user.isAdmin) return UserRole.hr;
    if (user.isManager) return UserRole.manager;
    return UserRole.employee;
  }

  /// Returns the role for a demo email, or null when the account is unknown.
  UserRole? roleForEmail(String email) {
    final e = email.trim().toLowerCase();
    for (final r in UserRole.values) {
      if (r.demoEmail == e) return r;
    }
    return null;
  }

  // ── API-mode authentication ────────────────────────────────────────────────

  /// API-mode login. Returns `null` on success (role already set) or an error
  /// message to show the user.
  Future<String?> login(String email, String password, {bool remember = true}) async {
    final api = _api;
    if (api == null) return 'API mode is disabled';
    try {
      final user = await api.login(email.trim(), password);
      rememberMe = remember;
      unawaited(_savePreferences());
      // Without "Remember me" the token lives in memory only, so the next
      // app launch asks for the password again.
      if (!remember) await api.forgetStoredToken();
      role = roleOf(user);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (e.isRateLimited) return 'Too many attempts. Please wait a minute and try again.';
      return e.message;
    }
  }

  /// Reads the saved token and refreshes the user. Returns true when a valid
  /// session was restored (role is set), false when there is none. Throws
  /// [ApiException] when the server can't be reached — the saved session is
  /// kept so the user can retry.
  Future<bool> restoreSession() async {
    final api = _api;
    if (api == null) return false;
    final user = await api.restoreSession();
    if (user == null) return false;
    role = roleOf(user);
    notifyListeners();
    return true;
  }

  void completeOnboarding() {
    onboardingSeen = true;
    notifyListeners();
    unawaited(_savePreferences());
  }

  void signIn(UserRole r, {bool remember = true}) {
    rememberMe = remember;
    role = r;
    notifyListeners();
    unawaited(_savePreferences());
  }

  void signOut() {
    role = null;
    notifyListeners();
    // Best-effort server-side token revocation; the local session is already
    // cleared by OfficeApi.logout even if the request fails.
    unawaited(_api?.logout() ?? Future.value());
  }

  /// Called by the API client when a request returns 401 — the token has
  /// already been cleared locally.
  void handleUnauthorized() {
    if (role == null) return;
    role = null;
    notifyListeners();
  }

  /// Changes preferences and saves them.
  void update(void Function() change) {
    change();
    notifyListeners();
    unawaited(_savePreferences());
  }
}
