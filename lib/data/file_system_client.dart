import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

/// Simple wrapper around dart:io
/// Contains information about the current project and directories
class FileSystemClient {
  FileSystemClient(
      {String? projectRoot, String? pubspecPath, List<String>? ignoredDirs})
      : projectRoot = projectRoot ?? Directory.current.absolute.path,
        pubspecPath = pubspecPath ?? p.join(projectRoot!, 'pubspec.yaml'),
        ignoredDirs = ignoredDirs ?? ['test', 'build'];
  final String projectRoot;
  final String pubspecPath;
  final List<String> ignoredDirs; // folders to ignore during code search

  // ===========
  // Process
  // ===========
  FsProcessResult runProcess(String executable, List<String> args) {
    final result = Process.runSync(executable, args);
    return FsProcessResult(result.exitCode);
  }

  // ===========
  // Platform
  // ===========

  bool get isWindows => Platform.isWindows;
  bool get isMacOS => Platform.isMacOS;
  bool get isLinux => Platform.isLinux;

  // ============
  // File
  // ============

  String readPubspec() {
    return readAsString(pubspecPath);
  }

  bool fileExists(String path) {
    return File(path).existsSync();
  }

  bool isFile(String path) {
    return fileExists(path);
  }

  void create(String path) {
    return File(path).createSync(recursive: true);
  }

  String readAsString(String path) {
    return File(path).readAsStringSync();
  }

  Uint8List readAsBytes(String path) {
    return File(path).readAsBytesSync();
  }

  void writeAsBytes(String path, Uint8List bytes) {
    return File(path).writeAsBytesSync(bytes);
  }

  int lengthSync(String path) {
    return File(path).lengthSync();
  }

  Future<int> length(String path) {
    return File(path).length();
  }

  Future<void> delete(String path) {
    return File(path).delete();
  }

  void deleteSync(String path) {
    return File(path).deleteSync();
  }

  // ============
  // Directory
  // ============

  bool directoryExists(String path) {
    return Directory(path).existsSync();
  }

  bool isDirectory(String path) {
    return directoryExists(path);
  }

  String get currentDir => Directory.current.path;

  Set<String> listFilesSync(String path) {
    return Directory(path).listSync(recursive: true).map((e) => e.path).toSet();
  }

  List<String> getFilesRecursivelyRelative(String dirPath) {
    final files = <String>[];
    if (!directoryExists(dirPath)) return files;
    try {
      for (var entity in listFilesSync(dirPath)) {
        if (isFile(entity)) {
          files
              .add(p.relative(entity, from: projectRoot).replaceAll('\\', '/'));
        }
      }
    } catch (e) {
      rethrow;
    }
    return files;
  }
}

final class FsProcessResult {
  FsProcessResult(this.exitCode);
  int exitCode;
}
