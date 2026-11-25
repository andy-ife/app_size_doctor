import 'package:asset_doctor/service/asset_id/ios_asset_id.dart';
import 'package:path/path.dart' as p;

class IosAssetsSearchService {
  /// Return all iOS/macOS-style asset IDs/strings from a single file's [content]
  Set<String> findAlliOSAssetIDsInFile(String content) {
    final allAssets = <String>{};

    final matches = getIosAssetRegex().allMatches(content);

    for (var match in matches) {
      final name = match.namedGroup('typed_name') ??
          match.namedGroup('swiftui_name') ??
          match.namedGroup('named_name') ??
          match.namedGroup('objc_name') ??
          match.namedGroup('catalog_path') ??
          match.namedGroup('xib_attr') ??
          match.namedGroup('xib_image') ??
          match.namedGroup('filename_value')!;

      allAssets.add(name);
    }

    return allAssets;
  }

  /// Compare [assetFiles] with [allAssetIds].
  /// Return used assets
  Set<String> matchIosAssetsAndIds(
      Set<String> assetFiles, Set<String> allAssetIds) {
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
