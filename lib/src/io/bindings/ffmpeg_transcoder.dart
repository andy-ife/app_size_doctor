import 'package:media_asset_optimizer/src/io/file_system_client.dart';
import 'package:media_asset_optimizer/src/exception/file_exception.dart';

class FfmpegTranscoder {
  /// Uses pre-installed ffmpeg binary on the user's system
  ///
  /// If ffmpeg is missing, transcoding fails
  const FfmpegTranscoder({String? ffmpegPath});

  /// Write the output to a temp file.
  /// Do not pass the same path as inputPath and outputPath
  ({int status, int hresult}) transcode(
      {required FileSystemClient fs,
      required String inputPath,
      required String outputPath,
      int quality = 85}) {
    assert(inputPath != outputPath,
        'Do not pass the same path as inputPath and outputPath');

    final normalizedQuality = quality <= 0 ? 85 : quality.clamp(1, 100).toInt();
    // Map quality (higher is better) to H.264 CRF (higher is smaller).
    // Quality 85 keeps the previous default of CRF 21.
    final crf =
        (21 + (85 - normalizedQuality) * (30 / 84)).round().clamp(0, 51);
    final audioBitrate = (normalizedQuality * 1.5).round().clamp(32, 320);

    final command = 'ffmpeg';
    final args = [
      '-y',
      '-i',
      inputPath,
      '-c:v',
      'libx264',
      '-preset',
      'slow',
      '-crf',
      '$crf',
      '-c:a',
      'libmp3lame',
      '-ar',
      '22050',
      '-sample_fmt',
      's16p',
      '-b:a',
      '${audioBitrate}k',
      outputPath
    ];

    late final FsProcessResult result;
    try {
      result = fs.runProcess(command, args);
    } catch (e) {
      throw FFmpegProcessException(reason: e.toString());
    }

    return (status: result.exitCode, hresult: result.exitCode);
  }
}
