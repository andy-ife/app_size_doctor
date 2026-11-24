import 'dart:io';

class FfmpegTranscoder {
  /// Uses pre-installed ffmpeg binary on the user's system
  ///
  /// If ffmpeg is missing, transcoding fails
  const FfmpegTranscoder({String? ffmpegPath});

  /// Write the output to a temp file.
  /// Do not pass the same path as inputPath and outputPath
  ({int status, int hresult}) transcode(
      {required String inputPath,
      required String outputPath,
      int quality = 85}) {
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

    late final ProcessResult result;
    try {
      result = Process.runSync(command, args);
    } catch (e) {
      rethrow;
    }

    return (status: result.exitCode, hresult: result.exitCode);
  }
}
