import 'package:PiliPlus/common/widgets/car_side_navigation.dart';
import 'package:PiliPlus/common/widgets/car_viewport.dart';
import 'package:PiliPlus/common/widgets/main_layout.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _labels = ['首页', '动态', '我的'];

Widget fixture({
  required Size window,
  required ValueNotifier<int> selected,
  required List<int> pressed,
  bool extended = true,
  double scale = 1,
  double topPadding = 40,
  double bottomPadding = 64,
  double minimumTop = 0,
  double headerHeight = 144,
  List<int> order = const [0, 1, 2],
  VoidCallback? onHistory,
  VoidCallback? onSearch,
}) {
  final size = window / scale;
  final data = MediaQueryData(
    size: size,
    padding: EdgeInsets.only(
      top: topPadding / scale,
      bottom: bottomPadding / scale,
    ),
    viewPadding: EdgeInsets.only(
      top: topPadding / scale,
      bottom: bottomPadding / scale,
    ),
  );
  final sideBar = ValueListenableBuilder<int>(
    valueListenable: selected,
    builder: (context, index, _) => CarSideNavigation(
      extended: extended,
      selectedIndex: index,
      onDestinationSelected: (index) {
        pressed.add(order[index]);
        selected.value = index;
      },
      header: SizedBox(
        height: headerHeight,
        child: Column(
          children: [
            const SizedBox(height: 48),
            IconButton(
              key: const ValueKey('search'),
              onPressed: onSearch ?? () {},
              icon: const Icon(Icons.search),
            ),
          ],
        ),
      ),
      destinations: [
        for (var index = 0; index < order.length; index++) ...[
          if (order[index] == 2)
            CarSideNavigationDestination.action(
              label: '播放历史',
              icon: const Icon(Icons.history),
              onPressed: onHistory ?? () {},
            ),
          CarSideNavigationDestination(
            navigationIndex: index,
            label: _labels[order[index]],
            icon: const Icon(Icons.circle_outlined),
            selectedIcon: const Icon(Icons.circle),
          ),
        ],
        if (!order.contains(2))
          CarSideNavigationDestination.action(
            label: '播放历史',
            icon: const Icon(Icons.history),
            onPressed: onHistory ?? () {},
          ),
      ],
    ),
  );
  return MaterialApp(
    home: SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: MediaQuery(
            data: data,
            child: CarViewport(
              minimumTop: minimumTop / scale,
              minimumBottom: 0,
              child: Material(
                child: MainLayout(
                  sideBar: sideBar,
                  bottomNav: null,
                  body: const SizedBox.expand(key: ValueKey('main-body')),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> tapDestination(
  WidgetTester tester,
  int index,
  List<int> pressed, {
  int? expected,
}) async {
  final finder = find.byKey(ValueKey('car-nav-destination-$index'));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final rect = tester.getRect(finder);
  // Exercise the icon/label center and the upper/lower parts of the same tile,
  // not an artificially compensated point below the displayed button.
  for (final fraction in [-0.25, 0.0, 0.25]) {
    final count = pressed.length;
    await tester.tapAt(rect.center + Offset(0, rect.height * fraction));
    await tester.pumpAndSettle();
    expect(pressed.length, count + 1);
    expect(pressed.last, expected ?? index);
  }
}

void main() {
  for (final extended in [true, false]) {
    for (final scale in [1.0, 1.25]) {
      testWidgets('tile bounds match taps: extended=$extended scale=$scale', (
        tester,
      ) async {
        final selected = ValueNotifier(0);
        addTearDown(selected.dispose);
        final pressed = <int>[];
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        for (final window in [
          const Size(1920, 900),
          const Size(1100, 900),
          const Size(960, 540),
          const Size(650, 360),
        ]) {
          tester.view.physicalSize = window * 2;
          await tester.pumpWidget(
            fixture(
              window: window,
              selected: selected,
              pressed: pressed,
              extended: extended,
              scale: scale,
              minimumTop: 56,
            ),
          );
          await tester.pumpAndSettle();
          for (var index = 0; index < 3; index++) {
            await tapDestination(
              tester,
              index == 2 ? 3 : index,
              pressed,
              expected: index,
            );
          }
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  testWidgets(
    'repeated split/full resizes and inset changes keep taps aligned',
    (tester) async {
      final selected = ValueNotifier(0);
      addTearDown(selected.dispose);
      final pressed = <int>[];
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (var cycle = 0; cycle < 20; cycle++) {
        final window = Size(cycle.isEven ? 1280 : 800, 720);
        tester.view.physicalSize = window;
        await tester.pumpWidget(
          fixture(
            window: window,
            selected: selected,
            pressed: pressed,
            topPadding: cycle.isEven ? 40 : 56,
            bottomPadding: cycle.isEven ? 64 : 80,
          ),
        );
        await tester.pumpAndSettle();
        final index = cycle % 3;
        await tapDestination(
          tester,
          index == 2 ? 3 : index,
          pressed,
          expected: index,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('custom destination order and header actions are preserved', (
    tester,
  ) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    final pressed = <int>[];
    var history = 0;
    var search = 0;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1100, 900);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      fixture(
        window: const Size(1100, 900),
        selected: selected,
        pressed: pressed,
        order: const [2, 0],
        onHistory: () => history++,
        onSearch: () => search++,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('car-nav-destination-0')));
    await tester.tap(find.byKey(const ValueKey('search')));
    await tester.pumpAndSettle();
    expect(history, 1);
    expect(search, 1);
    await tapDestination(tester, 1, pressed, expected: 2);
    await tapDestination(tester, 2, pressed, expected: 0);
    expect(selected.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('four buttons center on the whole safe viewport', (tester) async {
    final selected = ValueNotifier(2);
    addTearDown(selected.dispose);
    final pressed = <int>[];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final extended in [true, false]) {
      for (final scale in [1.0, 1.25]) {
        for (final headerHeight in [112.0, 176.0]) {
          for (final window in [
            const Size(1100, 1000),
            const Size(1600, 1200),
          ]) {
            tester.view.physicalSize = window;
            for (final bottomPadding in [0.0, 80.0]) {
              await tester.pumpWidget(
                fixture(
                  window: window,
                  selected: selected,
                  pressed: pressed,
                  extended: extended,
                  scale: scale,
                  headerHeight: headerHeight,
                  topPadding: 56,
                  bottomPadding: bottomPadding,
                  minimumTop: 72,
                ),
              );
              await tester.pumpAndSettle();
              final buttons = [
                for (var index = 0; index < 4; index++)
                  tester.getRect(
                    find.byKey(ValueKey('car-nav-destination-$index')),
                  ),
              ];
              // Status/HVAC insets and explicit top safety space are excluded,
              // while the avatar/search header is part of the centered viewport.
              final expectedCenter = (72 + window.height - bottomPadding) / 2;
              expect(
                tester.getRect(find.byKey(const ValueKey('main-body'))).bottom,
                closeTo(window.height - bottomPadding, 0.01),
              );
              expect(
                (buttons.first.top + buttons.last.bottom) / 2,
                closeTo(expectedCenter, 0.01),
                reason:
                    'extended=$extended scale=$scale header=$headerHeight window=$window',
              );
              for (var index = 1; index < 4; index++) {
                expect(
                  buttons[index].top,
                  greaterThan(buttons[index - 1].bottom),
                );
              }
              final search = tester.getRect(
                find.byKey(const ValueKey('search')),
              );
              expect(search.bottom, lessThanOrEqualTo(buttons.first.top));
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
    }
  });

  testWidgets('header and all buttons fit without excess scroll space', (
    tester,
  ) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 650);
    addTearDown(tester.view.reset);
    final pressed = <int>[];
    await tester.pumpWidget(
      fixture(
        window: const Size(1100, 650),
        selected: selected,
        pressed: pressed,
        headerHeight: 176,
      ),
    );
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.maxScrollExtent, 0);
    await tapDestination(tester, 3, pressed, expected: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history stays independent between dynamics and mine', (
    tester,
  ) async {
    final selected = ValueNotifier(1);
    addTearDown(selected.dispose);
    final pressed = <int>[];
    var history = 0;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1100, 900);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      fixture(
        window: const Size(1100, 900),
        selected: selected,
        pressed: pressed,
        onHistory: () => history++,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('播放历史'), findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(find.text('播放历史')).didExceedMaxLines,
      isFalse,
    );
    final historyButton = find.byKey(const ValueKey('car-nav-destination-2'));
    expect(
      find.descendant(of: historyButton, matching: find.text('播放历史')),
      findsOneWidget,
    );
    final rect = tester.getRect(historyButton);
    for (final fraction in [-0.25, 0.0, 0.25]) {
      await tester.tapAt(rect.center + Offset(0, rect.height * fraction));
      await tester.pumpAndSettle();
    }
    expect(history, 3);
    expect(selected.value, 1);
    expect(pressed, isEmpty);
    final dynamics = tester.getRect(
      find.byKey(const ValueKey('car-nav-destination-1')),
    );
    final mine = tester.getRect(
      find.byKey(const ValueKey('car-nav-destination-3')),
    );
    expect(rect.top, greaterThan(dynamics.bottom));
    expect(rect.bottom, lessThan(mine.top));
    await tapDestination(tester, 3, pressed, expected: 2);
    expect(selected.value, 2);
    expect(tester.takeException(), isNull);
  });
}
