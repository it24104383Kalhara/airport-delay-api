// ============================================================
//  severity_badge.dart
//  Color-coded pill chip for CRITICAL / MODERATE / LOW severity.
// ============================================================

import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class SeverityBadge extends StatelessWidget {
  final SeverityLevel severity;
  final bool large;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon) = _attrs(severity);
    final fontSize = large ? 13.0 : 11.0;
    final hPad = large ? 14.0 : 10.0;
    final vPad = large ? 8.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppShapes.badgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 5),
          Text(
            severity.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color, IconData) _attrs(SeverityLevel s) {
    switch (s) {
      case SeverityLevel.critical:
        return (
          AppColors.critical,
          AppColors.criticalSurface,
          Icons.warning_rounded,
        );
      case SeverityLevel.moderate:
        return (
          AppColors.moderate,
          AppColors.moderateSurface,
          Icons.error_outline_rounded,
        );
      case SeverityLevel.low:
        return (
          AppColors.low,
          AppColors.lowSurface,
          Icons.check_circle_outline_rounded,
        );
    }
  }
}

// ─── Status Badge (reuses the same pill style) ───────────────
class StatusBadge extends StatelessWidget {
  final AlertStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _attrs(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppShapes.badgeRadius),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static (Color, Color) _attrs(AlertStatus s) {
    switch (s) {
      case AlertStatus.active:
        return (AppColors.primary, const Color(0xFFE8EFF8));
      case AlertStatus.resolved:
        return (AppColors.resolved, const Color(0xFFE5F6FA));
      case AlertStatus.cancelled:
        return (AppColors.cancelled, const Color(0xFFF0F0F0));
      case AlertStatus.archived:
        return (AppColors.archived, const Color(0xFFF5F5F5));
    }
  }
}
