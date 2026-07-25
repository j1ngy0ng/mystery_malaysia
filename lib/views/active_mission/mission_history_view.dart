import 'package:flutter/material.dart';

import '../../controllers/active_mission/mission_history_controller.dart';
import '../../models/active_mission/mission_history_item.dart';
import '../../models/active_mission/mission_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_pill.dart';

class MissionHistoryView extends StatefulWidget {
  const MissionHistoryView({super.key});

  @override
  State<MissionHistoryView> createState() => _MissionHistoryViewState();
}

class _MissionHistoryViewState extends State<MissionHistoryView> {
  final controller = MissionHistoryController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My missions')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
            children: [
              Text(
                'Every adventure,\nin one place.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Continue active or paused missions and revisit completed journeys.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MissionHistoryFilter.values.map((filter) {
                    final label = switch (filter) {
                      MissionHistoryFilter.all => 'All',
                      MissionHistoryFilter.active => 'Active',
                      MissionHistoryFilter.paused => 'Paused',
                      MissionHistoryFilter.completed => 'Completed',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: controller.filter == filter,
                        onSelected: (_) => controller.selectFilter(filter),
                        selectedColor: AppColors.paleTeal,
                        side: BorderSide(
                          color: controller.filter == filter
                              ? AppColors.teal
                              : AppColors.outline,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              ...controller.visibleMissions.map(
                (mission) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MissionHistoryCard(
                    mission: mission,
                    onTap: () {
                      if (mission.status == MissionStatus.active ||
                          mission.status == MissionStatus.paused) {
                        Navigator.pushNamed(context, '/play/demo');
                      } else {
                        Navigator.pushNamed(context, '/diary');
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MissionHistoryCard extends StatelessWidget {
  const _MissionHistoryCard({required this.mission, required this.onTap});

  final MissionHistoryItem mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (mission.status) {
      MissionStatus.active => (
        'Active',
        AppColors.green,
        Icons.play_circle_outline_rounded,
      ),
      MissionStatus.paused => (
        'Paused',
        AppColors.purple,
        Icons.pause_circle_outline_rounded,
      ),
      MissionStatus.completed => (
        'Completed',
        AppColors.straits,
        Icons.check_circle_outline_rounded,
      ),
      MissionStatus.abandoned => (
        'Abandoned',
        AppColors.secondaryText,
        Icons.cancel_outlined,
      ),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: Text(
                  mission.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mission.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusPill(label: label, color: color, icon: icon),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mission.region} • ${mission.dateLabel}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: mission.progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(99),
                      color: color,
                      backgroundColor: color.withValues(alpha: .12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Stage ${mission.currentStage} of ${mission.totalStages}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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
