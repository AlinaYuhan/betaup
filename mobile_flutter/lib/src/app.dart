import 'package:flutter/material.dart';

import 'session/app_session.dart';
import 'theme/app_theme.dart';
import 'ui/auth_screen.dart';
import 'ui/common.dart';
import 'ui/main_shell.dart';

class BetaUpApp extends StatefulWidget {
  const BetaUpApp({super.key});

  @override
  State<BetaUpApp> createState() => _BetaUpAppState();
}

class _BetaUpAppState extends State<BetaUpApp> {
  late final AppSession _session;

  @override
  void initState() {
    super.initState();
    _session = AppSession();
    _session.initialize();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: _session,
      child: MaterialApp(
        title: "BetaUp Mobile",
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: AnimatedBuilder(
          animation: _session,
          builder: (context, _) {
            if (_session.isInitializing) {
              return const SplashScreen();
            }

            if (_session.isAuthenticated && _session.user != null) {
              return const MainShell();
            }

            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
