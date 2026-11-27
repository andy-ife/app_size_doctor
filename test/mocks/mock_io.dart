import 'package:media_asset_optimizer/src/io/compression_client.dart';
import 'package:media_asset_optimizer/src/io/console.dart';
import 'package:media_asset_optimizer/src/io/file_system_client.dart';
import 'package:mocktail/mocktail.dart';

import 'sample_data.dart';

class MockFileSystemClient extends Mock implements FileSystemClient {
  MockFileSystemClient() {
    _registerDefaultFsStubs(this);
  }
}

class MockCompressionClient extends Mock implements CompressionClient {
  MockCompressionClient() {
    _registerDefaultCompressionClientStubs(this);
  }
}

class MockConsole extends Mock implements Console {
  MockConsole() {
    _registerDefaultConsoleStubs(this);
  }
}

void _registerDefaultFsStubs(MockFileSystemClient fs) {
  when(() => fs.projectRoot).thenReturn(SAMPLE_PROJECT_ROOT);
  when(() => fs.ignoredDirs).thenReturn(SAMPLE_IGNORED_DIRS);
  when(() => fs.fileExists(any())).thenAnswer((_) => true);
  when(() => fs.lengthSync(any())).thenAnswer((_) => 20);
}

void _registerDefaultCompressionClientStubs(MockCompressionClient client) {
  when(() => client.compressImage(any())).thenAnswer((_) => 20);
  when(() => client.compressVideoOrAudio(any())).thenAnswer((_) => 20);
  when(() => client.compressMedia(any())).thenAnswer((_) => 20);
  when(() => client.compressAllMedia(any())).thenAnswer((_) => 20);
}

void _registerDefaultConsoleStubs(MockConsole console) {
  when(() => console.printError(any())).thenAnswer((_) {});
  when(() => console.printInfo(any())).thenAnswer((_) {});
  when(() => console.printHeader(any())).thenAnswer((_) {});
  when(() => console.printHint(any())).thenAnswer((_) {});
  when(() => console.buildTree(any())).thenAnswer((_) => {});
  when(() => console.printWarning(any())).thenAnswer((_) {});
}

void stubPrintLoading<T>(MockConsole console) {
  when(() => console.printLoading<T>(
        message: any(named: 'message'),
        work: any(named: 'work'),
      )).thenAnswer((invocation) async {
    final work = invocation.namedArguments[#work] as T Function();
    return work();
  });
}
