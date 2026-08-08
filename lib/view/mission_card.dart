import 'package:flutter/material.dart';

import '../model/mission_discovery/mission_recommendation.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'status_pill.dart';

IconData mysteryPreviewIcon(String description) {
  final text = description.toLowerCase();
  bool mentions(List<String> words) => words.any(text.contains);

  if (mentions([
    'food',
    'cafe',
    'coffee',
    'culinary',
    'cuisine',
    'dish',
    'hawker',
    'restaurant',
  ])) {
    return Icons.restaurant_rounded;
  }
  if (mentions([
    'forest',
    'nature',
    'garden',
    'rainforest',
    'waterfall',
    'river',
    'lake',
    'mangrove',
    'beach',
    'coast',
    'hill',
    'trail',
    'wildlife',
    'park',
  ])) {
    return Icons.park_rounded;
  }
  if (mentions([
    'art',
    'craft',
    'artisan',
    'batik',
    'mural',
    'creative',
    'workshop',
  ])) {
    return Icons.palette_rounded;
  }
  if (mentions([
    'museum',
    'gallery',
    'archive',
    'history',
    'historic',
    'heritage',
    'monument',
  ])) {
    return Icons.museum_rounded;
  }
  if (mentions([
    'mosque',
    'temple',
    'church',
    'shrine',
    'spiritual',
    'worship',
  ])) {
    return Icons.account_balance_rounded;
  }
  if (mentions(['village', 'community', 'neighbourhood', 'local life'])) {
    return Icons.holiday_village_rounded;
  }
  if (mentions(['architecture', 'tower', 'bridge', 'city', 'urban'])) {
    return Icons.location_city_rounded;
  }
  return Icons.explore_rounded;
}

class MissionCard extends StatelessWidget {
  const MissionCard({
    required this.mission,
    required this.onTap,
    super.key,
    this.selected = false,
  });

  final MissionRecommendation mission;
  final VoidCallback onTap;
  final bool selected;

  IconData get icon => mysteryPreviewIcon(
    '${mission.iconKey} ${mission.title} ${mission.briefing}',
  );

  @override
  Widget build(BuildContext context) {
    final color = Color(mission.colorValue);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .22),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
              ]
            : null,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: selected ? color : AppColors.outline,
            width: selected ? 2.2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 5, color: color),
              ),
              Positioned(
                right: -28,
                top: -32,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .055),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  right: 12,
                  top: 11,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.check_rounded, size: 17),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: .2),
                            color.withValues(alpha: .08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: color.withValues(alpha: .18)),
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(letterSpacing: -.2),
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: .1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      mission.stopPreviews[index],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: selected ? 28 : 0),
                      child: Icon(Icons.chevron_right_rounded, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
