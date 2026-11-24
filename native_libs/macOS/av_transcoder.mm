#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>

#include "av_transcoder.h"
#include <dispatch/dispatch.h>
#include <algorithm>
#include <cmath>
#include <cstring>

namespace {

NSInteger ComputeTargetVideoBitrate(CGSize size, double fps, uint32_t quality) {
  if (quality == 0) quality = 85;
  if (quality > 100) quality = 100;
  if (fps <= 1.0) fps = 30.0;

  double pixels = std::max(1.0, static_cast<double>(size.width) * static_cast<double>(size.height));
  double qNorm = static_cast<double>(quality) / 85.0;
  double fpsScale = fps / 30.0;
  double bitsPerSecond = pixels * fpsScale * 0.12 * std::pow(qNorm, 1.4);

  double clamped = std::clamp(bitsPerSecond, 250000.0, 50000000.0);
  return static_cast<NSInteger>(std::llround(clamped));
}

AVFileType SelectOutputFileType(NSString* outputPath, BOOL hasVideo, BOOL hasAudio) {
  NSString* ext = [[outputPath pathExtension] lowercaseString];
  if (!hasVideo && hasAudio) {
    if ([ext isEqualToString:@"mp3"]) {
      return AVFileTypeMPEGLayer3;
    }
    if ([ext isEqualToString:@"mov"]) {
      return AVFileTypeQuickTimeMovie;
    }
    return AVFileTypeMPEG4;
  }

  if ([ext isEqualToString:@"mov"]) {
    return AVFileTypeQuickTimeMovie;
  }
  return AVFileTypeMPEG4;
}

int32_t RunTranscode(NSString* inputPath,
                     NSString* outputPath,
                     uint32_t quality,
                     int32_t& outCode) {
  outCode = noErr;

  NSURL* inputUrl = [NSURL fileURLWithPath:inputPath];
  NSURL* outputUrl = [NSURL fileURLWithPath:outputPath];

  NSFileManager* fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:outputPath]) {
    NSError* removeErr = nil;
    [fm removeItemAtPath:outputPath error:&removeErr];
  }

  NSDictionary* assetOpts = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
  AVURLAsset* asset = [AVURLAsset URLAssetWithURL:inputUrl options:assetOpts];

  NSArray<AVAssetTrack*>* videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
  NSArray<AVAssetTrack*>* audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];

  BOOL hasVideo = (videoTracks.count > 0);
  BOOL hasAudio = (audioTracks.count > 0);

  if (!hasVideo && !hasAudio) {
    outCode = -7;
    return AV_TRANSCODE_ERR_STREAM_SETUP;
  }

  NSError* error = nil;
  AVAssetReader* reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
  if (!reader || error) {
    outCode = error ? static_cast<int32_t>(error.code) : -1;
    return AV_TRANSCODE_ERR_READER_INIT;
  }

  AVFileType fileType = SelectOutputFileType(outputPath, hasVideo, hasAudio);
  AVAssetWriter* writer = [[AVAssetWriter alloc] initWithURL:outputUrl fileType:fileType error:&error];
  if (!writer || error) {
    outCode = error ? static_cast<int32_t>(error.code) : -2;
    return AV_TRANSCODE_ERR_WRITER_INIT;
  }

  AVAssetReaderTrackOutput* videoReaderOut = nil;
  AVAssetWriterInput* videoWriterIn = nil;

  // --- 1. Video Track (only when input has video) ---
  if (hasVideo) {
    AVAssetTrack* srcVideoTrack = videoTracks.firstObject;
    CGSize natSize = srcVideoTrack.naturalSize;
    CGAffineTransform prefTransform = srcVideoTrack.preferredTransform;
    CGSize transformedSize = CGSizeApplyAffineTransform(natSize, prefTransform);
    uint32_t width = static_cast<uint32_t>(std::max(1.0, std::abs(transformedSize.width)));
    uint32_t height = static_cast<uint32_t>(std::max(1.0, std::abs(transformedSize.height)));

    float nominalFps = srcVideoTrack.nominalFrameRate;
    double fps = nominalFps > 1.0f ? static_cast<double>(nominalFps) : 30.0;

    NSDictionary* readerVideoSettings = @{
      (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
    };
    videoReaderOut = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:srcVideoTrack
                                                               outputSettings:readerVideoSettings];
    videoReaderOut.alwaysCopiesSampleData = NO;
    if (![reader canAddOutput:videoReaderOut]) {
      outCode = -3;
      return AV_TRANSCODE_ERR_STREAM_SETUP;
    }
    [reader addOutput:videoReaderOut];

    NSInteger targetBitrate = ComputeTargetVideoBitrate(CGSizeMake(width, height), fps, quality);
    NSDictionary* compressionProps = @{
      AVVideoAverageBitRateKey : @(targetBitrate),
      AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
      AVVideoAllowFrameReorderingKey : @YES
    };

    NSDictionary* writerVideoSettings = @{
      AVVideoCodecKey : AVVideoCodecTypeH264,
      AVVideoWidthKey : @(width),
      AVVideoHeightKey : @(height),
      AVVideoCompressionPropertiesKey : compressionProps
    };

    videoWriterIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                     outputSettings:writerVideoSettings];
    videoWriterIn.expectsMediaDataInRealTime = NO;
    videoWriterIn.transform = prefTransform;

    if (![writer canAddInput:videoWriterIn]) {
      outCode = -4;
      return AV_TRANSCODE_ERR_STREAM_SETUP;
    }
    [writer addInput:videoWriterIn];
  }

  AVAssetReaderTrackOutput* audioReaderOut = nil;
  AVAssetWriterInput* audioWriterIn = nil;

  // --- 2. Audio Track (only when input has audio) ---
  if (hasAudio) {
    AVAssetTrack* srcAudioTrack = audioTracks.firstObject;

    uint32_t channels = 2;
    CMFormatDescriptionRef fmtDesc = (__bridge CMFormatDescriptionRef)srcAudioTrack.formatDescriptions.firstObject;
    if (fmtDesc) {
      const AudioStreamBasicDescription* asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmtDesc);
      if (asbd && asbd->mChannelsPerFrame > 0) {
        channels = (asbd->mChannelsPerFrame == 1) ? 1 : 2;
      }
    }

    const double sampleRate = 22050.0;
    const uint32_t bitsPerChannel = 16;
    const NSInteger mp3BitrateBps = 128000;

    NSDictionary* readerAudioSettings = @{
      AVFormatIDKey : @(kAudioFormatLinearPCM),
      AVSampleRateKey : @(sampleRate),
      AVNumberOfChannelsKey : @(channels),
      AVLinearPCMBitDepthKey : @(bitsPerChannel),
      AVLinearPCMIsFloatKey : @NO,
      AVLinearPCMIsBigEndianKey : @NO,
      AVLinearPCMIsNonInterleaved : @NO
    };

    audioReaderOut = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:srcAudioTrack
                                                               outputSettings:readerAudioSettings];
    audioReaderOut.alwaysCopiesSampleData = NO;
    if (![reader canAddOutput:audioReaderOut]) {
      outCode = -5;
      return AV_TRANSCODE_ERR_STREAM_SETUP;
    }
    [reader addOutput:audioReaderOut];

    NSDictionary* writerAudioSettings = @{
      AVFormatIDKey : @(kAudioFormatMPEGLayer3),
      AVSampleRateKey : @(sampleRate),
      AVNumberOfChannelsKey : @(channels),
      AVEncoderBitRateKey : @(mp3BitrateBps)
    };

    audioWriterIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                     outputSettings:writerAudioSettings];
    audioWriterIn.expectsMediaDataInRealTime = NO;

    if (![writer canAddInput:audioWriterIn]) {
      outCode = -6;
      return AV_TRANSCODE_ERR_STREAM_SETUP;
    }
    [writer addInput:audioWriterIn];
  }

  if (![reader startReading]) {
    outCode = reader.error ? static_cast<int32_t>(reader.error.code) : -8;
    return AV_TRANSCODE_ERR_PIPELINE;
  }

  if (![writer startWriting]) {
    outCode = writer.error ? static_cast<int32_t>(writer.error.code) : -9;
    [reader cancelReading];
    return AV_TRANSCODE_ERR_PIPELINE;
  }

  [writer startSessionAtSourceTime:kCMTimeZero];

  dispatch_group_t group = dispatch_group_create();
  __block BOOL pumpFailed = NO;
  __block int32_t pumpErrCode = noErr;

  if (hasVideo && videoWriterIn && videoReaderOut) {
    dispatch_group_enter(group);
    dispatch_queue_t vQueue = dispatch_queue_create("av.transcoder.video", DISPATCH_QUEUE_SERIAL);
    [videoWriterIn requestMediaDataWhenReadyOnQueue:vQueue usingBlock:^{
      while ([videoWriterIn isReadyForMoreMediaData]) {
        if (pumpFailed || [reader status] != AVAssetReaderStatusReading) {
          [videoWriterIn markAsFinished];
          dispatch_group_leave(group);
          return;
        }
        CMSampleBufferRef sample = [videoReaderOut copyNextSampleBuffer];
        if (sample) {
          BOOL ok = [videoWriterIn appendSampleBuffer:sample];
          CFRelease(sample);
          if (!ok) {
            pumpFailed = YES;
            pumpErrCode = writer.error ? static_cast<int32_t>(writer.error.code) : -10;
            [videoWriterIn markAsFinished];
            dispatch_group_leave(group);
            return;
          }
        } else {
          [videoWriterIn markAsFinished];
          dispatch_group_leave(group);
          return;
        }
      }
    }];
  }

  if (hasAudio && audioWriterIn && audioReaderOut) {
    dispatch_group_enter(group);
    dispatch_queue_t aQueue = dispatch_queue_create("av.transcoder.audio", DISPATCH_QUEUE_SERIAL);
    [audioWriterIn requestMediaDataWhenReadyOnQueue:aQueue usingBlock:^{
      while ([audioWriterIn isReadyForMoreMediaData]) {
        if (pumpFailed || [reader status] != AVAssetReaderStatusReading) {
          [audioWriterIn markAsFinished];
          dispatch_group_leave(group);
          return;
        }
        CMSampleBufferRef sample = [audioReaderOut copyNextSampleBuffer];
        if (sample) {
          BOOL ok = [audioWriterIn appendSampleBuffer:sample];
          CFRelease(sample);
          if (!ok) {
            pumpFailed = YES;
            pumpErrCode = writer.error ? static_cast<int32_t>(writer.error.code) : -11;
            [audioWriterIn markAsFinished];
            dispatch_group_leave(group);
            return;
          }
        } else {
          [audioWriterIn markAsFinished];
          dispatch_group_leave(group);
          return;
        }
      }
    }];
  }

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

  if (pumpFailed || [reader status] == AVAssetReaderStatusFailed) {
    [reader cancelReading];
    [writer cancelWriting];
    outCode = pumpFailed ? pumpErrCode
        : (reader.error ? static_cast<int32_t>(reader.error.code) : -12);
    return AV_TRANSCODE_ERR_PIPELINE;
  }

  dispatch_semaphore_t finishSem = dispatch_semaphore_create(0);
  __block BOOL writeOk = NO;
  __block int32_t finishErrCode = noErr;

  [writer finishWritingWithCompletionHandler:^{
    writeOk = ([writer status] == AVAssetWriterStatusCompleted);
    if (!writeOk && writer.error) {
      finishErrCode = static_cast<int32_t>(writer.error.code);
    }
    dispatch_semaphore_signal(finishSem);
  }];

  dispatch_semaphore_wait(finishSem, DISPATCH_TIME_FOREVER);

  if (!writeOk) {
    outCode = finishErrCode != noErr ? finishErrCode : -13;
    return AV_TRANSCODE_ERR_PIPELINE;
  }

  return AV_TRANSCODE_OK;
}

} // namespace

extern "C" int32_t av_transcode_to_h264_mp3(
    const char* input_path_utf8,
    const char* output_path_utf8,
    uint32_t video_quality,
    int32_t* out_os_status) {
  int32_t code = noErr;
  auto setCode = [&](int32_t c) {
    code = c;
    if (out_os_status) {
      *out_os_status = c;
    }
  };

  if (!input_path_utf8 || !output_path_utf8) {
    setCode(kParamErr);
    return AV_TRANSCODE_ERR_INVALID_ARG;
  }

  @autoreleasepool {
    NSString* inputPath = [NSString stringWithUTF8String:input_path_utf8];
    NSString* outputPath = [NSString stringWithUTF8String:output_path_utf8];
    if (!inputPath || !outputPath) {
      setCode(kParamErr);
      return AV_TRANSCODE_ERR_UTF8_CONVERT;
    }

    int32_t status = RunTranscode(inputPath, outputPath, video_quality, code);
    setCode(code);
    return status;
  }
}