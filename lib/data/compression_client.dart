import 'package:media_asset_optimizer/data/bindings/av_transcoder.dart';
import 'package:media_asset_optimizer/data/bindings/ffmpeg_transcoder.dart';
import 'package:media_asset_optimizer/data/bindings/mf_transcoder.dart';
import 'package:media_asset_optimizer/data/file_system_client.dart';
import 'package:media_asset_optimizer/exception/transcoder_exception.dart';
import 'package:media_asset_optimizer/utils/asset_utils.dart';
import 'package:path/path.dart' as p;

import 'package:image_compression/image_compression.dart';

class CompressionClient {
  CompressionClient({FileSystemClient? fs, this.quality}) {
    this.fs = fs ?? FileSystemClient();
    if (this.fs.isWindows) {
      mft = MfTranscoder();
    } else if (this.fs.isMacOS) {
      avt = AvTranscoder();
    } else if (this.fs.isLinux) {
      fft = FfmpegTranscoder();
    } else {
      throw UnsupportedPlatformException(null);
    }
  }

  late final FileSystemClient fs;

  /// File quality from 1 (smallest file) to 100 (best quality).
  ///
  /// Each media type keeps its own default when this is null.
  final int? quality;

  AvTranscoder? avt;
  MfTranscoder? mft;
  FfmpegTranscoder? fft;

  int get _imageQuality => (quality ?? 50).clamp(1, 100).toInt();

  int get _videoQuality => (quality ?? 85).clamp(1, 100).toInt();

  double compressImage(String path) {
    final input = ImageFile(filePath: path, rawBytes: fs.readAsBytes(path));

    final output = compress(ImageFileConfiguration(
        input: input, config: Configuration(jpgQuality: _imageQuality)));

    fs.writeAsBytes(path, output.rawBytes);
    return (input.sizeInBytes - output.sizeInBytes).toDouble();
  }

  double compressVideoOrAudio(String path) {
    final tempPath =
        p.join(fs.projectRoot, '.dart_tool', '.temp', p.basename(path));
    fs.create(tempPath);
    final inputLength = fs.lengthSync(path);

    try {
      final result = fs.isWindows
          ? mft!.transcode(
              inputPath: path,
              outputPath: tempPath,
              quality: _videoQuality,
            )
          : fs.isMacOS
              ? avt!.transcode(
                  inputPath: path,
                  outputPath: tempPath,
                  quality: _videoQuality,
                )
              : fs.isLinux
                  ? fft!.transcode(
                      fs: fs,
                      inputPath: path,
                      outputPath: tempPath,
                      quality: _videoQuality,
                    )
                  : throw UnsupportedPlatformException(null);

      if (result.status != 0) {
        throw getTranscoderException(result.status, result.hresult, fs);
      }
      if (!fs.fileExists(tempPath) || fs.lengthSync(tempPath) == 0) {
        throw UnexpectedException(result.hresult);
      }

      final outputLength = fs.lengthSync(tempPath);
      final outputBytes = fs.readAsBytes(tempPath);
      fs.writeAsBytes(path, outputBytes);
      return (inputLength - outputLength).toDouble();
    } on Exception catch (e) {
      throw getTranscoderException(e, null, fs);
    } finally {
      if (fs.fileExists(tempPath)) {
        fs.deleteSync(tempPath);
      }
    }
  }

  double? compressMedia(String path) {
    switch (AssetUtils.getAssetType(path)) {
      case AssetType.image:
        return compressImage(path);
      case AssetType.video:
        return compressVideoOrAudio(path);
      case AssetType.audio:
        return compressVideoOrAudio(path);
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
