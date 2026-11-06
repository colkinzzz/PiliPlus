import 'dart:convert';
import 'dart:io';

// The widget tests don't use plugins. Keep the production source and patched
// UI packages, but don't build the app's desktop native libraries for them.
void main(List<String> args) {
  final project = Directory(args.single).absolute.uri;
  final config = File('.dart_tool/package_config.json').absolute;
  final packages =
      (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;

  String packagePath(String name) {
    final package = packages.cast<Map>().singleWhere((p) => p['name'] == name);
    return jsonEncode(
      config.uri.resolve(package['rootUri'] as String).toFilePath(),
    );
  }

  for (final path in const [
    'lib/common/widgets/car_side_navigation.dart',
    'lib/common/widgets/car_viewport.dart',
    'lib/common/widgets/main_layout.dart',
    'lib/common/widgets/scaffold/simple_scaffold.dart',
    'lib/common/widgets/slotted_layout_helper.dart',
    'lib/common/widgets/view_insets_safe_area.dart',
    'test/widgets/car_side_navigation_test.dart',
    'test/widgets/car_viewport_test.dart',
  ]) {
    final destination = File.fromUri(project.resolve(path));
    destination.parent.createSync(recursive: true);
    File(path).copySync(destination.path);
  }

  File.fromUri(project.resolve('pubspec.yaml')).writeAsStringSync('''
name: PiliPlus
publish_to: none
environment:
  sdk: '>=3.13.0'
dependencies:
  flutter: {sdk: flutter}
  material_ui: {path: ${packagePath('material_ui')}}
dev_dependencies:
  flutter_test: {sdk: flutter}
dependency_overrides:
  cupertino_ui: {path: ${packagePath('cupertino_ui')}}
''');
}
