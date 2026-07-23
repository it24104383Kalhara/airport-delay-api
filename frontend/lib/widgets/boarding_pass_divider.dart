// ============================================================
//  boarding_pass_divider.dart
//  Dashed horizontal divider with circular notches on each end,
//  mimicking a physical boarding pass tear-line.
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme.dart';

class BoardingPassDivider extends StatelessWidget {
  const BoardingPassDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          // Left notch (sticks out of the card edge)
          _Notch(isLeft: true),
          // Dashed line in the middle
          Expanded(
            child: CustomPaint(
              painter: _DashedLinePainter(),
            ),
          ),
          // Right notch
          _Notch(isLeft: false),
        ],
      ),
    );
  }
}

// ─── Circular notch ──────────────────────────────────────────
class _Notch extends StatelessWidget {
  final bool isLeft;
  const _Notch({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(isLeft ? -16 : 16, 0),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.background, // matches scaffold background
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1.2),
        ),
      ),
    );
  }
}

// ─── Dashed line painter ─────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
