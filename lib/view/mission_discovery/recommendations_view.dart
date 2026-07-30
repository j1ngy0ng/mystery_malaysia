import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/services/errors/api_error.dart';
import '../../controller/mission_discovery/mission_discovery_facade_interface.dart';
import '../../model/mission_discovery/mission_recommendation.dart';
import '../active_mission/active_mission_view.dart';
import '../collaborative_travel/shared_mission_view.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/status_pill.dart';

class RecommendationsView extends StatefulWidget {
  const RecommendationsView({
    required this.facade,
    super.key,
    this.recommendations,
    this.budgetMyr = 120,
    this.availableHours = 4,
  });

  final IMissionDiscoveryFacade facade;
  final List<MissionRecommendation>? recommendations;
  final double budgetMyr;
  final double availableHours;

  @override
  State<RecommendationsView> createState() => _RecommendationsViewState();
}

class _RecommendationsViewState extends State<RecommendationsView> {
  late final IMissionDiscoveryFacade facade = widget.facade;
  MissionRecommendation? selected;
  late final List<MissionRecommendation> recommendations;
  bool isRegenerating = false;

  @override
  void initState() {
    super.initState();
    recommendations = List.of(widget.recommendations ?? facade.recommendations);
  }

  @override
  void dispose() {
    facade.dispose();
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
            'Built around your selected vibe, RM ${widget.budgetMyr.round()} '
            'budget and ${widget.availableHours.round()}-hour window.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          ...recommendations.map(
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
              OutlinedButton.icon(
                onPressed: mission.id == null || isRegenerating
                    ? null
                    : () => _chooseStopToRegenerate(context, mission),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Regenerate one mystery stop'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _startMission(mission);
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start this mission'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _createSharedMission(mission);
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

  Future<void> _chooseStopToRegenerate(
    BuildContext sheetContext,
    MissionRecommendation mission,
  ) async {
    final stop = await showDialog<int>(
      context: sheetContext,
      builder: (context) => AlertDialog(
        title: const Text('Replace which mystery stop?'),
        content: const Text(
          'Only this hidden stop will change. The other missions and stops stay the same.',
        ),
        actions: [
          for (var index = 1; index <= 3; index++)
            TextButton(
              onPressed: () => Navigator.pop(context, index),
              child: Text('Stop $index'),
            ),
        ],
      ),
    );
    if (stop == null || mission.id == null) return;
    setState(() => isRegenerating = true);
    try {
      final updated = await facade.regenerateStop(mission.id!, stop);
      final index = recommendations.indexWhere((item) => item.id == mission.id);
      if (index >= 0) recommendations[index] = updated;
      selected = updated;
      if (!mounted || !sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mystery stop $stop was regenerated.')),
      );
    } on ApiError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => isRegenerating = false);
    }
  }

  Future<void> _startMission(MissionRecommendation mission) async {
    final recommendationId = mission.id;
    if (recommendationId == null) {
      await Navigator.pushNamed(context, '/play/demo');
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final launch = await facade.startMission(recommendationId);
      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ActiveMissionView(
            facade: AppDependencies.activeMission(launch: launch),
          ),
        ),
      );
    } on ApiError catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _createSharedMission(MissionRecommendation mission) async {
    if (mission.id == null) {
      await Navigator.pushNamed(context, '/shared/demo');
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final sessionId = await facade.createSharedMission(mission.id!);
      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SharedMissionView(
            facade: AppDependencies.collaborativeTravel(sessionId: sessionId),
          ),
        ),
      );
    } on ApiError catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
