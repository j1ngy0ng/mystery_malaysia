import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MalaysiaBackdrop extends StatelessWidget {
  const MalaysiaBackdrop({
    required this.child,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BatikPainter(),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _BatikPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final teal = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final coral = Paint()
      ..color = AppColors.hibiscus.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final mango = Paint()
      ..color = AppColors.mango.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    for (var x = 28.0; x < size.width; x += 118) {
      for (var y = 36.0; y < size.height; y += 128) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate((x + y) % 2 == 0 ? 0.35 : -0.35);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 25, height: 48),
          teal,
        );
        canvas.drawCircle(const Offset(15, 15), 5, coral);
        canvas.drawCircle(const Offset(-17, 9), 3, mango);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
