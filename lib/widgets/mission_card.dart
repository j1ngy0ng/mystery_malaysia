import 'package:flutter/material.dart';

import '../model/mission_discovery/mission_recommendation.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'status_pill.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({required this.mission, required this.onTap, super.key});

  final MissionRecommendation mission;
  final VoidCallback onTap;

  IconData get icon => switch (mission.iconKey) {
    'forest' => Icons.forest_rounded,
    'food' => Icons.ramen_dining_rounded,
    _ => Icons.festival_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = Color(mission.colorValue);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 76,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.briefing,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusPill(
                          label: mission.duration,
                          icon: Icons.schedule_rounded,
                          color: AppColors.straits,
                        ),
                        StatusPill(
                          label: mission.budget,
                          icon: Icons.payments_outlined,
                          color: AppColors.green,
                        ),
                        StatusPill(
                          label: '${mission.stops} stops',
                          icon: Icons.flag_outlined,
                          color: AppColors.purple,
                        ),
                        StatusPill(
                          label: mission.difficulty,
                          icon: Icons.signal_cellular_alt_rounded,
                          color: AppColors.hibiscus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Time note: allow at least ${mission.duration}; delays may extend it.',
                      style: const TextStyle(
                        color: AppColors.hibiscus,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (
                      var index = 0;
                      index < mission.stopPreviews.length;
                      index++
                    )
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'Stop ${index + 1}: ${mission.stopPreviews[index]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
