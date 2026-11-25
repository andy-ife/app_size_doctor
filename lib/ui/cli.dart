import 'package:args/args.dart';
import 'package:media_asset_optimizer/ui/console.dart';

enum CliMode { compressAll, compressSome, dryRun, none }

const PADDING = 32;

class Cli {
  Cli({Console? console}) : console = console ?? Console();

  late final Console console;

  CliMode start(List<String> arguments) {
    final parser = ArgParser()
      ..addFlag('help', abbr: 'h', defaultsTo: false)
      ..addFlag('all', abbr: 'a', defaultsTo: false)
      ..addFlag('select', abbr: 's', defaultsTo: false)
      ..addFlag('dry-run', abbr: 'd', defaultsTo: false);

    ArgResults argResults = parser.parse(arguments);
    bool requestingHelp = argResults['help'] as bool;
    bool compressAll = argResults['all'] as bool;
    bool compressSome = argResults['select'] as bool;
    bool dryRun = argResults['dry-run'] as bool;
    final noArgs = !compressAll && !dryRun && !requestingHelp;

    if (noArgs) {
      console.printHeader('Media Asset Optimizer');
      console.printInfo('Get started');
      int selection = 0;
      do {
        selection = console.printSelect(message: 'Options', optionsAndHints: {
          '1. Compress all': 'Compress all non-hidden assets in the project',
          '2. Compress some': 'Select which assets to skip',
          '3. Dry run': 'Estimate savings without touching anything',
          '4. Help': 'Help'
        });
        selection++;
      } while (selection < 1);

      switch (selection) {
        case 1:
          compressAll = true;
          break;
        case 2:
          compressSome = true;
          break;
        case 3:
          dryRun = true;
          break;
        case 4:
          requestingHelp = true;
          break;
        default:
          console.printError('Invalid option. Please choose 1 - 4');
          break;
      }
    }

    if (requestingHelp) {
      showHelp();
      return CliMode.none;
    }

    if (compressAll) {
      return CliMode.compressAll;
    }

    if (compressSome) {
      return CliMode.compressSome;
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
    console.printHint('`dart run media_asset_optimizer`\n');
    console.printInfo('Flags (optional):');
    console.printInfo(
        '${'-a, --all'.padRight(PADDING)}Compress all project assets');
    console.printInfo(
        '${'-s, --select'.padRight(PADDING)}Select some assets to ignore');
    console.printInfo(
        '${'-d, --dry-run'.padRight(PADDING)}Dry run (See potential size savings without touching anything)');
    console.printInfo('${'-h, --help'.padRight(PADDING)}Help');
  }

  void showTutorial() {
    console.printInfo('\nOptions:');
    console.printInfo('1. Compress all');
    console.printInfo('2. Compress some (select assets to ignore)');
    console.printInfo('3. Dry run');
    console.printInfo('4. Help');
    console.printInputPrompt('Choose one (1-4): ');
  }
}
