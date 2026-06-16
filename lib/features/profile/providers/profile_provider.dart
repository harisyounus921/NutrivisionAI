import 'dart:developer' as dev;

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
    _d('loadProfile — GET /profile');
    _setLoading(true);
    _profile = await _profileService.loadProfile();
    _d('loadProfile — ${_profile != null ? 'found (age=${_profile!.age}, goal=${_profile!.goal.name})' : 'not set up yet'}');
    _setLoading(false);
  }

  Future<void> saveProfile(UserProfile profile) async {
    _d('saveProfile — PUT /profile');
    _setLoading(true);
    try {
      await _profileService.saveProfile(profile);
      _profile = profile;
      _d('saveProfile — saved successfully');
    } catch (e) {
      _d('saveProfile — error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearProfile() async {
    _d('clearProfile — (local clear only)');
    await _profileService.clearProfile();
    _profile = null;
    notifyListeners();
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·Profile');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
