# OfficeHub – Test Report & Error Log

**Tested:** 2026-11-17 · **Fixed:** 2026-11-17 · working tree on `main` (uncommitted)

## Summary

| # | Issue | Severity | Status |
|---|---|---|---|
| 1 | Failed saves still show "Success" | 🔴 High | ✅ Fixed |
| 2 | Going offline at app start logs the user out | 🔴 High | ✅ Fixed |
| 3 | Location verification was fake | 🔴 High | ✅ Fixed (app sends GPS, API enforces geofence) |
| 4 | Employee passwords shown in plain text in lists | 🔴 High | ✅ Fixed |
| 5 | Check-in possible again after check-out | 🟠 Medium | ✅ Fixed |
| 6 | Same leave / WFH could be applied twice | 🟠 Medium | ✅ Fixed |
| 7 | App ignored the phone's system font size | 🟠 Medium | ✅ Fixed |
| 8 | Layout overflows on small phones / large text | 🟠 Medium | ✅ Fixed |
| 9 | Settings not saved; fake security toggles | 🟠 Medium | ✅ Fixed |
| 10 | Change-password sheet could spin forever | 🟡 Low | ✅ Fixed |
| 11 | Non-API errors treated as success | 🟡 Low | ✅ Fixed |
| 12 | Stale cached data right after a write | 🟡 Low | ✅ Fixed |
| 13 | Load from previous session could leak into next login | 🟡 Low | ✅ Fixed |
| 14 | Demo mode accepted any password, no hint | 🟡 Low | ✅ Fixed |
| 15 | Placeholder metadata ("A new Flutter project.") | 🟡 Low | ✅ Fixed (app name still needs a decision) |
| 16 | Fake "Support Team" reply in helpdesk (real API too) | 🟡 Low | ✅ Fixed (found while fixing) |
| 17 | Admin Settings page is not saved | 🟡 Low | ✅ Fixed (saved via `/admin/settings`) |
| 18 | Language selector does nothing | 🟡 Low | ⏳ Open |
| B1 | API never checked the punch location | 🔴 High | ✅ Fixed (backend) |
| B2 | Temporary staff passwords stored in plain text | 🔴 High | ✅ Fixed (backend) |
| B3 | Temporary passwords copied into the audit log | 🔴 High | ✅ Fixed (backend) |
| B4 | New branch always failed (working hours sent as timezone) | 🟠 Medium | ✅ Fixed (app) |
| B5 | Branch address allowed 500 chars, column holds 255 | 🟡 Low | ✅ Fixed (backend) |
| B6 | Setting `false` saved as empty string | 🟡 Low | ✅ Fixed (backend) |
| B7 | Team "today" board used server date, not branch timezone | 🟡 Low | ✅ Fixed (backend) |
| B8 | Break duration saved as a fraction | 🟡 Low | ✅ Fixed (backend) |
| B9 | Password reset left the temporary password visible | 🟡 Low | ✅ Fixed (backend) |

---

## How it was tested

- `dart analyze lib test` – no issues. `flutter test` – all pass.
- Automated user journeys (headless, mock data): log in as **Employee, Manager, HR**, open every menu page
  at **320px, 390px and 1366px** width with **Large** text → **no crashes, no layout overflows**.
- Flow checks with a fake server that rejects writes: check-in, leave, add department → all rolled back
  and an error was shown; check-in twice / after check-out refused; same-day leave twice refused;
  settings survive an app restart; wrong demo password rejected.
- **Not verified:** live API calls (production API not touched), real GPS on a device, and the Android
  build – `flutter build apk` fails on this PC before compiling with
  `java.io.IOException: Unable to establish loopback connection` (Gradle/Java environment issue,
  unrelated to the code). Please run on your phone to confirm.

---

## What was changed

### 1. Failed saves now roll back and show the server's error
- `api_app_repository.dart` `_run` now **throws** `RepoWriteException` (new, in `app_repository.dart`)
  instead of swallowing errors.
- `AppController._persist()` wraps every write: on failure it undoes the local change (incl. the audit-log
  entry), and sends the message to `AppController.writeErrors`.
- `app.dart` listens to `writeErrors` and shows a red snackbar on any screen.
- `checkIn / checkOut / startBreak / endBreak / submitLeave / submitWfh / submitRegularization /
  reviewApproval / toggleEmployeeActive` now return `bool`; screens show "success" only when it's `true`.

### 2. Offline launch keeps you logged in
- `OfficeApi.restoreSession()` clears the token **only on 401/403**; network errors are rethrown.
- Splash screen shows *"Cannot reach the server…"* with a **Retry** button instead of logging out.

### 3. Real GPS location for check-in / check-out
- Added `geolocator`. The location dialog now asks for permission, reads a real GPS fix, rejects
  mock-location apps, and offers **Try again / Open settings** on failure.
- Latitude, longitude and accuracy are sent to `POST /attendance/check-in` and `/check-out`
  (`latitude`, `longitude`, `accuracy_meters`).
- Android `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` and iOS
  `NSLocationWhenInUseUsageDescription` added.
- The simulated **QR scan** is hidden in API mode (it would bypass location); still available in the demo build.
- ⚠️ **Backend must check the coordinates against the branch geofence.** The app only sends them.
- Demo build (`USE_API=false`) skips GPS so it still works on web/desktop.

### 4. Passwords hidden
- Removed from the Employees table and mobile cards.
- Employee detail page: visible to **HR only**, masked (`••••••••`) until tapped.

### 5. Check-in guarded
- `checkIn` does nothing unless state is *Not checked in*; a "punch in progress" flag also blocks double taps.

### 6. Overlap check
- `AppController.overlappingLeave()` / `overlappingWfh()`; the apply screens show
  *"You already have a … request for these dates."*

### 7. System font size respected
- `app.dart` multiplies the phone's accessibility scale by the in-app Small/Normal/Large setting (capped at 2×).

### 8. Layout fixes
- `work_status_panel.dart` header, `onboarding_screen.dart` (scrollable, smaller art on short screens),
  login "Remember me / Forgot password" row, `month_calendar.dart` day cells, helpdesk ticket header,
  leave balance card, admin settings section titles.

### 9. Settings saved on the device
- Added `shared_preferences`. Saved: onboarding seen, Remember me, notification switches, language, text size.
- **Remember me** unchecked → the token is kept in memory only, so the next launch asks for the password.
- Removed the **Biometric lock** and **Two-factor** switches (they did nothing).
- About tile no longer says "static demo data" in API mode.

### 10–13. Smaller fixes
- Change password: any error resets the button and shows a message.
- Unknown (non-API) save errors now produce *"Something went wrong while saving."*.
- GET cache uses a generation counter: reads that started before/during a write are not cached.
- `AppController.reset()` clears the in-flight load; results from a signed-out session are discarded.

### 14. Demo login
- Demo build checks the password (`Demo@123`) and lists the demo accounts under the Sign-in button
  (hidden in API mode).

### 15. Metadata
- `pubspec.yaml` description, web `<title>`, web manifest name/description → "OfficeHub".
- The "broken characters" (`â€”`) seen earlier were only PowerShell's display – the files are fine.

---

## Backend fixes (`C:\laragon\www\office-management-api`)

Tested with `php artisan test` – **15 passed** (13 new feature tests). Pint clean.

### B1. Geofence enforced on check-in / check-out
- New migration `2026_11_17_123415_add_geofence_to_branches_table` – `branches.latitude`,
  `longitude`, `geofence_radius_meters`.
- New `app/Services/GeofenceService.php` (haversine distance). `AttendanceService::checkIn/checkOut`
  call it first; outside the fence → **422** e.g. *"You are 1001 m from Kolkata HQ. You must be within
  100 m of the office…"*. Missing location → 422.
- GPS accuracy adds at most **50 m** of slack (a phone claiming ±5 km can't bypass it).
- Only branches **with coordinates** are fenced. Radius = branch radius → setting
  `attendance.geofence_radius_meters` → 100 m. Switch off with setting
  `attendance.geofence_enforced = false`.
- `BranchController` store/update accept `latitude`, `longitude`, `geofence_radius_meters`.
- App: **Branches** screen now has *Set / Edit location* (with *Use my current location*) and shows each
  branch's geofence status. **Admin Settings** loads/saves `/admin/settings` (enforce on/off, default
  radius, company info, grace, leave/notification options); unimplemented 2FA / session-timeout /
  selfie / auto-checkout / QR toggles were removed.

### B2–B3. Temporary passwords protected
- `Staff` model: `initial_password` cast as **`encrypted`** and added to `$hidden`, so it no longer
  appears in `toArray()` → no longer written to `audit_logs` on staff create / update.
- New migration `2026_11_17_123417_encrypt_staff_initial_password` turns the column into `TEXT` and
  encrypts existing values in place (`down()` reverses it).
- `StaffResource` still returns it to admins only (unchanged behaviour for the app).

### B4–B9. Smaller fixes
- App no longer sends free-text working hours as the branch `timezone` (the API rejected every new branch).
- Branch `address` validation `max:500` → `max:255` (matches the column).
- Settings: booleans stored as `"true"`/`"false"` (`false` used to become `""`).
- `GET /attendance/team/today` uses the viewer's branch timezone like check-in does.
- `endBreak` stores `duration_minutes` as an integer.
- `POST /auth/reset-password` clears `initial_password` (change-password already did).

### ⚠️ Before this works on a server
```
php artisan migrate
```
Run it locally (it failed here: MySQL refused `root` without a password / not running) and on the
production server, then deploy the code. Then open **Branches → Set location** for each office.
**Until a branch has coordinates, its staff can still check in from anywhere.**

---

## Still open

- **App name is inconsistent:** Android launcher = *"HRM Matainja"*, iOS = *"Office Management"*,
  inside the app = *"OfficeHub"*. Pick one and I'll apply it everywhere.
- **#18 Language** (Hindi / Bengali) is saved but the app has no translations yet.
- **HR Admin vs Super Admin:** the app treats both as "HR", but `/admin/settings` and
  `/admin/audit-logs` are Super Admin only – HR Admins see a "Only a Super Admin can view…" message
  on Settings and an empty audit log.
- **Forgotten check-out:** `checkOut` closes the *latest* open session even if it is from a previous
  day (needed for overnight shifts), so a missed check-out yesterday is closed today with a very long
  day. Needs a policy decision (auto-close at shift end vs. correction request).
- Admin settings other than the two geofence keys (grace, carry-forward, digests) are stored but not
  yet used by the API.
- Known API gaps from `AGENTS.md` (payslips, document upload, unpublish announcement) are unchanged.
