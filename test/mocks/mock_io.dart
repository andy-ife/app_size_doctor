import 'package:media_asset_optimizer/src/io/console.dart';
import 'package:media_asset_optimizer/src/io/file_system_client.dart';
import 'package:mocktail/mocktail.dart';

class MockFileSystemClient extends Mock implements FileSystemClient {}

class MockConsole extends Mock implements Console {}
