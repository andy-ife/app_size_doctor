// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: constant_identifier_names

class AndroidResourceID {
  const AndroidResourceID(
      {required this.id, required this.type, required this.name});

  final String id; // full id e.g R.drawable.foo, @mipmap/appIcon
  final String type; // folder e.g drawable, mipmap
  final String name; // basename e.g foo, appIcon

  RegExp get regex => getAndroidResourceRegex(type: type, name: name);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AndroidResourceID &&
            id == other.id &&
            type == other.type &&
            name == other.name;
  }

  @override
  int get hashCode => Object.hash(id, type, name);
}

RegExp getAndroidResourceRegex({String? type, String? name}) {
  final typeRegex = type != null
      ? '($type)'
      : r'(drawable|mipmap|layout|anim|animator|menu|navigation|raw|xml|font|transition|interpolator|color)';

  final nameRegex = name != null ? '($name)' : r'([A-Za-z_][A-Za-z0-9_]*)';

  final androidResourceIdRegex = RegExp(
    r'(?:'
            // Kotlin/Java:  R.drawable.foo  (also matches com.example.R.drawable.foo)
            r'\bR\.' +
        typeRegex +
        r'\.' +
        nameRegex +
        r'|'
            // XML:  @drawable/foo  @+id/foo  @android:drawable/foo  @*android:drawable/foo
            r'@[+*]?(?:[A-Za-z0-9_.]+:)?' +
        typeRegex +
        r'/' +
        nameRegex +
        r')',
  );

  return androidResourceIdRegex;
}

RegExp getViewBindingRegex() {
  final bindingRegex = RegExp(r'(?:'
      r'\b'
      r'([A-Za-z_][A-Za-z0-9_]*Binding)\.inflate\s*\('
      r')');
  return bindingRegex;
}

const RES_FOLDERS = [
  'drawable',
  'raw',
  'mipmap',
  'layout',
  'animator',
  'anim',
  'menu',
  'navigation',
  'xml',
  'font',
  'transition',
  'interpolator',
  'color',
  'values'
];
