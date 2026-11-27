import 'package:args/args.dart';
import 'package:media_asset_optimizer/src/io/console.dart';

enum CliMode {
  compressAll('all', 'a'),
  compressSome('select', 's'),
  compressFile('', ''),
  dryRun('dry-run', 'd'),
  none('help', 'h');

  const CliMode(this.modeName, this.abbr);

  final String modeName;
  final String abbr;
}

enum CliArgs {
  quality('quality', 'q'),
  singleFile('single-file', 'f');

  const CliArgs(this.flagName, this.abbr);

  final String flagName;
  final String abbr;
}

const PADDING = 32;

class Cli {
  Cli({Console? console}) : console = console ?? Console();

  final Console console;

  int? _quality;
  String? _singleFile;

  /// File quality from 1 (smallest file) to 100 (best quality).
  ///
  /// When null, each media type keeps its own default.
  int? get quality => _quality;

  /// Path to a single asset to compress instead of scanning the project.
  String? get singleFile => _singleFile;

  CliMode start(List<String> arguments) {
    final parser = ArgParser()
      ..addFlag(
        CliMode.none.modeName,
        abbr: CliMode.none.abbr,
        defaultsTo: false,
      )
      ..addFlag(
        CliMode.compressAll.modeName,
        abbr: CliMode.compressAll.abbr,
        defaultsTo: false,
      )
      ..addFlag(
        CliMode.compressSome.modeName,
        abbr: CliMode.compressSome.abbr,
        defaultsTo: false,
      )
      ..addFlag(
        CliMode.dryRun.modeName,
        abbr: CliMode.dryRun.abbr,
        defaultsTo: false,
      )
      ..addOption(
        CliArgs.quality.flagName,
        abbr: CliArgs.quality.abbr,
        valueHelp: '1-100',
      )
      ..addOption(
        CliArgs.singleFile.flagName,
        abbr: CliArgs.singleFile.abbr,
        valueHelp: 'path/to/asset',
      );

    ArgResults argResults;
    try {
      argResults = parser.parse(arguments);
    } on FormatException catch (e) {
      console.printError(e.message);
      showHelp();
      return CliMode.none;
    }

    bool requestingHelp = argResults[CliMode.none.modeName] as bool;
    bool compressAll = argResults[CliMode.compressAll.modeName] as bool;
    bool compressSome = argResults[CliMode.compressSome.modeName] as bool;
    bool dryRun = argResults[CliMode.dryRun.modeName] as bool;

    if (requestingHelp) {
      showHelp();
      return CliMode.none;
    }

    final rawQuality = argResults[CliArgs.quality.flagName] as String?;
    if (rawQuality != null) {
      final quality = int.tryParse(rawQuality);
      if (quality == null || quality < 1 || quality > 100) {
        console.printError(
            'Invalid quality "$rawQuality". Choose a value between 1 and 100.');
        return CliMode.none;
      }
      _quality = quality;
    }

    final rawSingleFile = argResults[CliArgs.singleFile.flagName] as String?;
    final singleFile = rawSingleFile?.trim();
    if (singleFile != null && singleFile.isNotEmpty) {
      _singleFile = singleFile;
      return CliMode.compressFile;
    }

    final noArgs = !compressAll && !compressSome && !dryRun;

    if (noArgs) {
      console.printHeader('Media Asset Optimizer');
      console.printInfo('Get started');
      int selection = 0;
      do {
        selection = showTutorial();
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
    _printModeHelp(CliMode.compressAll, 'Compress all project assets');
    _printModeHelp(CliMode.compressSome, 'Select some assets to ignore');
    _printModeHelp(CliMode.dryRun,
        'Dry run (See potential size savings without touching anything)');
    _printArgHelp(
        CliArgs.quality, 'File quality: 1 = smallest file, 100 = best quality',
        valueHelp: '<1-100>');
    _printArgHelp(
        CliArgs.singleFile, 'Compress one asset, e.g. assets/logo.png',
        valueHelp: '<path>');
    _printModeHelp(CliMode.none, 'Help');
  }

  void _printModeHelp(CliMode mode, String description) {
    _printHelpEntry(mode.modeName, mode.abbr, description);
  }

  void _printArgHelp(CliArgs arg, String description, {String? valueHelp}) {
    _printHelpEntry(arg.flagName, arg.abbr, description, valueHelp: valueHelp);
  }

  void _printHelpEntry(String name, String abbr, String description,
      {String? valueHelp}) {
    final flag = [
      if (abbr.isNotEmpty && name.isNotEmpty)
        '-$abbr, --$name'
      else if (abbr.isNotEmpty)
        '-$abbr'
      else if (name.isNotEmpty)
        '--$name',
      if (valueHelp != null) valueHelp,
    ].join(' ');
    console.printInfo('${flag.padRight(PADDING)}$description');
  }

  int showTutorial() {
    return console.printSelect(message: 'Options', optionsAndHints: {
          '1. Compress all': 'Compress all non-hidden assets in the project',
          '2. Compress some': 'Select which assets to skip',
          '3. Dry run': 'Estimate savings without touching anything',
          '4. Help': 'Help'
        }) +
        1;
  }
}
