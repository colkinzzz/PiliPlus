import 'dart:io';

import 'package:flutter/services.dart';

class CarWindowState {
  const CarWindowState({
    required this.supported,
    required this.isHostFullScreen,
    required this.widthRatio,
  });

  final bool supported;
  final bool isHostFullScreen;
  final double widthRatio;

  factory CarWindowState.unsupported() => const CarWindowState(
    supported: false,
    isHostFullScreen: false,
    widthRatio: 0,
  );

  factory CarWindowState.fromMap(Map<Object?, Object?> map) {
    return CarWindowState(
      supported: true,
      isHostFullScreen: map['isHostFullScreen'] == true,
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
