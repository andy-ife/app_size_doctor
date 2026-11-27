import 'package:media_asset_optimizer/src/ui/cli.dart';
import 'package:test/test.dart';

void main() {
  group('Cli', () {
    test('parses quality with --all', () {
      final cli = Cli();

      expect(
        cli.start(['--all', '--quality', '75']),
        CliMode.compressAll,
      );
      expect(cli.quality, 75);
    });

    test('parses the short quality flag', () {
      final cli = Cli();

      expect(cli.start(['-a', '-q', '25']), CliMode.compressAll);
      expect(cli.quality, 25);
    });

    test('keeps quality null when not provided', () {
      final cli = Cli();

      expect(cli.start(['--all']), CliMode.compressAll);
      expect(cli.quality, isNull);
    });

    test('parses a single file', () {
      final cli = Cli();

      expect(
        cli.start(['--single-file', 'assets/logo.png']),
        CliMode.compressFile,
      );
      expect(cli.singleFile, 'assets/logo.png');
    });

    test('parses the short single file flag', () {
      final cli = Cli();

      expect(cli.start(['-f', 'assets/logo.png']), CliMode.compressFile);
      expect(cli.singleFile, 'assets/logo.png');
    });

    test('rejects quality outside 1-100', () {
      for (final quality in ['0', '101', 'high']) {
        final cli = Cli();
        expect(
          cli.start(['--all', '--quality', quality]),
          CliMode.none,
        );
      }
    });

    test('does not launch the tutorial for --select', () {
      expect(Cli().start(['--select']), CliMode.compressSome);
    });

    test('parses the help flag', () {
      expect(Cli().start(['-h']), CliMode.none);
      expect(Cli().start(['--help']), CliMode.none);
    });
  });
}
