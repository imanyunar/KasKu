# Dokumen User Acceptance Testing (UAT) - CatatKas UMKM

Dokumen ini berisi skenario pengujian untuk memastikan aplikasi **CatatKas UMKM** berjalan sesuai dengan kebutuhan pengguna. Anda dapat menggunakan daftar periksa (*checklist*) ini untuk melakukan pengujian manual pada perangkat Android Anda.

## 1. Instalasi dan Kesan Pertama
| ID | Skenario Pengujian | Langkah-langkah | Hasil yang Diharapkan | Status (Pass/Fail) |
|---|---|---|---|---|
| 1.1 | Instalasi APK | Install `CatatKas_UMKM.apk` di perangkat Android. | Aplikasi terinstal tanpa peringatan keamanan (Play Protect warning) atau berhasil di-bypass jika ada. Logo aplikasi yang muncul adalah Logo UNNES. | |
| 1.2 | Splash Screen | Buka aplikasi untuk pertama kalinya. | Tampil layar merah *maroon* dengan Logo UNNES dan tulisan "CATATKAS UMKM". | |
| 1.3 | Onboarding | Lewati Splash Screen. | Muncul 3 halaman panduan penggunaan (Onboarding). Halaman terakhir memiliki tombol "Mulai Gunakan Aplikasi". | |

## 2. Dasbor (Halaman Utama)
| ID | Skenario Pengujian | Langkah-langkah | Hasil yang Diharapkan | Status (Pass/Fail) |
|---|---|---|---|---|
| 2.1 | Tampilan Dasbor | Buka halaman utama. | Header menampilkan inisial atau logo, teks "CatatKas UMKM", dan tanggal hari ini. | |
| 2.2 | Ringkasan Saldo | Lihat bagian "Saldo Kas Saat Ini" dan "Bulan Ini". | Saldo Kas Saat Ini, Pemasukan, Pengeluaran, dan Laba Bersih tampil Rp 0 (jika belum ada transaksi). | |
| 2.3 | Tombol Navigasi | Klik menu "Katalog Produk", "Riwayat", dan "Buat PDF". | Halaman berpindah sesuai dengan menu yang diklik. | |

## 3. Tambah Transaksi & Ketik Cepat (Quick Input)
| ID | Skenario Pengujian | Langkah-langkah | Hasil yang Diharapkan | Status (Pass/Fail) |
|---|---|---|---|---|
| 3.1 | Ketik Cepat Pemasukan | Di Dasbor, klik "Tambah Transaksi". Di kolom input cepat, ketik: `jual bawang merah 1kg 20rb` lalu klik Simpan. | Transaksi tersimpan sebagai Pemasukan sebesar Rp 20.000 dengan nama barang "bawang merah". Saldo bertambah. | |
| 3.2 | Ketik Cepat Pengeluaran | Di kolom input cepat, ketik: `beli pupuk 2 50rb` lalu klik Simpan. | Transaksi tersimpan sebagai Pengeluaran sebesar Rp 50.000 dengan nama barang "pupuk". Saldo berkurang. | |
| 3.3 | Transaksi Manual | Gunakan form pengisian manual, pilih jenis "Pengeluaran", isi nama barang, jumlah, dan harga, lalu Simpan. | Transaksi berhasil tersimpan dan riwayat/saldo diperbarui dengan benar. | |

## 4. Riwayat Transaksi & Filter
| ID | Skenario Pengujian | Langkah-langkah | Hasil yang Diharapkan | Status (Pass/Fail) |
|---|---|---|---|---|
| 4.1 | Filter Tanggal | Buka menu "Riwayat", ubah filter menjadi "Hari Ini", "Minggu Ini", atau "Bulan Ini". | Daftar transaksi yang muncul sesuai dengan rentang waktu yang dipilih. Ringkasan laba/rugi di bawah filter juga berubah. | |
| 4.2 | Hapus Transaksi | Geser (swipe) salah satu transaksi ke kiri atau kanan, atau tekan lama untuk menghapus. | Muncul konfirmasi penghapusan. Setelah di-oke, transaksi hilang dari daftar dan saldo diperbarui. | |

## 5. Ekspor PDF Laporan
| ID | Skenario Pengujian | Langkah-langkah | Hasil yang Diharapkan | Status (Pass/Fail) |
|---|---|---|---|---|
| 5.1 | Buat PDF Dasbor | Di Dasbor, klik ikon PDF (Cetak Laporan). | Muncul loading "Membuat PDF Laporan...", lalu aplikasi PDF Viewer terbuka. Notifikasi "PDF Berhasil Dibuat" muncul di aplikasi dengan tombol Bagikan. | |
| 5.2 | Validasi Isi PDF | Lihat file PDF yang dihasilkan. | Format tabel rapi, logo dan teks "CatatKas UMKM" muncul di kop surat, nominal transaksi dan total laba/rugi sesuai dengan riwayat bulan ini. | |

## 6. Katalog Produk
| ID | Skenario Pengujian | Langkah-langkah | Hasil yang Diharapkan | Status (Pass/Fail) |
|---|---|---|---|---|
| 6.1 | Tambah Produk | Buka menu Katalog Produk, klik ikon '+', isi nama "Beras", harga 15000, satuan "kg". | Produk baru tersimpan di daftar katalog. | |
| 6.2 | Integrasi Autocomplete | Buka Tambah Transaksi Manual, mulai ketik "Ber". | Saran kata "Beras" muncul. Jika diklik, harga (15000) dan satuan (kg) otomatis terisi. | |

## 7. Pengaturan & Backup/Restore
| ID | Skenario Pengujian | Langkah-langkah | Hasil yang Diharapkan | Status (Pass/Fail) |
|---|---|---|---|---|
| 7.1 | Backup CSV | Buka menu Pengaturan (ikon di sudut kanan atas Dasbor), klik "Backup Data (Ekspor)". | File CSV berhasil disimpan ke folder Download perangkat Android. Muncul notifikasi sukses. | |
| 7.2 | Restore CSV | Hapus beberapa transaksi di aplikasi, lalu klik "Restore Data (Impor)" dan pilih file CSV tadi. | Data transaksi kembali seperti saat di-backup. Saldo ter-update kembali. | |
| 7.3 | Pengingat Backup (7 Hari) | Pastikan belum pernah backup (atau ubah tanggal HP lebih dari 7 hari), lalu buka ulang aplikasi. | Muncul *pop-up* "Amankan Data Anda" (modern simple) di halaman Dasbor. Klik "Backup Sekarang", file CSV akan terbuat dan menu Share (Bagikan) muncul untuk memilih WhatsApp. | |
| 7.4 | Tentang Aplikasi | Klik "Tentang CatatKas UMKM". | Menampilkan layar informasi dengan Logo UNNES, nama aplikasi, dan nama pengembang. | |

---
**Catatan untuk Pengujian:**
- Gunakan perangkat Android fisik untuk menguji fitur berbagi (Share) dan penyimpanan file (Backup/PDF).
- Centang kolom *Status* jika fitur sudah berfungsi dengan benar. Jika ada kesalahan (*bug*), catat di bagian keterangan.
