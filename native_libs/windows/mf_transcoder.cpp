#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <codecapi.h>
#include <wrl/client.h>

#include "mf_transcoder.h"

#include <string>

using Microsoft::WRL::ComPtr;

namespace
{

  bool Utf8ToWide(const char *utf8, std::wstring &out)
  {
    if (!utf8)
      return false;
    int len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8, -1, nullptr, 0);
    if (len <= 0)
      return false;
    out.resize(static_cast<size_t>(len));
    int written = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8, -1, out.data(), len);
    if (written <= 0)
      return false;
    if (!out.empty() && out.back() == L'\0')
    {
      out.pop_back();
    }
    return true;
  }

  void FindSourceStreamIndex(IMFSourceReader *reader,
                             const GUID &targetMajorType,
                             bool &outFound,
                             DWORD &outStreamIndex)
  {
    outFound = false;
    outStreamIndex = MF_SOURCE_READER_INVALID_STREAM_INDEX;
    if (!reader)
      return;

    for (DWORD i = 0;; ++i)
    {
      MF_SOURCE_READER_FLAG flags = MF_SOURCE_READER_FLAG_ERROR;
      ComPtr<IMFMediaType> nativeType;
      HRESULT hr = reader->GetNativeMediaType(i, 0, &nativeType);
      if (FAILED(hr) || !nativeType)
      {
        break;
      }

      BOOL selected = FALSE;
      if (FAILED(reader->GetStreamSelection(i, &selected)) || !selected)
      {
        continue;
      }

      GUID majorType = GUID_NULL;
      if (SUCCEEDED(nativeType->GetGUID(MF_MT_MAJOR_TYPE, &majorType)) &&
          majorType == targetMajorType)
      {
        outFound = true;
        outStreamIndex = i;
        return;
      }
      (void)flags;
    }
  }

  void SetVariantUint32(IMFAttributes *attrs,
                        const GUID &key,
                        UINT32 value,
                        bool required,
                        HRESULT &lastHr)
  {
    if (!attrs)
      return;
    VARIANT v;
    VariantInit(&v);
    v.vt = VT_UI4;
    v.ulVal = value;
    HRESULT hr = attrs->SetItem(key, v);
    VariantClear(&v);
    if (FAILED(hr))
    {
      lastHr = hr;
      if (required)
      {
        throw hr;
      }
    }
  }

  void SetVariantBool(IMFAttributes *attrs,
                      const GUID &key,
                      VARIANT_BOOL value,
                      bool required,
                      HRESULT &lastHr)
  {
    if (!attrs)
      return;
    VARIANT v;
    VariantInit(&v);
    v.vt = VT_BOOL;
    v.boolVal = value;
    HRESULT hr = attrs->SetItem(key, v);
    VariantClear(&v);
    if (FAILED(hr))
    {
      lastHr = hr;
      if (required)
      {
        throw hr;
      }
    }
  }

  void ConfigureH264SlowQualityAttrs(IMFAttributes *attrs, UINT32 quality, HRESULT &lastHr)
  {
    SetVariantUint32(attrs, CODECAPI_AVEncCommonRateControlMode,
                     eAVEncCommonRateControlMode_Quality, true, lastHr);
    SetVariantUint32(attrs, CODECAPI_AVEncCommonQuality, quality, true, lastHr);

    // Best-effort tuning attributes for higher quality/efficiency (non-fatal if unsupported)
    SetVariantUint32(attrs, CODECAPI_AVEncCommonQualityVsSpeed, 80, false, lastHr);
    SetVariantBool(attrs, CODECAPI_AVLowLatencyMode, VARIANT_FALSE, false, lastHr);
    SetVariantBool(attrs, CODECAPI_AVEncH264CABACEnable, VARIANT_TRUE, false, lastHr);
    SetVariantUint32(attrs, CODECAPI_AVEncMPVDefaultBPictureCount, 2, false, lastHr);
  }

  int32_t RunTranscode(const std::wstring &inputPath,
                       const std::wstring &outputPath,
                       UINT32 quality,
                       HRESULT &lastHr)
  {
    ComPtr<IMFSourceReader> reader;
    ComPtr<IMFSinkWriter> writer;

    lastHr = MFCreateSourceReaderFromURL(inputPath.c_str(), nullptr, &reader);
    if (FAILED(lastHr))
      return MF_TRANSCODE_ERR_SOURCE_READER;

    lastHr = MFCreateSinkWriterFromURL(outputPath.c_str(), nullptr, nullptr, &writer);
    if (FAILED(lastHr))
      return MF_TRANSCODE_ERR_SINK_WRITER;

    bool hasVideo = false;
    DWORD srcVideoStream = MF_SOURCE_READER_INVALID_STREAM_INDEX;
    FindSourceStreamIndex(reader.Get(), MFMediaType_Video, hasVideo, srcVideoStream);

    bool hasAudio = false;
    DWORD srcAudioStream = MF_SOURCE_READER_INVALID_STREAM_INDEX;
    FindSourceStreamIndex(reader.Get(), MFMediaType_Audio, hasAudio, srcAudioStream);

    if (!hasVideo && !hasAudio)
    {
      lastHr = MF_E_TOPO_NO_OUTPUT;
      return MF_TRANSCODE_ERR_STREAM_SETUP;
    }

    DWORD sinkVideoStream = static_cast<DWORD>(-1);
    DWORD sinkAudioStream = static_cast<DWORD>(-1);

    // --- 1. Video Stream (only when input contains a video stream) ---
    if (hasVideo)
    {
      ComPtr<IMFMediaType> nativeVideoType;
      lastHr = reader->GetNativeMediaType(srcVideoStream, 0, &nativeVideoType);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      UINT32 width = 0, height = 0;
      UINT32 fpsNum = 30, fpsDen = 1;
      MFGetAttributeSize(nativeVideoType.Get(), MF_MT_FRAME_SIZE, &width, &height);
      if (FAILED(MFGetAttributeRatio(nativeVideoType.Get(), MF_MT_FRAME_RATE, &fpsNum, &fpsDen)) ||
          fpsNum == 0 || fpsDen == 0)
      {
        fpsNum = 30;
        fpsDen = 1;
      }

      ComPtr<IMFMediaType> readerVideoOut;
      lastHr = MFCreateMediaType(&readerVideoOut);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      readerVideoOut->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
      readerVideoOut->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_NV12);
      MFSetAttributeSize(readerVideoOut.Get(), MF_MT_FRAME_SIZE, width, height);
      MFSetAttributeRatio(readerVideoOut.Get(), MF_MT_FRAME_RATE, fpsNum, fpsDen);

      lastHr = reader->SetCurrentMediaType(srcVideoStream, nullptr, readerVideoOut.Get());
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      ComPtr<IMFMediaType> sinkVideoOut;
      lastHr = MFCreateMediaType(&sinkVideoOut);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      sinkVideoOut->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
      sinkVideoOut->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_H264);
      MFSetAttributeSize(sinkVideoOut.Get(), MF_MT_FRAME_SIZE, width, height);
      MFSetAttributeRatio(sinkVideoOut.Get(), MF_MT_FRAME_RATE, fpsNum, fpsDen);
      sinkVideoOut->SetUINT32(MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive);

      lastHr = writer->AddStream(sinkVideoOut.Get(), &sinkVideoStream);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_STREAM_SETUP;

      ComPtr<IMFMediaType> sinkVideoIn;
      lastHr = MFCreateMediaType(&sinkVideoIn);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      sinkVideoIn->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
      sinkVideoIn->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_NV12);
      MFSetAttributeSize(sinkVideoIn.Get(), MF_MT_FRAME_SIZE, width, height);
      MFSetAttributeRatio(sinkVideoIn.Get(), MF_MT_FRAME_RATE, fpsNum, fpsDen);

      ComPtr<IMFAttributes> encAttrs;
      lastHr = MFCreateAttributes(&encAttrs, 6);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_STREAM_SETUP;

      try
      {
        ConfigureH264SlowQualityAttrs(encAttrs.Get(), quality, lastHr);
      }
      catch (HRESULT hr)
      {
        lastHr = hr;
        return MF_TRANSCODE_ERR_STREAM_SETUP;
      }

      lastHr = writer->SetInputMediaType(sinkVideoStream, sinkVideoIn.Get(), encAttrs.Get());
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_STREAM_SETUP;
    }

    // --- 2. Audio Stream (only when input contains an audio stream) ---
    if (hasAudio)
    {
      ComPtr<IMFMediaType> nativeAudioType;
      lastHr = reader->GetNativeMediaType(srcAudioStream, 0, &nativeAudioType);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      UINT32 channels = 2;
      UINT32 nativeChannels = 0;
      if (SUCCEEDED(nativeAudioType->GetUINT32(MF_MT_AUDIO_NUM_CHANNELS, &nativeChannels)) &&
          nativeChannels > 0)
      {
        channels = (nativeChannels == 1) ? 1 : 2;
      }

      const UINT32 sampleRate = 22050;
      const UINT32 bitsPerSample = 16;
      const UINT32 blockAlign = channels * (bitsPerSample / 8);
      const UINT32 pcmAvgBytesPerSec = sampleRate * blockAlign;
      const UINT32 mp3AvgBytesPerSec = 128000 / 8; // 128 kbps = 16,000 bytes/sec

      ComPtr<IMFMediaType> readerAudioOut;
      lastHr = MFCreateMediaType(&readerAudioOut);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      readerAudioOut->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
      readerAudioOut->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_PCM);
      readerAudioOut->SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, channels);
      readerAudioOut->SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, sampleRate);
      readerAudioOut->SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, bitsPerSample);
      readerAudioOut->SetUINT32(MF_MT_AUDIO_BLOCK_ALIGNMENT, blockAlign);
      readerAudioOut->SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, pcmAvgBytesPerSec);

      lastHr = reader->SetCurrentMediaType(srcAudioStream, nullptr, readerAudioOut.Get());
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      ComPtr<IMFMediaType> sinkAudioOut;
      lastHr = MFCreateMediaType(&sinkAudioOut);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      sinkAudioOut->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
      sinkAudioOut->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_MP3);
      sinkAudioOut->SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, channels);
      sinkAudioOut->SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, sampleRate);
      sinkAudioOut->SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, mp3AvgBytesPerSec);

      lastHr = writer->AddStream(sinkAudioOut.Get(), &sinkAudioStream);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_STREAM_SETUP;

      ComPtr<IMFMediaType> sinkAudioIn;
      lastHr = MFCreateMediaType(&sinkAudioIn);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_MEDIA_TYPE;

      sinkAudioIn->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
      sinkAudioIn->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_PCM);
      sinkAudioIn->SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, channels);
      sinkAudioIn->SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, sampleRate);
      sinkAudioIn->SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, bitsPerSample);
      sinkAudioIn->SetUINT32(MF_MT_AUDIO_BLOCK_ALIGNMENT, blockAlign);
      sinkAudioIn->SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, pcmAvgBytesPerSec);

      lastHr = writer->SetInputMediaType(sinkAudioStream, sinkAudioIn.Get(), nullptr);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_STREAM_SETUP;
    }

    lastHr = writer->BeginWriting();
    if (FAILED(lastHr))
      return MF_TRANSCODE_ERR_PIPELINE;

    // --- 3. Sample Loop ---
    while (true)
    {
      DWORD streamIndex = 0;
      DWORD flags = 0;
      LONGLONG timestamp = 0;
      ComPtr<IMFSample> sample;

      lastHr = reader->ReadSample(
          static_cast<DWORD>(MF_SOURCE_READER_ANY_STREAM),
          0,
          &streamIndex,
          &flags,
          &timestamp,
          &sample);
      if (FAILED(lastHr))
        return MF_TRANSCODE_ERR_PIPELINE;

      if (flags & MF_SOURCE_READERF_ENDOFSTREAM)
      {
        break;
      }

      if (flags & MF_SOURCE_READERF_STREAMTICK)
      {
        if (hasVideo && streamIndex == srcVideoStream)
        {
          writer->SendStreamTick(sinkVideoStream, timestamp);
        }
        else if (hasAudio && streamIndex == srcAudioStream)
        {
          writer->SendStreamTick(sinkAudioStream, timestamp);
        }
        continue;
      }

      if (sample)
      {
        if (hasVideo && streamIndex == srcVideoStream)
        {
          lastHr = writer->WriteSample(sinkVideoStream, sample.Get());
          if (FAILED(lastHr))
            return MF_TRANSCODE_ERR_PIPELINE;
        }
        else if (hasAudio && streamIndex == srcAudioStream)
        {
          lastHr = writer->WriteSample(sinkAudioStream, sample.Get());
          if (FAILED(lastHr))
            return MF_TRANSCODE_ERR_PIPELINE;
        }
      }
    }

    if (hasVideo)
    {
      writer->NotifyEndOfSegment(sinkVideoStream);
    }
    if (hasAudio)
    {
      writer->NotifyEndOfSegment(sinkAudioStream);
    }

    lastHr = writer->Finalize();
    if (FAILED(lastHr))
      return MF_TRANSCODE_ERR_PIPELINE;

    return MF_TRANSCODE_OK;
  }

} // namespace

extern "C" int32_t mf_transcode_to_h264_mp3(
    const char *input_path_utf8,
    const char *output_path_utf8,
    uint32_t quality,
    int32_t *out_hresult)
{
  HRESULT lastHr = S_OK;
  auto setHr = [&](HRESULT hr)
  {
    lastHr = hr;
    if (out_hresult)
    {
      *out_hresult = static_cast<int32_t>(hr);
    }
  };

  if (!input_path_utf8 || !output_path_utf8)
  {
    setHr(E_POINTER);
    return MF_TRANSCODE_ERR_INVALID_ARG;
  }

  std::wstring wideInput;
  std::wstring wideOutput;
  if (!Utf8ToWide(input_path_utf8, wideInput) || !Utf8ToWide(output_path_utf8, wideOutput))
  {
    setHr(E_INVALIDARG);
    return MF_TRANSCODE_ERR_UTF8_CONVERT;
  }

  UINT32 quality = (quality == 0) ? 85u : quality;
  if (quality > 100u)
    quality = 100u;

  HRESULT hrCo = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  bool didInitCom = SUCCEEDED(hrCo);
  if (FAILED(hrCo) && hrCo != RPC_E_CHANGED_MODE)
  {
    setHr(hrCo);
    return MF_TRANSCODE_ERR_COM_INIT;
  }

  HRESULT hrMf = MFStartup(MF_VERSION, MFSTARTUP_NOSOCKET);
  if (FAILED(hrMf))
  {
    if (didInitCom)
      CoUninitialize();
    setHr(hrMf);
    return MF_TRANSCODE_ERR_MF_STARTUP;
  }

  int32_t status = RunTranscode(wideInput, wideOutput, quality, lastHr);
  setHr(lastHr);

  MFShutdown();
  if (didInitCom)
  {
    CoUninitialize();
  }

  return status;
}