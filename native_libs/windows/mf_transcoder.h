#ifndef MF_TRANSCODER_H
#define MF_TRANSCODER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) || defined(_WIN64)
  #if defined(MF_TRANSCODER_BUILD_DLL)
    #define MF_TRANSCODER_API __declspec(dllexport)
  #else
    #define MF_TRANSCODER_API __declspec(dllimport)
  #endif
#else
  #define MF_TRANSCODER_API
#endif

typedef enum MfTranscodeStatus {
  MF_TRANSCODE_OK = 0,
  MF_TRANSCODE_ERR_INVALID_ARG = 1,
  MF_TRANSCODE_ERR_UTF8_CONVERT = 2,
  MF_TRANSCODE_ERR_COM_INIT = 3,
  MF_TRANSCODE_ERR_MF_STARTUP = 4,
  MF_TRANSCODE_ERR_SOURCE_READER = 5,
  MF_TRANSCODE_ERR_SINK_WRITER = 6,
  MF_TRANSCODE_ERR_MEDIA_TYPE = 7,
  MF_TRANSCODE_ERR_STREAM_SETUP = 8,
  MF_TRANSCODE_ERR_PIPELINE = 9
} MfTranscodeStatus;

/**
 * Transcodes a video file to H.264 video + MP3 audio (128 kbps, 22050 Hz, 16-bit)
 * using Windows Media Foundation quality-biased encoding.
 *
 * @param input_path_utf8   Null-terminated UTF-8 path to the input media file.
 * @param output_path_utf8  Null-terminated UTF-8 path for the output media file.
 * @param video_quality     Quality level in [1..100] (defaults to 85 if <= 0).
 * @param out_hresult       Optional pointer to receive the last failing HRESULT.
 * @return                  MF_TRANSCODE_OK (0) on success, non-zero error code otherwise.
 */
MF_TRANSCODER_API int32_t mf_transcode_to_h264_mp3(
    const char* input_path_utf8,
    const char* output_path_utf8,
    uint32_t video_quality,
    int32_t* out_hresult);

#ifdef __cplusplus
}
#endif

#endif // MF_TRANSCODER_H