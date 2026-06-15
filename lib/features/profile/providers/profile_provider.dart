import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileService? profileService})
      : _profileService = profileService ?? ProfileService();

  final ProfileService _profileService;

  UserProfile? _profile;
  bool _isLoading = false;

  UserProfile? get profile => _profile;
  bool get hasProfile => _profile != null;
  bool get isLoading => _isLoading;

  Future<void> loadProfile() async {
    _setLoading(true);
    _profile = await _profileService.loadProfile();
    _setLoading(false);
  }

  Future<void> saveProfile(UserProfile profile) async {
    _setLoading(true);
    await _profileService.saveProfile(profile);
    _profile = profile;
    _setLoading(false);
  }

  Future<void> clearProfile() async {
    await _profileService.clearProfile();
    _profile = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
