import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/mission_discovery/mission_discovery_facade_interface.dart';
import '../../model/mission_discovery/mission_recommendation.dart';
import '../active_mission/active_mission_view.dart';
import '../collaborative_travel/shared_mission_view.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/malaysia_loading.dart';

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
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.straits],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: .22),
                  blurRadius: 24,
                  offset: const Offset(0, 11),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -28,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 134,
                    color: Colors.white.withValues(alpha: .09),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusPill(
                      label: 'AI-curated nearby',
                      icon: Icons.location_searching_rounded,
                      color: AppColors.ink,
                      background: AppColors.mango,
                    ),
                    const SizedBox(height: 17),
                    Text(
                      'Three adventures.\nZero spoilers.',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Built around RM ${widget.budgetMyr.round()} and a '
                      '${widget.availableHours.round()}-hour travel window.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose your mystery',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a card to select it, then preview the hidden stops.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...recommendations.map(
            (mission) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MissionCard(
                mission: mission,
                selected: selected?.id == mission.id,
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(mission.colorValue), AppColors.straits],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR MYSTERY PREVIEW',
                      style: TextStyle(
                        color: AppColors.mango,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      mission.title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      mission.briefing,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusPill(
                          label: mission.duration,
                          icon: Icons.schedule,
                          color: AppColors.ink,
                          background: Colors.white,
                        ),
                        StatusPill(
                          label: mission.budget,
                          icon: Icons.payments_outlined,
                          color: AppColors.ink,
                          background: AppColors.paleTeal,
                        ),
                        StatusPill(
                          label: mission.difficulty,
                          icon: Icons.signal_cellular_alt_rounded,
                          color: AppColors.ink,
                          background: AppColors.paleHibiscus,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paleMango,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Allow at least ${mission.duration}. Traffic, queues and walking pace may extend the journey.',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
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
                'Destination previews',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enough detail to compare each stop, without revealing its name or location.',
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < mission.stops; index++) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const [
                          AppColors.paleTeal,
                          AppColors.paleHibiscus,
                          AppColors.paleMango,
                        ][index % 3],
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: const [
                        AppColors.teal,
                        AppColors.hibiscus,
                        AppColors.mango,
                      ][index % 3].withValues(alpha: .22),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: const [
                          AppColors.teal,
                          AppColors.hibiscus,
                          AppColors.mango,
                        ][index % 3],
                        foregroundColor: index == 2
                            ? AppColors.ink
                            : Colors.white,
                        child: Icon(
                          mysteryPreviewIcon(
                            index < mission.stopPreviews.length
                                ? mission.stopPreviews[index]
                                : '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mystery stop ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              index < mission.stopPreviews.length
                                  ? mission.stopPreviews[index]
                                  : 'A hidden Malaysian experience with its own story and discovery challenge.',
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 17,
                                  color: AppColors.hibiscus,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    index < mission.stopOpeningWarnings.length
                                        ? mission.stopOpeningWarnings[index]
                                        : 'Opening-time warning: Check current operating hours before departure.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Regenerate mystery stop ${index + 1}',
                        onPressed: mission.id == null || isRegenerating
                            ? null
                            : () =>
                                  _regenerateStop(context, mission, index + 1),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveMission(mission);
                },
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Choose this mission'),
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

  Future<void> _regenerateStop(
    BuildContext sheetContext,
    MissionRecommendation mission,
    int stop,
  ) async {
    if (mission.id == null || isRegenerating) return;
    setState(() => isRegenerating = true);
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          child: MalaysiaLoading(message: 'Regenerating mystery stop $stop...'),
        ),
      ),
    );

    MissionRecommendation? updated;
    try {
      updated = await facade.regenerateStop(mission.id!, stop);
    } finally {
      if (navigator.mounted) navigator.pop();
      if (mounted) setState(() => isRegenerating = false);
    }

    if (!mounted) return;
    if (updated == null) {
      _showOperationError();
      return;
    }
    final index = recommendations.indexWhere((item) => item.id == mission.id);
    if (index >= 0) recommendations[index] = updated;
    selected = updated;
    if (!sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mystery stop $stop was regenerated.')),
    );
  }

  Future<void> _saveMission(MissionRecommendation mission) async {
    final recommendationId = mission.id;
    if (recommendationId == null) {
      await Navigator.pushNamed(context, '/play/demo');
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: MalaysiaLoading(message: 'Saving your mystery route...'),
      ),
    );
    try {
      final launch = await facade.selectMission(recommendationId);
      if (!mounted) return;
      Navigator.pop(context);
      if (launch == null) {
        _showOperationError();
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ActiveMissionView(
            facade: AppDependencies.activeMission(launch: launch),
          ),
        ),
      );
    } catch (_) {
      if (mounted) Navigator.pop(context);
      rethrow;
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
      builder: (_) => const Dialog(
        child: MalaysiaLoading(message: 'Preparing the shared adventure...'),
      ),
    );
    try {
      final sessionId = await facade.createSharedMission(mission.id!);
      if (!mounted) return;
      Navigator.pop(context);
      if (sessionId == null) {
        _showOperationError();
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SharedMissionView(
            facade: AppDependencies.collaborativeTravel(sessionId: sessionId),
          ),
        ),
      );
    } catch (_) {
      if (mounted) Navigator.pop(context);
      rethrow;
    }
  }

  void _showOperationError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          facade.operationError ?? 'The request could not be completed.',
        ),
      ),
    );
  }
}
