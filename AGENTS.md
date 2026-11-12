# Office Management (OfficeHub)

Flutter app for the Office Management API (Laravel 13 + Sanctum, `/api/v1`).
API contract details live in `FLUTTER_API_GUIDE.md` (outside this repo).

## Backend modes (compile-time)

| Mode | Command |
|---|---|
| Real API, physical device via USB (default) | `adb reverse tcp:8080 tcp:8080` then `flutter run` (adb reverse resets on reconnect/reboot) |
| Real API, device over Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://192.168.1.32:8080/office-management-api/public/api/v1` (needs inbound :8080 allowed in Windows Firewall) |
| Real API, Android emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` |
| Mock demo | `flutter run --dart-define=USE_API=false` |

- Backend runs under Laragon or `php artisan serve` on port 8000. Laragon
  Apache is on port 8080 (vhost `office-management-api.test` →
  `C:/laragon/www/office-management-api/public`); on the emulator use
  `http://10.0.2.2:8080/office-management-api/public/api/v1` since `.test`
  does not resolve there.
- `10.0.2.2` = host localhost from the Android emulator; use LAN IP for real
  devices (`php artisan serve --host=0.0.0.0`).
- Physical device: `adb reverse tcp:8080 tcp:8080` tunnels the API over USB
  (rerun after disconnect/reboot). Dio logs every request/response in debug
  builds via `LogInterceptor` (`OfficeApi(enableLogging: ...)`). Silence
  graphics logcat spam with
  `adb shell setprop log.tag.BLASTBufferQueue S` (+ `BufferQueueConsumer`,
  `SurfaceView`).
- Seed logins (password `password`): `admin@`, `hr@`, `manager@`,
  `employee@example.com`. Login tiles prefill them in API mode.
- See `lib/data/api/api_config.dart`.

## Architecture

- `lib/data/api/office_api_client.dart` — Dio client, one method per endpoint,
  token in `flutter_secure_storage`, `ApiException`, `PagedResult` (handles the
  API's 4 pagination shapes).
- `lib/data/api/api_mappers.dart` — API JSON -> app domain models (date-only
  fields take `substring(0,10)`; instants use `.toLocal()`).
- `lib/data/api/api_app_repository.dart` — `AppRepository` impl. `load()` fetches
  all lists in parallel (role-gated endpoints are guarded). Write hooks do
  **state-diffing**: the UI mutates local objects, and the repo maps each change
  to the right endpoint (punch in/out/break, submit vs approve/reject, etc.).
- `lib/repositories/app_repository.dart` — contract shared by both backends.
- `lib/controllers/` — Provider state (`AppController` data + business rules,
  `AuthController` session). `UserRole` = employee | manager | hr (server
  "Super Admin" and "HR Admin" both map to `hr`).
- Screens never call the API directly; everything goes through `AppController`.

## Known gaps vs the API

- No payslip endpoint → payslips list is always empty in API mode.
- Document upload needs a file path the UI doesn't collect → `addDocument`
  stays local-only; delete works.
- No "unpublish announcement" endpoint → local toggle only.
- Leave/WFH statuses `withdrawn`/`cancelled` collapse to `rejected` (the app
  enum has only pending/approved/rejected); original text kept in
  `reviewerNote`.

## Verify

- `dart analyze lib` and `flutter test` must stay clean.
- AndroidManifest keeps `INTERNET` + `usesCleartextTraffic` for the HTTP dev
  server — don't remove without switching the app to HTTPS config.
