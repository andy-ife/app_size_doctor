import 'dart:io';
import 'package:media_asset_optimizer/src/app/analysis_printer.dart';
import 'package:media_asset_optimizer/src/app/asset_compressor.dart';
import 'package:media_asset_optimizer/src/app/asset_usage_scanner.dart';
import 'package:media_asset_optimizer/src/runner.dart';
import 'package:media_asset_optimizer/src/data/file_system_client.dart';
import 'package:media_asset_optimizer/src/ui/cli.dart';
import 'package:media_asset_optimizer/src/ui/console.dart';

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
  static final console = Console();

  static void cleanup() async {
    console.resetConsole();
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
    try {
      final ignoredDirs = ['test', 'build'];

      final fs = FileSystemClient(
        ignoredDirs: ignoredDirs,
      );

      if (fs.projectRoot != Directory.current.path) {
        console.printInfo('Changed project root to: ${fs.projectRoot}');
      }

      final scanner = AssetUsageScanner(fs: fs);

      final cli = Cli();
      final cliMode = cli.start(args);

      if (cliMode == CliMode.none) {
        exit(0);
      }

      final Set<String> allAssets;
      if (cliMode == CliMode.compressFile) {
        // A single file does not need the whole project scanned.
        allAssets = {};
      } else {
        allAssets = await scanner.getAllAssets();
      }

      if (allAssets.isEmpty && cliMode != CliMode.compressFile) {
        console.printInfo('\nNo assets found in the project. Exiting.');
        exit(0);
      }

      // Start
      final runner = Runner(
          cliMode: cliMode,
          singleFile: cli.singleFile,
          assetCompressor: AssetCompressor(
            allAssets: allAssets,
            fs: scanner.fs,
            quality: cli.quality,
          ),
          analysisPrinter: AnalysisPrinter(
            fs: scanner.fs,
          ));

      await runner.run();
    } catch (e) {
      console.printError(e.toString());
    } finally {
      cleanup();
      exit(0);
    }
  }
}
