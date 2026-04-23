import 'package:flutter/material.dart';
import 'package:health/health.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  /// Membuat state untuk halaman Home yang mengelola koneksi Health Connect.
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Health _health = Health();

  final List<HealthDataType> _healthTypes = const [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  final List<HealthDataAccess> _permissions = const [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  String _statusMessage = 'Belum terhubung ke Health Connect';
  int? _todaySteps;
  num? _latestHeartRate;
  bool _isLoading = false;

  /// Menjalankan konfigurasi awal plugin health saat halaman pertama kali dibuat.
  @override
  void initState() {
    super.initState();
    _configureHealth();
  }

  /// Menginisialisasi plugin health agar siap dipakai untuk request izin dan baca data.
  Future<void> _configureHealth() async {
    try {
      await _health.configure();
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Health plugin siap digunakan';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Gagal inisialisasi Health plugin';
      });
    }
  }

  /// Menghubungkan aplikasi ke Health Connect lalu membaca langkah dan heart rate hari ini.
  Future<void> _connectAndReadHealthData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Mengecek Health Connect...';
    });

    try {
      final isAvailable = await _health.isHealthConnectAvailable();
      if (!isAvailable) {
        await _health.installHealthConnect();
        if (!mounted) return;
        setState(() {
          _statusMessage =
              'Health Connect belum terpasang. Silakan install dulu dari Play Store.';
          _isLoading = false;
        });
        return;
      }

      final hasAccess =
          await _health.hasPermissions(
            _healthTypes,
            permissions: _permissions,
          ) ??
          false;

      final isAuthorized = hasAccess
          ? true
          : await _health.requestAuthorization(
              _healthTypes,
              permissions: _permissions,
            );

      if (!isAuthorized) {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Izin Health Connect ditolak';
          _isLoading = false;
        });
        return;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(startOfDay, now);
      final heartRatePoints = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: startOfDay,
        endTime: now,
      );

      num? latestHeartRate;
      if (heartRatePoints.isNotEmpty) {
        heartRatePoints.sort((a, b) => b.dateTo.compareTo(a.dateTo));
        final latestValue = heartRatePoints.first.value;
        if (latestValue is NumericHealthValue) {
          latestHeartRate = latestValue.numericValue;
        }
      }

      if (!mounted) return;
      setState(() {
        _todaySteps = steps;
        _latestHeartRate = latestHeartRate;
        _statusMessage = 'Terhubung ke Health Connect';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Terjadi error saat konek ke Health Connect';
        _isLoading = false;
      });
    }
  }

  /// Membangun tampilan halaman yang menampilkan status koneksi dan data kesehatan.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Connect')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              _todaySteps == null
                  ? 'Langkah hari ini: belum tersedia'
                  : 'Langkah hari ini: $_todaySteps',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _latestHeartRate == null
                  ? 'Heart rate terbaru: belum tersedia'
                  : 'Heart rate terbaru: ${_latestHeartRate!.toStringAsFixed(0)} bpm',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _connectAndReadHealthData,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Koneksikan Health Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
