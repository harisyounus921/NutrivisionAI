import 'package:flutter/foundation.dart';

import '../../../core/services/session_service.dart';
import '../models/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Holds auth state and session persistence (via [SessionService]).
///
/// Login/registration currently succeed locally without a backend call —
/// this will be replaced once the backend (Firebase or custom REST API) is
/// chosen, without changing the public API used by the UI.
class AuthProvider extends ChangeNotifier {
  AuthProvider({SessionService? sessionService})
      : _sessionService = sessionService ?? SessionService();

  final SessionService _sessionService;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _isLoading = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> tryAutoLogin() async {
    final loggedIn = await _sessionService.isLoggedIn();
    if (loggedIn) {
      final name = await _sessionService.getUserName() ?? '';
      final email = await _sessionService.getUserEmail() ?? '';
      _user = AppUser(name: name, email: email);
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));
    final name = email.split('@').first;
    await _sessionService.saveSession(name: name, email: email);
    _user = AppUser(name: name, email: email);
    _status = AuthStatus.authenticated;
    _setLoading(false);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));
    await _sessionService.saveSession(name: name, email: email);
    _user = AppUser(name: name, email: email);
    _status = AuthStatus.authenticated;
    _setLoading(false);
  }

  Future<void> logout() async {
    await _sessionService.clearSession();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
