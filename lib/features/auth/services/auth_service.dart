import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/app_exception.dart';
import '../../../core/services/firebase_backend.dart';
import '../models/app_user.dart';

class AuthResult {
  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AppUser user;
  final String accessToken;
  final String refreshToken;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );
}

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth}) : _auth = firebaseAuth;

  final FirebaseAuth? _auth;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseBackend.auth;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const ApiException('Registration failed.');
      await user.updateDisplayName(name);
      await FirebaseBackend.userDoc(user.uid).set({
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      return AuthResult(
        user: AppUser(id: user.uid, name: name, email: email),
        accessToken: '',
        refreshToken: '',
      );
    } on FirebaseAuthException catch (e) {
      throw ApiException(e.message ?? 'Registration failed.');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const ApiException('Login failed.');
      return AuthResult(
        user: await _appUserFromFirebaseUser(user),
        accessToken: '',
        refreshToken: '',
      );
    } on FirebaseAuthException catch (e) {
      throw ApiException(e.message ?? 'Login failed.');
    }
  }

  Future<AppUser> getMe() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw const ApiException('Please log in again.');
    return _appUserFromFirebaseUser(user);
  }

  Future<void> forgotPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _firebaseAuth.confirmPasswordReset(
      code: token,
      newPassword: newPassword,
    );
  }

  Future<void> logout() => _firebaseAuth.signOut();

  Future<AppUser> _appUserFromFirebaseUser(User user) async {
    final doc = await FirebaseBackend.userDoc(user.uid).get();
    final data = doc.data();
    return AppUser(
      id: user.uid,
      name: (data?['name'] as String?) ?? user.displayName ?? '',
      email: (data?['email'] as String?) ?? user.email ?? '',
    );
  }
}
