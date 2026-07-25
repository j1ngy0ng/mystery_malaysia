import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_logo.dart';
import '../widgets/malaysia_backdrop.dart';
import '../widgets/section_header.dart';
import '../widgets/status_pill.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MalaysiaBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          Row(
            children: [
              const AppLogo(compact: true),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notifications',
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Hai, Aina! 👋',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 5),
          Text(
            'Where will today’s mystery take you?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          _DiscoveryHero(
            onStart: () => Navigator.pushNamed(context, '/missions/request'),
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Your missions',
            action: 'View history',
            onAction: () => Navigator.pushNamed(context, '/missions'),
          ),
          const SizedBox(height: 10),
          _MissionSummaryCard(
            title: 'Lanterns & Legends',
            subtitle: 'Kuala Lumpur • Stage 2 of 3',
            status: 'Active',
            emoji: '🏮',
            color: AppColors.green,
            progress: .66,
            onTap: () => Navigator.pushNamed(context, '/play/demo'),
          ),
          const SizedBox(height: 12),
          _MissionSummaryCard(
            title: 'Spice Route Secrets',
            subtitle: 'Penang • Stage 1 of 4',
            status: 'Paused',
            emoji: '🍜',
            color: AppColors.purple,
            progress: .25,
            onTap: () => Navigator.pushNamed(context, '/missions'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/missions'),
            icon: const Icon(Icons.history_rounded),
            label: const Text('See all past and current missions'),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryHero extends StatelessWidget {
  const _DiscoveryHero({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.teal, AppColors.straits],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: .24),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -10,
            child: Transform.rotate(
              angle: .16,
              child: const Text('🗺️', style: TextStyle(fontSize: 90)),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 255),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(
                  label: 'AI mystery maker',
                  icon: Icons.auto_awesome,
                  color: AppColors.ink,
                  background: AppColors.mango,
                ),
                const SizedBox(height: 18),
                Text(
                  'Find me a mystery',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 7),
                const Text(
                  'We use your current location, time and budget to create a hidden route.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.straits,
                  ),
                  onPressed: onStart,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Build my mission'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionSummaryCard extends StatelessWidget {
  const _MissionSummaryCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.emoji,
    required this.color,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final String emoji;
  final Color color;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 66,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 31)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusPill(label: status, color: color),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 9),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(99),
                      color: color,
                      backgroundColor: color.withValues(alpha: .12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
