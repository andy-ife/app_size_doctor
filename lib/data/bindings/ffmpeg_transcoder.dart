import 'dart:io';

/// Uses pre-installed ffmpeg binary on the user's system
/// If ffmpeg is missing, transcoding fails
class FfmpegTranscoder {
  const FfmpegTranscoder({String? ffmpegPath});

  /// Write the output to a temp file.
  /// Do not pass the same path as inputPath and outputPath
  Future<int> transcode(
      {required String inputPath,
      required String outputPath,
      int quality = 85}) async {
    final ffmpegCommand = '''
            ffmpeg -y -i $inputPath
            -map 0:v? -map 0:a?
            -c:v libx264 -preset slow -crf 21
            -c:a libmp3lame -ar 22050 -sample_fmt s16 -b:a 128k
            $outputPath
          '''
        .replaceAll('\n', ' ');

    late final ProcessResult result;
    try {
      result = await Process.run(ffmpegCommand, []);
    } catch (e) {
      rethrow;
    }

    if (result.stderr != null) {
      throw result.stderr;
    }

    return result.exitCode;
  }
}
