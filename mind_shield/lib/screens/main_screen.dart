import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'check_in_screen.dart';
import 'analytics_screen.dart';
import 'support_screen.dart';
import '../services/mind_shield_api.dart';
import '../theme/colors.dart';
import '../theme/design_tokens.dart';

class MainScreen extends StatefulWidget {
  final MindShieldApi api;
  final VoidCallback onLogout;

  const MainScreen({super.key, required this.api, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _homeRefreshCounter = 0;

  void _onCheckInComplete() {
    setState(() {
      _currentIndex = 0; // Go back to Home
      _homeRefreshCounter++;
    });
    // In a real app, this would also show a snackbar or popup confirmation
    final message = widget.api.pendingCheckinsCount > 0
        ? 'CHECK-IN QUEUED IN THIS SESSION. RECONNECT BEFORE CLOSING THE APP.'
        : 'CHECK-IN SUBMITTED SUCCESSFULLY';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmLogout() async {
    if (widget.api.pendingCheckinsCount == 0) { widget.onLogout(); return; }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsent check-in'),
        content: const Text('This check-in has not reached the server. Signing out will clear the temporary session queue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay signed in')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard and sign out')),
        ],
      ),
    );
    if (discard == true) widget.onLogout();
  }

  List<Widget> get _screens => [
    HomeScreen(key: ValueKey(_homeRefreshCounter), api: widget.api),
    CheckInScreen(api: widget.api, onComplete: _onCheckInComplete),
    AnalyticsScreen(api: widget.api),
    SupportScreen(api: widget.api),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.small,
              ),
              child: Image.asset('assets/mind_shield_logo.png'),
            ),
            const SizedBox(width: 10),
            const Text('MIND SHIELD'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECFF),
                borderRadius: AppRadii.pill,
              ),
              child: const Center(
                child: Text(
                  'PRIVACY',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.page),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'HOME',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'CHECK-IN',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'ANALYTICS',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'SUPPORT',
          ),
        ],
      ),
    );
  }
}
