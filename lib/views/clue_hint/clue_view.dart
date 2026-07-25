import 'package:flutter/material.dart';

import '../../controllers/clue_hint/clue_hint_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_pill.dart';

class ClueView extends StatefulWidget {
  const ClueView({super.key});

  @override
  State<ClueView> createState() => _ClueViewState();
}

class _ClueViewState extends State<ClueView> {
  final controller = ClueHintController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mystery clue')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(
                children: [
                  const StatusPill(
                    label: 'Stage 2 of 3',
                    icon: Icons.flag_outlined,
                    color: AppColors.purple,
                  ),
                  const Spacer(),
                  StatusPill(
                    label: controller.clue.hintRevealed
                        ? 'Hint used'
                        : '1 hint left',
                    icon: Icons.lightbulb_outline_rounded,
                    color: AppColors.mango,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.paleHibiscus,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔎', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Clue #${controller.clue.number}',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.straits,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.straits.withValues(alpha: .2),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Text(
                  '“${controller.clue.text}”',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (controller.clue.hintRevealed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.paleMango,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.hibiscus,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your one extra hint',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            Text(controller.clue.hint),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.my_location_rounded, color: AppColors.teal),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arrival is verified by location',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Return to the map and follow the Hot & Cold signal. The destination is revealed only after GPS confirms you are inside the geofence.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: controller.clue.hintRevealed
                    ? null
                    : () => _confirmHint(context),
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: Text(
                  controller.clue.hintRevealed
                      ? 'Hint already used'
                      : 'Request one additional hint',
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Back to location verification'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmHint(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Text('💡', style: TextStyle(fontSize: 42)),
        title: const Text('Use your only hint?'),
        content: const Text(
          'Each destination allows one additional hint. You cannot request another for this stage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep thinking'),
          ),
          FilledButton(
            onPressed: () {
              controller.revealHint();
              Navigator.pop(context);
            },
            child: const Text('Reveal hint'),
          ),
        ],
      ),
    );
  }
}
