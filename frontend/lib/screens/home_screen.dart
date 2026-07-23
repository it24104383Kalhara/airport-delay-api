// ============================================================
//  home_screen.dart
//  Premium home / landing screen for ground staff.
//
//  Structure:
//    1. Full-bleed hero header (aviation photo + gradient overlay
//       + glassmorphism stat card) — all inside one ClipRRect.
//    2. Quick action cards (View All Alerts / Log New Delay).
//    3. Recent Critical alert preview.
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import 'detail_screen.dart';
import 'form_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  /// Callback to switch to the Dashboard tab from the Shell.
  final VoidCallback onGoToDashboard;

  const HomeScreen({super.key, required this.onGoToDashboard});

  // High-res Unsplash aviation photo (commercial aircraft on tarmac)
  static const _heroImageUrl =
      'https://images.unsplash.com/photo-1436491865332-7a61a109cc05'
      '?q=80&w=1200&auto=format&fit=crop';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();
    final auth = context.watch<AuthProvider>();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return RefreshIndicator(
      onRefresh: provider.loadAlerts,
      color: AppColors.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── 1. Hero header ──────────────────────────────────
          _HeroHeader(
            greeting: greeting,
            username: auth.user?.username ?? 'Dispatcher',
            provider: provider,
            heroImageUrl: _heroImageUrl,
          ),

          const SizedBox(height: 28),

          // ── 2. Quick actions ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'QUICK ACTIONS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.dashboard_rounded,
                    label: 'View All\nAlerts',
                    color: AppColors.primary,
                    onTap: onGoToDashboard,
                  ),
                ),
                if (auth.isAdmin) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Log New\nDelay',
                      color: AppColors.moderate,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FormScreen()),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── 3. Recent critical ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT CRITICAL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                ),
                if (!provider.isLoading)
                  TextButton(
                    onPressed: onGoToDashboard,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('See all →'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: provider.isLoading
                ? const _LoadingShimmer()
                : provider.criticalAlerts.isEmpty
                    ? _NoCriticalCard()
                    : Column(
                        children: provider.criticalAlerts
                            .map(
                              (alert) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _RecentAlertCard(
                                  alert: alert,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DetailScreen(
                                        alert: alert,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── 1. Hero Header ───────────────────────────────────────────
/// Full-bleed aviation photo with a multi-stop blue gradient overlay.
/// The glassmorphism stat card floats in the lower portion of the image.
class _HeroHeader extends StatelessWidget {
  final String greeting;
  final String username;
  final AlertProvider provider;
  final String heroImageUrl;

  const _HeroHeader({
    required this.greeting,
    required this.username,
    required this.provider,
    required this.heroImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: SizedBox(
        // Tall enough to hold greeting + card with breathing room
        height: 360,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ──────────────────────────────
            Image.network(
              heroImageUrl,
              fit: BoxFit.cover,
              // Shown while the image loads — solid primary colour
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppColors.primary,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    color: Colors.white30,
                    strokeWidth: 2,
                  ),
                );
              },
              // On error — fall back to a solid gradient container
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.primary],
                  ),
                ),
              ),
            ),

            // ── Dark-blue gradient overlay ────────────────────
            // Three stops: lighter at top (image visible) →
            //              deep blue at bottom (text legible).
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.40, 1.0],
                  colors: [
                    AppColors.primary.withValues(alpha: 0.42),
                    AppColors.primary.withValues(alpha: 0.62),
                    AppColors.primary.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),

            // ── Foreground content ────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting row ──────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                username,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Profile avatar (white ghost style)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.40),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ── Glassmorphism stat card ────────────────
                    _GlassStatCard(
                      activeCount: provider.activeCount,
                      criticalCount: provider.criticalCount,
                      isLoading: provider.isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 1b. Glassmorphism Stat Card ─────────────────────────────
/// Floats inside the hero image via BackdropFilter blur.
/// Shows the active delay count with a frosted-glass surface.
class _GlassStatCard extends StatelessWidget {
  final int activeCount;
  final int criticalCount;
  final bool isLoading;

  const _GlassStatCard({
    required this.activeCount,
    required this.criticalCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = isLoading
        ? 'Fetching latest data...'
        : criticalCount > 0
            ? '$criticalCount CRITICAL require immediate attention'
            : 'All flights under control ✓';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            // Frosted glass — white tinted at low opacity
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Metric text ──────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE DELAYS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Large animated number
                    Text(
                      isLoading ? '—' : activeCount.toString(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 54,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: criticalCount > 0
                            ? const Color(0xFFFFD580) // warm amber for warning
                            : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // ── Icon ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 2. Quick Action Card ─────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppShapes.cardBorderRadius,
          boxShadow: AppShapes.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 3. Recent Alert preview ──────────────────────────────────
class _RecentAlertCard extends StatelessWidget {
  final FlightDelayAlert alert;
  final VoidCallback onTap;

  const _RecentAlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final localNew = alert.newDeparture.toLocal();
    final timeStr = DateFormat('HH:mm').format(localNew);
    final dateStr = DateFormat('dd MMM').format(localNew);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppShapes.cardBorderRadius,
          boxShadow: AppShapes.cardShadow,
          border: Border.all(
            color: AppColors.critical.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Pulsing red dot indicator
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 14),
              decoration: const BoxDecoration(
                color: AppColors.critical,
                shape: BoxShape.circle,
              ),
            ),
            // Flight info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${alert.flightNumber}  •  ${alert.airline}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert.destination,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // New departure time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No-critical placeholder ──────────────────────────────────
class _NoCriticalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.lowSurface,
        borderRadius: AppShapes.cardBorderRadius,
        border: Border.all(
          color: AppColors.low.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.low, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No critical alerts right now.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.low,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading shimmer placeholder ──────────────────────────────
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: AppShapes.cardBorderRadius,
      ),
    );
  }
}
