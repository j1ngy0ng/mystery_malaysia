import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_logo.dart';
import '../malaysia_backdrop.dart';
import '../malaysia_skyline.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MalaysiaBackdrop(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 46,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppLogo(),
                      const SizedBox(height: 26),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: .94, end: 1),
                        duration: const Duration(milliseconds: 750),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: Container(
                          height: 270,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.straits, AppColors.purple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.straits.withValues(alpha: .25),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: -12,
                                child: Opacity(
                                  opacity: .88,
                                  child: const MalaysiaSkyline(height: 194),
                                ),
                              ),
                              const Positioned(
                                left: 20,
                                top: 20,
                                child: _WelcomeTag(
                                  icon: Icons.explore_rounded,
                                  label: 'Tour Malaysia differently',
                                  dark: true,
                                ),
                              ),
                              const Positioned(
                                right: 18,
                                top: 22,
                                child: _FloatingBadge(code: 'sbh', size: 62),
                              ),
                              const Positioned(
                                right: 64,
                                top: 83,
                                child: _FloatingBadge(code: 'png', size: 48),
                              ),
                              const Positioned(
                                right: 16,
                                top: 130,
                                child: _FloatingBadge(code: 'mlk', size: 42),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Malaysia is full of secrets.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Turn every jalan-jalan into a playful mystery of clues, hidden gems and local stories.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 22),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _WelcomeTag(
                            icon: Icons.auto_awesome,
                            label: 'AI quests',
                          ),
                          _WelcomeTag(
                            icon: Icons.groups_rounded,
                            label: 'Play together',
                          ),
                          _WelcomeTag(
                            icon: Icons.travel_explore,
                            label: 'Local gems',
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/auth/sign-in'),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Start the adventure'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/home'),
                          child: const Text('Explore the UI demo'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeTag extends StatelessWidget {
  const _WelcomeTag({
    required this.icon,
    required this.label,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: .16) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: .28) : AppColors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: dark ? AppColors.mango : AppColors.hibiscus,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: dark ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.code, required this.size});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      border: Border.all(color: AppColors.mango, width: 2),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ClipOval(
      child: Image.asset(
        'assets/images/state_badges/$code.webp',
        fit: BoxFit.cover,
      ),
    ),
  );
}
