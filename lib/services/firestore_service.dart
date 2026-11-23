import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../models/service_model.dart';
import '../models/queue_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  // =====================================================
  // 1. MEMANTAU SELURUH LAYANAN
  // =====================================================

  Stream<List<ServiceModel>> watchServices() {
    return _db
        .collection(AppCollections.layanan)
        .orderBy('nama')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((document) {
            return ServiceModel.fromMap(document.id, document.data());
          }).toList();
        });
  }

  // =====================================================
  // 2. MENGAMBIL SATU LAYANAN
  // =====================================================

  Future<ServiceModel?> getServiceById(String layananId) async {
    final document = await _db
        .collection(AppCollections.layanan)
        .doc(layananId)
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return ServiceModel.fromMap(document.id, document.data()!);
  }

  // =====================================================
  // 3. MEMANTAU SATU LAYANAN SECARA REALTIME
  // =====================================================

  Stream<ServiceModel?> watchServiceById(String layananId) {
    return _db
        .collection(AppCollections.layanan)
        .doc(layananId)
        .snapshots()
        .map((document) {
          if (!document.exists || document.data() == null) {
            return null;
          }

          return ServiceModel.fromMap(document.id, document.data()!);
        });
  }

  // =====================================================
  // 4. MEMANTAU ANTREAN YANG MENUNGGU
  // =====================================================

  Stream<List<QueueModel>> watchWaitingQueue({
    required String layananId,
    String? tanggal,
  }) {
    final date = tanggal ?? DateKeyUtils.today();

    return _db
        .collection(AppCollections.antrean)
        .where('layananId', isEqualTo: layananId)
        .where('tanggal', isEqualTo: date)
        .where('status', isEqualTo: QueueStatus.menunggu)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((document) {
            return QueueModel.fromMap(document.id, document.data());
          }).toList();
        });
  }

  // =====================================================
  // 5. MEMANTAU ANTREAN YANG SEDANG DIPANGGIL
  // =====================================================

  Stream<QueueModel?> watchCurrentQueue({
    required String layananId,
    String? tanggal,
  }) {
    final date = tanggal ?? DateKeyUtils.today();

    return _db
        .collection(AppCollections.antrean)
        .where('layananId', isEqualTo: layananId)
        .where('tanggal', isEqualTo: date)
        .where('status', isEqualTo: QueueStatus.dipanggil)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final document = snapshot.docs.first;

          return QueueModel.fromMap(document.id, document.data());
        });
  }

  // =====================================================
  // 6. MEMANTAU SATU TIKET BERDASARKAN ID
  // =====================================================

  Stream<QueueModel?> watchTicket(String antreanId) {
    return _db
        .collection(AppCollections.antrean)
        .doc(antreanId)
        .snapshots()
        .map((document) {
          if (!document.exists || document.data() == null) {
            return null;
          }

          return QueueModel.fromMap(document.id, document.data()!);
        });
  }

  // =====================================================
  // 7. MEMANTAU RIWAYAT ANTREAN MAHASISWA
  // =====================================================

  Stream<List<QueueModel>> watchQueueHistory({required String uid}) {
    return _db
        .collection(AppCollections.antrean)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((document) {
            return QueueModel.fromMap(document.id, document.data());
          }).toList();
        });
  }
}
