// ============================================================
//  detail_screen.dart
//  "Digital Boarding Pass" read view for a single alert.
//  Shows full details with a dashed divider in the middle.
//  Bottom actions: Edit (opens FormScreen) and Archive.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/boarding_pass_divider.dart';
import '../widgets/severity_badge.dart';
import 'form_screen.dart';

class DetailScreen extends StatefulWidget {
  final FlightDelayAlert alert;

  const DetailScreen({super.key, required this.alert});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late FlightDelayAlert _alert;
  final _fullFormatter = DateFormat('dd MMM yyyy  •  HH:mm zzz');
  final _timeOnlyFormatter = DateFormat('HH:mm');
  final _dateOnlyFormatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _alert = widget.alert;
  }

  Future<void> _openEdit() async {
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormScreen(existingAlert: _alert),
      ),
    );
    if (refreshed == true && mounted) {
      // Reload the updated alert from the provider
      final updated = context.read<AlertProvider>().alerts.firstWhere(
            (a) => a.id == _alert.id,
            orElse: () => _alert,
          );
      setState(() => _alert = updated);
    }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.cardBorderRadius,
        ),
        title: const Text(
          'Archive Alert?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This alert will be marked as ARCHIVED and hidden from the active dashboard. This action is for aviation compliance record-keeping.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success =
        await context.read<AlertProvider>().archiveAlert(_alert.id!);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert archived ✓')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AlertProvider>().errorMessage ?? 'Archive failed.',
            ),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  // ── Permanent Delete ─────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.cardBorderRadius,
        ),
        title: const Text(
          'Delete Alert?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            children: [
              const TextSpan(
                text: 'Are you sure you want to permanently delete the record for flight ',
              ),
              TextSpan(
                text: _alert.flightNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const TextSpan(
                text: '?\n\n',
              ),
              const TextSpan(
                text: 'This action cannot be undone.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.critical,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            onPressed: () => Navigator.pop(ctx, true),
            label: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success =
        await context.read<AlertProvider>().deleteAlert(_alert.id!);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert permanently deleted'),
          ),
        );
      } else {
        final err =
            context.read<AlertProvider>().errorMessage ?? 'Delete failed.';
        context.read<AlertProvider>().clearError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localOrig = _alert.originalDeparture.toLocal();
    final localNew = _alert.newDeparture.toLocal();
    final delayMins = _alert.newDeparture
        .difference(_alert.originalDeparture)
        .inMinutes;
    final isLoading = context.watch<AlertProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
        actions: [
          // ── Delete (permanent) ─────────────────────────────
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.critical,
              tooltip: 'Delete Alert',
              onPressed: isLoading ? null : _confirmDelete,
            ),
          // ── Severity badge ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SeverityBadge(severity: _alert.severityLevel, large: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Boarding Pass Card ──────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppShapes.cardBorderRadius,
                boxShadow: AppShapes.cardShadow,
              ),
              child: Column(
                children: [
                  // ── Top half ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Flight number header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _alert.flightNumber,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  Text(
                                    _alert.airline,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: _alert.status),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Route row
                        Row(
                          children: [
                            _InfoColumn(
                              label: 'Destination',
                              value: _alert.destination,
                            ),
                            const SizedBox(width: 24),
                            _InfoColumn(
                              label: 'Terminal',
                              value: _alert.terminalZone,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Dashed divider ─────────────────────────
                  const BoardingPassDivider(),

                  // ── Bottom half ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time comparison
                        Row(
                          children: [
                            Expanded(
                              child: _TimeBlock(
                                label: 'Original Departure',
                                time: _timeOnlyFormatter.format(localOrig),
                                date: _dateOnlyFormatter.format(localOrig),
                                strikethrough: true,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.criticalSurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: AppColors.critical,
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _TimeBlock(
                                  label: 'New Departure',
                                  time: _timeOnlyFormatter.format(localNew),
                                  date: _dateOnlyFormatter.format(localNew),
                                  highlight: true,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Delay duration
                        if (delayMins > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timelapse_rounded,
                                  size: 14,
                                  color: AppColors.critical,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Total delay: ${_formatDelay(delayMins)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.critical,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // Delay reason
                        const Text(
                          'DELAY REASON',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _alert.delayReason,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Timestamps
                        if (_alert.createdAt != null)
                          _TimestampRow(
                            label: 'Logged at',
                            dt: _alert.createdAt!,
                            formatter: _fullFormatter,
                          ),
                        if (_alert.updatedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _TimestampRow(
                              label: 'Last updated',
                              dt: _alert.updatedAt!,
                              formatter: _fullFormatter,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Action buttons ──────────────────────────────
            if (auth.isAdmin)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _archive,
                      icon: const Icon(Icons.archive_rounded, size: 18),
                      label: const Text('Archive'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.critical,
                        side: const BorderSide(
                          color: AppColors.critical,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _openEdit,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Alert'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDelay(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ─── Small helpers ────────────────────────────────────────────
class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  const _InfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final String time;
  final String date;
  final bool strikethrough;
  final bool highlight;

  const _TimeBlock({
    required this.label,
    required this.time,
    required this.date,
    this.strikethrough = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.textSecondary,
            decoration: strikethrough ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondary,
            decorationThickness: 2,
          ),
        ),
        Text(
          date,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.textSecondary,
            decoration: strikethrough ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TimestampRow extends StatelessWidget {
  final String label;
  final DateTime dt;
  final DateFormat formatter;

  const _TimestampRow({
    required this.label,
    required this.dt,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          formatter.format(dt.toLocal()),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
