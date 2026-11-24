import 'package:asset_doctor/service/ios/ios_asset_id.dart';

class FindAllIOSAssetIDsInFileService {
  const FindAllIOSAssetIDsInFileService({required this.content});
  final String content;

  /// Return all iOS/macOS-style asset IDs/strings from a single file's [content]
  Set<String> run() {
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
}
