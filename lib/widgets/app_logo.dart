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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.hibiscus.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/mystery_malaysia_logo-v2.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 11),
        Text(
          compact ? 'Mystery MY' : 'Mystery Malaysia',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.straits,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
