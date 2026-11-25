import 'package:path/path.dart' as p;

final nameRegex = RegExp(r'^\s*name:\s*([a-z0-9_]+)', multiLine: true);
final environmentRegex =
    RegExp(r'^\s*environment:\s*\n(?:[ \t]+.+\n?)*', multiLine: true);

class AssetsSearchService {
  /// Takes full raw text from pubspec.yaml and returns the list of assets from the
  /// assets section if present. The returned list is composed of both file and
  /// directory paths, so it is up to the caller to verify each
  ///
  /// [pubspecContent] is the raw text read from the pubspec file
  List<String> extractPubspecAssets(String pubspecContent, String projectRoot) {
    if (!(nameRegex.hasMatch(pubspecContent) &&
        environmentRegex.hasMatch(pubspecContent))) {
      throw 'Invalid Dart/Flutter pubspec.yaml file. Missing name: and environment: sections';
    }

    final assetRegex = RegExp(r'assets:\s*((?:\s+-\s+.+\n)+)', multiLine: true);
    final match = assetRegex.firstMatch(pubspecContent);
    if (match == null) return [];
    final assetLines = match
        .group(1)!
        .split('\n')
        .where((line) => line.trim().startsWith('-'))
        .map(
          (line) => line
              .trim()
              .substring(1)
              .trim()
              .replaceAll("'", '')
              .replaceAll('"', ''),
        )
        .toList();
    final assets = <String>[];
    for (var declaration in assetLines) {
      final fullPath = p.join(projectRoot, declaration).replaceAll('\\', '/');
      assets.add(fullPath);
    }
    return assets;
  }

  /// Return all string literals from a single file's [content]
  Set<String> findAllStringLiteralsInFile(String content) {
    final allNormalizedLiterals = <String>{};
    final stringLiteralRegex = RegExp(
        '\'(?:[^\\\'\\\\]|\\\\.)*\\\'|\\"(?:[^\\"\\\\]|\\\\.)*\\"|r\'[^\\\']*\\\'|r"[^\\"]*\\""',
        multiLine: true);

    final matches = stringLiteralRegex.allMatches(content);
    for (var match in matches) {
      String literal = match.group(0)!;
      String? normalized = _normalizeStringLiteral(literal);
      if (normalized != null && normalized.isNotEmpty) {
        allNormalizedLiterals.add(normalized);
      }
    }

    return allNormalizedLiterals;
  }

  /// Removes wrapping `r`, `'`, and `"` and extracts the string content itself
  ///
  /// Examples
  ///
  /// Input: `'Hello'`
  /// Output: `Hello`
  ///
  /// Input: `r"World's"`
  /// Output: `World's`
  static String? _normalizeStringLiteral(String literal) {
    if (literal.isEmpty) return null;
    String? content;
    if (literal.startsWith('r')) {
      if (literal.length >= 3) {
        content = literal.substring(2, literal.length - 1);
      }
    } else if ((literal.startsWith("'") && literal.endsWith("'")) ||
        (literal.startsWith('"') && literal.endsWith('"'))) {
      if (literal.length >= 2) {
        content = literal.substring(1, literal.length - 1);
      }
    }
    return content?.trim();
  }

  /// Compare all asset files with all string literals from the source code.
  ///
  /// For an example file `foo.png`, we have the following strings:
  ///
  /// - filename: `foo.png`
  ///
  /// - path: `project/lib/assets/foo.png`
  ///
  /// - basename without extension: `foo`
  ///
  /// If any of these strings is found in the string literals set,
  /// we make an educated guess that the asset is used.
  ///
  /// Returns the list of used assets
  Set<String> matchAssetsAndStringLiterals(
      Set<String> assetFiles, Set<String> allNormalizedLiterals) {
    Set<String> usedAssetPaths = {};
    for (final assetPath in assetFiles) {
      final filename = p.basename(assetPath);
      final basenameWithoutExtension = p.basenameWithoutExtension(assetPath);

      final potentialReferences = [
        assetPath,
        filename,
        basenameWithoutExtension,
      ];

      final isUsed = allNormalizedLiterals.any((literal) {
        return potentialReferences.any((ref) => literal.contains(ref));
      });

      if (isUsed) {
        usedAssetPaths.add(assetPath);
      }
    }
    return usedAssetPaths;
  }
}
