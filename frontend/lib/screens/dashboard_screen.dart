// ============================================================
//  dashboard_screen.dart
//  Scrollable list of all active (non-archived) delay alerts.
//  Pull-to-refresh supported. FAB opens FormScreen to log a
//  new alert.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/alert_card.dart';
import 'detail_screen.dart';
import 'form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SeverityLevel? _filterSeverity;

  Future<void> _refresh() =>
      context.read<AlertProvider>().loadAlerts();

  void _openDetail(FlightDelayAlert alert) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(alert: alert)),
    );
  }

  void _openForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();
    final auth = context.watch<AuthProvider>();
    final allAlerts = provider.alerts;

    // Apply optional severity filter
    final displayAlerts = _filterSeverity == null
        ? allAlerts
        : allAlerts
            .where((a) => a.severityLevel == _filterSeverity)
            .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Alerts',
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${allAlerts.length} alert${allAlerts.length != 1 ? 's' : ''} on record',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            // ── Severity filter chips ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterSeverity == null,
                      onTap: () =>
                          setState(() => _filterSeverity = null),
                    ),
                    const SizedBox(width: 8),
                    ...SeverityLevel.values.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: s.label,
                          isSelected: _filterSeverity == s,
                          onTap: () =>
                              setState(() => _filterSeverity = s),
                          severity: s,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── List ─────────────────────────────────────────
            Expanded(
              child: _buildBody(provider, displayAlerts),
            ),
          ],
        ),
      ),
      floatingActionButton: auth.isAdmin
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90.0), // Lift above floating bottom nav
              child: FloatingActionButton(
                onPressed: _openForm,
                tooltip: 'Log New Delay',
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(
    AlertProvider provider,
    List<FlightDelayAlert> alerts,
  ) {
    if (provider.isLoading && alerts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.state == ProviderState.error && alerts.isEmpty) {
      return _ErrorState(
        message: provider.errorMessage ?? 'Unknown error',
        onRetry: _refresh,
      );
    }

    if (alerts.isEmpty) {
      return _EmptyState(onAdd: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FormScreen()),
        );
      });
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: alerts.length,
        itemBuilder: (_, i) => AlertCard(
          alert: alerts[i],
          onTap: () => _openDetail(alerts[i]),
        ),
      ),
    );
  }
}

// ─── Filter chip ──────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final SeverityLevel? severity;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.severity,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (isSelected) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else {
      bg = AppColors.inputFill;
      fg = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flight_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'All Clear',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No active delay alerts at this time.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Log a Delay'),
          ),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
