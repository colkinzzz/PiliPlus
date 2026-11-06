import 'package:PiliPlus/common/widgets/car_viewport.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/view_insets_safe_area.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _listKey = ValueKey('search-suggestions');
const _firstSuggestion = '测试搜索建议';

Widget _searchLayout({
  double minimumTop = 0,
  double minimumBottom = 0,
  VoidCallback? onSuggestion,
}) => MaterialApp(
  builder: (context, child) => CarViewport(
    minimumTop: minimumTop,
    minimumBottom: minimumBottom,
    child: child!,
  ),
  home: SimpleScaffold(
    appBar: AppBar(title: const TextField()),
    body: ViewInsetsSafeArea(
      child: CustomScrollView(
        key: _listKey,
        slivers: [
          SliverList.builder(
            itemCount: 16,
            itemBuilder: (context, index) => ListTile(
              title: Text(index == 0 ? _firstSuggestion : '建议 $index'),
              onTap: onSuggestion,
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('car root consumes side and bottom insets once', (tester) async {
    final view = tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(2400, 1600);
    addTearDown(view.reset);

    for (final bottom in [192.0, 0.0]) {
      final padding = FakeViewPadding(top: 80, left: 32, bottom: bottom);
      view
        ..viewPadding = padding
        ..padding = padding;
      await tester.pumpWidget(_searchLayout(minimumTop: 56));
      await tester.pumpAndSettle();

      final list = find.byKey(_listKey);
      final rect = tester.getRect(list);
      final context = tester.element(list);
      expect(rect.left, 16);
      expect(rect.top, 56 + kToolbarHeight);
      expect(rect.bottom, 800 - bottom / 2);
      expect(MediaQuery.viewPaddingOf(context), const EdgeInsets.only(top: 40));
      expect(MediaQuery.paddingOf(context), const EdgeInsets.only(top: 40));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('keyboard only reduces search space below the visible rows', (
    tester,
  ) async {
    const padding = FakeViewPadding(top: 80, bottom: 144);
    final view = tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(2400, 1600)
      ..viewPadding = padding
      ..padding = padding;
    addTearDown(view.reset);

    var presses = 0;
    await tester.pumpWidget(
      _searchLayout(minimumBottom: 80, onSuggestion: () => presses++),
    );
    await tester.pumpAndSettle();

    final list = find.byKey(_listKey);
    final text = find.text(_firstSuggestion);
    final textRect = tester.getRect(text);
    final fieldRect = tester.getRect(find.byType(TextField));
    expect(tester.getRect(list).bottom, 720);

    for (final (width, keyboard) in [
      (2400.0, 620.0),
      (1800.0, 560.0),
      (2400.0, 620.0),
      (2400.0, 0.0),
    ]) {
      view
        ..physicalSize = Size(width, 1600)
        ..viewInsets = FakeViewPadding(bottom: keyboard)
        ..padding = keyboard == 0 ? padding : const FakeViewPadding(top: 80);
      await tester.pumpAndSettle();

      expect(
        tester.getRect(list).bottom,
        keyboard == 0 ? 720 : 800 - keyboard / 2,
      );
      final newText = tester.getRect(text);
      final newField = tester.getRect(find.byType(TextField));
      expect(newText.top, textRect.top);
      expect(newText.height, textRect.height);
      expect(newField.top, fieldRect.top);
      expect(newField.height, fieldRect.height);
      await tester.tapAt(Offset(newText.left + 16, newText.center.dy));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(presses, 4);
  });
}
