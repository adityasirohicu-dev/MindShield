import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/officer_dashboard_screen.dart';
import 'services/mind_shield_api.dart';

void main() {
  runApp(const MindShieldApp());
}

class MindShieldApp extends StatelessWidget {
  const MindShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIND SHIELD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppRoot(),
    );
  }
}

/// Routes the user to the correct screen based on login state & role.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final MindShieldApi _api = MindShieldApi();
  bool _isLoggedIn = false;
  bool _showSignUp = false;
  String _role = 'personnel'; // 'personnel' | 'welfare_officer' | 'counsellor' | 'org_admin'

  void _onLoginSuccess({String role = 'personnel'}) {
    setState(() {
      _isLoggedIn = true;
      _role = role;
    });
  }

  void _onLogout() {
    _api.logout();
    setState(() {
      _isLoggedIn = false;
      _showSignUp = false;
      _role = 'personnel';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      if (_showSignUp) {
        return SignUpScreen(
          api: _api,
          onSignUpSuccess: _onLoginSuccess,
          onSwitchToLogin: () => setState(() => _showSignUp = false),
        );
      }
      return LoginScreen(
        api: _api,
        onLoginSuccess: _onLoginSuccess,
        onSwitchToSignUp: () => setState(() => _showSignUp = true),
      );
    }

    // Officer / counsellor / admin → Officer dashboard
    if (_role == 'welfare_officer' ||
        _role == 'counsellor' ||
        _role == 'org_admin') {
      return OfficerDashboardScreen(api: _api, onLogout: _onLogout);
    }

    // Personnel → Main app
    return MainScreen(api: _api, onLogout: _onLogout);
  }
}

