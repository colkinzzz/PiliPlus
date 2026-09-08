/// State of the window owned by the vehicle launcher.
///
/// This is intentionally separate from the player's in-app fullscreen state.
/// Unknown is the safe value: callers must not hide system bars for it.
class CarWindowState {
  bool get canUseImmersive => supported && hostWindowState == 'full';
  const CarWindowState({
    required this.supported,
    required this.isAutomotive,
    required this.isInMultiWindowMode,
    required this.hostWindowState,
    required this.width,
    required this.height,
    required this.maximumWidth,
    required this.maximumHeight,
    required this.widthRatio,
    required this.insetLeft,
    required this.insetTop,
    required this.insetRight,
    required this.insetBottom,
  });

  final bool supported;
  final bool isAutomotive;
  final bool isInMultiWindowMode;
  final String hostWindowState;
  final double width;
  final double height;
  final double maximumWidth;
  final double maximumHeight;
  final double widthRatio;
  final double insetLeft;
  final double insetTop;
  final double insetRight;
  final double insetBottom;

  factory CarWindowState.unsupported() => const CarWindowState(
    supported: false,
    isAutomotive: false,
    isInMultiWindowMode: false,
    hostWindowState: 'unknown',
    width: 0,
    height: 0,
    maximumWidth: 0,
    maximumHeight: 0,
    widthRatio: 0,
    insetLeft: 0,
    insetTop: 0,
    insetRight: 0,
    insetBottom: 0,
  );

  factory CarWindowState.fromMap(Map<Object?, Object?> map) {
    bool boolean(String key) => map[key] == true;
    double number(String key) {
      final value = map[key];
      if (value is! num || !value.isFinite || value < 0) return 0;
      return value.toDouble();
    }

    if (map['schemaVersion'] != null && map['schemaVersion'] != 1) {
      return CarWindowState.unsupported();
    }

    final rawState = map['hostWindowState'];
    final hostWindowState = boolean('isInMultiWindowMode')
        ? 'split'
        : switch (rawState) {
            'split' => 'split',
            'full' => 'full',
            _ when boolean('isInMultiWindowMode') => 'split',
            _ => 'unknown',
          };
    return CarWindowState(
      supported: true,
      isAutomotive: boolean('isAutomotive'),
      isInMultiWindowMode: boolean('isInMultiWindowMode'),
      hostWindowState: hostWindowState,
      width: number('width'),
      height: number('height'),
      maximumWidth: number('maximumWidth'),
      maximumHeight: number('maximumHeight'),
      widthRatio: number('widthRatio'),
      insetLeft: number('insetLeft'),
      insetTop: number('insetTop'),
      insetRight: number('insetRight'),
      insetBottom: number('insetBottom'),
    );
  }
}
