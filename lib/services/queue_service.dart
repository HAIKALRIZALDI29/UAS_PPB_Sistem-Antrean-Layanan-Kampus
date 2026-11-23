import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../models/queue_model.dart';

class QueueService {
  final FirebaseFirestore _db;

  QueueService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  // Referensi collection antrean
  CollectionReference<Map<String, dynamic>> get _queueCollection {
    return _db.collection(AppCollections.antrean);
  }

  // Referensi dokumen counter harian
  DocumentReference<Map<String, dynamic>> _dailyCounterRef({
    required String layananId,
    required String tanggal,
  }) {
    return _db
        .collection(AppCollections.layanan)
        .doc(layananId)
        .collection('harian')
        .doc(tanggal);
  }

  // =====================================================
  // 1. MEMASTIKAN COUNTER HARIAN TERSEDIA
  // =====================================================

  Future<void> ensureDailyCounter({
    required String layananId,
    String? tanggal,
  }) async {
    final date = tanggal ?? DateKeyUtils.today();

    final counterRef = _dailyCounterRef(layananId: layananId, tanggal: date);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      if (!snapshot.exists) {
        transaction.set(counterRef, {'lastNumber': 0, 'currentNumber': 0});
      }
    });
  }

  // =====================================================
  // 1B. MENGAMBIL NOMOR ANTREAN (MAHASISWA)
  // =====================================================

  /// Membuat tiket baru dan mengembalikan ID dokumen antrean.
  ///
  /// Aturan yang dijaga:
  /// - layanan harus ada dan sedang buka,
  /// - keperluan harus termasuk daftar keperluan layanan,
  /// - satu mahasiswa hanya punya satu tiket aktif
  ///   (menunggu/dipanggil) per layanan per hari,
  /// - nomor naik berurutan per layanan per tanggal (A001, A002, ...).
  Future<String> takeTicket({
    required String layananId,
    required String uid,
    required String keperluan,
    String? tanggal,
  }) async {
    final date = tanggal ?? DateKeyUtils.today();

    final serviceRef = _db.collection(AppCollections.layanan).doc(layananId);
    final counterRef = _dailyCounterRef(layananId: layananId, tanggal: date);

    // Cek tiket aktif. Query memakai filter sama-dengan saja (tanpa
    // composite index), status disaring di sisi klien.
    // Catatan: ini dilakukan di luar transaction karena Firestore
    // Flutter SDK tidak mendukung query di dalam transaction.
    final existing = await _queueCollection
        .where('uid', isEqualTo: uid)
        .where('layananId', isEqualTo: layananId)
        .where('tanggal', isEqualTo: date)
        .get();

    final hasActiveTicket = existing.docs.any((doc) {
      final status = doc.data()['status'];
      return status == QueueStatus.menunggu || status == QueueStatus.dipanggil;
    });

    if (hasActiveTicket) {
      throw StateError(
        'Anda masih memiliki tiket aktif pada layanan ini hari ini.',
      );
    }

    // ID dokumen dibuat dulu agar bisa dikembalikan setelah transaction.
    final ticketRef = _queueCollection.doc();

    await _db.runTransaction((transaction) async {
      // Semua pembacaan dilakukan sebelum penulisan.
      final serviceSnapshot = await transaction.get(serviceRef);
      final counterSnapshot = await transaction.get(counterRef);

      if (!serviceSnapshot.exists || serviceSnapshot.data() == null) {
        throw StateError('Layanan tidak ditemukan.');
      }

      final serviceData = serviceSnapshot.data()!;

      if (serviceData['isOpen'] != true) {
        throw StateError('Layanan sedang ditutup.');
      }

      final keperluanList = serviceData['keperluan'];

      if (keperluanList is! List || !keperluanList.contains(keperluan)) {
        throw StateError('Keperluan tidak tersedia pada layanan ini.');
      }

      final counterData = counterSnapshot.data() ?? {};

      final lastNumber = (counterData['lastNumber'] as num?)?.toInt() ?? 0;
      final currentNumber =
          (counterData['currentNumber'] as num?)?.toInt() ?? 0;

      final nextNumber = lastNumber + 1;

      final nomor = formatQueueNumber(layananId, nextNumber);

      // Perbarui counter harian layanan ini.
      transaction.set(counterRef, {
        'lastNumber': nextNumber,
        'currentNumber': currentNumber,
      }, SetOptions(merge: true));

      // Buat tiket baru.
      transaction.set(ticketRef, {
        'layananId': layananId,
        'uid': uid,
        'nomor': nomor,
        'tanggal': date,
        'status': QueueStatus.menunggu,
        'keperluan': keperluan,
        'createdAt': FieldValue.serverTimestamp(),
        'calledAt': null,
        'finishedAt': null,
      });
    });

    return ticketRef.id;
  }

  /// Format nomor antrean: kode layanan + 3 digit (A001).
  static String formatQueueNumber(String layananId, int sequence) {
    return '$layananId${sequence.toString().padLeft(3, '0')}';
  }

  // =====================================================
  // 2. MEMANGGIL ANTREAN BERIKUTNYA
  // =====================================================

  Future<QueueModel?> callNext({
    required String layananId,
    String? tanggal,
  }) async {
    final date = tanggal ?? DateKeyUtils.today();

    final serviceRef = _db.collection(AppCollections.layanan).doc(layananId);

    final counterRef = _dailyCounterRef(layananId: layananId, tanggal: date);

    // Pastikan layanan tidak sedang memanggil antrean lain.
    final activeSnapshot = await _queueCollection
        .where('layananId', isEqualTo: layananId)
        .where('tanggal', isEqualTo: date)
        .where('status', isEqualTo: QueueStatus.dipanggil)
        .limit(1)
        .get();

    if (activeSnapshot.docs.isNotEmpty) {
      throw StateError(
        'Masih ada antrean yang sedang dipanggil. '
        'Selesaikan atau lewati antrean tersebut terlebih dahulu.',
      );
    }

    // Cari antrean menunggu paling awal.
    final waitingSnapshot = await _queueCollection
        .where('layananId', isEqualTo: layananId)
        .where('tanggal', isEqualTo: date)
        .where('status', isEqualTo: QueueStatus.menunggu)
        .orderBy('createdAt')
        .limit(1)
        .get();

    if (waitingSnapshot.docs.isEmpty) {
      return null;
    }

    final candidate = waitingSnapshot.docs.first;
    final ticketRef = candidate.reference;

    // Proses perubahan menggunakan transaction.
    final resultId = await _db.runTransaction<String?>((transaction) async {
      // Semua pembacaan dilakukan sebelum penulisan.
      final serviceSnapshot = await transaction.get(serviceRef);
      final counterSnapshot = await transaction.get(counterRef);
      final ticketSnapshot = await transaction.get(ticketRef);

      if (!serviceSnapshot.exists) {
        throw StateError('Data layanan tidak ditemukan.');
      }

      if (serviceSnapshot.data()?['isOpen'] != true) {
        throw StateError('Layanan sedang ditutup.');
      }

      if (!ticketSnapshot.exists) {
        throw StateError('Data antrean tidak ditemukan.');
      }

      final ticketData = ticketSnapshot.data()!;

      // Pastikan antrean masih menunggu.
      if (ticketData['status'] != QueueStatus.menunggu) {
        throw StateError('Status antrean telah berubah. Muat ulang data.');
      }

      // Mengambil nomor urut dari nomor antrean.
      final nomor = ticketData['nomor'] as String? ?? '';

      final sequence = _extractQueueSequence(nomor, layananId);

      final counterData = counterSnapshot.data() ?? {};

      final currentNumber =
          (counterData['currentNumber'] as num?)?.toInt() ?? 0;

      final lastNumber = (counterData['lastNumber'] as num?)?.toInt() ?? 0;

      if (sequence <= currentNumber) {
        throw StateError('Nomor antrean tidak sesuai urutan pelayanan.');
      }

      // Ubah status antrean menjadi dipanggil.
      transaction.update(ticketRef, {
        'status': QueueStatus.dipanggil,
        'calledAt': FieldValue.serverTimestamp(),
      });

      // Simpan nomor yang sedang dilayani.
      transaction.set(counterRef, {
        'lastNumber': lastNumber,
        'currentNumber': sequence,
      }, SetOptions(merge: true));

      return ticketSnapshot.id;
    });

    if (resultId == null) {
      return null;
    }

    // Ambil kembali dokumen yang telah diperbarui.
    final updatedDocument = await ticketRef.get();

    if (!updatedDocument.exists || updatedDocument.data() == null) {
      return null;
    }

    return QueueModel.fromMap(updatedDocument.id, updatedDocument.data()!);
  }

  // =====================================================
  // 3. MELEWATI ANTREAN
  // =====================================================

  Future<void> skipQueue({required String antreanId}) async {
    await _updateActiveQueueStatus(
      antreanId: antreanId,
      newStatus: QueueStatus.dilewati,
    );
  }

  // =====================================================
  // 4. MENYELESAIKAN ANTREAN
  // =====================================================

  Future<void> completeQueue({required String antreanId}) async {
    await _updateActiveQueueStatus(
      antreanId: antreanId,
      newStatus: QueueStatus.selesai,
    );
  }

  // Fungsi internal untuk menyelesaikan atau melewati antrean.
  Future<void> _updateActiveQueueStatus({
    required String antreanId,
    required String newStatus,
  }) async {
    final ticketRef = _queueCollection.doc(antreanId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ticketRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Data antrean tidak ditemukan.');
      }

      final currentStatus = snapshot.data()!['status'];

      // Hanya antrean yang dipanggil yang dapat diproses.
      if (currentStatus != QueueStatus.dipanggil) {
        throw StateError('Antrean tidak sedang dalam status dipanggil.');
      }

      transaction.update(ticketRef, {
        'status': newStatus,
        'finishedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // =====================================================
  // 5. MEMBATALKAN ANTREAN MAHASISWA
  // =====================================================

  Future<void> cancelQueue({
    required String antreanId,
    required String uid,
  }) async {
    final ticketRef = _queueCollection.doc(antreanId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ticketRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Data antrean tidak ditemukan.');
      }

      final data = snapshot.data()!;

      // Pastikan tiket merupakan milik mahasiswa tersebut.
      if (data['uid'] != uid) {
        throw StateError('Anda tidak memiliki izin membatalkan antrean ini.');
      }

      // Hanya antrean menunggu yang bisa dibatalkan.
      if (data['status'] != QueueStatus.menunggu) {
        throw StateError(
          'Antrean tidak dapat dibatalkan karena sudah diproses.',
        );
      }

      transaction.update(ticketRef, {'status': QueueStatus.batal});
    });
  }

  // =====================================================
  // 6. MEMBUKA ATAU MENUTUP LAYANAN
  // =====================================================

  Future<void> setServiceOpen({
    required String layananId,
    required bool isOpen,
  }) async {
    final serviceRef = _db.collection(AppCollections.layanan).doc(layananId);

    await serviceRef.update({'isOpen': isOpen});
  }

  // =====================================================
  // 7. MENGAMBIL ANGKA URUT DARI NOMOR ANTREAN
  // =====================================================

  int _extractQueueSequence(String nomor, String layananId) {
    if (!nomor.startsWith(layananId)) {
      throw FormatException('Format nomor antrean tidak sesuai layanan.');
    }

    final match = RegExp(r'(\d+)$').firstMatch(nomor);

    if (match == null) {
      throw FormatException('Nomor antrean tidak memiliki angka urut.');
    }

    return int.parse(match.group(1)!);
  }
}
