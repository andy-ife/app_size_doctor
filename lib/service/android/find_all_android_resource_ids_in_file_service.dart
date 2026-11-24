import 'package:asset_doctor/service/android/android_resource_id.dart';

class FindAllAndroidResourceIDsInFileService {
  const FindAllAndroidResourceIDsInFileService({required this.content});
  final String content;

  /// Return all Android-style resource IDs/strings from a single file's [content]
  Set<AndroidResourceID> run() {
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
}
