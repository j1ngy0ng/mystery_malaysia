import 'package:flutter/foundation.dart';

import '../../models/passport_diary/traveller_progress.dart';

class PassportDiaryController extends ChangeNotifier {
  final stamps = const [
    PassportStamp(
      place: 'Kampung Baru',
      state: 'Kuala Lumpur',
      emoji: '🏠',
      earned: true,
    ),
    PassportStamp(
      place: 'Jonker Walk',
      state: 'Melaka',
      emoji: '🏮',
      earned: true,
    ),
    PassportStamp(
      place: 'Penang Hill',
      state: 'Penang',
      emoji: '🚞',
      earned: true,
    ),
    PassportStamp(
      place: 'Kundasang',
      state: 'Sabah',
      emoji: '⛰️',
      earned: false,
    ),
    PassportStamp(place: 'Bako', state: 'Sarawak', emoji: '🐒', earned: false),
    PassportStamp(
      place: 'Royal Belum',
      state: 'Perak',
      emoji: '🌿',
      earned: false,
    ),
  ];

  final achievements = const [
    Achievement(
      name: 'Clue Cracker',
      description: 'Solved 10 mysteries',
      emoji: '🧩',
    ),
    Achievement(
      name: 'Jalan-Jalan',
      description: 'Explored 3 states',
      emoji: '🛵',
    ),
    Achievement(
      name: 'Team Spirit',
      description: 'Finished a shared mission',
      emoji: '🤝',
    ),
  ];

  final memories = const [
    DiaryMemory(
      title: 'A Night of Lanterns',
      date: '18 Jul 2026',
      summary:
          'We followed the scent of roasted chestnuts and found a courtyard full of stories.',
      emoji: '🏮',
    ),
    DiaryMemory(
      title: 'Clouds Above Penang',
      date: '02 Jul 2026',
      summary:
          'The funicular climbed into the mist while George Town became a tiny map below.',
      emoji: '☁️',
    ),
  ];

  int get xp => 1280;
  int get nextLevelXp => 1600;
  double get levelProgress => xp / nextLevelXp;
}
