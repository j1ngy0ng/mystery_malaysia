import 'package:flutter/foundation.dart';

import 'passport_diary_controller.dart';
import 'passport_diary_facade_interface.dart';
import '../../model/passport_diary/traveller_progress.dart';

class PassportDiaryFacade extends ChangeNotifier
    implements IPassportDiaryFacade {
  PassportDiaryFacade() : _controller = PassportDiaryController() {
    _controller.addListener(notifyListeners);
  }

  final PassportDiaryController _controller;

  @override
  TravellerProgress? get progress => _controller.progress;
  @override
  List<PassportStamp> get stamps => _controller.stamps;
  @override
  List<MissionStamp> get missionStamps => _controller.missionStamps;
  @override
  List<Achievement> get achievements => _controller.achievements;
  @override
  List<DiaryMemory> get memories => _controller.memories;
  @override
  int get xp => _controller.xp;
  @override
  int get level => _controller.level;
  @override
  int get nextLevelXp => _controller.nextLevelXp;
  @override
  double get levelProgress => _controller.levelProgress;
  @override
  bool get isLoading => _controller.isLoading;
  @override
  String? get error => _controller.error;

  @override
  Future<void> load() => _controller.load();
  @override
  Future<({bool generated, String title, String content, String message})?>
  generateDiary(String sessionId, String reflection) =>
      _controller.generateDiary(sessionId, reflection);
  @override
  Future<bool> saveDiary({
    required String sessionId,
    required String title,
    required String content,
  }) => _controller.saveDiary(
    sessionId: sessionId,
    title: title,
    content: content,
  );

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}
