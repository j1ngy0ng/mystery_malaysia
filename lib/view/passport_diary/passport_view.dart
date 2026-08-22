import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/passport_diary/passport_diary_facade_interface.dart';
import '../../model/passport_diary/traveller_progress.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../section_header.dart';
import '../malaysia_loading.dart';

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
      builder: (context, _) => MalaysiaLoadingBlocker(
        loading: facade.isLoading,
        message: 'Opening your passport...',
        child: ListView(
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
            if (facade.error != null)
              Card(
                child: ListTile(
                  title: Text(facade.error!),
                  trailing: TextButton(
                    onPressed: facade.load,
                    child: const Text('Retry'),
                  ),
                ),
              ),
            const SectionHeader(title: 'Mission badges'),
            const SizedBox(height: 4),
            Text(
              '${facade.stamps.length} pieces · ${facade.missionStamps.where((stamp) => stamp.complete).length} complete',
              style: Theme.of(context).textTheme.bodyMedium,
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
                'No mission badges yet. Each GPS-verified destination adds one of three state badge pieces.',
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
            const SectionHeader(title: 'Travel diary'),
            const SizedBox(height: 10),
            if (facade.eligibleDiaryMissions.isNotEmpty) ...[
              for (final mission in facade.eligibleDiaryMissions)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.paleMango,
                      foregroundColor: AppColors.hibiscus,
                      child: Icon(Icons.auto_stories_rounded),
                    ),
                    title: Text(mission.title),
                    subtitle: Text(
                      mission.mode == 'collaborative'
                          ? 'Crew reflections needed for one shared diary'
                          : 'Eligible for an AI travel diary',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openDiaryFor(mission.sessionId),
                  ),
                ),
              const SizedBox(height: 4),
            ],
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Only eligible completed missions can become new diaries.',
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
      ),
    );
  }

  Future<void> _openDiary() async {
    await Navigator.pushNamed(context, '/diary');
    if (mounted) await facade.load();
  }

  Future<void> _openDiaryFor(String sessionId) async {
    await Navigator.pushNamed(context, '/diary', arguments: sessionId);
    if (mounted) await facade.load();
  }

  void _showStamp(MissionStamp stamp) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MissionStampEmblem(stamp: stamp, size: 112),
              const SizedBox(height: 12),
              Text(
                stamp.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('${stamp.earnedPieces}/3 destination pieces collected'),
              const SizedBox(height: 8),
              Text(
                '${stamp.state} mission badge',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              for (var index = 0; index < stamp.pieces.length; index++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
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
              _MissionStampEmblem(stamp: stamp, size: 78),
              const SizedBox(height: 7),
              Flexible(
                child: Text(
                  stamp.place,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),
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

  @override
  Widget build(BuildContext context) {
    final code = missionBadgeCode(stamp.state);
    final asset = code == 'MYS'
        ? 'assets/images/mystery_malaysia_logo-v2.png'
        : 'assets/images/state_badges/${code.toLowerCase()}.webp';
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: Image.asset(
              asset,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _StateBadgePiecesPainter(stamp.earnedPieces),
          ),
          Positioned(
            bottom: size * .05,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * .08,
                vertical: size * .02,
              ),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: .82),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                code,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * .08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBadgePiecesPainter extends CustomPainter {
  const _StateBadgePiecesPainter(this.earnedPieces);

  final int earnedPieces;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const sweep = math.pi * 2 / 3;
    for (var index = earnedPieces; index < 3; index++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + index * sweep,
        sweep,
        true,
        Paint()..color = AppColors.outline.withValues(alpha: .93),
      );
    }
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide / 2 - 1,
      Paint()
        ..color = AppColors.mango
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
  bool shouldRepaint(covariant _StateBadgePiecesPainter oldDelegate) =>
      oldDelegate.earnedPieces != earnedPieces;
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
