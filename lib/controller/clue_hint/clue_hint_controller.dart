import 'package:flutter/foundation.dart';

import '../services/errors/api_error.dart';
import '../../model/clue_hint/mystery_clue.dart';
import '../services/supabase/supabase_data_service.dart';

class ClueHintController extends ChangeNotifier {
  ClueHintController({
    MysteryClue? initialClue,
    this.sessionId,
    SupabaseDataService? dataService,
  }) : _dataService = dataService ?? SupabaseDataService(),
       clue =
           initialClue ??
           const MysteryClue(
             number: 2,
             text:
                 'I watch the city through petals of glass. At my feet, old stories and new skylines share the same reflection.',
             hint:
                 'Look for a peaceful place of worship near a river confluence and a busy heritage district.',
           );

  final SupabaseDataService _dataService;
  final String? sessionId;
  MysteryClue clue;
  bool isLoading = false;
  String? error;

  Future<void> recordViewed() async {
    if (sessionId != null) {
      try {
        await _dataService.recordClueViewed(sessionId!);
      } catch (_) {}
    }
  }

  Future<bool> revealHint() async {
    if (clue.hintRevealed) return true;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      if (sessionId == null) {
        clue = clue.copyWith(hintRevealed: true);
      } else {
        final result = await _dataService.requestHint(sessionId!);
        clue = clue.copyWith(hint: result.hint, hintRevealed: true);
      }
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
