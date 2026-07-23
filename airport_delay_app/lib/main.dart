// ============================================================
//  main.dart
//  App entry point.
//  - Sets up the Provider tree (AlertProvider)
//  - Applies AppTheme.light()
//  - Lands on ShellScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/alert_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for the airline ground-staff form factor
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Optional: style the Android status bar to match the app background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AeroDelayApp());
}

class AeroDelayApp extends StatefulWidget {
  const AeroDelayApp({super.key});

  @override
  State<AeroDelayApp> createState() => _AeroDelayAppState();
}

class _AeroDelayAppState extends State<AeroDelayApp> {
  final _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    _authProvider.checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
      ],
      child: MaterialApp(
        title: 'AeroDelay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.state == AuthState.initial) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (auth.state == AuthState.authenticated) {
              return const ShellScreen();
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
