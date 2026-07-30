import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/mission_discovery/mission_discovery_facade_interface.dart';
import 'recommendations_view.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/status_pill.dart';

class MissionBuilderView extends StatefulWidget {
  const MissionBuilderView({required this.facade, super.key});

  final IMissionDiscoveryFacade facade;

  @override
  State<MissionBuilderView> createState() => _MissionBuilderViewState();
}

class _MissionBuilderViewState extends State<MissionBuilderView> {
  late final IMissionDiscoveryFacade facade = widget.facade;

  @override
  void initState() {
    super.initState();
    facade.detectCurrentLocation();
  }

  @override
  void dispose() {
    facade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build your mystery')),
      body: AnimatedBuilder(
        animation: facade,
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
                value: facade.selectedCategory,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: facade.categories.map((category) {
                  final selected = facade.selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => facade.selectCategory(category),
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
                value: 'Up to RM ${facade.budget.round()}',
              ),
              Slider(
                value: facade.budget,
                min: 30,
                max: 300,
                divisions: 18,
                label: 'RM ${facade.budget.round()}',
                onChanged: facade.updateBudget,
              ),
              const SizedBox(height: 12),
              _FieldLabel(
                title: 'Available time',
                value: '${facade.duration.round()} hours',
              ),
              Slider(
                value: facade.duration,
                min: 2,
                max: 10,
                divisions: 8,
                label: '${facade.duration.round()}h',
                onChanged: facade.updateDuration,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.my_location_rounded),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Starting near your current location',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(facade.locationError ?? facade.locationLabel),
                        ],
                      ),
                    ),
                    if (facade.isLocating)
                      const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        tooltip: facade.hasLocation
                            ? 'Refresh location'
                            : 'Try location again',
                        onPressed: facade.detectCurrentLocation,
                        icon: Icon(
                          facade.hasLocation
                              ? Icons.check_circle_rounded
                              : Icons.refresh_rounded,
                          color: facade.hasLocation
                              ? AppColors.green
                              : AppColors.hibiscus,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    label: facade.hasLocation
                        ? 'GPS location ready'
                        : 'GPS required',
                    icon: Icons.my_location_rounded,
                    color: facade.hasLocation
                        ? AppColors.green
                        : AppColors.hibiscus,
                  ),
                  const StatusPill(
                    label: 'Online',
                    icon: Icons.wifi_rounded,
                    color: AppColors.straits,
                  ),
                ],
              ),
              if (facade.generationError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.paleHibiscus,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    facade.generationError!,
                    style: const TextStyle(
                      color: AppColors.hibiscus,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: AnimatedBuilder(
            animation: facade,
            builder: (context, _) => FilledButton.icon(
              onPressed: facade.isGenerating || !facade.hasLocation
                  ? null
                  : () async {
                      final generated = await facade.generate();
                      if (!generated || !context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => RecommendationsView(
                            facade: AppDependencies.missionDiscovery(
                              recommendations: facade.recommendations,
                            ),
                            budgetMyr: facade.budget,
                            availableHours: facade.duration,
                          ),
                        ),
                      );
                    },
              icon: facade.isGenerating
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
                facade.isGenerating
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
