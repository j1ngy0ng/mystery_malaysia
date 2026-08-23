import 'package:flutter/material.dart';

import '../../controller/clue_hint/clue_hint_facade_interface.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/status_pill.dart';

class ClueView extends StatefulWidget {
  const ClueView({required this.facade, super.key, this.totalStages = 3});

  final IClueHintFacade facade;
  final int totalStages;

  @override
  State<ClueView> createState() => _ClueViewState();
}

class _ClueViewState extends State<ClueView> {
  late final IClueHintFacade facade;

  @override
  void initState() {
    super.initState();
    facade = widget.facade;
    facade.recordViewed();
  }

  @override
  void dispose() {
    facade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mystery clue')),
      body: AnimatedBuilder(
        animation: facade,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(
                children: [
                  StatusPill(
                    label:
                        'Stage ${facade.clue.number} of ${widget.totalStages}',
                    icon: Icons.flag_outlined,
                    color: AppColors.purple,
                  ),
                  const Spacer(),
                  StatusPill(
                    label: facade.clue.hintRevealed
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
                'Clue #${facade.clue.number}',
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
                  '“${facade.clue.text}”',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (facade.clue.hintRevealed) ...[
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
                            Text(facade.clue.hint),
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
                            'Use the clue and Hot & Cold signal to explore. The map shows only your location, and the destination is revealed after GPS confirms your arrival.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (facade.error != null) ...[
                Text(
                  facade.error!,
                  style: const TextStyle(color: AppColors.hibiscus),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                onPressed: facade.clue.hintRevealed || facade.isLoading
                    ? null
                    : () => _confirmHint(context),
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: Text(
                  facade.clue.hintRevealed
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
            onPressed: () async {
              final revealed = await facade.revealHint();
              if (revealed && context.mounted) Navigator.pop(context);
            },
            child: const Text('Reveal hint'),
          ),
        ],
      ),
    );
  }
}
