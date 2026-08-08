import 'dart:async';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class MalaysiaLoading extends StatefulWidget {
  const MalaysiaLoading({
    super.key,
    this.message = 'Preparing your Malaysian mystery...',
  });

  final String message;

  @override
  State<MalaysiaLoading> createState() => _MalaysiaLoadingState();
}

class _MalaysiaLoadingState extends State<MalaysiaLoading>
    with SingleTickerProviderStateMixin {
  static const facts = [
    (
      icon: Icons.local_florist_rounded,
      title: 'Bunga raya',
      description:
          'The red hibiscus is Malaysia\'s national flower and symbolises courage and vitality.',
    ),
    (
      icon: Icons.restaurant_rounded,
      title: 'Makan together',
      description:
          'Malaysian food culture brings Malay, Chinese, Indian and Indigenous traditions to one table.',
    ),
    (
      icon: Icons.palette_rounded,
      title: 'Batik craft',
      description:
          'Malaysian batik is known for flowing floral and nature-inspired patterns.',
    ),
    (
      icon: Icons.home_work_rounded,
      title: 'Rumah tradisi',
      description:
          'Traditional timber homes use raised floors and ventilation suited to the tropical climate.',
    ),
  ];

  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  Timer? timer;
  int index = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => index = (index + 1) % facts.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fact = facts[index];
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFFBEC), Color(0xFFEDFFFA)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.straits.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.straits.withValues(alpha: .13),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: pulse,
                  child: CustomPaint(
                    size: const Size.square(86),
                    painter: const _LoadingRingPainter(),
                  ),
                ),
                ScaleTransition(
                  scale: Tween(begin: .9, end: 1.06).animate(
                    CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.paleMango,
                    foregroundColor: AppColors.hibiscus,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Icon(fact.icon, key: ValueKey(index), size: 32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Column(
              key: ValueKey(index),
              children: [
                Text(
                  fact.title,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fact.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              facts.length,
              (dot) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: dot == index ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: dot == index ? AppColors.teal : AppColors.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingRingPainter extends CustomPainter {
  const _LoadingRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [
      AppColors.hibiscus,
      AppColors.mango,
      AppColors.teal,
      AppColors.purple,
      AppColors.sky,
      AppColors.green,
    ];
    for (var i = 0; i < colors.length; i++) {
      final angle = i * 1.0472;
      final offset = Offset.fromDirection(angle, size.width * .42);
      canvas.drawCircle(
        center + offset,
        i.isEven ? 5.5 : 4,
        Paint()..color = colors[i],
      );
    }
    canvas.drawCircle(
      center,
      size.width * .43,
      Paint()
        ..color = AppColors.teal.withValues(alpha: .16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
