import 'package:media_asset_optimizer/service/asset_id/android_resource_id.dart';
import 'package:path/path.dart' as p;

class AndroidAssetsSearchService {
  /// Return all Android-style resource IDs/strings from a single file's [content].
  /// Valid patterns:
  /// - R.drawable.foo
  /// - com.example.app.R.drawable.foo
  /// - @mipmap/foo
  /// - @+id/foo
  /// - @android:drawable/foo
  /// - @*android:drawable/foo
  /// - ActivityMainBinding.inflate(
  /// TODO: Handle resource aliases, qualifiers, data binding
  Set<AndroidResourceID> findAllAndroidResourceIDsInFile(String content) {
    final allResourceIds = <AndroidResourceID>{};

    // Check for resource ids e.g R.drawable.foo, @mipmap/foo
    final matches = getAndroidResourceRegex().allMatches(content);

    for (var match in matches) {
      String id = match.group(0)!;
      String type = match.group(1) ?? match.group(3)!;
      String name = match.group(2) ?? match.group(4)!;

      allResourceIds.add(AndroidResourceID(id: id, type: type, name: name));
    }

    // Check for ViewBinding
    final viewBindingMatches = getViewBindingRegex().allMatches(content);
    for (var match in viewBindingMatches) {
      final bindingStr = match.group(1)!;
      final words =
          bindingStr.split(RegExp(r'(?=[A-Z])')).where((e) => e != 'Binding');
      final layoutFile = words.join('_').toLowerCase();

      allResourceIds.add(AndroidResourceID(
          id: 'R.layout.$layoutFile', type: 'layout', name: layoutFile));
    }

    return allResourceIds;
  }

  /// Compare all [androidResources] with all [allResourceIds] from the source code
  /// Returns the list of used resources
  Set<String> matchAndroidResourcesAndIds(
      Set<String> androidResources, Set<AndroidResourceID> allResourceIds) {
    Set<String> usedResources = {};

    for (final resourcePath in androidResources) {
      final resFolder = RES_FOLDERS.firstWhere((cur) {
        final resPath = p.relative(resourcePath, from: '/res');
        final variant = p.split(resPath).firstOrNull; // e.g /drawable-xxhdpi
        final folder = variant?.split('-').first;
        return folder != null && folder == cur;
      }, orElse: () => '');

      if (resFolder.isEmpty) {
        usedResources.add(resourcePath); // assume it's used
        continue;
      }

      final basenameWithoutExtension = p.basenameWithoutExtension(resourcePath);

      // handle nine-patch files
      final ninePatchIndex = basenameWithoutExtension.lastIndexOf('.9');
      final basename = ninePatchIndex == -1
          ? basenameWithoutExtension
          : basenameWithoutExtension.replaceRange(ninePatchIndex, null, '');

      final isUsed = allResourceIds.any((id) {
        return id.type == resFolder && id.name == basename;
      });

      if (isUsed) {
        usedResources.add(resourcePath);
      }
    }

    return usedResources;
  }
}
