import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/attendance.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Row(children: [
      Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(message)),
    ]),
    backgroundColor: error ? AppColors.danger : AppColors.navy,
  ));
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        AppButton(label: cancelLabel, type: AppButtonType.secondary, compact: true, onPressed: () => Navigator.pop(ctx, false)),
        AppButton(
            label: confirmLabel,
            type: destructive ? AppButtonType.destructive : AppButtonType.primary,
            compact: true,
            onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showSuccessDialog(BuildContext context, {required String title, required String message, String buttonLabel = 'Done'}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha:0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
            ),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          AppButton(label: buttonLabel, expand: true, onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    ),
  );
}

/// Gets the device's real GPS position for a check-in / check-out.
///
/// Returns the fix, or null when the user cancelled or location is
/// unavailable (permission denied, location services off). The server checks
/// the coordinates against the branch geofence and rejects punches outside
/// it. In the demo build (no API) location is not required and a
/// placeholder fix is returned without asking for permission.
///
/// On a work-from-home day ([wfh]) the fix is still recorded so HR can see
/// where the employee worked, but the server does not apply the geofence.
Future<PunchLocation?> runLocationVerification(BuildContext context, {String office = '', bool wfh = false}) async {
  if (!context.read<AuthController>().isApiMode) {
    return const PunchLocation(latitude: 0, longitude: 0, accuracyMeters: 0);
  }
  return showDialog<PunchLocation>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _VerifyDialog(office: office, wfh: wfh),
  );
}

class _VerifyDialog extends StatefulWidget {
  const _VerifyDialog({required this.office, this.wfh = false});
  final String office;
  final bool wfh;

  @override
  State<_VerifyDialog> createState() => _VerifyDialogState();
}

class _VerifyDialogState extends State<_VerifyDialog> {
  String? _error;
  bool _openSettings = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _retry() {
    setState(() {
      _error = null;
      _openSettings = false;
    });
    _run();
  }

  Future<void> _run() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _fail('Location is turned off. Turn on location to check in.', settings: true);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        return _fail(widget.wfh
            ? 'Location permission is needed to record where you are working from.'
            : 'Location permission is needed to verify you are at the office.');
      }
      if (perm == LocationPermission.deniedForever) {
        return _fail('Location permission is blocked. Allow it in the app settings to check in.', settings: true);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      if (pos.isMocked) {
        return _fail('A mock-location app is active. Turn it off to check in.');
      }
      if (!mounted) return;
      Navigator.pop(
        context,
        PunchLocation(latitude: pos.latitude, longitude: pos.longitude, accuracyMeters: pos.accuracy.round()),
      );
    } catch (e) {
      _fail('Could not get your location. Move to an open area and try again.');
    }
  }

  void _fail(String message, {bool settings = false}) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _openSettings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 64,
            height: 64,
            child: error == null
                ? const CircularProgressIndicator(strokeWidth: 4)
                : Container(
                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.location_off, color: AppColors.danger, size: 34),
                  ),
          ),
          const SizedBox(height: 20),
          Text(error == null ? 'Getting your location' : 'Location needed',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            error ??
                (widget.wfh
                    ? 'Work from home day - recording your location...'
                    : widget.office.isEmpty
                        ? 'Checking GPS signal...'
                        : 'Checking GPS signal for ${widget.office}...'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (error != null && _openSettings)
          TextButton(
            onPressed: () async {
              final perm = await Geolocator.checkPermission();
              if (perm == LocationPermission.deniedForever) {
                await Geolocator.openAppSettings();
              } else {
                await Geolocator.openLocationSettings();
              }
            },
            child: const Text('Open settings'),
          ),
        if (error != null) FilledButton(onPressed: _retry, child: const Text('Try again')),
      ],
    );
  }
}

/// Modal sheet with consistent styling.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(top: false, child: builder(ctx)),
    ),
  );
}
