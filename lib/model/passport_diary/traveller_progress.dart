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
    this.missionTitle,
  });

  final String place;
  final String state;
  final String emoji;
  final bool earned;
  final String name;
  final String rarity;
  final DateTime? earnedAt;
  final String? sessionId;
  final String? missionTitle;

  factory PassportStamp.fromJson(Map<String, dynamic> json) => PassportStamp(
    place: json['place'] as String? ?? 'Mystery destination',
    state: json['state'] as String? ?? 'Malaysia',
    emoji: json['rarity'] == 'legendary' ? '🏆' : '🏅',
    earned: true,
    name: json['name'] as String? ?? '',
    rarity: json['rarity'] as String? ?? 'common',
    earnedAt: DateTime.tryParse(json['earned_at'] as String? ?? ''),
    sessionId: json['session_id'] as String?,
    missionTitle: json['mission_title'] as String?,
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
    if (pieces.isEmpty) return 'Malaysia';
    final badgeCodes = pieces
        .map((piece) => missionBadgeCode(piece.state))
        .toSet();
    return badgeCodes.length == 1 && badgeCodes.single != 'MYS'
        ? pieces.first.state
        : 'Malaysia';
  }

  String get name {
    final title = pieces.isEmpty ? null : pieces.first.missionTitle?.trim();
    return title?.isNotEmpty == true ? title! : '$state Mystery Trail';
  }

  String get place => name;
  String get emoji => '';
}

String missionBadgeCode(String state) {
  final name = state.toLowerCase();
  if (name.contains('johor')) return 'JHR';
  if (name.contains('kedah')) return 'KDH';
  if (name.contains('kelantan')) return 'KTN';
  if (name.contains('melaka') || name.contains('malacca')) return 'MLK';
  if (name.contains('negeri sembilan')) return 'NSN';
  if (name.contains('pahang')) return 'PHG';
  if (name.contains('penang') || name.contains('pulau pinang')) return 'PNG';
  if (name.contains('perak')) return 'PRK';
  if (name.contains('perlis')) return 'PLS';
  if (name.contains('sabah')) return 'SBH';
  if (name.contains('sarawak')) return 'SWK';
  if (name.contains('selangor')) return 'SGR';
  if (name.contains('terengganu')) return 'TRG';
  if (name.contains('kuala lumpur')) return 'KUL';
  if (name.contains('putrajaya')) return 'PJY';
  if (name.contains('labuan')) return 'LBN';
  return 'MYS';
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
    this.isShared = false,
  });

  final String? id;
  final String? sessionId;
  final String title;
  final String date;
  final String summary;
  final String emoji;
  final bool isShared;

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
      isShared: json['diary_type'] == 'shared',
    );
  }
}

class GroupReflection {
  const GroupReflection({
    required this.userId,
    required this.name,
    required this.isHost,
    required this.isViewer,
    this.reflection,
    this.submittedAt,
  });

  final String userId;
  final String name;
  final bool isHost;
  final bool isViewer;
  final String? reflection;
  final DateTime? submittedAt;

  bool get submitted => reflection?.trim().isNotEmpty == true;

  factory GroupReflection.fromJson(Map<String, dynamic> json) =>
      GroupReflection(
        userId: json['user_id'] as String,
        name: json['name'] as String? ?? 'Explorer',
        isHost: json['role'] == 'host',
        isViewer: json['is_viewer'] == true,
        reflection: json['reflection'] as String?,
        submittedAt: DateTime.tryParse(json['submitted_at'] as String? ?? ''),
      );
}

class GroupDiaryState {
  const GroupDiaryState({
    required this.isHost,
    required this.allSubmitted,
    required this.members,
    this.diary,
  });

  final bool isHost;
  final bool allSubmitted;
  final List<GroupReflection> members;
  final DiaryMemory? diary;

  GroupReflection? get viewer {
    for (final member in members) {
      if (member.isViewer) return member;
    }
    return null;
  }

  factory GroupDiaryState.fromJson(Map<String, dynamic> json) {
    final diary = json['diary'];
    return GroupDiaryState(
      isHost: json['is_host'] == true,
      allSubmitted: json['all_submitted'] == true,
      members: TravellerProgress._maps(
        json['members'],
      ).map(GroupReflection.fromJson).toList(),
      diary: diary is Map
          ? DiaryMemory.fromJson(Map<String, dynamic>.from(diary))
          : null,
    );
  }
}

class EligibleDiaryMission {
  const EligibleDiaryMission({
    required this.sessionId,
    required this.title,
    required this.mode,
    required this.completedAt,
  });

  final String sessionId;
  final String title;
  final String mode;
  final DateTime? completedAt;

  factory EligibleDiaryMission.fromJson(Map<String, dynamic> json) =>
      EligibleDiaryMission(
        sessionId: json['session_id'] as String,
        title: json['title'] as String? ?? 'Completed mystery mission',
        mode: json['mode'] as String? ?? 'solo',
        completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
      );
}

class TravellerProgress {
  const TravellerProgress({
    required this.completedMissions,
    required this.visitedDestinations,
    required this.exploredStates,
    required this.stamps,
    required this.achievements,
    required this.memories,
    required this.eligibleDiaryMissions,
    required this.newBadges,
  });

  final int completedMissions;
  final int visitedDestinations;
  final int exploredStates;
  final List<PassportStamp> stamps;
  final List<Achievement> achievements;
  final List<DiaryMemory> memories;
  final List<EligibleDiaryMission> eligibleDiaryMissions;
  final List<String> newBadges;

  factory TravellerProgress.fromJson(Map<String, dynamic> json) {
    final stats = Map<String, dynamic>.from(json['stats'] as Map? ?? {});
    return TravellerProgress(
      completedMissions: (stats['completed_missions'] as num?)?.round() ?? 0,
      visitedDestinations:
          (stats['visited_destinations'] as num?)?.round() ?? 0,
      exploredStates: (stats['explored_states'] as num?)?.round() ?? 0,
      stamps: _maps(json['stamps']).map(PassportStamp.fromJson).toList(),
      achievements: _maps(json['badges']).map(Achievement.fromJson).toList(),
      memories: _maps(json['diaries']).map(DiaryMemory.fromJson).toList(),
      eligibleDiaryMissions: _maps(
        json['eligible_diary_missions'],
      ).map(EligibleDiaryMission.fromJson).toList(),
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
