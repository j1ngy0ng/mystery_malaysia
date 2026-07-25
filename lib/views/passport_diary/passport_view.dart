import 'package:flutter/material.dart';

import '../../controllers/passport_diary/passport_diary_controller.dart';
import '../../models/passport_diary/traveller_progress.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/section_header.dart';

class PassportView extends StatefulWidget {
  const PassportView({super.key});

  @override
  State<PassportView> createState() => _PassportViewState();
}

class _PassportViewState extends State<PassportView> {
  final controller = PassportDiaryController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Digital passport',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const Text('🇲🇾', style: TextStyle(fontSize: 38)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Every solved mystery leaves a story behind.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        _LevelCard(controller: controller),
        const SizedBox(height: 26),
        SectionHeader(title: 'Your stamps', action: '3 / 6', onAction: () {}),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .82,
          ),
          itemCount: controller.stamps.length,
          itemBuilder: (context, index) =>
              _StampCard(stamp: controller.stamps[index]),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Achievements'),
        const SizedBox(height: 10),
        SizedBox(
          height: 145,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.achievements.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _AchievementCard(achievement: controller.achievements[index]),
          ),
        ),
        const SizedBox(height: 28),
        SectionHeader(
          title: 'Travel diary',
          action: 'Open diary',
          onAction: () => Navigator.pushNamed(context, '/diary'),
        ),
        const SizedBox(height: 10),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: () => Navigator.pushNamed(context, '/diary'),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Text('📖', style: TextStyle(fontSize: 42)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2 AI-crafted memories',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add a reflection and relive your completed missions.',
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.controller});

  final PassportDiaryController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.purple, AppColors.straits],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: AppColors.mango,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '7',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hidden Gem Hunter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.xp} / ${controller.nextLevelXp} XP',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 9),
                LinearProgressIndicator(
                  value: controller.levelProgress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.mango,
                  backgroundColor: Colors.white24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  const _StampCard({required this.stamp});

  final PassportStamp stamp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: stamp.earned
            ? Colors.white
            : AppColors.outline.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: stamp.earned ? AppColors.mango : AppColors.outline,
          width: stamp.earned ? 2 : 1,
        ),
      ),
      child: Opacity(
        opacity: stamp.earned ? 1 : .38,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stamp.earned ? stamp.emoji : '🔒',
              style: const TextStyle(fontSize: 31),
            ),
            const SizedBox(height: 7),
            Text(
              stamp.place,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            Text(
              stamp.state,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paleTeal,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(achievement.emoji, style: const TextStyle(fontSize: 34)),
          const Spacer(),
          Text(
            achievement.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Text(
            achievement.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
