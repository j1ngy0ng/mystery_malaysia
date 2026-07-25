import 'package:flutter/material.dart';

import '../../controllers/mission_discovery/mission_discovery_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_pill.dart';

class MissionBuilderView extends StatefulWidget {
  const MissionBuilderView({super.key});

  @override
  State<MissionBuilderView> createState() => _MissionBuilderViewState();
}

class _MissionBuilderViewState extends State<MissionBuilderView> {
  final controller = MissionDiscoveryController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build your mystery')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  children: [
                    const Text('🧭', style: TextStyle(fontSize: 46)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set the vibe, not the place',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'We keep every destination secret until you arrive.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _FieldLabel(
                title: 'What sounds fun?',
                value: controller.selectedCategory,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: controller.categories.map((category) {
                  final selected = controller.selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => controller.selectCategory(category),
                    selectedColor: AppColors.paleHibiscus,
                    side: BorderSide(
                      color: selected ? AppColors.hibiscus : AppColors.outline,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 26),
              _FieldLabel(
                title: 'Budget',
                value: 'Up to RM ${controller.budget.round()}',
              ),
              Slider(
                value: controller.budget,
                min: 30,
                max: 300,
                divisions: 18,
                label: 'RM ${controller.budget.round()}',
                onChanged: controller.updateBudget,
              ),
              const SizedBox(height: 12),
              _FieldLabel(
                title: 'Available time',
                value: '${controller.duration.round()} hours',
              ),
              Slider(
                value: controller.duration,
                min: 2,
                max: 10,
                divisions: 8,
                label: '${controller.duration.round()}h',
                onChanged: controller.updateDuration,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.my_location_rounded),
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starting near your current location',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text('Bukit Bintang, Kuala Lumpur • GPS detected'),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_rounded, color: AppColors.green),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  StatusPill(
                    label: 'GPS location ready',
                    icon: Icons.my_location_rounded,
                    color: AppColors.green,
                  ),
                  SizedBox(width: 8),
                  StatusPill(
                    label: 'Online',
                    icon: Icons.wifi_rounded,
                    color: AppColors.straits,
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => FilledButton.icon(
              onPressed: controller.isGenerating
                  ? null
                  : () async {
                      await controller.generate();
                      if (!context.mounted) return;
                      Navigator.pushNamed(context, '/missions/demo/preview');
                    },
              icon: controller.isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                controller.isGenerating
                    ? 'Finding hidden gems...'
                    : 'Generate mysterious missions',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.teal,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
