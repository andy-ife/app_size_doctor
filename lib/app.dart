import 'dart:io';
import 'package:media_asset_optimizer/app/analysis_printer.dart';
import 'package:media_asset_optimizer/app/asset_compressor.dart';
import 'package:media_asset_optimizer/app/asset_usage_scanner.dart';
import 'package:media_asset_optimizer/media_asset_optimizer.dart';
import 'package:media_asset_optimizer/data/file_system_client.dart';
import 'package:media_asset_optimizer/ui/cli.dart';
import 'package:media_asset_optimizer/ui/console.dart';
import 'package:path/path.dart' as p;

const test_asset_reference2 = 'test_pic2.jpg';
const test_asset_reference3 = 'test_vid1.mp4';
const test_asset_reference4 = 'test_aud1.mp3';
const test_asset_reference5 = 'test_vid3.mkv';
const test_asset_ref6 = 'test_aud2.mp3';
const test_asset_ref7 = 'test_pic1.bmp';
const test_asset_ref8 = 'test_pic3.png';
const test_asset_ref9 = 'test_pic4.tif';
const test_asset_ref10 = 'test_pic5.gif';
const test_asset_ref11 = 'test_pic6.webp';
const test_asset_ref12 = 'test_pic7.avif';
const test_asset_ref13 = 'test_vid2.webm';

class App {
  static void cleanup() async {
    Console().resetConsole();
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

    final fs = FileSystemClient(
      projectRoot: projectRoot,
      ignoredDirs: ignoredDirs,
      pubspecPath: pubspecPath,
    );

    final scanner = AssetUsageScanner(fs: fs);

    final cliMode = Cli().start(args);

    if (cliMode == CliMode.none) {
      exit(0);
    }

    final initialData = await scanner.init();

    // Start
    final assetDoctor = MediaAssetOptimizer(
        cliMode: cliMode,
        assetCompressor: AssetCompressor(
          allAssets: initialData.allAssets,
          usedAssets: initialData.usedAssets,
          fs: scanner.fs,
        ),
        analysisPrinter: AnalysisPrinter(
          usedAssets: initialData.usedAssets,
          pubspecAssets: initialData.pubspecAssets,
          fs: scanner.fs,
        ));

    await assetDoctor.run();
    exit(0);
  }
}
