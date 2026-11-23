import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Builder halaman yang menerima [GoRouterState], sehingga halaman
/// bisa membaca parameter rute lewat `state.pathParameters`.
typedef AppPageBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
);

/// KONTRAK RUTE (disepakati Anggota A dan B)
///
/// /login                           -> loginBuilder
/// /register                        -> registerBuilder
/// /mahasiswa                       -> mahasiswaHomeBuilder
/// /mahasiswa/layanan               -> serviceListBuilder (pilih unit)
/// /mahasiswa/layanan/:layananId    -> serviceDetailBuilder
///                                     (pilih keperluan + ambil nomor)
/// /mahasiswa/tiket/:antreanId      -> ticketBuilder
/// /mahasiswa/monitoring/:antreanId -> monitoringBuilder
/// /mahasiswa/riwayat               -> historyBuilder
/// /petugas                         -> petugasDashboardBuilder
///
/// Membaca parameter di halaman:
///   state.pathParameters['layananId']
///   state.pathParameters['antreanId']
/// Pindah halaman: context.go('/mahasiswa/tiket/$id') atau context.push(...)
class AppRouter {
  final AuthProvider authProvider;

  // Builder untuk halaman yang dikerjakan anggota A
  final AppPageBuilder loginBuilder;
  final AppPageBuilder registerBuilder;
  final AppPageBuilder mahasiswaHomeBuilder;
  final AppPageBuilder serviceListBuilder;
  final AppPageBuilder serviceDetailBuilder;
  final AppPageBuilder ticketBuilder;
  final AppPageBuilder monitoringBuilder;
  final AppPageBuilder historyBuilder;

  // Builder dashboard petugas
  final AppPageBuilder petugasDashboardBuilder;

  late final GoRouter router;

  AppRouter({
    required this.authProvider,
    required this.loginBuilder,
    required this.registerBuilder,
    required this.mahasiswaHomeBuilder,
    required this.serviceListBuilder,
    required this.serviceDetailBuilder,
    required this.ticketBuilder,
    required this.monitoringBuilder,
    required this.historyBuilder,
    required this.petugasDashboardBuilder,
  }) {
    router = GoRouter(
      initialLocation: '/',

      // Routing diperbarui ketika AuthProvider berubah.
      refreshListenable: authProvider,

      redirect: (context, state) {
        return _redirect(state.matchedLocation);
      },

      routes: [
        // Halaman awal
        GoRoute(
          path: '/',
          builder: (context, state) {
            return const _LoadingScreen();
          },
        ),

        // Loading
        GoRoute(
          path: '/loading',
          builder: (context, state) {
            return const _LoadingScreen();
          },
        ),

        // Authentication
        GoRoute(
          path: '/login',
          builder: (context, state) {
            return loginBuilder(context, state);
          },
        ),

        GoRoute(
          path: '/register',
          builder: (context, state) {
            return registerBuilder(context, state);
          },
        ),

        // Halaman mahasiswa
        GoRoute(
          path: '/mahasiswa',
          builder: (context, state) {
            return mahasiswaHomeBuilder(context, state);
          },
        ),

        GoRoute(
          path: '/mahasiswa/layanan',
          builder: (context, state) {
            return serviceListBuilder(context, state);
          },
        ),

        GoRoute(
          path: '/mahasiswa/layanan/:layananId',
          builder: (context, state) {
            return serviceDetailBuilder(context, state);
          },
        ),

        GoRoute(
          path: '/mahasiswa/tiket/:antreanId',
          builder: (context, state) {
            return ticketBuilder(context, state);
          },
        ),

        GoRoute(
          path: '/mahasiswa/monitoring/:antreanId',
          builder: (context, state) {
            return monitoringBuilder(context, state);
          },
        ),

        GoRoute(
          path: '/mahasiswa/riwayat',
          builder: (context, state) {
            return historyBuilder(context, state);
          },
        ),

        // Halaman petugas
        GoRoute(
          path: '/petugas',
          builder: (context, state) {
            return petugasDashboardBuilder(context, state);
          },
        ),

        // Profil tidak tersedia atau role tidak dikenal
        GoRoute(
          path: '/profile-missing',
          builder: (context, state) {
            return _ProfileMissingScreen(onSignOut: authProvider.signOut);
          },
        ),
      ],

      errorBuilder: (context, state) {
        return Scaffold(
          body: Center(
            child: Text(
              'Halaman tidak ditemukan: ${state.error}',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  // ==================================================
  // LOGIKA REDIRECT BERDASARKAN ROLE
  // ==================================================

  String? _redirect(String location) {
    final isLoginPage = location == '/login';
    final isRegisterPage = location == '/register';
    final isAuthPage = isLoginPage || isRegisterPage;

    // 1. Periksa apakah Firebase masih memuat status login.
    if (authProvider.isLoading) {
      return location == '/loading' ? null : '/loading';
    }

    // 2. Jika belum login, arahkan ke halaman login.
    if (!authProvider.isAuthenticated) {
      if (isAuthPage) {
        return null;
      }

      return '/login';
    }

    // 3. Jika sudah login, periksa profil Firestore.
    final profile = authProvider.userProfile;

    if (profile == null) {
      return location == '/profile-missing' ? null : '/profile-missing';
    }

    // 4. Tentukan tujuan berdasarkan role.
    String rolePath;

    switch (profile.role) {
      case 'mahasiswa':
        rolePath = '/mahasiswa';
        break;

      case 'petugas':
        rolePath = '/petugas';
        break;

      default:
        rolePath = '/profile-missing';
    }

    // 5. Jika role tidak dikenal.
    if (rolePath == '/profile-missing') {
      return location == rolePath ? null : rolePath;
    }

    // 6. Pengguna yang sudah login tidak perlu kembali ke login/register.
    if (isAuthPage || location == '/' || location == '/loading') {
      return rolePath;
    }

    // 7. Mahasiswa tidak boleh membuka halaman petugas.
    if (location.startsWith('/petugas') && profile.role != 'petugas') {
      return rolePath;
    }

    // 8. Petugas tidak boleh membuka halaman mahasiswa.
    if (location.startsWith('/mahasiswa') && profile.role != 'mahasiswa') {
      return rolePath;
    }

    // 9. Profil yang tidak dikenal.
    if (location == '/profile-missing') {
      return rolePath;
    }

    return null;
  }

  void dispose() {
    router.dispose();
  }
}

// ==================================================
// LOADING SCREEN
// ==================================================

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memeriksa akun pengguna...'),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// PROFILE MISSING SCREEN
// ==================================================

class _ProfileMissingScreen extends StatelessWidget {
  final Future<void> Function() onSignOut;

  const _ProfileMissingScreen({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 64),

              const SizedBox(height: 16),

              const Text(
                'Profil Pengguna Tidak Ditemukan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'Data profil atau role akun belum tersedia. '
                'Silakan hubungi administrator.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  try {
                    await onSignOut();
                  } catch (_) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal keluar dari akun.')),
                    );
                  }
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
