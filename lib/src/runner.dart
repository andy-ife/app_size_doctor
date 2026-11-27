import 'package:media_asset_optimizer/src/app/analysis_printer.dart';
import 'package:media_asset_optimizer/src/app/asset_compressor.dart';
import 'package:media_asset_optimizer/src/ui/cli.dart';

class Runner {
  const Runner(
      {required this.cliMode,
      required this.compressor,
      required this.printer,
      this.singleFile});

  final CliMode cliMode;

  /// Asset to compress when [cliMode] is [CliMode.compressFile].
  final String? singleFile;

  final AssetCompressor compressor;
  final AnalysisPrinter printer;

  Future<void> run() async {
    switch (cliMode) {
      case CliMode.compressAll || CliMode.compressSome:
        {
          final result = await compress(
              selectAssetsToIgnore: cliMode == CliMode.compressSome);
          if (result == null) return;

          if (result.hasCompressed) {
            printer.printWorkSummary(result);
          }
          break;
        }
      case CliMode.compressFile:
        {
          final assetPath = singleFile;
          if (assetPath == null) {
            break;
          }
          final result = await compressor.compressFile(assetPath);
          if (result != null && result.hasCompressed) {
            printer.printWorkSummary(result);
          }
          break;
        }
      case CliMode.dryRun:
        {
          await dryRun();
          break;
        }
      case CliMode.none:
        {
          break;
        }
    }
  }

  Future<void> dryRun() async {
    final compressResult = compressor.analyze();

    printer.printDryRunAnalysis(compressResult);
  }

  Future<CompressResult?> compress({required bool selectAssetsToIgnore}) async {
    final compress0 = compressor.analyze();
    printer.printCompressAnalysis(compress0);

    final compress1 = await compressor.compressMultiple(
        selectAssetsToIgnore: selectAssetsToIgnore);
    return compress1;
  }
}
