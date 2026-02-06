import 'package:flutter/material.dart';

import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/messages_screen.dart';
import '../ui/screens/providers_screen.dart';
import '../ui/screens/settings_screen.dart';
import 'app_state_scope.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProvidersScreen(),
    MessagesScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    'FidelTele',
    'Providers',
    'Messages',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 16,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            height: 80,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined, size: 26),
                selectedIcon: Icon(Icons.dashboard_rounded, size: 26),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.public_outlined, size: 26),
                selectedIcon: Icon(Icons.public_rounded, size: 26),
                label: 'Providers',
              ),
              NavigationDestination(
                icon: Icon(Icons.sms_outlined, size: 26),
                selectedIcon: Icon(Icons.sms_rounded, size: 26),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined, size: 26),
                selectedIcon: Icon(Icons.settings_rounded, size: 26),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
