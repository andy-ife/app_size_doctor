import 'package:path/path.dart' as p;

enum AssetType { image, video, audio, text, unkown }

class AssetUtils {
  static const imageExtensions = [
    '.png',
    '.jpg',
    '.jpeg',
    '.jfif',
    '.svg',
    '.tiff',
    '.gif',
    '.webp',
    '.avif',
    '.bmp'
  ];

  static const videoExtensions = [
    '.mp4',
    '.mkv',
    '.avi',
    '.webm',
  ];

  static const audioExtensions = [
    '.m4a',
    '.mp3',
    '.ogg',
    '.opus',
    '.wav',
  ];

  static const textExtensions = [
    '.yaml',
    '.json',
    '.xml',
    '.txt',
    '',
  ];

  static bool isImage(String path) =>
      imageExtensions.contains(p.extension(path, 2));
  static bool isVideo(String path) =>
      videoExtensions.contains(p.extension(path, 2));
  static bool isAudio(String path) =>
      audioExtensions.contains(p.extension(path, 2));
  static bool isText(String path) =>
      textExtensions.contains(p.extension(path, 2));
  static bool isMedia(String path) =>
      isImage(path) || isVideo(path) || isAudio(path);

  static AssetType getAssetType(String path) => isImage(path)
      ? AssetType.image
      : isVideo(path)
          ? AssetType.video
          : isAudio(path)
              ? AssetType.audio
              : isText(path)
                  ? AssetType.text
                  : AssetType.unkown;
}
