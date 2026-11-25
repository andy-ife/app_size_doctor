import 'package:media_asset_optimizer/app/analysis_printer.dart';
import 'package:media_asset_optimizer/app/asset_compressor.dart';
import 'package:media_asset_optimizer/ui/cli.dart';

class MediaAssetOptimizer {
  const MediaAssetOptimizer(
      {required this.cliMode,
      required this.assetCompressor,
      required this.analysisPrinter,
      this.singleFile});

  final CliMode cliMode;

  /// Asset to compress when [cliMode] is [CliMode.compressFile].
  final String? singleFile;

  final AssetCompressor assetCompressor;
  final AnalysisPrinter analysisPrinter;

  Future<void> run() async {
    switch (cliMode) {
      case CliMode.compressAll || CliMode.compressSome:
        {
          final result = await compress(
              selectAssetsToIgnore: cliMode == CliMode.compressSome);
          if (result == null) return;

          if (result.hasCompressed) {
            analysisPrinter.printPubspecAnalysis();
            analysisPrinter.printWorkSummary(result);
          }
          break;
        }
      case CliMode.compressFile:
        {
          final assetPath = singleFile;
          if (assetPath == null) {
            break;
          }
          final result = await assetCompressor.compressFile(assetPath);
          if (result != null && result.hasCompressed) {
            analysisPrinter.printWorkSummary(result);
          }
          break;
        }
      case CliMode.dryRun:
        {
          await dryRun();
          // analysisPrinter.printPubspecAnalysis();
          break;
        }
      case CliMode.none:
        {
          break;
        }
    }
  }

  Future<void> dryRun() async {
    final compressResult = assetCompressor.analyze();

    analysisPrinter.printDryRunAnalysis(compressResult);
  }

  Future<CompressResult?> compress({required bool selectAssetsToIgnore}) async {
    final compress0 = assetCompressor.analyze();
    analysisPrinter.printCompressAnalysis(compress0);

    final compress1 = await assetCompressor.compress(
        selectAssetsToIgnore: selectAssetsToIgnore);
    return compress1;
  }
}
