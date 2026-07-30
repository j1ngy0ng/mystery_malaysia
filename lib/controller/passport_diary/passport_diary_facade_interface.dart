import 'package:flutter/foundation.dart';

import '../../model/passport_diary/traveller_progress.dart';

abstract interface class IPassportDiaryFacade implements Listenable {
  TravellerProgress? get progress;
  List<PassportStamp> get stamps;
  List<MissionStamp> get missionStamps;
  List<Achievement> get achievements;
  List<DiaryMemory> get memories;
  int get xp;
  int get level;
  int get nextLevelXp;
  double get levelProgress;
  bool get isLoading;
  String? get error;

  Future<void> load();
  Future<({bool generated, String title, String content, String message})?>
  generateDiary(String sessionId, String reflection);
  Future<bool> saveDiary({
    required String sessionId,
    required String title,
    required String content,
  });
  void dispose();
}
