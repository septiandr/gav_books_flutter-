## Alur Aplikasi
1. Halaman Utama (BookListPage)
   
   - Saat aplikasi dibuka, aplikasi akan meminta izin akses storage.
   - Aplikasi akan mencari dan menampilkan daftar file PDF yang ada di folder /storage/emulated/0/books .
   - Jika sebelumnya ada file PDF yang sudah dibuka, aplikasi akan menampilkan shortcut "Last viewed" di bagian atas.
2. Melihat PDF
   
   - Pengguna dapat memilih file PDF dari daftar untuk membukanya.
   - Saat file PDF dibuka, aplikasi akan menyimpan path file tersebut sebagai "last viewed" di SharedPreferences.
   - Aplikasi juga menyimpan halaman terakhir yang dibaca, sehingga saat file PDF dibuka kembali, akan langsung diarahkan ke halaman terakhir tersebut.
3. Edit Nama dan Hapus PDF
   
   - Pada setiap item PDF di daftar, terdapat menu (ikon tiga titik) untuk mengedit nama file atau menghapus file PDF.
   - Jika memilih "Edit Nama", akan muncul dialog untuk mengganti nama file PDF.
   - Jika memilih "Hapus", akan muncul dialog konfirmasi sebelum file benar-benar dihapus.
4. Refresh Daftar PDF
   
   - Pengguna dapat melakukan pull-to-refresh (scroll ke atas) pada daftar PDF untuk memperbarui daftar file dan shortcut "Last viewed".

## Fitur Aplikasi
- Daftar PDF Otomatis: Menampilkan semua file PDF dari folder tertentu secara otomatis.
- Viewer PDF Lengkap: Bisa scroll, auto-scroll, dan melanjutkan ke halaman terakhir yang dibaca.
- Shortcut Last Viewed: Akses cepat ke file PDF terakhir yang dibuka.
- Edit Nama PDF: Ganti nama file PDF langsung dari aplikasi.
- Hapus PDF: Hapus file PDF dengan konfirmasi.
- Pull-to-Refresh: Swipe ke bawah untuk memperbarui daftar file dan shortcut.
- Notifikasi Harian: Notifikasi otomatis jam 4 pagi dan 7 malam berisi nama file PDF terakhir yang dibuka.
- Thumbnail PDF: Setiap file PDF di daftar menampilkan thumbnail halaman pertama.