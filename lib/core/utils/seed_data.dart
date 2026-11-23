import 'package:cloud_firestore/cloud_firestore.dart';

class SeedData {
  // Data awal enam unit layanan CampusQueue.
  // Lokasi, jam operasional, dan estimasi harus
  // diisi berdasarkan hasil pendataan kelompok.

  static const List<Map<String, dynamic>> services = [
    {
      'id': 'A',
      'nama': 'Layanan Akademik',
      'lokasi': '',
      'isOpen': false,
      'jamBuka': '',
      'jamTutup': '',
      'estimasiMenit': 0,
      'keperluan': [
        'KRS',
        'Surat keterangan mahasiswa',
        'Nilai dan transkrip',
        'Status mahasiswa',
        'Wisuda',
      ],
    },
    {
      'id': 'K',
      'nama': 'Layanan Keuangan',
      'lokasi': '',
      'isOpen': false,
      'jamBuka': '',
      'jamTutup': '',
      'estimasiMenit': 0,
      'keperluan': [
        'Pembayaran dan tagihan UKT/SPP',
        'Keringanan dan cicilan',
        'Pencairan dana',
      ],
    },
    {
      'id': 'M',
      'nama': 'Layanan Kemahasiswaan',
      'lokasi': '',
      'isOpen': false,
      'jamBuka': '',
      'jamTutup': '',
      'estimasiMenit': 0,
      'keperluan': ['Beasiswa', 'KTM', 'Organisasi', 'Proposal kegiatan'],
    },
    {
      'id': 'P',
      'nama': 'Layanan Perpustakaan',
      'lokasi': '',
      'isOpen': false,
      'jamBuka': '',
      'jamTutup': '',
      'estimasiMenit': 0,
      'keperluan': [
        'Bebas pustaka',
        'Uji kemiripan',
        'Sirkulasi',
        'Keanggotaan',
      ],
    },
    {
      'id': 'T',
      'nama': 'Layanan IT dan Sistem Informasi',
      'lokasi': '',
      'isOpen': false,
      'jamBuka': '',
      'jamTutup': '',
      'estimasiMenit': 0,
      'keperluan': ['Reset akun dan password', 'Perbaikan data pokok'],
    },
    {
      'id': 'U',
      'nama': 'Layanan Umum dan Fasilitas',
      'lokasi': '',
      'isOpen': false,
      'jamBuka': '',
      'jamTutup': '',
      'estimasiMenit': 0,
      'keperluan': ['Peminjaman sarana prasarana', 'Persuratan', 'Tamu'],
    },
  ];

  // Memasukkan data awal ke collection layanan.
  // Dokumen yang sudah ada tidak ditimpa.

  static Future<void> seedServices({FirebaseFirestore? firestore}) async {
    final db = firestore ?? FirebaseFirestore.instance;

    final batch = db.batch();
    var totalInserted = 0;

    for (final service in services) {
      final id = service['id'] as String;

      final documentRef = db.collection('layanan').doc(id);

      final existingDocument = await documentRef.get();

      // Hindari menimpa data layanan yang sudah ada.
      if (existingDocument.exists) {
        continue;
      }

      _validateService(service);

      final documentData = Map<String, dynamic>.from(service);

      // ID digunakan sebagai ID dokumen,
      // bukan sebagai field tambahan.
      documentData.remove('id');

      batch.set(documentRef, documentData);
      totalInserted++;
    }

    if (totalInserted > 0) {
      await batch.commit();
    }
  }

  // Validasi sebelum data dimasukkan ke Firestore.
  static void _validateService(Map<String, dynamic> service) {
    final id = service['id'];

    if ((service['lokasi'] as String).trim().isEmpty) {
      throw StateError(
        'Lokasi layanan $id belum diisi. '
        'Lengkapi berdasarkan hasil pendataan kelompok.',
      );
    }

    if ((service['jamBuka'] as String).trim().isEmpty ||
        (service['jamTutup'] as String).trim().isEmpty) {
      throw StateError('Jam operasional layanan $id belum diisi.');
    }

    if ((service['estimasiMenit'] as int) <= 0) {
      throw StateError('Estimasi menit layanan $id harus lebih dari 0.');
    }
  }
}
