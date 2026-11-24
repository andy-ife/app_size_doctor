import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/utils/asset_utils.dart';

import 'package:compressor/compressor.dart' as cp;
import 'package:image_compression/image_compression.dart';

class CompressionClient {
  CompressionClient({required this.projectRoot, FileSystemClient? fs})
      : fs = fs ?? FileSystemClient(projectRoot: projectRoot);

  final String projectRoot;
  late final FileSystemClient fs;

  double compressImage(String path) {
    final input = ImageFile(filePath: path, rawBytes: fs.readAsBytes(path));

    final output = compress(ImageFileConfiguration(
        input: input, config: Configuration(jpgQuality: 50)));

    fs.writeAsBytes(path, output.rawBytes);
    return (input.sizeInBytes - output.sizeInBytes).toDouble();
  }

  double compressVideo(String path) {
    final initialSize = fs.lengthSync(path);
    final compressor = cp.Compressor(path: path, isLocal: true);
    compressor.compressVideo();
    return (initialSize - fs.lengthSync(path)).toDouble();
  }

  double? compressAudio(String path) {
    // print("Audio compression unsupported. Skipping $path");
    return null;
  }

  double? compressMedia(String path) {
    switch (AssetUtils.getAssetType(path)) {
      case AssetType.image:
        return compressImage(path);
      case AssetType.video:
        return compressVideo(path);
      case AssetType.audio:
        return compressAudio(path);
      case AssetType.text:
        return null;
      case AssetType.unkown:
        return null;
    }
  }

  double? compressAllMedia(Iterable<String> paths) {
    double result = 0;
    for (var p in paths) {
      final size = compressMedia(p) ?? 0;
      result += size;
    }
    return result;
  }
}
