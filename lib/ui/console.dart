import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:interact_cli/interact_cli.dart';

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
    write('$bold$message$reset');
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

  void printDefault(String message) {
    _print(message);
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

  /// Asks the user for multiple options check by using the SpaceBar.
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
            activeItemPrefix: '>',
            checkedItemPrefix: '$cyan✔$reset',
            uncheckedItemPrefix: ' ',
            pickedItemPrefix: '$cyan✔$reset',
            unpickedItemPrefix: ' '),
      ).interact();
    } catch (e) {
      resetConsole();
      rethrow;
    }
  }
}
