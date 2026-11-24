// ignore_for_file: constant_identifier_names

RegExp getIosAssetRegex() {
  final regex = RegExp(
    // 1. Xcode 15+ typed symbols: Image(.foo), UIImage(resource: .foo)
    r'(?<typed>\b(?:Image|Color|UIImage|NSImage|UIColor|NSColor)\s*\(\s*(?:resource:\s*)?\.(?<typed_name>[A-Za-z_][A-Za-z0-9_]*))'
    r'|'
    // 2. SwiftUI Image("Foo") / Color("Foo")
    r'(?<swiftui>\b(?:Image|Color)\s*\(\s*(?:asset:|decorative:)?\s*"(?<swiftui_name>[^"\\]+)")'
    r'|'
    // 3. UIKit/AppKit named: initializers
    r'(?<named>\b(?:UIImage|NSImage|UIColor|NSColor)\s*\(\s*named:\s*"(?<named_name>[^"\\]+)")'
    r'|'
    // 4. Objective-C selectors
    r'(?<objc>\b(?:imageNamed|colorNamed)\s*:\s*@"(?<objc_name>[^"\\]+)")'
    r'|'
    // 5. Asset catalog folders
    r'(?<catalog>(?<catalog_path>[A-Za-z0-9_\-\/][A-Za-z0-9_\-\/ ]*?)\.(?<catalog_type>imageset|colorset|symbolset|appiconset|launchimage|dataset|brandassets|cubetextureset|mipmapset|textureset|sticker|stickerpack|arresourcegroup|arreferenceimage|spriteatlas|imagestack|iconset)\b)'
    r'|'
    // 6. XIB/Storyboard image references
    r'(?<xib>\bimage\s*=\s*"(?<xib_attr>[^"\\]+)"|<image\s+name\s*=\s*"(?<xib_image>[^"\\]+)")'
    r'|'
    // 7. Contents.json filename entries
    r'(?<contents_filename>"filename"\s*:\s*"(?<filename_value>[^"\\]+)")',
  );
  return regex;
}

const ASSET_SUFFIXES = [
  '.imageset',
  '.colorset',
  '.dataset',
  '.symbolset',
  '.appiconset'
];
