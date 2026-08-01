import 'dart:async';

import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/active_mission/active_mission_facade_interface.dart';
import '../../model/active_mission/destination_guide.dart';
import '../../model/active_mission/mission_session.dart';
import '../clue_hint/clue_view.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/mission_map.dart';
import '../../widgets/status_pill.dart';

class ActiveMissionView extends StatefulWidget {
  const ActiveMissionView({required this.facade, super.key});

  final IActiveMissionFacade facade;

  @override
  State<ActiveMissionView> createState() => _ActiveMissionViewState();
}

class _ActiveMissionViewState extends State<ActiveMissionView> {
  late final IActiveMissionFacade facade;
  Timer? locationTimer;
  bool arrivalSheetOpen = false;

  @override
  void initState() {
    super.initState();
    facade = widget.facade;
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackLocation());
    if (facade.sessionId != null) {
      locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
        if (facade.session.status == MissionStatus.active &&
            !facade.isLocating &&
            !facade.isVerifying &&
            !arrivalSheetOpen) {
          await _trackLocation();
        }
      });
    }
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    facade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: facade,
      builder: (context, _) {
        final session = facade.session;
        final paused = session.status == MissionStatus.paused;
        final ready = session.status == MissionStatus.ready;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Active mission'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'abandon') _confirmAbandon(context);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'abandon',
                    child: Text('Abandon mission'),
                  ),
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${session.region} • Stage ${session.currentStage} of ${session.totalStages}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      StatusPill(
                        label: ready
                            ? 'Ready'
                            : paused
                            ? 'Paused'
                            : 'Live',
                        icon: ready
                            ? Icons.flag_circle_outlined
                            : paused
                            ? Icons.pause_rounded
                            : Icons.navigation_rounded,
                        color: ready
                            ? AppColors.mango
                            : paused
                            ? AppColors.purple
                            : AppColors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: session.progress,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(99),
                    color: AppColors.hibiscus,
                    backgroundColor: AppColors.paleHibiscus,
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      MissionMap(
                        currentLocation: facade.currentLocation,
                        height: 290,
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        top: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                color: AppColors.straits,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  facade.mapStatus,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (facade.locationError != null) ...[
                    const SizedBox(height: 12),
                    _LocationErrorCard(
                      message: facade.locationError!,
                      onRetry: _trackLocation,
                    ),
                  ],
                  if (facade.arrivalError != null) ...[
                    const SizedBox(height: 12),
                    _LocationErrorCard(
                      message: facade.arrivalError!,
                      onRetry: _trackLocation,
                    ),
                  ],
                  const SizedBox(height: 18),
                  _TemperatureCard(temperature: facade.temperature),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: paused || ready
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ClueView(
                                      facade: AppDependencies.clueHint(
                                        clue: facade.currentClue,
                                        sessionId: facade.sessionId,
                                      ),
                                      totalStages: session.totalStages,
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: const Text('View clue'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: facade.isUpdatingStatus
                              ? null
                              : () => _togglePause(context),
                          icon: Icon(
                            paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                          label: Text(paused ? 'Resume' : 'Pause'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Mission trail',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (var stage = 1; stage <= session.totalStages; stage++)
                    _TrailStep(
                      number: '$stage',
                      title: 'Mystery stage $stage',
                      subtitle: stage < session.currentStage
                          ? 'Destination verified'
                          : stage == session.currentStage
                          ? 'Current mystery'
                          : 'Complete stage ${stage - 1} to unlock',
                      completed: stage < session.currentStage,
                      active: stage == session.currentStage,
                    ),
                ],
              ),
              if (paused || ready)
                Positioned.fill(
                  child: Container(
                    color: AppColors.canvas.withValues(alpha: .88),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(30),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ready ? '🧭' : '⏸️',
                              style: const TextStyle(fontSize: 52),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ready ? 'Mission ready' : 'Mission paused',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ready
                                  ? 'Your chosen mystery is saved. Start whenever you are ready to begin location tracking.'
                                  : 'Your stage, clue and progress are safely saved.',
                              textAlign: TextAlign.center,
                            ),
                            if (facade.arrivalError != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                facade.arrivalError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.hibiscus,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: facade.isUpdatingStatus
                                    ? null
                                    : ready
                                    ? _startMission
                                    : () => _togglePause(context),
                                icon: facade.isUpdatingStatus
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.play_arrow_rounded),
                                label: Text(
                                  ready ? 'Start mission' : 'Resume mission',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar:
              paused || ready || session.status == MissionStatus.completed
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paleHibiscus,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          if (facade.isLocating || facade.isVerifying)
                            const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.hibiscus,
                              ),
                            )
                          else
                            const Icon(
                              Icons.location_searching_rounded,
                              color: AppColors.hibiscus,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              facade.isLocating
                                  ? 'Checking your location...'
                                  : facade.isVerifying
                                  ? 'Verifying arrival automatically...'
                                  : 'Arrival verification is automatic while this mission is open.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _confirmAbandon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon this mission?'),
        content: const Text(
          'This adventure will not count as completed and GPS tracking will stop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () async {
              final abandoned = await facade.abandon();
              if (!abandoned || !context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePause(BuildContext context) async {
    if (facade.session.status == MissionStatus.paused) {
      final resumed = await facade.togglePause();
      if (resumed) await _trackLocation();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause this mission?'),
        content: const Text(
          'Your current stage and progress will be saved for later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pause mission'),
          ),
        ],
      ),
    );
    if (confirmed == true) await facade.togglePause();
  }

  Future<void> _startMission() async {
    final started = await facade.start();
    if (started) await _trackLocation();
  }

  Future<void> _trackLocation() async {
    if (!mounted ||
        arrivalSheetOpen ||
        facade.isLocating ||
        facade.isVerifying ||
        facade.session.status != MissionStatus.active) {
      return;
    }
    final result = await facade.refreshLocation();
    if (!mounted || result == null) return;
    arrivalSheetOpen = true;
    await _showDestinationGuide(result);
    arrivalSheetOpen = false;
  }

  Future<void> _showDestinationGuide(ArrivalResult result) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _DestinationGuideSheet(result: result),
    );
  }
}

class _DestinationGuideSheet extends StatelessWidget {
  const _DestinationGuideSheet({required this.result});

  final ArrivalResult result;

  @override
  Widget build(BuildContext context) {
    final guide = result.guide!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .9,
      minChildSize: .65,
      maxChildSize: .96,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
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
          const SizedBox(height: 22),
          const Icon(
            Icons.celebration_rounded,
            size: 58,
            color: AppColors.mango,
          ),
          const SizedBox(height: 12),
          Text(
            'Destination revealed!',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            guide.name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (guide.imageUrl != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Image.network(
                guide.imageUrl!,
                height: 210,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            if (guide.photoAttributions.isNotEmpty)
              Text(
                'Photo: ${guide.photoAttributions.join(', ')}',
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
          ],
          const SizedBox(height: 6),
          Text(
            [
              guide.city,
              guide.state,
            ].where((text) => text.isNotEmpty).join(', '),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const StatusPill(
                label: 'GPS verified',
                icon: Icons.verified_rounded,
                color: AppColors.green,
              ),
              const StatusPill(
                label: 'Stamp collected',
                icon: Icons.approval_rounded,
                color: AppColors.hibiscus,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _GuideSection(
            icon: Icons.menu_book_rounded,
            title: 'Why this place matters',
            color: AppColors.paleMango,
            children: [
              Text(guide.learningSummary),
              for (final fact in guide.facts.skip(1)) ...[
                const SizedBox(height: 8),
                Text('• $fact'),
              ],
              if (guide.educationalSource != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Source: ${guide.educationalSource}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (guide.summaryDisclosure != null)
                Text(
                  guide.summaryDisclosure!,
                  style: const TextStyle(fontSize: 12),
                ),
              for (final source in guide.educationalSources) ...[
                const SizedBox(height: 6),
                SelectableText(
                  '${source.title}\n${source.uri}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _GuideSection(
            icon: Icons.diversity_1_rounded,
            title: 'Cultural etiquette',
            color: AppColors.paleHibiscus,
            children: [
              for (final note in guide.culturalEtiquette) Text('• $note'),
            ],
          ),
          const SizedBox(height: 14),
          _GuideSection(
            icon: Icons.health_and_safety_outlined,
            title: 'Safety before you explore',
            color: const Color(0xFFE4F2FF),
            children: [
              for (final note in guide.safetyNotes) Text('• $note'),
              if (guide.safetyScore != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Automated tourist-suitability score: '
                  '${(guide.safetyScore! * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _GuideSection(
            icon: Icons.schedule_rounded,
            title: 'Weekly opening hours',
            color: AppColors.paleTeal,
            children: guide.weeklyHours.isEmpty
                ? const [
                    Text(
                      'Weekly hours were not supplied. Check current signs or the official venue listing before entering.',
                    ),
                  ]
                : [for (final hours in guide.weeklyHours) Text(hours)],
          ),
          if (guide.visitorNotes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _GuideSection(
              icon: Icons.explore_rounded,
              title: 'Visitor guidance',
              color: AppColors.paleTeal,
              children: [
                for (final note in guide.visitorNotes) Text('• $note'),
              ],
            ),
          ],
          if (guide.accessibilityNotes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _GuideSection(
              icon: Icons.accessible_rounded,
              title: 'Accessibility',
              color: const Color(0xFFE4F2FF),
              children: [
                for (final note in guide.accessibilityNotes) Text('• $note'),
              ],
            ),
          ],
          if (guide.googleRating != null || guide.openNow != null) ...[
            const SizedBox(height: 14),
            _GuideSection(
              icon: Icons.info_outline_rounded,
              title: 'Current visitor information',
              color: AppColors.paleHibiscus,
              children: [
                if (guide.openNow != null)
                  Text(guide.openNow! ? 'Open now' : 'Currently closed'),
                if (guide.googleRating != null)
                  Text(
                    '${guide.googleRating!.toStringAsFixed(1)} Google rating'
                    '${guide.googleUserRatingCount == null ? '' : ' from ${guide.googleUserRatingCount} reviews'}',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Opening conditions and accessibility can change. Follow signs, staff instructions and local cultural etiquette.',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (result.missionCompleted) Navigator.pop(context);
            },
            icon: Icon(
              result.missionCompleted
                  ? Icons.emoji_events_rounded
                  : result.waitingForMembers
                  ? Icons.groups_rounded
                  : Icons.arrow_forward_rounded,
            ),
            label: Text(
              result.missionCompleted
                  ? 'Finish mission'
                  : result.waitingForMembers
                  ? 'Wait for the group'
                  : 'Continue to next clue',
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 9),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _LocationErrorCard extends StatelessWidget {
  const _LocationErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paleHibiscus,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded, color: AppColors.hibiscus),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _TemperatureCard extends StatelessWidget {
  const _TemperatureCard({required this.temperature});

  final String temperature;

  @override
  Widget build(BuildContext context) {
    final hot = temperature == 'Hot' || temperature == 'Destination reached!';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hot
              ? [AppColors.paleMango, AppColors.paleHibiscus]
              : [AppColors.paleTeal, const Color(0xFFE4F2FF)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Text(hot ? '🔥' : '🧊', style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temperature,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  hot
                      ? 'Your hidden gem is close. Keep exploring!'
                      : 'Use your clue and keep exploring nearby.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailStep extends StatelessWidget {
  const _TrailStep({
    required this.number,
    required this.title,
    required this.subtitle,
    this.completed = false,
    this.active = false,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: completed
                ? AppColors.green
                : active
                ? AppColors.mango
                : AppColors.outline,
            child: completed
                ? const Icon(Icons.check, color: Colors.white)
                : Text(
                    number,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
