import 'package:asset_doctor/service/android/android_resource_id.dart';
import 'package:path/path.dart' as p;

class MatchAndroidResourcesAndIDsService {
  const MatchAndroidResourcesAndIDsService(
      {required this.androidResources, required this.allResourceIds});
  final Set<String> androidResources;
  final Set<AndroidResourceID> allResourceIds;

  /// Compare all [androidResources] with all [allResourceIds] from the source code
  /// Returns the list of used resources
  Set<String> run() {
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
