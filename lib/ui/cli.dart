import 'package:args/args.dart';
import 'package:asset_doctor/ui/console.dart';

enum CliMode { compress, dryRun, none }

const PADDING = 32;

class Cli {
  Cli({Console? console}) : console = console ?? Console();

  late final Console console;

  CliMode start(List<String> arguments) {
    final parser = ArgParser()
      ..addFlag('help', abbr: 'h', defaultsTo: false)
      ..addFlag('compress', abbr: 'x', defaultsTo: false)
      ..addFlag('dry-run', abbr: 'd', defaultsTo: false);

    ArgResults argResults = parser.parse(arguments);
    bool requestingHelp = argResults['help'] as bool;
    bool compress = argResults['compress'] as bool;
    bool dryRun = argResults['dry-run'] as bool;
    final noArgs = !compress && !dryRun && !requestingHelp;

    console.printHeader('Asset Doctor');

    if (noArgs) {
      console.printInfo('Get started');
      showTutorial();
      do {
        final input = console.read();
        switch (input?.trim()) {
          case '1':
            compress = true;
            break;
          case '2':
            dryRun = true;
            break;
          case '3':
            requestingHelp = true;
            break;
          default:
            console.printError('Invalid option. Please choose 1 - 4');
        }
      } while (!compress && !dryRun && !requestingHelp);
    }

    if (requestingHelp) {
      showHelp();
      return CliMode.none;
    }

    if (compress) {
      return CliMode.compress;
    }

    if (dryRun) {
      return CliMode.dryRun;
    }

    return CliMode.none;
  }

  void showHelp() {
    console.printHeader("Help");
    console.printInfo('Optimize your project\'s assets');
    console.printInfo("\nMain command:");
    console.printHint('`dart run asset_doctor`\n');
    console.printInfo('Flags (optional):');
    console
        .printInfo('${'-x, --compress-only'.padRight(PADDING)}Compress only');
    console.printInfo(
        '${'-d, --dry-run'.padRight(PADDING)}Dry run (See potential size savings without touching anything)');
    console.printInfo('${'-h, --help'.padRight(PADDING)}Help');
  }

  void showTutorial() {
    console.printInfo('\nOptions:');
    console.printInfo('1. Compress');
    console.printInfo('2. Dry run');
    console.printInfo('3. Help');
    console.printInputPrompt('Choose one (1-3): ');
  }
}
