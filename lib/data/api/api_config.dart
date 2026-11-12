/// Compile-time configuration for the real backend.
///
/// The app can run in two modes, switched at build time with `--dart-define`:
///
///   # Real API (default)
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
///
///   # Local mock data (original demo, no backend needed)
///   flutter run --dart-define=USE_API=false
///
/// Where the app should look for `/api/v1`, by run target:
///
///   Android emulator   → http://10.0.2.2:8000/api/v1   (default; 10.0.2.2 is
///                        the emulator's alias for the host's localhost)
///   Windows / web      → http://localhost:8000/api/v1
///   Real phone (LAN)   → `http://<LAN-IP>:8000/api/v1`   with
///                        `php artisan serve --host=0.0.0.0`
///   Laragon Apache     → http://10.0.2.2:8080/office-management-api/public/api/v1
///                        (the `.test` vhost does not resolve in the emulator)
abstract final class ApiConfig {
  /// Whether the app talks to the Laravel API (true) or the bundled mock
  /// repository (false).
  static const bool useApi = bool.fromEnvironment('USE_API', defaultValue: true);

  /// Base URL of the `/api/v1` root, without a trailing slash.
  /// Default: physical device via `adb reverse tcp:8080 tcp:8080` -> Laragon
  /// Apache on :8080. Over Wi-Fi (no USB) use
  /// `--dart-define=API_BASE_URL=http://192.168.1.32:8080/office-management-api/public/api/v1`
  /// (requires inbound :8080 allowed in Windows Firewall).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/office-management-api/public/api/v1',
  );

  /// Seed accounts created by the backend's `DatabaseSeeder` (password
  /// `password`). Used by the login screen's quick-access tiles in API mode.
  static const Map<String, String> seedAccounts = {
    'employee': 'employee@example.com',
    'manager': 'manager@example.com',
    'hr': 'hr@example.com',
    'superadmin': 'admin@example.com',
  };

  static const String seedPassword = 'password';
}
