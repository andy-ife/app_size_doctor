import 'package:asset_doctor/data/compression_client.dart';
import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/ui/console.dart';
import 'package:asset_doctor/utils/extension.dart';
import 'package:asset_doctor/utils/asset_utils.dart';
import 'package:path/path.dart' as p;

class CompressResult {
  CompressResult(
      {required this.allMediaAssets,
      required this.assetsForCompression,
      required this.assetsForCompressionTree,
      required this.spaceOfMediaAssetsBeforeCompress,
      required this.potentiallySavedSpace,
      required this.spaceOfMediaAssetsAfterCompress,
      required this.hasAnalyzed,
      required this.hasCompressed});

  Set<String> allMediaAssets;
  List<String> assetsForCompression; // by default, these are used assets
  Map<String, dynamic> assetsForCompressionTree;
  double spaceOfMediaAssetsBeforeCompress;
  double potentiallySavedSpace;
  double? spaceOfMediaAssetsAfterCompress;
  bool hasAnalyzed;
  bool hasCompressed;
}

class AssetCompressor {
  AssetCompressor({
    required this.allAssets,
    required this.usedAssets,
    required this.fs,
    CompressionClient? client,
    Console? console,
  }) : console = console ?? Console() {
    this.client = client ?? CompressionClient(fs: fs);
  }

  final Set<String> allAssets;
  final Set<String> usedAssets;
  final FileSystemClient fs;
  late final CompressionClient client;
  final Console console;

  CompressResult? _result;
  CompressResult? get result => _result;

  CompressResult analyze() {
    final List<String> assetsForCompression = [];
    double spaceofMediaAssetsBeforeCompress = 0;

    final allMediaAssets = allAssets.where((e) => AssetUtils.isMedia(e));
    // final usedMediaAssets = usedAssets.where((e) => AssetUtils.isMedia(e));

    for (final assetPath in allMediaAssets) {
      final path = p.join(fs.projectRoot, assetPath);
      bool isNonEmpty = false;
      try {
        if (fs.fileExists(path)) {
          final size = fs.lengthSync(path);
          isNonEmpty = size > 0;
          spaceofMediaAssetsBeforeCompress += size;
        }
      } catch (e) {
        console.printWarning('Could not check size of "$assetPath": $e');
      }

      if (isNonEmpty) {
        assetsForCompression.add(assetPath);
      }
    }

    final compressTree = console.buildTree(assetsForCompression.toList());

    _result = CompressResult(
        allMediaAssets: allMediaAssets.toSet(),
        assetsForCompression: assetsForCompression,
        assetsForCompressionTree: compressTree,
        spaceOfMediaAssetsBeforeCompress: spaceofMediaAssetsBeforeCompress,
        spaceOfMediaAssetsAfterCompress: null,
        potentiallySavedSpace: spaceofMediaAssetsBeforeCompress * 0.6,
        hasAnalyzed: true,
        hasCompressed: false);
    return _result!;
  }

  Future<CompressResult?> compress({bool selectAssetsToIgnore = false}) async {
    if (_result == null || _result?.hasAnalyzed == false) {
      console.printError('Run analysis before compression');
      return null;
    }

    var curResult = _result!;

    if (selectAssetsToIgnore) {
      List<String> totalAssets = [];
      console
          .printInfo('\nSelect assets to skip (Remove from compression list)');
      final indexes = console.printMultiSelect(
          message: 'space: Select  |  enter: Confirm selection',
          options: curResult.allMediaAssets.toList());
      final toRemove = curResult.allMediaAssets.indexed
          .where((e) => indexes.contains(e.$1)) 
          .map((e) => e.$2);
      totalAssets =
          curResult.allMediaAssets.where((e) => !toRemove.contains(e)).toList();
      curResult.assetsForCompression = totalAssets;

      if (curResult.assetsForCompression.isNotEmpty) {
        console.printWarning(
            '\nMarking ${curResult.assetsForCompression.length}/${curResult.allMediaAssets.length} assets for compression...');
      } else {
        console.printSuccess('\n✨ Nothing to compress. Keeping all assets');
        return curResult;
      }
    }

    if (curResult.assetsForCompression.isEmpty) {
      console.printSuccess('No assets to compress. Keeping all assets...');
      return curResult;
    }

    String? finalConfirm;
    double freedSpace = 0;
    console.printInfo(
        '\nFINAL CONFIRMATION: You are about to compress ${curResult.assetsForCompression.length} asset(s).');
    do {
      console.printInputPrompt(
          'Proceed with compression? It may take a while (Y/N): ');
      finalConfirm = console.read();
      if (finalConfirm.isYes) {
        freedSpace += await console.printLoading<double>(
            message:
                'Compressing ${curResult.assetsForCompression.length} asset(s)',
            work: () {
              final justFreed = compressAssets(curResult.assetsForCompression);
              if (justFreed > 0) {
                console.printSuccess(
                    '\n✨ You have freed up ${justFreed.toStorageString()} of space.');
              } else {
                console.printError('Unable to compress some assets');
              }
              return justFreed.clamp(0, double.infinity); // no negative nums
            });
      } else if (finalConfirm.isNo) {
        console.printError('Compression cancelled by user.');
        _result = curResult
          ..hasCompressed = false
          ..spaceOfMediaAssetsAfterCompress = null;
        return _result;
      } else {
        console.printError('Invalid option. Please enter "y" or "n"');
      }
    } while (!finalConfirm.isYesOrNo);

    _result = curResult
      ..spaceOfMediaAssetsAfterCompress =
          curResult.spaceOfMediaAssetsBeforeCompress - freedSpace
      ..hasCompressed = true;

    return _result;
  }

  double compressAssets(List<String> assets) {
    double result = 0;
    for (var assetRelativePath in assets) {
      final path = p.join(fs.projectRoot, assetRelativePath);
      if (!fs.fileExists(path)) {
        console.printWarning(
            'File not found, skipping compression: "$assetRelativePath"');
        continue;
      }
      try {
        final res = client.compressMedia(path);
        result += (res ?? 0);
        if (res != null && res > 0) {
          console.printSuccess(
              '\nCompressed: $assetRelativePath: -${res.toStorageString()}');
        } else {
          console.printWarning(
              '\nCould not compress further: $assetRelativePath. Consider increasing the compression level');
        }
      } catch (e) {
        console.printError('Error compressing $path: $e');
      }
    }
    return result;
  }
}
