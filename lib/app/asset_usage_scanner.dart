import 'package:media_asset_optimizer/data/file_system_client.dart';
import 'package:media_asset_optimizer/service/android_assets_search_service.dart';
import 'package:media_asset_optimizer/service/assets_search_service.dart';
import 'package:media_asset_optimizer/service/ios_assets_search_service.dart';
import 'package:media_asset_optimizer/ui/console.dart';
import 'package:path/path.dart' as p;

// ignore_for_file: constant_identifier_names

const ASSETS_DIR = 'assets';
const ANDROID_ASSETS_DIR = 'android/app/src/main/res';
const IOS_ASSETS_DIR = 'ios/Runner/Assets/xcassets';

// const MACOS_ASSETS_DIR = 'macos/Runner/Assets.xcassets';
// const WINDOWS_ASSETS_DIR = 'windows/runner/resources';
// const LINUX_ASSETS_DIR = 'linux/runner/resources';

typedef AssetUsageScanResults = ({
  List<String> pubspecAssets,
  Set<String> allNormalizedLiterals,
  Set<String> allAssets,
  Set<String> usedAssets
});

typedef SearchServices = ({
  AssetsSearchService assetService,
  AndroidAssetsSearchService androidService,
  IosAssetsSearchService iosService,
});

class AssetUsageScanner {
  AssetUsageScanner({
    required this.fs,
    SearchServices? searchServices,
    Console? console,
  })  : searchServices = searchServices ??
            (
              assetService: AssetsSearchService(),
              androidService: AndroidAssetsSearchService(),
              iosService: IosAssetsSearchService()
            ),
        console = console ?? Console();

  final FileSystemClient fs;
  final Console console;
  final SearchServices searchServices;

  Future<AssetUsageScanResults> init() {
    return console.printLoading<AssetUsageScanResults>(
        message: "Finding assets and their usage",
        work: () {
          final pubspecAssets = getPubspecAssets();
          final allNormalizedLiterals = getAllNormalizedLiterals();
          final allAssets = getAllAssets();
          if (allAssets.isEmpty) {
            console.printWarning('No assets found in project');
            throw 'No assets found in project';
          }
          final usedAssets = getUsedAssets(allAssets, allNormalizedLiterals);

          return (
            pubspecAssets: pubspecAssets,
            allNormalizedLiterals: allNormalizedLiterals,
            allAssets: allAssets,
            usedAssets: usedAssets
          );
        });
  }

  List<String> getPubspecAssets() {
    final pubspecContent = fs.readPubspec();
    return searchServices.assetService
        .extractPubspecAssets(pubspecContent, fs.projectRoot);
  }

  Set<String> getAllNormalizedLiterals() {
    return _mapAllDartFilesInProject((curFile) {
      final literals = searchServices.assetService
          .findAllStringLiteralsInFile(fs.readAsString(curFile));
      return literals;
    });
  }

  Set<String> getAllAssets() {
    return _findAllFilesInDirectories([ASSETS_DIR]);
  }

  Set<String> getUsedAssets(
      Set<String> allAssets, Set<String> allNormalizedLiterals) {
    return searchServices.assetService
        .matchAssetsAndStringLiterals(allAssets, allNormalizedLiterals);
  }

  // ===============
  // Helpers
  // ==============

  /// Execute [mapper] on all Dart files in project
  /// Aggregate the results and return
  Set<String> _mapAllDartFilesInProject(Set<String> Function(String) mapper) {
    final result = <String>{};
    final libDir = p.join(fs.projectRoot, 'lib');
    if (fs.directoryExists(libDir)) {
      try {
        for (var entity in fs.listFilesSync(libDir)) {
          if (fs.isFile(entity) &&
              entity.endsWith('.dart') &&
              !_shouldIgnore(entity)) {
            result.addAll(mapper(entity));
          }
        }
      } catch (e) {
        final msg = 'Error traversing directory $libDir: $e';
        console.printError(msg);
        throw msg;
      }
      return result;
    } else {
      final msg = 'Lib directory not found at ${fs.projectRoot}';
      console.printError(msg);
      throw msg;
    }
  }

  /// Find all files in a directory
  Set<String> _findAllFilesInDirectory(String dir, {bool isFirst = false}) {
    final files = <String>{};
    if (!fs.directoryExists(dir)) {
      // console.printWarning(
      //     '${isFirst ? '\n' : ''}Assets directory not found at $dir');
      return files;
    }
    for (var entity in fs.listFilesSync(dir)) {
      try {
        if (fs.isFile(entity)) {
          if (!p.basename(entity).startsWith('.')) {
            files.add(
                p.relative(entity, from: fs.projectRoot).replaceAll('\\', '/'));
          }
        }
      } catch (e) {
        console.printError('Error listing files in /$dir: $e');
      }
    }
    if (files.isEmpty) {
      console.printWarning(
          '\nNo files found in the assets directory /$dir (Excluding hidden files)');
    } else {
      console.printInfo(
        '\nFound ${files.length} files in /$dir',
      );
    }
    return files;
  }

  /// Find all files from a set of directories
  Set<String> _findAllFilesInDirectories(List<String> directories) {
    final result = <String>{};
    for (var dir in directories) {
      result.addAll(
          _findAllFilesInDirectory(dir, isFirst: directories.first == dir));
    }
    return result;
  }

  bool _shouldIgnore(String path) {
    final filePath = path.replaceAll('\\', '/');
    final rootPath = fs.projectRoot.replaceAll('\\', '/');
    return fs.ignoredDirs.any((dir) {
      final ignoredPath = p.join(rootPath, dir).replaceAll('\\', '/');
      return filePath.contains(ignoredPath);
    });
  }
}
