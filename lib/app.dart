import 'dart:io';
import 'package:asset_doctor/app/analysis_printer.dart';
import 'package:asset_doctor/app/asset_cleaner.dart';
import 'package:asset_doctor/app/asset_compressor.dart';
import 'package:asset_doctor/asset_doctor.dart';
import 'package:asset_doctor/app/asset_usage_scanner.dart';
import 'package:asset_doctor/ui/cli.dart';
import 'package:path/path.dart' as p;

const test_asset_reference2 = 'test_pic2.jpg';
const test_asset_reference3 = 'test_vid1.mp4';
const test_asset_reference4 = 'test_aud1.mp3';

class App {
  static void cleanup() async {
    stdout.write('\x1B[?25h'); // show cursor
  }

  static void start(List<String> args) async {
    ProcessSignal.sigint.watch().listen((signal) {
      cleanup();
      exit(0);
    });

    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((signal) {
        cleanup();
        exit(0);
      });
    }

    // App
    final projectRoot = Directory.current.path;
    final ignoredDirs = ['test', 'build'];
    final pubspecPath = p.join(projectRoot, 'pubspec.yaml');

    final scanner = AssetUsageScanner(
        projectRoot: projectRoot,
        ignoredDirs: ignoredDirs,
        pubspecPath: pubspecPath);

    final cliMode = Cli().start(args);

    if (cliMode == CliMode.none) {
      print('Exiting...');
      return;
    }

    final initialData = await scanner.init();

    // Start
    final assetDoctor = AssetDoctor(
        cliMode: cliMode,
        assetCleaner: AssetCleaner(
            allAssets: initialData.allAssets,
            usedAssets: initialData.usedAssets,
            fs: scanner.fs),
        assetCompressor:
            AssetCompressor(usedAssets: initialData.usedAssets, fs: scanner.fs),
        analysisPrinter: AnalysisPrinter(
            usedAssets: initialData.usedAssets,
            pubspecAssets: initialData.pubspecAssets,
            fs: scanner.fs));

    await assetDoctor.run();
    exit(0);
  }
}
