# Setup Health Connect (Steps + Heart Rate) - Lengkap dan Detail

## 2. Prasyarat

1. Device Android yang mendukung Health Connect.
2. Aplikasi Health Connect terpasang.
3. Data steps dan/atau heart rate sudah ada di Health Connect (agar ada data untuk ditampilkan).
4. Koneksi internet aktif saat instalasi/aktivasi awal.

## 3. Struktur File yang Terkait

1. `lib/home_page.dart`
   - Logic utama koneksi, request izin, baca data, dan update UI.
2. `android/app/src/main/AndroidManifest.xml`
   - Deklarasi permission dan entry Health Connect.
3. `android/app/src/main/kotlin/com/example/flutter_application/MainActivity.kt`
   - Activity utama berbasis `FlutterFragmentActivity`.

## 4. Konfigurasi Android Wajib

### 4.1 Permission Manifest

Permission yang dipakai saat ini:

1. `android.permission.ACTIVITY_RECOGNITION`
2. `android.permission.health.READ_STEPS`
3. `android.permission.health.WRITE_STEPS`
4. `android.permission.health.READ_HEART_RATE`
5. `android.permission.health.WRITE_HEART_RATE`

Catatan:

1. Walaupun saat ini app fokus membaca data, deklarasi WRITE dipertahankan untuk kompatibilitas flow permission Health Connect tertentu.
2. Jika permission yang diminta runtime tidak dideklarasikan di manifest, plugin bisa mengembalikan log:
   - Health Connect permissions were not granted.

### 4.2 Entry Manifest Lain yang Penting

1. `queries` untuk package Health Connect:
   - `com.google.android.apps.healthdata`
2. `intent-filter` action:
   - `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE`
3. `activity-alias`:
   - `ViewPermissionUsageActivity`

### 4.3 MainActivity

`MainActivity` harus menggunakan:

1. `FlutterFragmentActivity`

Alasan:

1. Flow permission Health Connect modern menggunakan mekanisme berbasis Activity Result API yang kompatibel dengan pendekatan ini.

## 5. Detail Fungsi-Fungsi di Home Page

Berikut penjelasan fungsi per fungsi di `lib/home_page.dart`.

### 5.1 `createState()`

Fungsi:

1. Membuat instance state `_HomePageState`.

Peran:

1. Menyediakan lifecycle dan state management untuk halaman Home.

### 5.2 `initState()`

Fungsi:

1. Lifecycle awal saat widget dibuat.
2. Memanggil `_configureHealth()`.

Peran:

1. Menyiapkan plugin health sedini mungkin sebelum tombol koneksi ditekan.

### 5.3 `_configureHealth()`

Fungsi:

1. Menjalankan `_health.configure()`.
2. Mengubah status UI menjadi siap dipakai atau gagal inisialisasi.

Peran:

1. Inisialisasi wajib plugin sebelum panggilan API health lainnya.

Output ke UI:

1. `Health plugin siap digunakan` jika sukses.
2. `Gagal inisialisasi Health plugin` jika gagal.

### 5.4 `_connectAndReadHealthData()`

Fungsi utama integrasi. Urutan kerjanya:

1. Set loading `true` dan update status awal.
2. Cek ketersediaan Health Connect dengan `isHealthConnectAvailable()`.
3. Jika belum tersedia:
   - Jalankan `installHealthConnect()`.
   - Tampilkan status agar user install dulu.
4. Cek izin saat ini dengan `hasPermissions(...)`.
5. Jika belum ada izin:
   - Minta izin via `requestAuthorization(...)`.
6. Jika izin ditolak:
   - Set status ditolak.
7. Jika izin diterima:
   - Ambil langkah hari ini: `getTotalStepsInInterval(startOfDay, now)`.
   - Ambil heart rate hari ini: `getHealthDataFromTypes(...)` untuk `HEART_RATE`.
   - Urutkan data heart rate berdasarkan waktu terbaru.
   - Simpan heart rate paling baru jika tipe nilainya numerik.
8. Update UI akhir: status terhubung, steps, heart rate, loading `false`.

Peran:

1. Menjadi entry point tunggal untuk koneksi + baca data.

### 5.5 `build(BuildContext context)`

Fungsi:

1. Merender tampilan status koneksi.
2. Menampilkan nilai steps dan heart rate terbaru.
3. Menyediakan tombol trigger ke `_connectAndReadHealthData()`.

Peran:

1. Menjembatani state internal ke UI agar user tahu progres dan hasil.

## 6. Fungsi Package Health yang Dipakai

Metode plugin yang dipanggil dari Home Page:

1. `configure()`
   - Inisialisasi plugin.
2. `isHealthConnectAvailable()`
   - Mengecek Health Connect tersedia/siap.
3. `installHealthConnect()`
   - Arahkan user install Health Connect jika belum ada.
4. `hasPermissions(types, permissions)`
   - Cek izin sudah ada atau belum.
5. `requestAuthorization(types, permissions)`
   - Meminta izin data ke user.
6. `getTotalStepsInInterval(start, end)`
   - Ambil total langkah pada rentang waktu.
7. `getHealthDataFromTypes(types, startTime, endTime)`
   - Ambil daftar data kesehatan (untuk heart rate).

## 7. Mapping Data ke UI

State penting di `_HomePageState`:

1. `_statusMessage`
   - Menyimpan status proses koneksi.
2. `_todaySteps`
   - Menyimpan total langkah hari ini.
3. `_latestHeartRate`
   - Menyimpan heart rate terbaru (bpm).
4. `_isLoading`
   - Mengontrol loading state tombol.

## 8. Cara Menjalankan yang Benar

Penting: perubahan AndroidManifest tidak terambil oleh hot restart.

Jalankan urutan berikut:

1. Uninstall aplikasi dari device.
2. Dari root project, jalankan:

```bash
flutter clean
flutter pub get
flutter run
```

3. Saat dialog Health Connect muncul, berikan izin Steps dan Heart Rate.

## 9. Troubleshooting Detail

### 9.1 Error: "Health Connect permissions were not granted"

Kemungkinan penyebab:

1. APK belum memuat manifest terbaru (belum reinstall full).
2. Permission yang diminta runtime belum dideklarasikan manifest.
3. User menutup dialog tanpa menyetujui izin.
4. Izin dimatikan manual dari aplikasi Health Connect.

Langkah perbaikan:

1. Uninstall app.
2. Install ulang full (`flutter clean`, `flutter pub get`, `flutter run`).
3. Buka Health Connect -> App permissions -> aktifkan semua permission terkait.
4. Force close app lalu buka lagi.

### 9.2 Steps ada, Heart Rate kosong

Kemungkinan penyebab:

1. Memang belum ada data heart rate hari ini.
2. Data heart rate ada di rentang waktu lain.

Langkah cek:

1. Buka app Health Connect, pastikan ada record heart rate pada hari ini.
2. Ulang fetch dari tombol.

### 9.3 Cek apakah permission sudah benar-benar masuk APK

Opsional via ADB:

```bash
adb shell dumpsys package com.example.flutter_application
```

Lalu pastikan permission health yang diperlukan muncul di bagian requested permissions.

Jika ada lebih dari satu device terhubung:

```bash
adb devices -l
adb -s SERIAL_DEVICE shell dumpsys package com.example.flutter_application
```

## 10. Checklist Verifikasi Akhir

1. Aplikasi tidak error saat tombol koneksi ditekan.
2. Status berubah menjadi terhubung.
3. Nilai langkah tampil angka.
4. Nilai heart rate tampil angka bpm jika data tersedia.
5. Tidak ada log error permission berulang.

## 11. Ringkasan Singkat Alur Runtime

1. `initState()` memanggil `_configureHealth()`.
2. User menekan tombol, fungsi `_connectAndReadHealthData()` berjalan.
3. App cek availability + permission.
4. Jika lolos, app baca steps dan heart rate.
5. UI menampilkan hasil terbaru.
