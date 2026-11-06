import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class CarSideNavigationDestination {
  const CarSideNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.navigationIndex,
  }) : onPressed = null;

  const CarSideNavigationDestination.action({
    required this.label,
    required this.icon,
    required VoidCallback this.onPressed,
  }) : selectedIcon = icon,
       navigationIndex = null;

  final int? navigationIndex;
  final VoidCallback? onPressed;

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

/// Keep each car destination's label, indicator and tap target in one button.
///
/// The header and destinations share one explicitly unpadded scroll viewport;
/// there is no separately flexed NavigationDrawer ListView retaining its own
/// scroll/padding state after a host-window resize. Center the buttons in the
/// safe viewport as a group. If the header would overlap them, place them right
/// after it and scroll only when the combined content doesn't fit.
class CarSideNavigation extends StatelessWidget {
  const CarSideNavigation({
    super.key,
    required this.header,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.extended,
  });

  final Widget header;
  final List<CarSideNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;

  static const double _tileVerticalPadding = 5;
  double get _buttonHeight => extended ? 56 : 64;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return SizedBox(
      width: (extended ? 130 : 80) + MediaQuery.viewPaddingOf(context).left,
      child: SafeArea(
        bottom: false,
        right: false,
        child: CustomScrollView(
          primary: false,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: extended ? 25 : 0),
                child: header,
              ),
            ),
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final groupHeight =
                    destinations.length *
                    (_buttonHeight + 2 * _tileVerticalPadding);
                final centeredTop =
                    (constraints.viewportMainAxisExtent - groupHeight) / 2;
                return SliverPadding(
                  padding: EdgeInsets.only(
                    top: math.max(
                      0.0,
                      centeredTop - constraints.precedingScrollExtent,
                    ),
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < destinations.length;
                          index++
                        )
                          _destination(index, colorScheme),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _destination(int index, ColorScheme colors) {
    final destination = destinations[index];
    final selected = destination.navigationIndex == selectedIndex;
    final icon = selected ? destination.selectedIcon : destination.icon;
    final label = Text(
      destination.label,
      maxLines: extended ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: extended ? null : const TextStyle(fontSize: 12),
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _tileVerticalPadding,
        horizontal: extended ? 12 : 6,
      ),
      child: Semantics(
        selected: selected,
        child: SizedBox(
          height: _buttonHeight,
          child: TextButton(
            key: ValueKey('car-nav-destination-$index'),
            onPressed:
                destination.onPressed ??
                () => onDestinationSelected(destination.navigationIndex!),
            style: TextButton.styleFrom(
              foregroundColor: selected
                  ? colors.onSecondaryContainer
                  : colors.onSurfaceVariant,
              backgroundColor: selected
                  ? colors.secondaryContainer
                  : Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: extended ? 8 : 6),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: extended
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: 8),
                      Expanded(child: label),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      if (selected || destination.onPressed != null) label,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
