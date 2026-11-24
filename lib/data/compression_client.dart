import 'package:asset_doctor/data/bindings/av_transcoder.dart';
import 'package:asset_doctor/data/bindings/ffmpeg_transcoder.dart';
import 'package:asset_doctor/data/bindings/mf_transcoder.dart';
import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/exception/transcoder_exception.dart';
import 'package:asset_doctor/utils/asset_utils.dart';
import 'package:path/path.dart' as p;

import 'package:image_compression/image_compression.dart';

class CompressionClient {
  CompressionClient({FileSystemClient? fs}) {
    fs = fs ?? FileSystemClient();
    if (fs.isWindows) {
      mft = MfTranscoder();
    } else if (fs.isMacOS) {
      avt = AvTranscoder();
    } else if (fs.isLinux) {
      fft = FfmpegTranscoder();
    } else {
      throw UnsupportedPlatformException(null);
    }
  }

  late final FileSystemClient fs;
  AvTranscoder? avt;
  MfTranscoder? mft;
  FfmpegTranscoder? fft;

  int compressImage(String path) {
    final input = ImageFile(filePath: path, rawBytes: fs.readAsBytes(path));

    final output = compress(ImageFileConfiguration(
        input: input, config: Configuration(jpgQuality: 50)));

    fs.writeAsBytes(path, output.rawBytes);
    return (input.sizeInBytes - output.sizeInBytes);
  }

  int compressVideoOrAudio(String path) {
    ({int hresult, int status})? result;
    late final int savedSpace;

    final tempPath =
        p.join(fs.projectRoot, '.dart_tool', '.temp', p.basename(path));
    final inputLength = fs.lengthSync(path);
    try {
      result = fs.isWindows
          ? mft!.transcode(inputPath: path, outputPath: tempPath)
          : fs.isMacOS
              ? avt!.transcode(inputPath: path, outputPath: tempPath)
              : fs.isLinux
                  ? fft!.transcode(inputPath: path, outputPath: tempPath)
                  : throw Exception();
      final outputLength = fs.lengthSync(tempPath);
      final outputBytes = fs.readAsBytes(tempPath);
      fs.writeAsBytes(path, outputBytes);
      fs.deleteSync(tempPath);
      savedSpace = inputLength - outputLength;
      return savedSpace;
    } on Exception catch (e) {
      throw getTranscoderException(result?.status ?? e, result?.hresult, fs);
    }
  }

  int? compressMedia(String path) {
    switch (AssetUtils.getAssetType(path)) {
      case AssetType.image:
        return compressImage(path);
      case AssetType.video:
        return compressVideoOrAudio(path);
      case AssetType.audio:
        return compressVideoOrAudio(path);
      case AssetType.text:
        return null;
      case AssetType.unkown:
        return null;
    }
  }

  int? compressAllMedia(Iterable<String> paths) {
    int result = 0;
    for (var p in paths) {
      final size = compressMedia(p) ?? 0;
      result += size;
    }
    return result;
  }
}
