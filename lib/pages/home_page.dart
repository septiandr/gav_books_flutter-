import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gav_books_flutter/pages/view_page.dart';
import 'package:gav_books_flutter/services/file_service.dart';
import 'package:path/path.dart' as pathLib;

class BookListPage extends StatefulWidget {
  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  List<FileSystemEntity> pdfFiles = [];
  String? lastViewedPath;

  // Tambahkan cache thumbnail di sini
  final Map<String, Image?> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  /// Meminta izin storage, mengambil path file terakhir yang dibuka dari SharedPreferences,
  /// lalu memuat daftar file PDF dari folder '/storage/emulated/0/books' dan memperbarui state.
  Future<void> loadFiles() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();

    final prefs = await SharedPreferences.getInstance();
    lastViewedPath = prefs.getString('lastViewed');

    final files = await FileService.listPdfFiles("/storage/emulated/0/books");
    setState(() {
      pdfFiles = files;
    });
  }

  /// Mengambil thumbnail (gambar kecil) dari halaman pertama file PDF pada path yang diberikan.
  /// Jika sudah ada di cache, gunakan yang di cache. Jika belum, buat baru dan simpan ke cache.
  Future<Image?> getPdfThumbnail(String path) async {
    // Cek cache terlebih dahulu
    if (_thumbnailCache.containsKey(path)) {
      return _thumbnailCache[path];
    }

    final doc = await PdfDocument.openFile(path);
    final page = await doc.getPage(1);

    final pageImage = await page.render(
      width: 100,
      height: 150,
    );

    final uiImage = await _convertToUiImage(
      pageImage!.pixels,
      pageImage.width,
      pageImage.height,
    );

    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final image = Image.memory(pngBytes, fit: BoxFit.cover);

    // Simpan ke cache
    _thumbnailCache[path] = image;

    return image;
  }

  /// Mengonversi array pixel hasil render PDF menjadi objek ui.Image.
  /// [pixels]: data pixel gambar.
  /// [width]: lebar gambar.
  /// [height]: tinggi gambar.
  /// return: Future<ui.Image> objek gambar hasil konversi.
  Future<ui.Image> _convertToUiImage(
      Uint8List pixels, int width, int height) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) => completer.complete(img),
    );
    return completer.future;
  }

  /// Menyimpan path file PDF yang dibuka ke SharedPreferences sebagai file terakhir yang dilihat,
  /// lalu menavigasi ke halaman viewer PDF.
  /// [path]: path file PDF yang akan dibuka.
  void openPdf(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastViewed', path);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(path: path)),
    );
    // Setelah kembali dari viewer, refresh lastViewedPath
    await loadFiles();
  }

  Future<void> renamePdf(FileSystemEntity file) async {
    final oldPath = file.path;
    final fileName = oldPath.split('/').last;
    final dir = oldPath.substring(0, oldPath.lastIndexOf('/'));
    final controller =
        TextEditingController(text: fileName.replaceAll('.pdf', ''));

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Nama PDF'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Nama baru'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Simpan'),
          ),
        ],
      ),
    );

    if (newName != null &&
        newName.trim().isNotEmpty &&
        newName != fileName.replaceAll('.pdf', '')) {
      final newPath = pathLib.join(dir, newName.trim() + '.pdf');
      await File(oldPath).rename(newPath);
      await loadFiles();
    }
  }

  Future<void> deletePdf(FileSystemEntity file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus PDF'),
        content: Text('Yakin ingin menghapus file ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      await File(file.path).delete();
      await loadFiles();
    }
  }

  /// Membangun tampilan halaman utama aplikasi, menampilkan daftar file PDF beserta thumbnail,
  /// serta shortcut ke file terakhir yang dibuka.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GAV Books')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (lastViewedPath != null)
              Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.history, color: Colors.blue),
                  title: Text(
                    "Last viewed",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(lastViewedPath!.split('/').last),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => openPdf(lastViewedPath!),
                ),
              ),
            SizedBox(height: 8),
            Flexible(
              child: RefreshIndicator(
                onRefresh: loadFiles,
                child: ListView.separated(
                  itemCount: pdfFiles.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final file = pdfFiles[index];
                    return FutureBuilder<Image?>(
                      future: getPdfThumbnail(file.path),
                      builder: (context, snapshot) {
                        Widget thumbnail = snapshot.hasData
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 50,
                                  height: 70,
                                  child: snapshot.data!,
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                        return ListTile(
                          leading: thumbnail,
                          title: Text(
                            file.path
                                .split('/')
                                .last
                                .replaceAll(RegExp(r'[_\-\+]'), ' '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => openPdf(file.path),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'rename') {
                                renamePdf(file);
                              } else if (value == 'delete') {
                                deletePdf(file);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('Edit Nama'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
