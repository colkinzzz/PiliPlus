import 'dart:io';

import 'package:flutter/services.dart';

export 'car_window_state.dart';
import 'car_window_state.dart';

class CarWindowService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.piliplus/car_window',
  );

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
