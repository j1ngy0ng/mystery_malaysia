import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';

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
                height: 330,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6547DC), AppColors.straits],
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
                    Positioned(
                      left: -45,
                      bottom: -64,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.lagoon.withValues(alpha: .12),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -38,
                      top: -58,
                      child: Container(
                        width: 174,
                        height: 174,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mango.withValues(alpha: .12),
                        ),
                      ),
                    ),
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
                        const _MysteryChest(),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .22),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tap to open the mystery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.mango,
                                size: 20,
                              ),
                            ],
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

class _MysteryChest extends StatelessWidget {
  const _MysteryChest();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      height: 158,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 2,
            child: Container(
              width: 162,
              height: 104,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.hibiscus, Color(0xFFE43C65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .2),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 23,
            child: Transform.rotate(
              angle: -.06,
              child: Container(
                width: 176,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDD62), AppColors.mango],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 3,
            child: Container(
              width: 30,
              height: 126,
              decoration: BoxDecoration(
                color: AppColors.mango,
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: Colors.white.withValues(alpha: .5),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 41,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.straits],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: .2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.question_mark_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
