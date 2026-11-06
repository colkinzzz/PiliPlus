import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Reserve the vehicle's system bars in the same logical pixels as the page.
/// Pages continue to handle the top status bar and any remaining keyboard inset.
class CarViewport extends StatelessWidget {
  const CarViewport({
    super.key,
    required this.minimumTop,
    required this.minimumBottom,
    required this.child,
  });

  final double minimumTop;
  final double minimumBottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final bottom = math.max(data.viewPadding.bottom, minimumBottom);
    final extraTop = math.max(0.0, minimumTop - data.viewPadding.top);

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: data.padding.copyWith(top: extraTop, bottom: bottom),
        child: MediaQuery(
          // The navigator is already inside these bounds. In particular, the
          // IME and the bottom bar share an edge, so their heights do not add.
          data: data.copyWith(
            padding: EdgeInsets.only(top: data.padding.top),
            viewPadding: EdgeInsets.only(top: data.viewPadding.top),
            viewInsets: data.viewInsets.copyWith(
              bottom: math.max(0.0, data.viewInsets.bottom - bottom),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
