# CampusQueue

Aplikasi mobile Flutter untuk antrean layanan administrasi kampus Universitas Sebelas Maret (UNS). Proyek UAS mata kuliah Pemrograman Perangkat Bergerak.

Mahasiswa mengambil nomor antrean dari smartphone, memantau posisinya secara realtime, dan petugas unit layanan mengelola antrean lewat dashboard khusus.

## Fitur utama

1. Autentikasi dan role (mahasiswa / petugas).
2. Daftar layanan dan pengambilan nomor antrean.
3. Pemantauan antrean realtime (Firestore Stream).
4. Panel petugas: panggil, lewati, selesaikan, buka/tutup layanan.
5. Pembatalan tiket dan riwayat antrean.

## Teknologi

| Komponen | Pilihan |
|---|---|
| Framework | Flutter (Dart) |
| Database | Cloud Firestore |
| Autentikasi | Firebase Authentication (email dan password) |
| State dan routing | Provider, GoRouter |

## Struktur folder

```text
lib/
├── main.dart                 # Firebase init, AuthProvider, AppRouter
├── core/                     # konstanta, util tanggal, seed data
├── models/                   # UserModel, ServiceModel, QueueModel
├── services/                 # AuthService, FirestoreService, QueueService
├── providers/                # AuthProvider
├── routes/                   # AppRouter (redirect berdasarkan role)
└── screens/
    ├── petugas/              # dashboard petugas
    └── temp/                 # placeholder sementara sebelum UI mahasiswa siap
```

Detail arsitektur, kontrak integrasi, dan rancangan Firestore ada di [docs/arsitektur.md](docs/arsitektur.md).

## Setup Firebase

1. Buat project di [Firebase Console](https://console.firebase.google.com).
2. Aktifkan **Authentication** dengan provider *Email/Password*.
3. Buat database **Cloud Firestore**.
4. Hubungkan Flutter dengan FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. File berikut dibuat lokal dan **tidak boleh di-commit** (sudah ada di `.gitignore`):
   - `lib/firebase_options.dart`
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
6. Buat akun petugas secara manual (tidak ada registrasi publik untuk petugas):
   - Authentication > Add user (email dan password).
   - Firestore > `users/{uid}` dengan field `nama`, `nim` (`-`), `role` = `petugas`, `layananId` (contoh `A`).
7. Isi koleksi `layanan` dengan data aktual hasil pendataan kelompok (lihat `lib/core/utils/seed_data.dart`).
8. Buat composite index yang dibutuhkan (lihat bagian Index di dokumen arsitektur).

## Menjalankan aplikasi

```bash
flutter pub get
dart format lib/
flutter analyze
flutter test
flutter run
```

## Aturan antrean

- Nomor memakai kode layanan dan 3 digit (A001, K001, ...).
- Counter terpisah per layanan dan per tanggal (`layanan/{id}/harian/{yyyy-MM-dd}`).
- Satu mahasiswa hanya punya satu tiket aktif per layanan per hari.
- Status: `menunggu` → `dipanggil` → `selesai` / `dilewati`; mahasiswa dapat `batal` saat masih `menunggu`.

## Batasan sistem

Tanpa push notification, tanpa verifikasi lokasi, akun petugas dibuat pengembang, dan pembaruan realtime berlaku saat aplikasi dibuka.

## Tim

| Anggota | NIM | Fokus |
|---|---|---|
| Khoirul Bagus Wicaksono | K3524077 | Frontend dan produk (sisi mahasiswa) |
| Muhammad Haikal Rizaldi | K3524029 | Backend, fondasi sistem, sisi petugas |
| Maulana Albar Cassano | K3524057 | Pendataan unit layanan |
| Muhammad Rafly Caesario | K3524079 | Skenario pengujian dan dokumentasi progres |

## Status pengembangan

Bagian ini diperbarui sesuai hasil pengujian nyata. Belum ada klaim fitur "selesai" tanpa pengujian di perangkat atau emulator.
