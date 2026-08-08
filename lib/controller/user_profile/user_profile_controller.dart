import 'package:flutter/foundation.dart';

import '../services/config/app_config.dart';
import '../services/errors/api_error.dart';
import '../../model/user_profile/user_profile.dart';
import '../services/supabase/supabase_auth_service.dart';
import '../services/supabase/supabase_data_service.dart';

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
  );

  bool editing = false;
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    if (!AppConfig.demoMode && !AppConfig.isConfigured) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _dataService.loadOwnProfile();
      profile = UserProfile.fromSupabase(
        data,
        email: AppConfig.demoMode
            ? 'demo@mysterymalaysia.app'
            : _authService.currentUser?.email ?? '',
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

  Future<bool> save({
    required String name,
    required String username,
    String? gender,
    String? phoneNumber,
  }) async {
    if (name.trim().isEmpty || username.trim().replaceFirst('@', '').isEmpty) {
      error = 'Display name and username are required.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final cleanUsername = username.trim().replaceFirst('@', '');
      await _dataService.updateOwnProfile(
        displayName: name,
        username: cleanUsername,
        gender: gender,
        phoneNumber: phoneNumber,
      );
      profile = profile.copyWith(
        name: name.trim(),
        username: cleanUsername.isEmpty ? '' : '@$cleanUsername',
        gender: gender,
        phoneNumber: phoneNumber,
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

  Future<bool> uploadAvatar(
    Uint8List bytes, {
    required String extension,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final url = await _dataService.uploadAvatar(bytes, extension: extension);
      profile = profile.copyWith(avatarUrl: url);
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
