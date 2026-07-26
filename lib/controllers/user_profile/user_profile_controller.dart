import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';
import '../../errors/api_error.dart';
import '../../models/user_profile/user_profile.dart';
import '../../services/supabase/supabase_auth_service.dart';
import '../../services/supabase/supabase_data_service.dart';

class UserProfileController extends ChangeNotifier {
  UserProfileController({
    SupabaseDataService? dataService,
    SupabaseAuthService? authService,
  }) : _dataService = dataService ?? SupabaseDataService(),
       _authService = authService ?? SupabaseAuthService();

  final SupabaseDataService _dataService;
  final SupabaseAuthService _authService;

  UserProfile profile = const UserProfile(
    name: 'Explorer',
    username: '',
    email: '',
    homeState: 'Not set',
    level: 1,
    xp: 0,
  );

  bool editing = false;
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    if (!AppConfig.isConfigured) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _dataService.loadOwnProfile();
      profile = UserProfile.fromSupabase(
        data,
        email: _authService.currentUser?.email ?? '',
      );
    } on ApiError catch (apiError) {
      error = apiError.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleEditing() {
    editing = !editing;
    notifyListeners();
  }

  Future<bool> save({required String name, required String username}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final cleanUsername = username.trim().replaceFirst('@', '');
      await _dataService.updateOwnProfile(
        displayName: name,
        username: cleanUsername,
      );
      profile = profile.copyWith(
        name: name.trim(),
        username: cleanUsername.isEmpty ? '' : '@$cleanUsername',
      );
      editing = false;
      return true;
    } on ApiError catch (apiError) {
      error = apiError.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signOut() async {
    try {
      await _authService.signOut();
      return true;
    } on ApiError catch (apiError) {
      error = apiError.message;
      notifyListeners();
      return false;
    }
  }
}
