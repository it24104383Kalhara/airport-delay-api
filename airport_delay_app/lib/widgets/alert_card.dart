// ============================================================
//  alert_card.dart
//  Dashboard list card — shows flight number, airline,
//  new departure (local time), and a SeverityBadge.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/alert_model.dart';
import 'severity_badge.dart';

class AlertCard extends StatelessWidget {
  final FlightDelayAlert alert;
  final VoidCallback onTap;

  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Convert stored UTC to device's local timezone for display
    final localNewDep = alert.newDeparture.toLocal();
    final localOrigDep = alert.originalDeparture.toLocal();
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd MMM yyyy');
    final delayMinutes =
        alert.newDeparture.difference(alert.originalDeparture).inMinutes;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppShapes.cardBorderRadius,
          boxShadow: AppShapes.cardShadow,
        ),
        child: Column(
          children: [
            // ── Top strip — severity color bar ────────────────
            _SeverityStrip(severity: alert.severityLevel),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: flight + severity badge ────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.flightNumber,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.airline,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SeverityBadge(severity: alert.severityLevel),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // ── Row 2: route info ─────────────────────────
                  Row(
                    children: [
                      const Icon(
                        Icons.flight_takeoff_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${alert.destination}  •  ${alert.terminalZone}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Row 3: time comparison ────────────────────
                  Row(
                    children: [
                      // Original (struck through)
                      _TimeChip(
                        label: 'Original',
                        time: timeFormatter.format(localOrigDep),
                        date: dateFormatter.format(localOrigDep),
                        strikethrough: true,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      // New departure (highlighted)
                      _TimeChip(
                        label: 'New ETD',
                        time: timeFormatter.format(localNewDep),
                        date: dateFormatter.format(localNewDep),
                        strikethrough: false,
                        highlight: true,
                      ),
                      const Spacer(),
                      // Delay duration pill
                      if (delayMinutes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.criticalSurface,
                            borderRadius: BorderRadius.circular(
                              AppShapes.badgeRadius,
                            ),
                          ),
                          child: Text(
                            '+${_formatDelay(delayMinutes)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.critical,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDelay(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ─── Thin color strip at the top of the card ─────────────────
class _SeverityStrip extends StatelessWidget {
  final SeverityLevel severity;
  const _SeverityStrip({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      SeverityLevel.critical => AppColors.critical,
      SeverityLevel.moderate => AppColors.moderate,
      SeverityLevel.low => AppColors.low,
    };
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppShapes.cardRadius),
          topRight: Radius.circular(AppShapes.cardRadius),
        ),
      ),
    );
  }
}

// ─── Time display chip ────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final String date;
  final bool strikethrough;
  final bool highlight;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.date,
    required this.strikethrough,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeColor =
        highlight ? AppColors.primary : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: timeColor,
            decoration: strikethrough ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondary,
          ),
        ),
        Text(
          date,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
