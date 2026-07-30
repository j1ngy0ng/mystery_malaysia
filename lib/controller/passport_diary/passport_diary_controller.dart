import 'package:flutter/foundation.dart';

import '../services/errors/api_error.dart';
import '../../model/passport_diary/traveller_progress.dart';
import '../services/supabase/supabase_data_service.dart';

class PassportDiaryController extends ChangeNotifier {
  PassportDiaryController({SupabaseDataService? dataService})
    : _dataService = dataService ?? SupabaseDataService();

  final SupabaseDataService _dataService;
  TravellerProgress? progress;
  bool isLoading = false;
  String? error;

  List<PassportStamp> get stamps => progress?.stamps ?? const [];
  List<MissionStamp> get missionStamps {
    final grouped = <String, List<PassportStamp>>{};
    for (final stamp in stamps) {
      final id = stamp.sessionId ?? 'legacy:${stamp.place}:${stamp.earnedAt}';
      grouped.putIfAbsent(id, () => []).add(stamp);
    }
    return [
      for (final entry in grouped.entries)
        MissionStamp(id: entry.key, pieces: entry.value),
    ];
  }

  List<Achievement> get achievements => progress?.achievements ?? const [];
  List<DiaryMemory> get memories => progress?.memories ?? const [];
  int get xp => progress?.xp ?? 0;
  int get level => progress?.level ?? 1;
  int get nextLevelXp => progress?.nextLevelXp ?? 500;
  double get levelProgress => progress?.levelProgress ?? 0;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      progress = await _dataService.loadTravellerProgress();
    } on ApiError catch (apiError) {
      error = apiError.message;
    } catch (_) {
      error = 'Passport data could not be displayed. Tap retry.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<({bool generated, String title, String content, String message})?>
  generateDiary(String sessionId, String reflection) async {
    if (reflection.trim().length < 10) {
      error =
          'Please provide more details about your travel experience before generating the diary.';
      notifyListeners();
      return null;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _dataService.generateDiary(sessionId, reflection);
      return (
        generated: result.generated,
        title: result.title,
        content: result.content,
        message: result.message,
      );
    } on ApiError catch (apiError) {
      error = apiError.message;
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveDiary({
    required String sessionId,
    required String title,
    required String content,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _dataService.saveDiary(
        sessionId: sessionId,
        title: title,
        content: content,
      );
      await load();
      return true;
    } on ApiError catch (apiError) {
      error = apiError.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
