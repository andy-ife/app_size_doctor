import 'package:asset_doctor/app/analysis_printer.dart';
import 'package:asset_doctor/app/asset_compressor.dart';
import 'package:asset_doctor/app/models/compress_result.dart';
import 'package:asset_doctor/ui/cli.dart';

class AssetDoctor {
  const AssetDoctor(
      {required this.cliMode,
      required this.assetCompressor,
      required this.analysisPrinter});

  final CliMode cliMode;

  final AssetCompressor assetCompressor;
  final AnalysisPrinter analysisPrinter;

  Future<void> run() async {
    switch (cliMode) {
      case CliMode.compress:
        {
          final result = await compress();
          if (result == null) return;

          if (result.hasCompressed) {
            analysisPrinter.printPubspecAnalysis();
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

  Future<CompressResult?> compress() async {
    final compress0 = assetCompressor.analyze();
    analysisPrinter.printCompressAnalysis(compress0);

    final compress1 = await assetCompressor.compress();
    return compress1;
  }
}
