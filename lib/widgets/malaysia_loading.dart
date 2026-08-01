import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(
              begin: .9,
              end: 1.08,
            ).animate(CurvedAnimation(parent: pulse, curve: Curves.easeInOut)),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.paleMango,
              foregroundColor: AppColors.hibiscus,
              child: Icon(fact.icon, size: 36),
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
        ],
      ),
    );
  }
}
