import 'dart:async';

import 'package:flutter/foundation.dart';

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

  // Demo settings toggles (documentation section 12: "Settings").
  bool rememberMe = true;
  bool pushNotifications = true;
  bool emailAlerts = true;
  bool attendanceReminders = true;
  bool biometricLock = false;
  bool twoFactor = false;
  String language = 'English';
  double textScale = 1.0;

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
  Future<String?> login(String email, String password) async {
    final api = _api;
    if (api == null) return 'API mode is disabled';
    try {
      final user = await api.login(email.trim(), password);
      role = roleOf(user);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (e.isRateLimited) return 'Too many attempts. Please wait a minute and try again.';
      return e.message;
    }
  }

  /// Reads the saved token and refreshes the user. Returns true when a valid
  /// session was restored (role is set).
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
  }

  void signIn(UserRole r) {
    role = r;
    notifyListeners();
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

  void update(void Function() change) {
    change();
    notifyListeners();
  }
}
