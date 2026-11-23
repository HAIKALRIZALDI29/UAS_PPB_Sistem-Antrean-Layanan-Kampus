import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  // Mendapatkan pengguna yang sedang login
  User? get currentUser => _auth.currentUser;

  // Memantau perubahan status autentikasi
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // Login pengguna
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Pengguna tidak ditemukan.');
    }

    return getUserProfile(user.uid);
  }

  // Registrasi khusus mahasiswa
  Future<UserModel> registerMahasiswa({
    required String nama,
    required String nim,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Registrasi gagal.');
    }

    final userModel = UserModel(
      uid: firebaseUser.uid,
      nama: nama.trim(),
      nim: nim.trim(),
      role: 'mahasiswa',
      layananId: null,
    );

    try {
      await _db
          .collection(AppCollections.users)
          .doc(firebaseUser.uid)
          .set(userModel.toMap());
    } catch (e) {
      // Hapus akun Auth jika pembuatan profil gagal.
      try {
        await firebaseUser.delete();
      } catch (_) {
        // Error penghapusan akun tidak menggantikan error awal.
      }

      rethrow;
    }

    return userModel;
  }

  // Mengambil profil pengguna berdasarkan UID
  Future<UserModel?> getUserProfile(String uid) async {
    final document = await _db.collection(AppCollections.users).doc(uid).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return UserModel.fromMap(document.id, document.data()!);
  }

  // Memantau profil pengguna secara realtime
  Stream<UserModel?> watchUserProfile(String uid) {
    return _db.collection(AppCollections.users).doc(uid).snapshots().map((
      document,
    ) {
      if (!document.exists || document.data() == null) {
        return null;
      }

      return UserModel.fromMap(document.id, document.data()!);
    });
  }

  // Logout pengguna
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
