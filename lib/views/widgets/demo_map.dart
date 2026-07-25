import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DemoMap extends StatelessWidget {
  const DemoMap({super.key, this.height = 260});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _MapPainter()),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8F4E9),
    );
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = const Color(0xFFD5E2D6)
      ..strokeWidth = 4;
    final river = Paint()
      ..color = AppColors.sky.withValues(alpha: .62)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(-20, size.height * .72)
      ..cubicTo(
        size.width * .2,
        size.height * .55,
        size.width * .48,
        size.height * .82,
        size.width + 20,
        size.height * .45,
      );
    canvas.drawPath(riverPath, river);
    canvas.drawLine(
      Offset(size.width * .05, size.height * .22),
      Offset(size.width * .95, size.height * .68),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .2, size.height * .95),
      Offset(size.width * .72, size.height * .08),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .05, size.height * .48),
      Offset(size.width * .9, size.height * .32),
      minor,
    );

    final route = Paint()
      ..color = AppColors.hibiscus
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final routePath = Path()
      ..moveTo(size.width * .2, size.height * .78)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .5,
        size.width * .7,
        size.height * .32,
      );
    canvas.drawPath(routePath, route);
    canvas.drawCircle(
      Offset(size.width * .2, size.height * .78),
      12,
      Paint()..color = AppColors.straits,
    );
    canvas.drawCircle(
      Offset(size.width * .7, size.height * .32),
      14,
      Paint()..color = AppColors.mango,
    );
    canvas.drawCircle(
      Offset(size.width * .7, size.height * .32),
      6,
      Paint()..color = AppColors.hibiscus,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
