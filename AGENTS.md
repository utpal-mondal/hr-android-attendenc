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

## Super Admin web panel (backend)

- Blade panel inside the Laravel backend at `/admin` (session login, Super
  Admin only; plain CSS in `public/admin-assets/admin.css`, no build step).
  Code: `app/Http/Controllers/Admin/*`, `resources/views/admin/*`,
  `routes/web.php`, tests in `tests/Feature/AdminPanelTest.php`.
- Approvals delegate to the API controllers, so they follow the same rules.
- WFH weekdays are editable there; if changed, update `AppController.wfhWeekday`.

## Attendance & WFH

- Every Wednesday is WFH for everyone, as is any day covered by an approved
  WFH request. On those days the API skips the branch geofence and stores
  status `wfh` (backend setting `attendance.wfh_weekdays`, default `3`; the
  app's `AppController.wfhWeekday` must match).
- GPS is still captured on every punch. Attendance rows carry
  `check_in_location` / `check_out_location` (with distance from the office),
  shown on the attendance board, attendance details and the employee profile's
  Attendance tab (`features/attendance/punch_location_view.dart`).

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
- Release builds are HTTPS-only (`usesCleartextTraffic="false"` in the main
  AndroidManifest). Plain HTTP for the local dev server is enabled only in
  `android/app/src/debug/AndroidManifest.xml`.

## Play Store release

- Bump `version:` in `pubspec.yaml` (the `+N` build number must be higher than
  the last upload), then `flutter build appbundle --release` and upload
  `build/app/outputs/bundle/release/app-release.aab`.
- Signed with the upload key from `android/key.properties` (git-ignored).
- Launcher icon: adaptive vector in `res/drawable/ic_launcher_foreground.xml`
  + PNGs; Play listing icon in `store/play_store_icon_512.png`.
- Payslips and QR scan are demo-only and hidden in the live app
  (`NavConfig.demoOnlyPaths`, employee home quick actions).
