import 'package:flutter/material.dart';

import 'app_colors.dart';

class MalaysiaSkyline extends StatelessWidget {
  const MalaysiaSkyline({super.key, this.height = 220});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Playful Kuala Lumpur skyline illustration',
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _SkylinePainter()),
      ),
    );
  }
}

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = AppColors.sky.withValues(alpha: 0.18);
    final hill = Paint()..color = AppColors.teal.withValues(alpha: 0.20);
    final city = Paint()..color = AppColors.straits;
    final gold = Paint()..color = AppColors.mango;
    final hibiscus = Paint()..color = AppColors.hibiscus;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 6, size.width, size.height - 12),
        const Radius.circular(36),
      ),
      sky,
    );
    canvas.drawCircle(Offset(size.width * .78, 48), 26, gold);

    final hills = Path()
      ..moveTo(0, size.height * .7)
      ..quadraticBezierTo(
        size.width * .2,
        size.height * .46,
        size.width * .42,
        size.height * .71,
      )
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .46,
        size.width,
        size.height * .7,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hills, hill);

    final ground = size.height * .83;
    void tower(double x, double top, double width) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, width, ground - top),
          const Radius.circular(5),
        ),
        city,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + width * .46, top - 24, width * .08, 24),
        city,
      );
      for (var y = top + 12; y < ground - 8; y += 15) {
        canvas.drawRect(
          Rect.fromLTWH(x + 7, y, width - 14, 3),
          Paint()..color = Colors.white.withValues(alpha: .55),
        );
      }
    }

    tower(size.width * .38, size.height * .28, 45);
    tower(size.width * .55, size.height * .25, 45);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .38 + 45,
        size.height * .48,
        size.width * .17 - 45,
        6,
      ),
      city,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .13, ground - 42, 62, 42),
        const Radius.circular(7),
      ),
      hibiscus,
    );
    canvas.drawCircle(Offset(size.width * .13 + 31, ground - 42), 22, gold);
    canvas.drawRect(Rect.fromLTWH(0, ground, size.width, 5), city);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
