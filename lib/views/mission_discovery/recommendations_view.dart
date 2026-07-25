import 'package:flutter/material.dart';

import '../../controllers/mission_discovery/mission_discovery_controller.dart';
import '../../models/mission_discovery/mission_recommendation.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/mission_card.dart';
import '../widgets/status_pill.dart';

class RecommendationsView extends StatefulWidget {
  const RecommendationsView({super.key});

  @override
  State<RecommendationsView> createState() => _RecommendationsViewState();
}

class _RecommendationsViewState extends State<RecommendationsView> {
  final controller = MissionDiscoveryController();
  MissionRecommendation? selected;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your mystery picks')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Three adventures.\nZero spoilers.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const Text('✨', style: TextStyle(fontSize: 52)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Built around your culture vibe, RM 120 budget and four-hour window.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          ...controller.recommendations.map(
            (mission) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MissionCard(
                mission: mission,
                onTap: () => setState(() => selected = mission),
              ),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Adjust my preferences'),
          ),
        ],
      ),
      bottomNavigationBar: selected == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: FilledButton.icon(
                  onPressed: () => _showMissionPreview(context, selected!),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text('Preview ${selected!.title}'),
                ),
              ),
            ),
    );
  }

  void _showMissionPreview(
    BuildContext context,
    MissionRecommendation mission,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .82,
          maxChildSize: .95,
          minChildSize: .6,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                mission.title,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(mission.briefing),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(label: mission.duration, icon: Icons.schedule),
                  StatusPill(
                    label: mission.budget,
                    icon: Icons.payments_outlined,
                    color: AppColors.green,
                  ),
                  StatusPill(
                    label: mission.difficulty,
                    icon: Icons.signal_cellular_alt_rounded,
                    color: AppColors.hibiscus,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Why this fits you',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(mission.matchReason),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your route stays secret',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${mission.stops} hidden destinations are arranged into an efficient route. You unlock each clue one stage at a time.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/play/demo');
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start this mission'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/shared/demo');
                },
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Make it a shared mission'),
              ),
            ],
          ),
        );
      },
    );
  }
}
