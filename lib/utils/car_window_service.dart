import 'dart:io';

import 'package:PiliPlus/utils/car_window_state.dart';
import 'package:flutter/services.dart';

export 'package:PiliPlus/utils/car_window_state.dart';

class CarWindowService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.piliplus/car_window',
  );

  static Future<void> configureViewport() async {
    try {
      await _channel.invokeMethod<void>('configureViewport');
    } on PlatformException {
      // Keep the normal Android viewport on devices that reject the override.
    } on MissingPluginException {
      // The older Android embedder can still use Flutter's inset handling.
    }
  }

  static Future<CarWindowState> getWindowState() async {
    if (!Platform.isAndroid) {
      return CarWindowState.unsupported();
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getWindowState',
      );
      if (result == null) {
        return CarWindowState.unsupported();
      }
      return CarWindowState.fromMap(result);
    } on PlatformException {
      return CarWindowState.unsupported();
    } on MissingPluginException {
      return CarWindowState.unsupported();
    }
  }
}
