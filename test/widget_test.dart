// Pengujian unit CampusQueue (model, konstanta, util tanggal, format nomor).
// Tidak memerlukan Firebase aktif, jadi bisa dijalankan dengan `flutter test`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_queue/core/constants/app_constants.dart';
import 'package:campus_queue/core/utils/date_utils.dart';
import 'package:campus_queue/models/queue_model.dart';
import 'package:campus_queue/models/service_model.dart';
import 'package:campus_queue/models/user_model.dart';
import 'package:campus_queue/services/queue_service.dart';

void main() {
  group('Konstanta', () {
    test('nama koleksi sesuai rancangan database', () {
      expect(AppCollections.users, 'users');
      expect(AppCollections.layanan, 'layanan');
      expect(AppCollections.antrean, 'antrean');
    });

    test('status antrean sesuai rancangan', () {
      expect(QueueStatus.menunggu, 'menunggu');
      expect(QueueStatus.dipanggil, 'dipanggil');
      expect(QueueStatus.selesai, 'selesai');
      expect(QueueStatus.dilewati, 'dilewati');
      expect(QueueStatus.batal, 'batal');
    });
  });

  group('DateKeyUtils', () {
    test('today() memakai format yyyy-MM-dd', () {
      expect(DateKeyUtils.today(), matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });

  group('Format nomor antrean', () {
    test('kode layanan + 3 digit', () {
      expect(QueueService.formatQueueNumber('A', 1), 'A001');
      expect(QueueService.formatQueueNumber('K', 12), 'K012');
      expect(QueueService.formatQueueNumber('M', 123), 'M123');
    });

    test('lebih dari 999 tidak dipotong', () {
      expect(QueueService.formatQueueNumber('U', 1000), 'U1000');
    });
  });

  group('UserModel', () {
    test('petugas membawa layananId', () {
      final user = UserModel.fromMap('uid1', {
        'nama': 'Petugas Akademik',
        'nim': '-',
        'role': 'petugas',
        'layananId': 'A',
      });

      expect(user.role, 'petugas');
      expect(user.layananId, 'A');
      expect(user.toMap()['layananId'], 'A');
    });

    test('mahasiswa tidak menulis layananId', () {
      final user = UserModel.fromMap('uid2', {
        'nama': 'Mahasiswa',
        'nim': 'K3524000',
        'role': 'mahasiswa',
      });

      expect(user.layananId, isNull);
      expect(user.toMap().containsKey('layananId'), isFalse);
    });
  });

  group('ServiceModel', () {
    test('keperluan dibaca sebagai List<String>', () {
      final service = ServiceModel.fromMap('A', {
        'nama': 'Layanan Akademik',
        'lokasi': 'x',
        'isOpen': true,
        'jamBuka': '07:30',
        'jamTutup': '15:00',
        'estimasiMenit': 10,
        'keperluan': ['KRS', 'Wisuda'],
      });

      expect(service.keperluan, ['KRS', 'Wisuda']);
      expect(service.estimasiMenit, 10);
    });

    test('data kosong tidak membuat error', () {
      final service = ServiceModel.fromMap('A', {});

      expect(service.isOpen, isFalse);
      expect(service.keperluan, isEmpty);
    });
  });

  group('QueueModel', () {
    test('Timestamp dikonversi menjadi DateTime', () {
      final created = DateTime(2026, 11, 23, 8, 30);

      final queue = QueueModel.fromMap('q1', {
        'layananId': 'A',
        'uid': 'u1',
        'nomor': 'A001',
        'tanggal': '2026-11-23',
        'status': QueueStatus.menunggu,
        'keperluan': 'KRS',
        'createdAt': Timestamp.fromDate(created),
        'calledAt': null,
        'finishedAt': null,
      });

      expect(queue.createdAt, created);
      expect(queue.calledAt, isNull);
      expect(queue.keperluan, 'KRS');
    });

    test('createdAt null (serverTimestamp belum kembali) tidak error', () {
      final queue = QueueModel.fromMap('q2', {
        'layananId': 'A',
        'uid': 'u1',
        'nomor': 'A002',
        'tanggal': '2026-11-23',
        'status': QueueStatus.menunggu,
        'createdAt': null,
      });

      expect(queue.createdAt, isA<DateTime>());
      expect(queue.keperluan, '');
    });

    test('toMap memakai nama field sesuai rancangan', () {
      final queue = QueueModel(
        id: 'q3',
        layananId: 'K',
        uid: 'u1',
        nomor: 'K001',
        tanggal: '2026-11-23',
        status: QueueStatus.menunggu,
        keperluan: 'Pencairan dana',
        createdAt: DateTime(2026, 11, 23),
      );

      expect(
        queue.toMap().keys,
        containsAll([
          'layananId',
          'uid',
          'nomor',
          'tanggal',
          'status',
          'keperluan',
          'createdAt',
          'calledAt',
          'finishedAt',
        ]),
      );
    });
  });
}
