const validPubspec = '''
name: dio
version: 5.11.1

description: |
  A powerful HTTP networking package,
  supports Interceptors,
  Aborting and canceling a request,
  Custom adapters, Transformers, etc.
topics:
  - dio
  - http
  - network
  - interceptor
  - middleware
homepage: https://github.com/cfug/dio
repository: https://github.com/cfug/dio/blob/main/dio
issue_tracker: https://github.com/cfug/dio/issues

environment:
  sdk: '>=2.18.0 <4.0.0'

dependencies:
  async: ^2.8.2
  collection: ^1.16.0
  http_parser: ^4.0.0
  meta: ^1.5.0
  mime: '>=1.0.0 <3.0.0'
  path: ^1.8.0

  dio_web_adapter: '>=1.1.0 <3.0.0'

dev_dependencies:
  lints: any
  test: ^1.5.1
  build_runner: any
  coverage: ^1.0.3
  crypto: ^3.0.2
  mockito: ^5.2.0

  # Shared test package.
  dio_test:
    git:
      url: https://github.com/cfug/dio
      path: dio_test
  
  assets:
  - assets/awesome_vid.mp4
  - assets/awesome_aud.mp3
  - assets/awesome_pic.jpg
  - android/app/src/main/res/raw/alarm.wav
  - android/app/src/main/res/drawable/background.png
  - ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-20@2x.png
  - ios/Runner/Assets.xcassets/LaunchBackground.imageset/background.png
''';

const invalidPubspec = '''
version: 5.11.1

description: |
  A powerful HTTP networking package,
  supports Interceptors,
  Aborting and canceling a request,
  Custom adapters, Transformers, etc.
topics:
  - dio
  - http
  - network
  - interceptor
  - middleware
homepage: https://github.com/cfug/dio
repository: https://github.com/cfug/dio/blob/main/dio
issue_tracker: https://github.com/cfug/dio/issues

environment:
  sdk: '>=2.18.0 <4.0.0'

dependencies:
  async: ^2.8.2
  collection: ^1.16.0
  http_parser: ^4.0.0
  meta: ^1.5.0
  mime: '>=1.0.0 <3.0.0'
  path: ^1.8.0

  dio_web_adapter: '>=1.1.0 <3.0.0'

dev_dependencies:
  lints: any
  test: ^1.5.1
  build_runner: any
  coverage: ^1.0.3
  crypto: ^3.0.2
  mockito: ^5.2.0

  # Shared test package.
  dio_test:
    git:
      url: https://github.com/cfug/dio
      path: dio_test
''';

const samplePubspecAssets = {
  '$SAMPLE_PROJECT_ROOT/assets/awesome_vid.mp4',
  '$SAMPLE_PROJECT_ROOT/assets/awesome_aud.mp3',
  '$SAMPLE_PROJECT_ROOT/assets/awesome_pic.jpg',
  '$SAMPLE_PROJECT_ROOT/android/app/src/main/res/raw/alarm.wav',
  '$SAMPLE_PROJECT_ROOT/android/app/src/main/res/drawable/background.png',
  '$SAMPLE_PROJECT_ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-20@2x.png',
  '$SAMPLE_PROJECT_ROOT/ios/Runner/Assets.xcassets/LaunchBackground.imageset/background.png'
};

const sampleFlutterAssets = {
  '$SAMPLE_PROJECT_ROOT/assets/images/logo.png',
  '$SAMPLE_PROJECT_ROOT/assets/images/banner.jpg',
  '$SAMPLE_PROJECT_ROOT/assets/icons/home.svg',
  '$SAMPLE_PROJECT_ROOT/assets/audio/alert.wav',
  '$SAMPLE_PROJECT_ROOT/assets/videos/intro.mp4',
};

const sampleAndroidAssets = {
  '$SAMPLE_PROJECT_ROOT/android/app/src/main/res/drawable/background.png',
  '$SAMPLE_PROJECT_ROOT/android/app/src/main/res/drawable-hdpi/icon.png',
  '$SAMPLE_PROJECT_ROOT/android/app/src/main/res/raw/alarm.wav',
  '$SAMPLE_PROJECT_ROOT/android/app/src/main/res/raw/theme.mp3',
};

const sampleIosAssets = {
  '$SAMPLE_PROJECT_ROOT/ios/Runner/Assets/Assets.xcassets/AppIcon.appiconset/AppIcon-20@2x.png',
  '$SAMPLE_PROJECT_ROOT/ios/Runner/Assets/Assets.xcassets/LaunchBackground.imageset/background.png',
  '$SAMPLE_PROJECT_ROOT/ios/Runner/Assets/Assets.xcassets/Sounds/alert.wav',
};

const SAMPLE_PROJECT_ROOT = 'rootProj';
const SAMPLE_IGNORED_DIRS = ['test', 'build'];
