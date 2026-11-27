import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:interact_cli/interact_cli.dart';
import 'package:media_asset_optimizer/exception/file_exception.dart';
import 'package:path/path.dart' as p;

const String reset = '\x1B[0m';

const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String cyan = '\x1B[96m';

const String light = '\x1B[0;90m';
const String bold = '\x1B[1;37m';

/// Simple wrapper around [Stdin] & [Stdout]
class Console {
  Console();

  int _linesCount = 0;

  /// Shows how many lines are currently being used for rendering
  int get linesCount => _linesCount;

  void _print(String value) {
    _linesCount++;
    return print(value);
  }

  void write(String value) {
    if (value.contains('\n')) _linesCount++;
    return stdout.write(value);
  }

  void showCursor() {
    write('\x1B[?25h');
  }

  void hideCursor() {
    write('\x1B[?25l\n}');
  }

  void resetConsole() {
    showCursor();
    write(reset); // reset terminal colors
  }

  String? read() {
    try {
      return stdin.readLineSync();
    } on StdinException {
      showCursor();
      exit(0); // app cancelled by user (Ctrl+C)
    }
  }

  void printHeader(String title) {
    printHint('\n=============');
    printInfo(title);
    printHint('=============\n');
  }

  void printSubHeader(String title, {bool nl = true}) {
    printInfo('${nl ? '\n' : ''}$bold$title$reset');
  }

  void printDivider() {
    printHint('=============');
  }

  /// Print error. Adds leading and trailing newlines by default
  void printError(String message) {
    _print('\n$red$message$reset\n');
  }

  /// For small phrases/snippets
  void printHint(String message) {
    _print('$cyan$message$reset');
  }

  void printInputPrompt(String message) {
    write('${'$cyan>$reset'}  $bold$message$reset');
  }

  void printInfo(String message) {
    _print(message);
  }

  void printWarning(String message) {
    _print('$yellow$message$reset');
  }

  void printSuccess(String message) {
    _print('$green$message$reset');
  }

  /// Offloads [work] to a separate Isolate, while printing [message]
  /// and a loading animation on the main Isolate
  ///
  /// Important to remember that [work] runs in a new Isolate, so variables
  /// from the main Isolate are copied implicitly to the new Isolate.
  /// Meaning that mutating them in the new Isolate will NOT reflect in the
  /// old Isolate
  Future<T> printLoading<T>(
      {required String message, required T Function() work}) async {
    late final T result;
    bool loading = true;

    Isolate.run(work).then((data) {
      result = data;
    }).whenComplete(() {
      loading = false;
    });

    int i = 2;
    hideCursor();
    do {
      String dots = '.' * ((i % 3) + 1);
      write('\r$message${dots.padRight(4)}');
      i++;
      await Future.delayed(const Duration(milliseconds: 500));
    } while (loading);
    showCursor();
    return result;
  }

  /// Asks the user to select multiple options check by using spacebar to select, and enter to confirm.
  /// Returns a list of selected indexes.
  List<int> printMultiSelect(
      {required String message,
      required List<String> options,
      List<bool>? defaults}) {
    try {
      print('');
      return MultiSelect.withTheme(
        prompt: message,
        options: options,
        defaults: defaults,
        theme: Theme.basicTheme.copyWith(
            inputSuffix: '',
            successSuffix: '',
            messageStyle: (x) => x,
            hintStyle: (x) => '$cyan$x$reset',
            errorStyle: (x) => '$red$x$reset',
            activeItemStyle: (x) => x,
            inactiveItemStyle: (x) => '$light$x$reset',
            activeItemPrefix: '$cyan>$reset',
            checkedItemPrefix: '$cyan✔$reset',
            uncheckedItemPrefix: ' ',
            pickedItemPrefix: '$cyan✔$reset',
            unpickedItemPrefix: ' '),
      ).interact();
    } catch (e) {
      resetConsole();
      throw GeneralFileException(message: e.toString());
    }
  }

  /// Asks the user to select one out of multiple options.
  /// [optionsAndHints] is a map of options (keys) and their respective, optional hints (values).
  /// Hint will be shown in dim text when the associated item is hovered
  int printSelect({
    required String message,
    required Map<String, String?> optionsAndHints,
  }) {
    String? getHint(String option) =>
        optionsAndHints.entries.firstWhere((e) => e.key == option).value;

    try {
      print('');
      return Select.withTheme(
        prompt: message,
        options: optionsAndHints.keys.toList(),
        theme: Theme.basicTheme.copyWith(
            inputSuffix: '',
            successSuffix: '',
            messageStyle: (x) => x,
            hintStyle: (x) => '$cyan$x$reset',
            errorStyle: (x) => '$red$x$reset',
            activeItemStyle: (x) =>
                '$bold$x$reset ${getHint(x) == null ? '' : '$light(${getHint(x)})$reset'}',
            inactiveItemStyle: (x) => '$light$x$reset',
            activeItemPrefix: '$cyan>$reset',
            checkedItemPrefix: '$cyan✔$reset',
            uncheckedItemPrefix: ' ',
            pickedItemPrefix: '$cyan✔$reset',
            unpickedItemPrefix: ' '),
      ).interact();
    } catch (e) {
      resetConsole();
      throw GeneralFileException(message: e.toString());
    }
  }

  /// Prints items in a 2 - 6 column matrix
  /// Useful for long lists
  void printMatrix(Set<String> items) {
    if (items.length < 6) {
      for (var asset in items) {
        printInfo('• $asset');
      }
    } else {
      final matrix = _getBestMatrix(items, minSpacing: 8);
      if (matrix.length == 1) {
        // single list
        for (var asset in items) {
          printInfo('• $asset');
        }
      } else {
        // matrix
        for (var i in matrix) {
          printInfo(i.join());
        }
      }
    }
  }

  List<List<String>> _getBestMatrix(Set<String> items,
      {int maxColumns = 6, int minSpacing = 8}) {
    final terminalWidth = stdout.hasTerminal ? stdout.terminalColumns : 80;
    var bestMatrix = <List<String>>[];

    while (maxColumns > 0) {
      if (maxColumns == 1) {
        return [items.toList()];
      }

      final matrix = _buildMatrix(items, maxColumns);
      final longestRow =
          matrix.map((e) => e.length).reduce((a, b) => max(a, b));
      final cols = List<List<String>>.generate(longestRow, (_) => []);

      // get cols
      for (int i = 0; i < matrix.length; i++) {
        final row = matrix[i];
        for (int j = 0; j < row.length; j++) {
          final cur = row[j];
          cols[j].insert(i, cur);
        }
      }

      // get required width of all columns
      int totalRequiredWidth = 0;
      final colWidths = <int>[];
      for (var col in cols) {
        final widths = col.map((e) => e.length + minSpacing);
        final maxWidth = widths.reduce((a, b) => max(a, b));
        colWidths.add(maxWidth);
        totalRequiredWidth += maxWidth;
      }

      // check if requiredWidth will fit in terminalWidth
      if (totalRequiredWidth > terminalWidth) {
        maxColumns--;
        continue;
      } else {
        // add the widths to the cols
        final formattedCols = cols.indexed.map((cur) {
          final index = cur.$1;
          final col = cur.$2;
          return col.map((e) {
            return e.padRight(colWidths[index]);
          }).toList();
        }).toList();

        // convert cols list to rows list
        bestMatrix = matrix.map((_) => <String>[]).toList();
        for (int i = 0; i < formattedCols.length; i++) {
          final col = formattedCols[i];
          for (int j = 0; j < col.length; j++) {
            final cur = col[j];
            bestMatrix[j].insert(i, cur);
          }
        }
        break;
      }
    }

    return bestMatrix;
  }

  List<List<String>> _buildMatrix(Set<String> items, int colCount) {
    final matrix = <List<String>>[];
    final rowCount = (items.length / colCount).ceil();

    // populate matrix
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        final listIndex = (row * colCount) + col;
        if (listIndex >= items.length) break;
        final item = items.elementAt(listIndex);
        final newRow = (matrix.elementAtOrNull(row) ?? [])..add(item);
        if (matrix.elementAtOrNull(row) == null) {
          matrix.add(newRow);
        } else {
          matrix[row] = newRow;
        }
      }
    }
    return matrix;
  }

  // ===========
  // File trees
  // ===========

  Map<String, dynamic> treePaths = {};

  Map<String, dynamic> buildTree(List<String> paths) {
    Map<String, dynamic> root = SplayTreeMap<String, dynamic>();
    for (var path in paths) {
      final parts = p.split(path);
      Map<String, dynamic> currentNode = root;
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (i == parts.length - 1) {
          currentNode[part] = true;
        } else {
          currentNode.putIfAbsent(part, () => SplayTreeMap<String, dynamic>());
          currentNode = currentNode[part];
        }
      }
    }
    treePaths = root;
    return root;
  }

  void printTree({Map<String, dynamic>? paths, String? prefix}) {
    final node = paths ?? treePaths;
    final keys = node.keys.toList();
    final prefix0 = prefix ?? '';

    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final isLastEntry = (i == keys.length - 1);
      final entityPrefix = isLastEntry ? '└── ' : '├── ';
      final childPrefix = prefix0 + (isLastEntry ? '    ' : '│   ');
      printInfo('$prefix0$entityPrefix$key');
      if (node[key] is Map) {
        printTree(
          paths: node[key],
          prefix: childPrefix,
        );
      }
    }
  }

  void buildAndPrintTree(List<String> paths) {
    buildTree(paths);
    printTree();
  }
}
