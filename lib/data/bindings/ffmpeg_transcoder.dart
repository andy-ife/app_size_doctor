import 'package:media_asset_optimizer/data/file_system_client.dart';

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
      '21',
      '-c:a',
      'libmp3lame',
      '-ar',
      '22050',
      '-sample_fmt',
      's16p',
      '-b:a',
      '128k',
      outputPath
    ];

    late final FsProcessResult result;
    try {
      result = fs.runProcess(command, args);
    } catch (e) {
      rethrow;
    }

    return (status: result.exitCode, hresult: result.exitCode);
  }
}
