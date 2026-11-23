import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  late final StreamSubscription<User?> _authSubscription;

  User? _firebaseUser;
  UserModel? _userProfile;

  bool _isLoading = true;
  String? _errorMessage;

  int _profileRequestId = 0;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    // Mendengarkan perubahan login/logout Firebase.
    _authSubscription = _authService.authStateChanges.listen(
      (user) {
        _handleAuthChanged(user);
      },
      onError: (Object error) {
        _errorMessage = _getErrorMessage(error);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ==================================================
  // GETTERS
  // ==================================================

  User? get firebaseUser => _firebaseUser;

  UserModel? get userProfile => _userProfile;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _firebaseUser != null;

  String? get role => _userProfile?.role;

  bool get isMahasiswa => role == 'mahasiswa';

  bool get isPetugas => role == 'petugas';

  // ==================================================
  // MEMANTAU PERUBAHAN AUTHENTICATION
  // ==================================================

  Future<void> _handleAuthChanged(User? user) async {
    final requestId = ++_profileRequestId;

    _firebaseUser = user;
    _errorMessage = null;

    if (user == null) {
      _userProfile = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _userProfile = null;
    notifyListeners();

    try {
      final profile = await _authService.getUserProfile(user.uid);

      // Mencegah hasil request lama menimpa state terbaru.
      if (requestId != _profileRequestId) return;

      _userProfile = profile;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      if (requestId != _profileRequestId) return;

      _userProfile = null;
      _errorMessage = _getErrorMessage(error);
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================
  // LOGIN
  // ==================================================

  Future<void> signIn({required String email, required String password}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
      rethrow;
    }
  }

  // ==================================================
  // REGISTRASI MAHASISWA
  // ==================================================

  Future<void> registerMahasiswa({
    required String nama,
    required String nim,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerMahasiswa(
        nama: nama,
        nim: nim,
        email: email,
        password: password,
      );

      // Memuat ulang profil setelah dokumen Firestore dibuat.
      await refreshProfile();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
      rethrow;
    }
  }

  // ==================================================
  // MEMUAT ULANG PROFIL
  // ==================================================

  Future<void> refreshProfile() async {
    final user = _authService.currentUser;

    if (user == null) {
      _firebaseUser = null;
      _userProfile = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final requestId = ++_profileRequestId;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _authService.getUserProfile(user.uid);

      if (requestId != _profileRequestId) return;

      _firebaseUser = user;
      _userProfile = profile;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      if (requestId != _profileRequestId) return;

      _errorMessage = _getErrorMessage(error);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ==================================================
  // LOGOUT
  // ==================================================

  Future<void> signOut() async {
    _errorMessage = null;

    try {
      await _authService.signOut();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
      rethrow;
    }
  }

  // ==================================================
  // MEMBERSIHKAN ERROR
  // ==================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return error.message ?? error.code;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  // ==================================================
  // DISPOSE
  // ==================================================

  @override
  void dispose() {
    _profileRequestId++;
    unawaited(_authSubscription.cancel());
    super.dispose();
  }
}
