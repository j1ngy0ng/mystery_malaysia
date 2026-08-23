import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 40 : 48,
          height: compact ? 40 : 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.mango, AppColors.hibiscus, AppColors.teal],
            ),
            borderRadius: BorderRadius.circular(compact ? 14 : 17),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.straits.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 10 : 13),
            child: Image.asset(
              'assets/images/mystery_malaysia_logo-v2.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Text(
          compact ? 'Mystery MY' : 'Mystery Malaysia',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.straits,
            fontWeight: FontWeight.w900,
            letterSpacing: -.45,
          ),
        ),
      ],
    );
  }
}
