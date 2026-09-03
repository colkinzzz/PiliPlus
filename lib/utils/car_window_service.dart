import 'dart:io';

import 'package:flutter/services.dart';

/// State of the window owned by the vehicle launcher.
///
/// It is intentionally separate from the player's in-app fullscreen state.
/// Unknown is the safe value: callers must not hide system bars for it.
class CarWindowState {
  const CarWindowState({
    required this.supported,
    required this.isInMultiWindowMode,
    required this.hostWindowState,
    required this.widthRatio,
  });

  final bool supported;
  final bool isInMultiWindowMode;
  final String hostWindowState;
  final double widthRatio;

  factory CarWindowState.unsupported() => const CarWindowState(
    supported: false,
    isInMultiWindowMode: false,
    hostWindowState: 'unknown',
    widthRatio: 0,
  );

  factory CarWindowState.fromMap(Map<Object?, Object?> map) {
    final isInMultiWindowMode = map['isInMultiWindowMode'] == true;
    final rawState = map['hostWindowState'] as String?;
    final hostWindowState = switch (rawState) {
      'split' => 'split',
      'full' => 'full',
      _ when isInMultiWindowMode => 'split',
      _ => 'unknown',
    };
    return CarWindowState(
      supported: true,
      isInMultiWindowMode: isInMultiWindowMode,
      hostWindowState: hostWindowState,
      widthRatio: (map['widthRatio'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CarWindowService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.piliplus/car_window',
  );

  static Future<CarWindowState> getWindowState() async {
    if (!Platform.isAndroid) return CarWindowState.unsupported();
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getWindowState',
      );
      return result == null
          ? CarWindowState.unsupported()
          : CarWindowState.fromMap(result);
    } on PlatformException {
      return CarWindowState.unsupported();
    } on MissingPluginException {
      return CarWindowState.unsupported();
    }
  }
}
