import 'package:cloud_firestore/cloud_firestore.dart';

class QueueModel {
  // ID dokumen antrean dari Firestore
  final String id;

  // Informasi antrean
  final String layananId;
  final String uid;
  final String nomor;
  final String tanggal;
  final String status;

  // Keperluan mahasiswa
  final String keperluan;

  // Waktu aktivitas antrean
  final DateTime createdAt;
  final DateTime? calledAt;
  final DateTime? finishedAt;

  const QueueModel({
    required this.id,
    required this.layananId,
    required this.uid,
    required this.nomor,
    required this.tanggal,
    required this.status,
    this.keperluan = '',
    required this.createdAt,
    this.calledAt,
    this.finishedAt,
  });

  // Mengubah data Firestore menjadi QueueModel
  factory QueueModel.fromMap(String id, Map<String, dynamic> data) {
    return QueueModel(
      id: id,
      layananId: data['layananId'] ?? '',
      uid: data['uid'] ?? '',
      nomor: data['nomor'] ?? '',
      tanggal: data['tanggal'] ?? '',
      status: data['status'] ?? '',

      // Mendukung dokumen lama yang belum memiliki keperluan
      keperluan: data['keperluan'] ?? '',

      // createdAt bisa bernilai null sesaat setelah dokumen dibuat dengan
      // FieldValue.serverTimestamp() (nilai server belum kembali).
      // Gunakan waktu perangkat sementara agar stream tidak error.
      createdAt: _parseOptionalDate(data['createdAt']) ?? DateTime.now(),
      calledAt: _parseOptionalDate(data['calledAt']),
      finishedAt: _parseOptionalDate(data['finishedAt']),
    );
  }

  // Mengubah QueueModel menjadi Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'layananId': layananId,
      'uid': uid,
      'nomor': nomor,
      'tanggal': tanggal,
      'status': status,
      'keperluan': keperluan,
      'createdAt': Timestamp.fromDate(createdAt),
      'calledAt': calledAt != null ? Timestamp.fromDate(calledAt!) : null,
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
    };
  }

  // Mengonversi Timestamp menjadi DateTime opsional
  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    throw FormatException('Format tanggal tidak valid: ${value.runtimeType}');
  }
}
