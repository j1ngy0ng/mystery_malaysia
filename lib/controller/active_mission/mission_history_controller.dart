import 'package:flutter/foundation.dart';

import '../services/errors/api_error.dart';
import '../../model/active_mission/mission_history_item.dart';
import '../../model/active_mission/mission_session.dart';
import '../services/supabase/supabase_data_service.dart';

class MissionHistoryController extends ChangeNotifier {
  MissionHistoryController({SupabaseDataService? dataService})
    : _dataService = dataService ?? SupabaseDataService();

  final SupabaseDataService _dataService;
  MissionHistoryFilter filter = MissionHistoryFilter.all;
  List<MissionHistoryItem> missions = const [];
  bool isLoading = false;
  String? error;

  List<MissionHistoryItem> get visibleMissions =>
      filter == MissionHistoryFilter.all
      ? missions
      : missions
            .where(
              (mission) =>
                  mission.status.name ==
                  (filter == MissionHistoryFilter.active
                      ? MissionStatus.active.name
                      : filter == MissionHistoryFilter.paused
                      ? MissionStatus.paused.name
                      : MissionStatus.completed.name),
            )
            .toList(growable: false);

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      missions = await _dataService.loadMissionHistory();
    } on ApiError catch (apiError) {
      error = apiError.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectFilter(MissionHistoryFilter value) {
    filter = value;
    notifyListeners();
  }
}
