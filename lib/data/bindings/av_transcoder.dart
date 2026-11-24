import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef AvTranscoderNative = Int32 Function(
  Pointer<Utf8> inputPathUtf8,
  Pointer<Utf8> outputPathUtf8,
  Uint32 quality,
  Pointer<Int32> outOSStatus,
);

typedef AvTranscoderDart = int Function(
  Pointer<Utf8> inputPathUtf8,
  Pointer<Utf8> outputPathUtf8,
  int quality,
  Pointer<Int32> outOSStatus,
);

class AvTranscoder {
  /// AVFoundation
  ///
  /// Native OS-level transcoding for macOS
  AvTranscoder({String? dllPath})
      : _lib = DynamicLibrary.open(
            dllPath ?? 'native_libs/macOS/av_transcoder.dll') {
    _transcoder = _lib.lookupFunction<AvTranscoderNative, AvTranscoderDart>(
        'av_transcode_to_h264_mp3');
  }
  final DynamicLibrary _lib;
  late final AvTranscoderDart _transcoder;

  /// Write the output to a temp file
  /// Do not pass the same path as inputPath and outputPath
  ({int status, int hresult}) transcode(
      {required String inputPath,
      required String outputPath,
      int quality = 85}) {
    assert(inputPath != outputPath,
        'Do not pass the same path as inputPath and outputPath');

    final inputPtr = inputPath.toNativeUtf8();
    final outputPtr = outputPath.toNativeUtf8();
    final hrPtr = calloc<Int32>();

    try {
      final status = _transcoder(inputPtr, outputPtr, quality, hrPtr);
      return (status: status, hresult: hrPtr.value);
    } finally {
      malloc.free(inputPtr);
      malloc.free(outputPtr);
      calloc.free(hrPtr);
    }
  }
}
