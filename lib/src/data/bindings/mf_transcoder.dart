import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef MfTranscoderNative = Int32 Function(
  Pointer<Utf8> inputPathUtf8,
  Pointer<Utf8> outputPathUtf8,
  Uint32 quality,
  Pointer<Int32> outHresult,
);

typedef MfTranscoderDart = int Function(
  Pointer<Utf8> inputPathUtf8,
  Pointer<Utf8> outputPathUtf8,
  int quality,
  Pointer<Int32> outHresult,
);

class MfTranscoder {
  /// MediaFoundation
  ///
  /// Native OS-level transcoding for Windows
  MfTranscoder({this.dllPath});

  final String? dllPath;

  /// Write the output to a temp file.
  /// Do not pass the same path as inputPath and outputPath
  ({int status, int hresult}) transcode({
    required String inputPath,
    required String outputPath,
    int quality = 85,
  }) {
    assert(inputPath != outputPath,
        'Do not pass the same path as inputPath and outputPath');

    final lib =
        DynamicLibrary.open(dllPath ?? 'native_libs/windows/mf_transcode.dll');

    final transcoder = lib.lookupFunction<MfTranscoderNative, MfTranscoderDart>(
        'mf_transcode_to_h264_mp3');

    final inputPtr = inputPath.toNativeUtf8();
    final outputPtr = outputPath.toNativeUtf8();
    final hrPtr = calloc<Int32>();

    try {
      final status = transcoder(inputPtr, outputPtr, quality, hrPtr);
      return (status: status, hresult: hrPtr.value);
    } finally {
      malloc.free(inputPtr);
      malloc.free(outputPtr);
      calloc.free(hrPtr);
    }
  }
}
