import 'package:flutter/foundation.dart';

import '../../models/user_profile/user_profile.dart';

class UserProfileController extends ChangeNotifier {
  UserProfile profile = const UserProfile(
    name: 'Aina Rahman',
    username: '@ainajalan',
    email: 'aina@example.com',
    homeState: 'Selangor',
    level: 7,
    xp: 1280,
  );

  bool editing = false;

  void toggleEditing() {
    editing = !editing;
    notifyListeners();
  }

  void save({required String name, required String username}) {
    profile = profile.copyWith(name: name.trim(), username: username.trim());
    editing = false;
    notifyListeners();
  }
}
