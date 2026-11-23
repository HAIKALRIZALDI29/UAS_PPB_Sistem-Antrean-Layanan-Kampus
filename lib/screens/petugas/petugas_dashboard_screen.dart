import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';

import '../../models/service_model.dart';
import '../../models/queue_model.dart';

import '../../services/firestore_service.dart';
import '../../services/queue_service.dart';

class PetugasDashboardScreen extends StatefulWidget {
  const PetugasDashboardScreen({super.key});

  @override
  State<PetugasDashboardScreen> createState() => _PetugasDashboardScreenState();
}

class _PetugasDashboardScreenState extends State<PetugasDashboardScreen> {
  // =====================================================
  // SERVICE
  // =====================================================

  final FirestoreService _firestoreService = FirestoreService();

  final QueueService _queueService = QueueService();

  // =====================================================
  // STREAM CACHE
  // =====================================================

  String? _streamLayananId;

  Stream<ServiceModel?>? _serviceStream;

  Stream<QueueModel?>? _currentQueueStream;

  Stream<List<QueueModel>>? _waitingQueueStream;

  // =====================================================
  // STATE
  // =====================================================

  bool _isProcessing = false;

  bool _isLoggingOut = false;

  // =====================================================
  // MENYIAPKAN STREAM FIRESTORE
  // =====================================================

  void _prepareStreams(String layananId) {
    if (_streamLayananId == layananId) {
      return;
    }

    _streamLayananId = layananId;

    _serviceStream = _firestoreService.watchServiceById(layananId);

    _currentQueueStream = _firestoreService.watchCurrentQueue(
      layananId: layananId,
    );

    _waitingQueueStream = _firestoreService.watchWaitingQueue(
      layananId: layananId,
    );
  }

  // =====================================================
  // MENAMPILKAN PESAN
  // =====================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // =====================================================
  // FORMAT ERROR
  // =====================================================

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // =====================================================
  // KONFIRMASI AKSI
  // =====================================================

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // =====================================================
  // 1. MEMANGGIL ANTREAN BERIKUTNYA
  // =====================================================

  Future<void> _callNext(String layananId) async {
    if (_isProcessing) return;

    final confirmed = await _confirmAction(
      title: 'Panggil antrean berikutnya?',
      message:
          'Sistem akan memanggil mahasiswa dengan nomor '
          'antrean paling awal.',
      confirmText: 'Panggil',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _queueService.callNext(layananId: layananId);

      if (result == null) {
        _showMessage('Tidak ada antrean yang menunggu.');
      } else {
        _showMessage('Antrean ${result.nomor} berhasil dipanggil.');
      }
    } catch (error) {
      _showMessage('Gagal memanggil antrean: ${_errorMessage(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // =====================================================
  // 2. MENYELESAIKAN ANTREAN
  // =====================================================

  Future<void> _completeQueue(String antreanId) async {
    if (_isProcessing) return;

    final confirmed = await _confirmAction(
      title: 'Selesaikan antrean?',
      message: 'Apakah mahasiswa sudah selesai mendapatkan pelayanan?',
      confirmText: 'Selesaikan',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _queueService.completeQueue(antreanId: antreanId);

      _showMessage('Antrean berhasil diselesaikan.');
    } catch (error) {
      _showMessage('Gagal menyelesaikan antrean: ${_errorMessage(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // =====================================================
  // 3. MELEWATI ANTREAN
  // =====================================================

  Future<void> _skipQueue(String antreanId) async {
    if (_isProcessing) return;

    final confirmed = await _confirmAction(
      title: 'Lewati antrean?',
      message: 'Apakah Anda yakin ingin melewati mahasiswa ini?',
      confirmText: 'Lewati',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _queueService.skipQueue(antreanId: antreanId);

      _showMessage('Antrean berhasil dilewati.');
    } catch (error) {
      _showMessage('Gagal melewati antrean: ${_errorMessage(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // =====================================================
  // 4. MENGUBAH STATUS LAYANAN
  // =====================================================

  Future<void> _changeServiceStatus({
    required String layananId,
    required bool isOpen,
  }) async {
    if (_isProcessing) return;

    final confirmed = await _confirmAction(
      title: isOpen ? 'Buka layanan?' : 'Tutup layanan?',

      message: isOpen
          ? 'Mahasiswa dapat mengambil nomor antrean pada layanan ini.'
          : 'Mahasiswa tidak dapat mengambil nomor antrean baru.',

      confirmText: isOpen ? 'Buka' : 'Tutup',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _queueService.setServiceOpen(layananId: layananId, isOpen: isOpen);

      _showMessage(
        isOpen ? 'Layanan berhasil dibuka.' : 'Layanan berhasil ditutup.',
      );
    } catch (error) {
      _showMessage('Gagal mengubah status layanan: ${_errorMessage(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // =====================================================
  // 5. LOGOUT
  // =====================================================

  Future<void> _logout(AuthProvider auth) async {
    if (_isLoggingOut) return;

    final confirmed = await _confirmAction(
      title: 'Keluar dari aplikasi?',
      message: 'Anda akan keluar dari akun petugas.',
      confirmText: 'Keluar',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await auth.signOut();
    } catch (error) {
      _showMessage('Gagal logout: ${_errorMessage(error)}');

      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  // =====================================================
  // 6. BUILD UTAMA
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final profile = auth.userProfile;

    // Memeriksa proses autentikasi.
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Memeriksa profil dan role petugas.
    if (profile == null ||
        profile.role != 'petugas' ||
        profile.layananId == null ||
        profile.layananId!.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Akun petugas tidak memiliki data unit layanan. '
              'Silakan hubungi administrator.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Mengambil ID layanan dari profil petugas.
    final layananId = profile.layananId!;

    // Menyiapkan stream berdasarkan unit petugas.
    _prepareStreams(layananId);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: AppBar(
        title: const Text(
          'CampusQueue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          if (_isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Keluar',
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(auth),
            ),

          const SizedBox(width: 8),
        ],
      ),

      body: StreamBuilder<ServiceModel?>(
        stream: _serviceStream,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildError('Gagal mengambil data layanan.');
          }

          final service = snapshot.data;

          if (service == null) {
            return _buildError('Data layanan tidak ditemukan.');
          }

          return _buildDashboardContent(
            service: service,
            layananId: layananId,
            namaPetugas: profile.nama,
          );
        },
      ),
    );
  }

  // =====================================================
  // 7. KONTEN DASHBOARD
  // =====================================================

  Widget _buildDashboardContent({
    required ServiceModel service,
    required String layananId,
    required String namaPetugas,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sapaan petugas.
        _buildWelcomeCard(namaPetugas),

        const SizedBox(height: 20),

        // Informasi unit layanan.
        _buildServiceCard(service: service, layananId: layananId),

        const SizedBox(height: 24),

        // Judul antrean aktif.
        const Text(
          'Antrean Sedang Dipanggil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        // Data antrean aktif.
        _buildCurrentQueue(),

        const SizedBox(height: 12),

        // Tombol memanggil antrean berikutnya.
        _buildCallNextButton(layananId),

        const SizedBox(height: 24),

        // Judul antrean menunggu.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Daftar Antrean Menunggu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(
              Icons.groups_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Data antrean menunggu.
        _buildWaitingQueue(),

        const SizedBox(height: 24),
      ],
    );
  }

  // =====================================================
  // 8. KARTU SAMBUTAN
  // =====================================================

  Widget _buildWelcomeCard(String namaPetugas) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(context).colorScheme.primary,

              child: Icon(
                Icons.support_agent,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 30,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    'Selamat bertugas,',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    namaPetugas,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 9. KARTU INFORMASI LAYANAN
  // =====================================================

  Widget _buildServiceCard({
    required ServiceModel service,
    required String layananId,
  }) {
    final isOpen = service.isOpen;

    return Card(
      elevation: 1,

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    'Informasi Unit Layanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            Text(
              service.nama,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.confirmation_number_outlined,
              'Kode layanan',
              layananId,
            ),

            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.location_on_outlined,
              'Lokasi',
              service.lokasi.isEmpty ? 'Belum tersedia' : service.lokasi,
            ),

            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.access_time,
              'Jam operasional',
              '${service.jamBuka} - ${service.jamTutup}',
            ),

            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.timer_outlined,
              'Estimasi pelayanan',
              '${service.estimasiMenit} menit/orang',
            ),

            const Divider(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Status Layanan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Kelola status buka atau tutup',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Switch(
                  value: isOpen,

                  onChanged: _isProcessing
                      ? null
                      : (value) {
                          _changeServiceStatus(
                            layananId: layananId,
                            isOpen: value,
                          );
                        },
                ),
              ],
            ),

            Align(
              alignment: Alignment.centerRight,

              child: _buildStatusChip(isOpen ? 'Buka' : 'Tutup', isOpen),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 10. BARIS INFORMASI
  // =====================================================

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.grey),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // 11. STATUS CHIP
  // =====================================================

  Widget _buildStatusChip(String label, bool isOpen) {
    final color = isOpen ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // =====================================================
  // 12. ANTREAN SEDANG DIPANGGIL
  // =====================================================

  Widget _buildCurrentQueue() {
    return StreamBuilder<QueueModel?>(
      stream: _currentQueueStream,

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildError('Gagal mengambil antrean aktif.');
        }

        final queue = snapshot.data;

        if (queue == null) {
          return _buildEmptyCurrentQueue();
        }

        return _buildCurrentQueueCard(queue);
      },
    );
  }

  // =====================================================
  // 13. KARTU ANTREAN AKTIF
  // =====================================================

  Widget _buildCurrentQueueCard(QueueModel queue) {
    final waktuDipanggil = queue.calledAt == null
        ? '-'
        : DateFormat('HH:mm').format(queue.calledAt!);

    return Card(
      elevation: 1,

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const Text(
              'NOMOR ANTREAN',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              queue.nomor,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // KEPerLUAN MAHASISWA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,

                borderRadius: BorderRadius.circular(12),
              ),

              child: Column(
                children: [
                  const Text(
                    'Keperluan Mahasiswa',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    queue.keperluan.isEmpty ? 'Belum diisi' : queue.keperluan,

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.campaign, size: 18),

                const SizedBox(width: 6),

                Text(
                  'Dipanggil pukul $waktuDipanggil',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _completeQueue(queue.id),

                    icon: const Icon(Icons.check_circle_outline),

                    label: const Text('Selesai'),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _skipQueue(queue.id),

                    icon: const Icon(Icons.skip_next),

                    label: const Text('Lewati'),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),

            if (_isProcessing) ...[
              const SizedBox(height: 14),

              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 14. KONDISI KOSONG ANTREAN AKTIF
  // =====================================================

  Widget _buildEmptyCurrentQueue() {
    return Card(
      elevation: 0,

      color: Theme.of(context).colorScheme.surfaceContainerHighest,

      child: const Padding(
        padding: EdgeInsets.all(24),

        child: Column(
          children: [
            Icon(Icons.hourglass_empty, size: 45, color: Colors.grey),

            SizedBox(height: 12),

            Text(
              'Belum ada antrean yang dipanggil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 5),

            Text(
              'Tekan tombol panggil untuk melayani antrean berikutnya.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 15. TOMBOL PANGGIL ANTREAN BERIKUTNYA
  // =====================================================

  Widget _buildCallNextButton(String layananId) {
    return SizedBox(
      width: double.infinity,
      height: 52,

      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : () => _callNext(layananId),

        icon: const Icon(Icons.campaign),

        label: Text(
          _isProcessing ? 'Memproses...' : 'Panggil Antrean Berikutnya',
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,

          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  // =====================================================
  // 16. DAFTAR ANTREAN MENUNGGU
  // =====================================================

  Widget _buildWaitingQueue() {
    return StreamBuilder<List<QueueModel>>(
      stream: _waitingQueueStream,

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildError('Gagal mengambil daftar antrean menunggu.');
        }

        final queues = snapshot.data ?? [];

        if (queues.isEmpty) {
          return _buildEmptyWaitingQueue();
        }

        return Card(
          elevation: 1,

          child: Column(
            children: List.generate(queues.length, (index) {
              final queue = queues[index];

              final waktuAmbil = DateFormat('HH:mm').format(queue.createdAt);

              return Column(
                children: [
                  _buildWaitingQueueItem(
                    queue: queue,
                    waktuAmbil: waktuAmbil,
                    index: index,
                  ),

                  if (index != queues.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // =====================================================
  // 17. ITEM ANTREAN MENUNGGU
  // =====================================================

  Widget _buildWaitingQueueItem({
    required QueueModel queue,
    required String waktuAmbil,
    required int index,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,

        child: Text(
          queue.nomor.isNotEmpty ? queue.nomor.substring(0, 1) : '?',

          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),

      title: Text(
        queue.nomor,

        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),

      // KEPerLUAN DAN WAKTU PENGAMBILAN
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              queue.keperluan.isEmpty
                  ? 'Keperluan belum diisi'
                  : queue.keperluan,

              maxLines: 2,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.access_time, size: 13, color: Colors.grey),

                const SizedBox(width: 4),

                Text(
                  'Diambil pukul $waktuAmbil',

                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),

      trailing: _buildWaitingStatus(),
    );
  }

  // =====================================================
  // 18. STATUS ANTREAN MENUNGGU
  // =====================================================

  Widget _buildWaitingStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(20),
      ),

      child: const Text(
        'Menunggu',

        style: TextStyle(
          color: Colors.orange,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =====================================================
  // 19. KONDISI KOSONG ANTREAN MENUNGGU
  // =====================================================

  Widget _buildEmptyWaitingQueue() {
    return Card(
      elevation: 0,

      color: Theme.of(context).colorScheme.surfaceContainerHighest,

      child: const Padding(
        padding: EdgeInsets.all(24),

        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 42, color: Colors.grey),

            SizedBox(height: 10),

            Text(
              'Belum ada antrean yang menunggu.',
              textAlign: TextAlign.center,

              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 20. TAMPILAN ERROR
  // =====================================================

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.red),

            const SizedBox(height: 12),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {});
              },

              icon: const Icon(Icons.refresh),

              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
