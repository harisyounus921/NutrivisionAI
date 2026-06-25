import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../../../core/services/app_exception.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

export '../../../core/services/app_exception.dart' show ApiException;

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _isLoading = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> tryAutoLogin() async {
    _d('tryAutoLogin — checking Firebase auth user');
    try {
      _user = await _authService.getMe();
      _d('tryAutoLogin — success, user: ${_user?.email}');
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      _d('tryAutoLogin — auth error: ${e.message}');
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _d('tryAutoLogin — network/unexpected error: $e — keeping session');
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _d('login — Firebase Auth sign-in for $email');
    _setLoading(true);
    try {
      final result = await _authService.login(email: email, password: password);
      _user = result.user;
      _status = AuthStatus.authenticated;
      _d('login — success, userId: ${result.user.id}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _d('register — Firebase Auth create user for $email');
    _setLoading(true);
    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _user = result.user;
      _status = AuthStatus.authenticated;
      _d('register — success, userId: ${result.user.id}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _d('logout — Firebase sign out');
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'MealNudge·Auth');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
