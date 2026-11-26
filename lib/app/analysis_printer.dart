import 'package:media_asset_optimizer/app/asset_compressor.dart';
import 'package:media_asset_optimizer/data/file_system_client.dart';
import 'package:media_asset_optimizer/ui/console.dart';
import 'package:media_asset_optimizer/utils/extension.dart';

class AnalysisPrinter {
  AnalysisPrinter({
    required this.fs,
    Console? console,
  }) : console = console ?? Console();

  final FileSystemClient fs;
  final Console console;

  void printCompressAnalysis(CompressResult result) {
    final isAll =
        result.allMediaAssets.length == result.assetsForCompression.length;
    console.printWarning(
        '🔨 Assets MARKED FOR COMPRESSION (${isAll ? 'All' : 'Selected'} assets${isAll ? '' : ' only'}):');
    if (result.assetsForCompression.isNotEmpty) {
      console.printWarning('(${result.assetsForCompression.length} files)');
      console.printTree(paths: result.assetsForCompressionTree, prefix: '');
    } else {
      console.printInfo('  None found.');
    }

    final selectedAssets = result.assetsForCompression.toSet();
    final totalAssets = result.allMediaAssets.length;
    final totalForCompression = selectedAssets.length;
    final totalNotSelected =
        result.allMediaAssets.difference(selectedAssets).length;

    console.printSubHeader('Pre-compression Summary:');
    console.printInfo(
      '• Total assets (excluding hidden): ${totalAssets.toString()}',
    );

    console.printInfo(
      '• Assets marked for compression: ${totalForCompression.toString()}',
    );

    console.printInfo(
      '• Total media assets size: ${result.spaceOfMediaAssetsBeforeCompress.toStorageString()}',
    );

    console.printInfo(
      '• Assets not selected for compression: ${totalNotSelected.toString()}',
    );

    if (totalAssets > 0) {
      console.printInfo(
        '• Percentage selected for compression: ${((totalForCompression / totalAssets) * 100).toStringAsFixed(1)}%',
      );
    }

    console.printSuccess(
        '\n• Estimated space to be saved: ${result.potentiallySavedSpace.toStorageString()}');
  }

  /// Summarize what cleaning and compression would free up without
  /// changing any files. Meant to be more concise than the full
  /// [printCompressAnalysis] breakdown.
  void printDryRunAnalysis(CompressResult compressResult) {
    console.printHeader('Dry Run Analysis');
    console.printInfo('No files were changed. Here is what could be freed up:');

    final totalForCompression = compressResult.assetsForCompression.length;

    if (totalForCompression == 0) {
      console.printSuccess(
          '\n✨ Nothing to  compress. Your project is already lean.');
      return;
    }

    if (totalForCompression == 0) {
      console.printInfo('  Nothing to compress.');
    } else {
      console.printInfo(
        '• Assets marked for compression: ${totalForCompression.toString()}',
      );
      console.printInfo(
        '• Total media assets size: ${compressResult.spaceOfMediaAssetsBeforeCompress.toStorageString()}',
      );
      console.printInfo(
        '• Estimated savings: ${compressResult.potentiallySavedSpace.toStorageString()}',
      );
    }

    final totalPotentialSavings = compressResult.potentiallySavedSpace;
    console.printSubHeader('Total Potential Savings:');
    console.printSuccess(
        '• Estimated total savings: ${totalPotentialSavings.toStorageString()}');
    console.printInfo(
        '\nRun again without --dry-run to view detailed file trees and apply these changes.');
  }

  int countFilesInTree(Map<String, dynamic> node) {
    int count = 0;
    for (final key in node.keys) {
      if (node[key] is Map) {
        count += countFilesInTree(node[key]);
      } else {
        count++;
      }
    }
    return count;
  }

  void printWorkSummary(CompressResult? compressResult) {
    final hasCompressed = compressResult != null &&
        compressResult.hasCompressed &&
        compressResult.spaceOfMediaAssetsAfterCompress != null;

    if (hasCompressed) {
      console.printSuccess(
          "\nSpace taken by media assets before: ${compressResult.spaceOfMediaAssetsBeforeCompress.to1dp.toStorageString()}");
      console.printSuccess(
          'After compression: ${compressResult.spaceOfMediaAssetsAfterCompress!.to1dp.toStorageString()}');
      console.printSuccess(
          'Saved: ${(compressResult.spaceOfMediaAssetsBeforeCompress - compressResult.spaceOfMediaAssetsAfterCompress!).to1dp.toStorageString()}');
    }
  }
}
