import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../controllers/auth_controller.dart';
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

  @override
  void dispose() {
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
          theme: AppTheme.light(),
          routerConfig: _router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(auth.textScale)),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
