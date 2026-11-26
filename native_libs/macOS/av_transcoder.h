#ifndef AV_TRANSCODER_H
#define AV_TRANSCODER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

#if defined(__APPLE__)
#define AV_TRANSCODER_API __attribute__((visibility("default")))
#else
#define AV_TRANSCODER_API
#endif

  typedef enum AvTranscodeStatus
  {
    AV_TRANSCODER_OK = 0,
    AV_TRANSCODER_ERR_INVALID_ARG = 1,
    AV_TRANSCODER_ERR_UTF8_CONVERT = 2,
    AV_TRANSCODER_ERR_ASSET_LOAD = 3,
    AV_TRANSCODER_ERR_READER_INIT = 4,
    AV_TRANSCODER_ERR_WRITER_INIT = 5,
    AV_TRANSCODER_ERR_STREAM_SETUP = 6,
    AV_TRANSCODER_ERR_PIPELINE = 7,
    AV_TRANSCODER_ERR_UNSUPPORTED_AUDIO_ONLY = 8,
    AV_TRANSCODER_ERR_UNSUPPORTED_CONTAINER = 9
  } AvTranscodeStatus;

  /**
   * Transcodes a video file on macOS to H.264 video with AAC audio.
   * Standalone audio files are not supported because AVFoundation has no MP3 encoder.
   * Supported output extensions are .mp4, .m4v and .mov.
   *
   * @param input_path_utf8   Null-terminated UTF-8 path to the input media file.
   * @param output_path_utf8  Null-terminated UTF-8 path for the output media file.
   * @param quality     Quality level in [1..100] (defaults to 85 if 0).
   * @param out_os_status     Optional pointer to receive an OSStatus / error code.
   * @return                  AV_TRANSCODER_OK (0) on success, non-zero otherwise.
   */
  AV_TRANSCODER_API int32_t av_transcode_to_h264_mp3(
      const char *input_path_utf8,
      const char *output_path_utf8,
      uint32_t quality,
      int32_t *out_os_status);

#ifdef __cplusplus
}
#endif

#endif // AV_TRANSCODER_H