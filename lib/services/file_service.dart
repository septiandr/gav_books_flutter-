import 'dart:io';

class FileService {
  static Future<List<FileSystemEntity>> listPdfFiles(String path) async {
    final dir = Directory(path);
    final files = dir.listSync(recursive: true);
    return files.where((f) => f.path.endsWith('.pdf')).toList();
  }
}
