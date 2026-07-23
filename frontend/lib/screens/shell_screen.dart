// ============================================================
//  shell_screen.dart
//  Root scaffold that hosts the two main tabs (Home & Dashboard)
//  with the floating pill-shaped bottom navigation bar.
//  Uses an IndexedStack so both tabs maintain their scroll
//  positions when switching.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/alert_provider.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initial data load — runs once after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().loadAlerts();
    });
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Tab content ──────────────────────────────────
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(onGoToDashboard: () => _switchTab(1)),
              const DashboardScreen(),
            ],
          ),

          // ── Floating bottom nav ──────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(
              currentIndex: _currentIndex,
              onTap: _switchTab,
            ),
          ),
        ],
      ),
    );
  }
}
