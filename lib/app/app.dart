import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../data/api/api_app_repository.dart';
import '../data/api/api_config.dart';
import '../data/api/office_api_client.dart';
import '../repositories/app_repository.dart';
import '../repositories/mock_app_repository.dart';
import 'router.dart';

class OfficeHubApp extends StatefulWidget {
  const OfficeHubApp({super.key});

  @override
  State<OfficeHubApp> createState() => _OfficeHubAppState();
}

class _OfficeHubAppState extends State<OfficeHubApp> {
  // Real backend (default) or bundled mock data — see ApiConfig.
  // A 401 on any authenticated request clears the token and routes to login.
  late final OfficeApi? _api = ApiConfig.useApi
      ? OfficeApi(
          baseUrl: ApiConfig.baseUrl,
          onUnauthorized: () => _auth.handleUnauthorized(),
        )
      : null;

  late final AuthController _auth = AuthController(api: _api);
  late final AppRepository _repo =
      _api != null ? ApiAppRepository(_api) : MockAppRepository();
  late final AppController _app = AppController(_repo);
  late final _router = buildRouter(_auth);

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<String>? _writeErrorSub;

  @override
  void initState() {
    super.initState();
    unawaited(_auth.loadPreferences());
    // Any save the server rejected: the controller already rolled the local
    // change back, so tell the user why.
    _writeErrorSub = _app.writeErrors.listen((msg) {
      final m = _messengerKey.currentState;
      if (m == null) return;
      m.hideCurrentSnackBar();
      m.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: AppColors.danger,
      ));
    });
  }

  @override
  void dispose() {
    _writeErrorSub?.cancel();
    _router.dispose();
    _auth.dispose();
    _app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _auth),
        ChangeNotifierProvider<AppController>.value(value: _app),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) => MaterialApp.router(
          title: 'OfficeHub - Office Management & Attendance',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _messengerKey,
          theme: AppTheme.light(),
          routerConfig: _router,
          builder: (context, child) {
            // Apply the in-app text size on top of the phone's accessibility
            // font size instead of replacing it.
            final system = MediaQuery.textScalerOf(context);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: _ScaledTextScaler(system, auth.textScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

/// The system text scaler multiplied by the user's in-app text size, capped
/// so very large system fonts don't break layouts entirely.
class _ScaledTextScaler extends TextScaler {
  const _ScaledTextScaler(this.system, this.factor);
  final TextScaler system;
  final double factor;

  static const double _maxScale = 2.0;

  @override
  double scale(double fontSize) {
    final scaled = system.scale(fontSize) * factor;
    final cap = fontSize * _maxScale;
    return scaled > cap ? cap : scaled;
  }

  // ignore: deprecated_member_use
  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is _ScaledTextScaler && other.system == system && other.factor == factor;

  @override
  int get hashCode => Object.hash(system, factor);
}
