import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 120),
      children: [
        Text(
          'Begin your enigmatic odyssey',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'A secret three-stop Malaysian adventure is waiting inside.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 44),
        Semantics(
          button: true,
          label: 'Open the mystery box and build a mission',
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/missions/request'),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final value = Curves.easeInOut.transform(animation.value);
                return Transform.rotate(
                  angle: math.sin(value * math.pi * 2) * .025,
                  child: Transform.scale(
                    scale: .97 + value * .05,
                    child: child,
                  ),
                );
              },
              child: Container(
                height: 310,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.purple, AppColors.straits],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: .28),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final alignment in const [
                      Alignment(-.72, -.7),
                      Alignment(.72, -.62),
                      Alignment(-.62, .72),
                      Alignment(.65, .7),
                    ])
                      Align(
                        alignment: alignment,
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.mango,
                          size: 27,
                        ),
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppColors.mango,
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            size: 86,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Tap to open the mystery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paleTeal,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Row(
            children: [
              Icon(Icons.location_searching_rounded, color: AppColors.teal),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your current location helps uncover safe, less-crowded places nearby without revealing them early.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
