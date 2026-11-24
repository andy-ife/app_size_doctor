import 'package:path/path.dart' as p;

class MatchIOSAssetsAndIdsService {
  const MatchIOSAssetsAndIdsService(
      {required this.assetFiles, required this.allAssetIds});
  final Set<String> assetFiles;
  final Set<String> allAssetIds;

  /// Compare [assetFiles] with [allAssetIds].
  /// Return used assets
  Set<String> run() {
    final usedAssets = <String>{};

    for (var assetPath in assetFiles) {
      final path = p.relative(assetPath, from: 'Asset.xcassets');
      final assetName = p.split(path).firstOrNull?.split('.').firstOrNull;

      if (assetName == null) {
        usedAssets.add(assetPath);
        continue;
      }

      final isUsed = allAssetIds.any((e) => e == assetName);

      if (isUsed) {
        usedAssets.add(assetPath);
      }
    }

    return usedAssets;
  }
}
