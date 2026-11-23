// =====================================================
// HALAMAN SEMENTARA - SISI MAHASISWA
// =====================================================
// Placeholder agar router bisa dijalankan sebelum UI Anggota A siap.
// Bukan pengganti pekerjaan A. Hapus folder screens/temp/ setelah
// builder di main.dart diganti dengan halaman asli.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/service_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

/// Home sementara: sapaan, daftar layanan (realtime), dan logout.
class TempMahasiswaHomeScreen extends StatefulWidget {
  const TempMahasiswaHomeScreen({super.key});

  @override
  State<TempMahasiswaHomeScreen> createState() =>
      _TempMahasiswaHomeScreenState();
}

class _TempMahasiswaHomeScreenState extends State<TempMahasiswaHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late final Stream<List<ServiceModel>> _servicesStream = _firestoreService
      .watchServices();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nama = auth.userProfile?.nama ?? 'Mahasiswa';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusQueue'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await auth.signOut();
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Gagal keluar dari akun.')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: _servicesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat layanan: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final services = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Halo, $nama',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Halaman sementara. UI mahasiswa dikerjakan Anggota A.',
              ),
              const SizedBox(height: 16),
              if (services.isEmpty)
                const Text(
                  'Belum ada data layanan. Jalankan seed data '
                  'setelah data aktual dari Anggota 3 tersedia.',
                ),
              for (final service in services)
                Card(
                  child: ListTile(
                    leading: Icon(
                      service.isOpen ? Icons.check_circle : Icons.cancel,
                      color: service.isOpen ? Colors.green : Colors.red,
                    ),
                    title: Text(service.nama),
                    subtitle: Text(
                      service.isOpen ? 'Layanan buka' : 'Layanan tutup',
                    ),
                    onTap: () => context.go('/mahasiswa/layanan/${service.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Placeholder umum untuk halaman mahasiswa yang belum dibuat.
class TempPlaceholderScreen extends StatelessWidget {
  final String title;
  final String? detail;

  const TempPlaceholderScreen({super.key, required this.title, this.detail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: () => context.go('/mahasiswa')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            [
              'Halaman "$title" belum dibuat (bagian Anggota A).',
              ?detail,
            ].join('\n'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
