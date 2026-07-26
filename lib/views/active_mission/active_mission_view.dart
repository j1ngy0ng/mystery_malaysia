import 'package:flutter/material.dart';

import '../../controllers/active_mission/active_mission_controller.dart';
import '../../models/active_mission/mission_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/mission_map.dart';
import '../widgets/status_pill.dart';

class ActiveMissionView extends StatefulWidget {
  const ActiveMissionView({super.key});

  @override
  State<ActiveMissionView> createState() => _ActiveMissionViewState();
}

class _ActiveMissionViewState extends State<ActiveMissionView> {
  final controller = ActiveMissionController();

  @override
  void initState() {
    super.initState();
    controller.refreshLocation();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final session = controller.session;
        final paused = session.status == MissionStatus.paused;
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
                        label: paused ? 'Paused' : 'Live',
                        icon: paused
                            ? Icons.pause_rounded
                            : Icons.navigation_rounded,
                        color: paused ? AppColors.purple : AppColors.green,
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
                        focus: ActiveMissionController.mysteryZone,
                        currentLocation: controller.currentLocation,
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
                                  '${session.distanceMetres} m from the mystery zone',
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
                  if (controller.locationError != null) ...[
                    const SizedBox(height: 12),
                    _LocationErrorCard(
                      message: controller.locationError!,
                      onRetry: controller.refreshLocation,
                    ),
                  ],
                  const SizedBox(height: 18),
                  _TemperatureCard(
                    temperature: controller.temperature,
                    distance: session.distanceMetres,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: paused
                              ? null
                              : () => Navigator.pushNamed(
                                  context,
                                  '/play/demo/clue',
                                ),
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: const Text('View clue'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: controller.togglePause,
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
                  const _TrailStep(
                    number: '1',
                    title: 'A flavour from the past',
                    subtitle: 'Completed • Kampung Baru',
                    completed: true,
                  ),
                  const _TrailStep(
                    number: '2',
                    title: 'Petals of glass',
                    subtitle: 'Current mystery',
                    active: true,
                  ),
                  const _TrailStep(
                    number: '3',
                    title: 'Locked destination',
                    subtitle: 'Finish stage 2 to unlock',
                  ),
                ],
              ),
              if (paused)
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
                            const Text('⏸️', style: TextStyle(fontSize: 52)),
                            const SizedBox(height: 12),
                            Text(
                              'Mission paused',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your stage, clue and progress are safely saved.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: controller.togglePause,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Resume mission'),
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
          bottomNavigationBar: paused
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: controller.canConfirmArrival
                            ? AppColors.green
                            : AppColors.hibiscus,
                      ),
                      onPressed: controller.isLocating
                          ? null
                          : controller.canConfirmArrival
                          ? () => _showArrival(context)
                          : controller.refreshLocation,
                      icon: controller.isLocating
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              controller.canConfirmArrival
                                  ? Icons.location_on_rounded
                                  : Icons.my_location_rounded,
                            ),
                      label: Text(
                        controller.isLocating
                            ? 'Checking your location...'
                            : controller.canConfirmArrival
                            ? 'Confirm I have arrived'
                            : 'Refresh GPS location',
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
            onPressed: () {
              controller.abandon();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  void _showArrival(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: const BoxDecoration(
                color: AppColors.paleMango,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🕌', style: TextStyle(fontSize: 52)),
            ),
            const SizedBox(height: 18),
            Text(
              'Destination revealed!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sultan Abdul Samad Jamek Mosque',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'One of Kuala Lumpur’s oldest mosques, standing where the Klang and Gombak rivers meet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Collect stamp & continue'),
              ),
            ),
          ],
        ),
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
  const _TemperatureCard({required this.temperature, required this.distance});

  final String temperature;
  final int distance;

  @override
  Widget build(BuildContext context) {
    final hot = distance <= 350;
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
                      : 'Try moving toward the highlighted search area.',
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
