import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';
import 'screens/petugas/petugas_dashboard_screen.dart';
import 'screens/temp/temp_auth_screens.dart';
import 'screens/temp/temp_mahasiswa_screens.dart';

// =====================================================
// 1. ENTRY POINT
// =====================================================
// Alur: Firebase init -> AuthProvider -> AppRouter -> Screens
// AuthProvider dibuat SETELAH Firebase siap, karena AuthService
// memakai FirebaseAuth.instance.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    runApp(FirebaseErrorApp(error: error));
    return;
  }

  runApp(const CampusQueueApp());
}

// =====================================================
// 2. ROOT APLIKASI
// =====================================================

class CampusQueueApp extends StatefulWidget {
  const CampusQueueApp({super.key});

  @override
  State<CampusQueueApp> createState() => _CampusQueueAppState();
}

class _CampusQueueAppState extends State<CampusQueueApp> {
  late final AuthProvider _authProvider;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();

    _authProvider = AuthProvider();

    // Builder bertanda "Temp" adalah placeholder sementara.
    // Anggota A mengganti dengan halaman aslinya, contoh:
    //   loginBuilder: (context, state) => const LoginScreen(),
    //   ticketBuilder: (context, state) => TicketScreen(
    //     antreanId: state.pathParameters['antreanId']!,
    //   ),
    _appRouter = AppRouter(
      authProvider: _authProvider,
      loginBuilder: (context, state) => const TempLoginScreen(),
      registerBuilder: (context, state) => const TempRegisterScreen(),
      mahasiswaHomeBuilder: (context, state) => const TempMahasiswaHomeScreen(),
      serviceListBuilder: (context, state) =>
          const TempPlaceholderScreen(title: 'Daftar Layanan'),
      serviceDetailBuilder: (context, state) => TempPlaceholderScreen(
        title: 'Detail Layanan',
        detail: 'layananId: ${state.pathParameters['layananId']}',
      ),
      ticketBuilder: (context, state) => TempPlaceholderScreen(
        title: 'Tiket Antrean',
        detail: 'antreanId: ${state.pathParameters['antreanId']}',
      ),
      monitoringBuilder: (context, state) => TempPlaceholderScreen(
        title: 'Monitoring Antrean',
        detail: 'antreanId: ${state.pathParameters['antreanId']}',
      ),
      historyBuilder: (context, state) =>
          const TempPlaceholderScreen(title: 'Riwayat Antrean'),
      petugasDashboardBuilder: (context, state) =>
          const PetugasDashboardScreen(),
    );
  }

  @override
  void dispose() {
    _appRouter.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: 'CampusQueue',
        debugShowCheckedModeBanner: false,
        routerConfig: _appRouter.router,

        // Tema sementara. Digantikan app_theme.dart milik Anggota A.
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E8B)),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        ),
      ),
    );
  }
}

// =====================================================
// 3. LAYAR ERROR INISIALISASI FIREBASE
// =====================================================

class FirebaseErrorApp extends StatelessWidget {
  final Object error;

  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase gagal diinisialisasi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Pastikan lib/firebase_options.dart dan '
                  'google-services.json tersedia di komputer ini.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
