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
/// scroll/padding state after a host-window resize. Equal space above and below
/// the destinations centers them in the entire safe viewport, including the
/// header's space. Short windows can scroll without overlapping the header.
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return SizedBox(
      width: (extended ? 130 : 80) + MediaQuery.viewPaddingOf(context).left,
      child: SafeArea(
        bottom: false,
        right: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            primary: false,
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: extended ? 25 : 0),
                          child: header,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
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
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: extended ? null : const TextStyle(fontSize: 12),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: extended ? 12 : 6),
      child: Semantics(
        selected: selected,
        child: SizedBox(
          height: extended ? 56 : 64,
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: extended
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
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
