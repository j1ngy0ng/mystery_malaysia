import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/passport_diary/passport_diary_facade_interface.dart';
import '../../model/passport_diary/traveller_progress.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/section_header.dart';

class PassportView extends StatefulWidget {
  const PassportView({required this.facade, super.key});

  final IPassportDiaryFacade facade;

  @override
  State<PassportView> createState() => _PassportViewState();
}

class _PassportViewState extends State<PassportView> {
  late final IPassportDiaryFacade facade;

  @override
  void initState() {
    super.initState();
    facade = widget.facade;
    facade.load();
  }

  @override
  void dispose() {
    facade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: facade,
      builder: (context, _) => ListView(
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
              IconButton(
                tooltip: 'Refresh passport',
                onPressed: facade.isLoading ? null : facade.load,
                icon: const Icon(Icons.refresh_rounded),
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
          if (facade.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (facade.error != null)
            Card(
              child: ListTile(
                title: Text(facade.error!),
                trailing: TextButton(
                  onPressed: facade.load,
                  child: const Text('Retry'),
                ),
              ),
            ),
          _LevelCard(facade: facade),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'Your stamps',
            action:
                '${facade.stamps.length} pieces · ${facade.missionStamps.where((stamp) => stamp.complete).length} complete',
            onAction: () {},
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 190,
            ),
            itemCount: facade.missionStamps.length,
            itemBuilder: (context, index) => _MissionStampCard(
              stamp: facade.missionStamps[index],
              onTap: () => _showStamp(facade.missionStamps[index]),
            ),
          ),
          if (!facade.isLoading && facade.stamps.isEmpty)
            const Text(
              'No stamps yet. Each successful GPS arrival verification awards one immediately.',
            ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Achievements'),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: facade.achievements.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _AchievementCard(achievement: facade.achievements[index]),
            ),
          ),
          if (!facade.isLoading && facade.achievements.isEmpty)
            const Text(
              'No achievements yet. Complete all three stops to unlock First Steps; more badges unlock through destinations, states and shared missions.',
            ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Travel statistics'),
          const SizedBox(height: 10),
          if (facade.progress != null)
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Missions',
                    value: facade.progress!.completedMissions,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Destinations',
                    value: facade.progress!.visitedDestinations,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'States',
                    value: facade.progress!.exploredStates,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Travel diary',
            action: 'Open diary',
            onAction: _openDiary,
          ),
          const SizedBox(height: 10),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              onTap: _openDiary,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 42)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${facade.memories.length} AI-crafted memories',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add a reflection and relive your completed missions.',
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDiary() async {
    await Navigator.pushNamed(context, '/diary');
    if (mounted) await facade.load();
  }

  void _showStamp(MissionStamp stamp) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MissionStampEmblem(stamp: stamp, size: 112),
            const SizedBox(height: 12),
            Text(stamp.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${stamp.earnedPieces}/3 destination pieces collected'),
            const SizedBox(height: 14),
            for (var index = 0; index < stamp.pieces.length; index++)
              ListTile(
                dense: true,
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(stamp.pieces[index].place),
                subtitle: Text(stamp.pieces[index].state),
                trailing: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.facade});

  final IPassportDiaryFacade facade;

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
            child: Text(
              '${facade.level}',
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
                  '${facade.xp} / ${facade.nextLevelXp} XP',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 9),
                LinearProgressIndicator(
                  value: facade.levelProgress,
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

class _MissionStampCard extends StatelessWidget {
  const _MissionStampCard({required this.stamp, required this.onTap});

  final MissionStamp stamp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
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
              _MissionStampEmblem(stamp: stamp, size: 82),
              const SizedBox(height: 7),
              const SizedBox(height: 7),
              Text(
                stamp.place,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              Text(
                '${stamp.earnedPieces}/3 pieces',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionStampEmblem extends StatelessWidget {
  const _MissionStampEmblem({required this.stamp, required this.size});

  final MissionStamp stamp;
  final double size;

  static const icons = [
    Icons.local_florist_rounded,
    Icons.temple_buddhist_rounded,
    Icons.hiking_rounded,
    Icons.museum_rounded,
    Icons.park_rounded,
    Icons.storefront_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final seed = _stableSeed(stamp.id);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _StampPiecesPainter(
              missionSeed: seed,
              pieceSeeds: stamp.pieces
                  .take(3)
                  .map((piece) => _stableSeed(piece.place))
                  .toList(growable: false),
            ),
          ),
          Container(
            width: size * .43,
            height: size * .43,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icons[seed % icons.length],
              size: size * .25,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _StampPiecesPainter extends CustomPainter {
  const _StampPiecesPainter({
    required this.missionSeed,
    required this.pieceSeeds,
  });

  final int missionSeed;
  final List<int> pieceSeeds;

  static const colors = [
    AppColors.hibiscus,
    AppColors.mango,
    AppColors.teal,
    AppColors.purple,
    AppColors.green,
    AppColors.straits,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fill = Paint()..style = PaintingStyle.fill;
    const sweep = math.pi * 2 / 3;
    for (var index = 0; index < 3; index++) {
      fill.color = index < pieceSeeds.length
          ? colors[pieceSeeds[index] % colors.length]
          : AppColors.outline;
      canvas.drawArc(rect, -math.pi / 2 + index * sweep, sweep, true, fill);
    }
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide / 2 - 1,
      Paint()
        ..color = colors[missionSeed % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final divider = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var index = 0; index < 3; index++) {
      final angle = -math.pi / 2 + index * sweep;
      canvas.drawLine(
        size.center(Offset.zero),
        size.center(Offset.zero) +
            Offset(math.cos(angle), math.sin(angle)) * size.shortestSide / 2,
        divider,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StampPiecesPainter oldDelegate) =>
      oldDelegate.missionSeed != missionSeed ||
      oldDelegate.pieceSeeds.join(',') != pieceSeeds.join(',');
}

int _stableSeed(String value) =>
    value.codeUnits.fold(0, (seed, unit) => (seed * 31 + unit) & 0x7fffffff);

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    height: 92,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.paleTeal,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$value', style: Theme.of(context).textTheme.titleLarge),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
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
        color: achievement.earned ? AppColors.paleTeal : AppColors.outline,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Opacity(
        opacity: achievement.earned ? 1 : .55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AchievementEmblem(achievement: achievement),
            const Spacer(),
            Text(
              achievement.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementEmblem extends StatelessWidget {
  const _AchievementEmblem({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final seed = _stableSeed(achievement.name);
    const colors = [
      AppColors.hibiscus,
      AppColors.teal,
      AppColors.purple,
      AppColors.green,
      AppColors.straits,
    ];
    final icon = switch (achievement.name) {
      'First Steps' => Icons.flag_rounded,
      'Clue Cracker' => Icons.key_rounded,
      'Jalan-Jalan' => Icons.travel_explore_rounded,
      'Team Spirit' => Icons.groups_rounded,
      _ => Icons.auto_awesome_rounded,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[seed % colors.length],
            colors[(seed + 2) % colors.length],
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        achievement.earned ? icon : Icons.lock_rounded,
        color: Colors.white,
        size: 25,
      ),
    );
  }
}
