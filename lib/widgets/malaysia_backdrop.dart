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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF2), Color(0xFFF3FFFC), Color(0xFFFFF7E2)],
          stops: [0, .55, 1],
        ),
      ),
      child: CustomPaint(
        painter: _BatikPainter(),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _BatikPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final header = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 112)
      ..cubicTo(size.width * .76, 174, size.width * .33, 92, 0, 154)
      ..close();
    canvas.drawPath(
      header,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x1A34D5C0), Color(0x14FFC83D), Color(0x16FF5C75)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 180)),
    );

    final glow = Paint()..style = PaintingStyle.fill;
    glow.color = AppColors.mango.withValues(alpha: .09);
    canvas.drawCircle(const Offset(-24, 100), 135, glow);
    glow.color = AppColors.teal.withValues(alpha: .07);
    canvas.drawCircle(Offset(size.width + 26, size.height * .34), 155, glow);
    glow.color = AppColors.hibiscus.withValues(alpha: .055);
    canvas.drawCircle(Offset(size.width * .22, size.height + 54), 120, glow);

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.lagoon.withValues(alpha: .08);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width + 18, 104), radius: 82),
      .45,
      4.8,
      false,
      orbit,
    );
    orbit.color = AppColors.mango.withValues(alpha: .12);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(-10, 72), radius: 54),
      -1,
      4.4,
      false,
      orbit,
    );

    final teal = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final coral = Paint()
      ..color = AppColors.hibiscus.withValues(alpha: 0.065)
      ..style = PaintingStyle.fill;
    final mango = Paint()
      ..color = AppColors.mango.withValues(alpha: 0.11)
      ..style = PaintingStyle.fill;

    for (var x = 26.0; x < size.width; x += 126) {
      for (var y = 46.0; y < size.height; y += 138) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(((x + y).round().isEven) ? .38 : -.38);
        for (var petal = 0; petal < 4; petal++) {
          canvas.save();
          canvas.rotate(petal * 1.5708);
          canvas.drawOval(const Rect.fromLTWH(-6, -26, 12, 28), teal);
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, 3.5, mango);
        canvas.drawCircle(const Offset(18, 15), 4.5, coral);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
