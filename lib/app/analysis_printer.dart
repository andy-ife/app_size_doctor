import 'package:asset_doctor/app/asset_compressor.dart';
import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/ui/console.dart';
import 'package:asset_doctor/utils/extension.dart';
import 'package:path/path.dart' as p;

class AnalysisPrinter {
  AnalysisPrinter({
    required this.usedAssets,
    required this.pubspecAssets,
    required this.fs,
    Console? console,
  }) : console = console ?? Console();

  final Set<String> usedAssets;
  final List<String> pubspecAssets;
  final FileSystemClient fs;
  final Console console;

  void printCompressAnalysis(CompressResult result) {
    console.printHeader('Analysis');

    // console.printSubHeader(
    //     'Potentially Used assets (Found in assets/ and path/name found as a string somewhere in the code):',
    //     nl: false);
    // if (result.assetsForCompression.isNotEmpty) {
    //   console.printInfo('(${result.assetsForCompression.length} files)');
    //   console.printMatrix(result.assetsForCompression.toSet());
    // } else {
    //   console.printInfo('None found.');
    // }
    final isAll =
        result.allMediaAssets.length == result.assetsForCompression.length;
    console.printWarning(
        '🔨 Assets MARKED FOR COMPRESSION (${isAll ? 'All' : 'Selected'} assets ${isAll ? '' : 'only'}):');
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
    console.printInfo(
        'No files were changed. Here is what Asset Doctor could free up:');

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
    console.printInfo(
        '• Estimated total savings: ${totalPotentialSavings.toStorageString()}');
    console.printInfo(
        '\nRun again without --dry-run to view detailed file trees and apply these changes.');
  }

  void printPubspecAnalysis() {
    console.printInfo('\nChecking pubspec.yaml for any skipped assets...');

    final declaredAssetsInPubspec =
        pubspecAssets.where((e) => fs.isFile(e) || fs.isDirectory(e));

    if (declaredAssetsInPubspec.isNotEmpty) {
      final unusedDeclaredAssets =
          getUsedInAButNotB(declaredAssetsInPubspec, usedAssets)..sort();
      console.printHeader('pubspec.yaml Analysis');
      console.printInfo(
          'Found ${declaredAssetsInPubspec.length} assets declared in pubspec.yaml');
      if (unusedDeclaredAssets.isNotEmpty) {
        console.printSubHeader(
          '${unusedDeclaredAssets.length} declared assets were found in the assets section but not referenced in code:',
        );
        for (var asset in unusedDeclaredAssets) {
          console.printInfo('• $asset');
        }
      } else {
        console.printInfo(
            'All declared assets in pubspec.yaml seem to be referenced.');
      }
      final undeclaredUsedAssets =
          getUsedInAButNotB(usedAssets, declaredAssetsInPubspec)..sort();
      if (undeclaredUsedAssets.isNotEmpty) {
        console.printSubHeader(
            '${undeclaredUsedAssets.length} files in assets/ were used but *not* declared in pubspec.yaml:');
        for (var asset in undeclaredUsedAssets) {
          console.printInfo('• $asset');
        }
        console.printInfo(
            '\nTip: Consider declaring used assets in pubspec.yaml under the `assets:` section.');
      }
      console.printDivider();
    } else {
      console.printInfo('None found');
    }
  }

  /// Get folders referenced in a but not in b
  /// Handles sub folders, partial path
  List<String> getUsedInAButNotB(Iterable<String> a, Iterable<String> b) {
    return a.where((assetPath) {
      final relativePath =
          p.relative(assetPath, from: fs.projectRoot).replaceAll('\\', '/');
      final dirs = p.split(relativePath);

      // generate all possible subdirs
      final subdirs = <String>{};
      for (var i = 0; i < dirs.length; i++) {
        for (var j = i; j < dirs.length; j++) {
          if (j == i) {
            subdirs.add(dirs[j]);
          } else {
            subdirs.add('/${dirs.sublist(i, j).join('/')}');
          }
        }
      }
      // check if any of the subdirs are contained in pubspec
      return subdirs
          .every((subdir) => !b.any((bPath) => bPath.contains(subdir)));
    }).toList();
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
