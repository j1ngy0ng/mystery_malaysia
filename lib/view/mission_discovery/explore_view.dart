import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        Text(
          'Explore Malaysia',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 5),
        Text(
          'Choose a vibe. The exact destination stays hidden.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          readOnly: true,
          onTap: () => Navigator.pushNamed(context, '/missions/request'),
          decoration: const InputDecoration(
            hintText: 'Search a vibe, state or adventure',
            prefixIcon: Icon(Icons.search_rounded),
            suffixIcon: Icon(Icons.tune_rounded),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Pick your adventure'),
        const SizedBox(height: 10),
        _ExploreCard(
          title: 'Taste the neighbourhood',
          subtitle: 'Markets, kopitiams and family recipes',
          emoji: '🍜',
          color: AppColors.paleMango,
          accent: AppColors.hibiscus,
          onTap: () => Navigator.pushNamed(context, '/missions/request'),
        ),
        const SizedBox(height: 12),
        _ExploreCard(
          title: 'Stories in the streets',
          subtitle: 'Architecture, heritage and local legends',
          emoji: '🏮',
          color: AppColors.paleHibiscus,
          accent: AppColors.purple,
          onTap: () => Navigator.pushNamed(context, '/missions/request'),
        ),
        const SizedBox(height: 12),
        _ExploreCard(
          title: 'Into the green',
          subtitle: 'Waterfalls, rainforests and cool viewpoints',
          emoji: '🌿',
          color: AppColors.paleTeal,
          accent: AppColors.teal,
          onTap: () => Navigator.pushNamed(context, '/missions/request'),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Trending states'),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(label: 'Penang • Food', icon: Icons.trending_up_rounded),
            StatusPill(
              label: 'Sabah • Nature',
              icon: Icons.trending_up_rounded,
              color: AppColors.green,
            ),
            StatusPill(
              label: 'Melaka • Heritage',
              icon: Icons.trending_up_rounded,
              color: AppColors.hibiscus,
            ),
          ],
        ),
      ],
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 46)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                child: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
