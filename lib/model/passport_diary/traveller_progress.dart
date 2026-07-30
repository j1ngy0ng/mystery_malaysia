class PassportStamp {
  const PassportStamp({
    required this.place,
    required this.state,
    required this.emoji,
    required this.earned,
    this.name = '',
    this.rarity = 'common',
    this.earnedAt,
    this.sessionId,
  });

  final String place;
  final String state;
  final String emoji;
  final bool earned;
  final String name;
  final String rarity;
  final DateTime? earnedAt;
  final String? sessionId;

  factory PassportStamp.fromJson(Map<String, dynamic> json) => PassportStamp(
    place: json['place'] as String? ?? 'Mystery destination',
    state: json['state'] as String? ?? 'Malaysia',
    emoji: json['rarity'] == 'legendary' ? '🏆' : '🏅',
    earned: true,
    name: json['name'] as String? ?? '',
    rarity: json['rarity'] as String? ?? 'common',
    earnedAt: DateTime.tryParse(json['earned_at'] as String? ?? ''),
    sessionId: json['session_id'] as String?,
  );
}

class MissionStamp {
  const MissionStamp({required this.id, required this.pieces});

  final String id;
  final List<PassportStamp> pieces;

  int get earnedPieces => pieces.length > 3 ? 3 : pieces.length;
  bool get earned => earnedPieces > 0;
  bool get complete => earnedPieces == 3;
  String get state {
    final states = pieces.map((piece) => piece.state).toSet();
    return states.length == 1 ? states.first : 'Malaysia';
  }

  String get name => '$state Mystery Trail';
  String get place => name;
  String get emoji => '';
}

class Achievement {
  const Achievement({
    required this.name,
    required this.description,
    required this.emoji,
    this.earned = false,
    this.earnedAt,
  });

  final String name;
  final String description;
  final String emoji;
  final bool earned;
  final DateTime? earnedAt;

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    name: json['name'] as String? ?? 'Achievement',
    description: json['description'] as String? ?? '',
    earned: json['earned'] == true,
    emoji: '🎖️',
    earnedAt: DateTime.tryParse(json['earned_at'] as String? ?? ''),
  );
}

class DiaryMemory {
  const DiaryMemory({
    required this.title,
    required this.date,
    required this.summary,
    required this.emoji,
    this.id,
    this.sessionId,
  });

  final String? id;
  final String? sessionId;
  final String title;
  final String date;
  final String summary;
  final String emoji;

  factory DiaryMemory.fromJson(Map<String, dynamic> json) {
    final updated = DateTime.tryParse(
      json['updated_at'] as String? ?? '',
    )?.toLocal();
    return DiaryMemory(
      id: json['id'] as String?,
      sessionId: json['session_id'] as String?,
      title: json['title'] as String? ?? 'Travel memory',
      date: updated == null
          ? ''
          : '${updated.day}/${updated.month}/${updated.year}',
      summary: json['summary'] as String? ?? '',
      emoji: '✍️',
    );
  }
}

class TravellerProgress {
  const TravellerProgress({
    required this.xp,
    required this.level,
    required this.levelStartXp,
    required this.nextLevelXp,
    required this.completedMissions,
    required this.visitedDestinations,
    required this.exploredStates,
    required this.stamps,
    required this.achievements,
    required this.memories,
    required this.newBadges,
  });

  final int xp;
  final int level;
  final int levelStartXp;
  final int nextLevelXp;
  final int completedMissions;
  final int visitedDestinations;
  final int exploredStates;
  final List<PassportStamp> stamps;
  final List<Achievement> achievements;
  final List<DiaryMemory> memories;
  final List<String> newBadges;

  double get levelProgress =>
      ((xp - levelStartXp) / (nextLevelXp - levelStartXp)).clamp(0, 1);

  factory TravellerProgress.fromJson(Map<String, dynamic> json) {
    final stats = Map<String, dynamic>.from(json['stats'] as Map? ?? {});
    return TravellerProgress(
      xp: (json['xp'] as num?)?.round() ?? 0,
      level: (json['level'] as num?)?.round() ?? 1,
      levelStartXp: (json['level_start_xp'] as num?)?.round() ?? 0,
      nextLevelXp: (json['next_level_xp'] as num?)?.round() ?? 500,
      completedMissions: (stats['completed_missions'] as num?)?.round() ?? 0,
      visitedDestinations:
          (stats['visited_destinations'] as num?)?.round() ?? 0,
      exploredStates: (stats['explored_states'] as num?)?.round() ?? 0,
      stamps: _maps(json['stamps']).map(PassportStamp.fromJson).toList(),
      achievements: _maps(json['badges']).map(Achievement.fromJson).toList(),
      memories: _maps(json['diaries']).map(DiaryMemory.fromJson).toList(),
      newBadges:
          (json['newly_unlocked_badges'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }

  static Iterable<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from)
      : const [];
}
