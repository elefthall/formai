import 'package:flutter/services.dart';

class CameraFrame {
  const CameraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.formatRaw,
    required this.sensorOrientationDegrees,
    required this.deviceOrientationDegrees,
    required this.isFrontCamera,
    required this.isIos,
    required this.timestamp,
    this.sourceImage,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;
  final int formatRaw;
  final int sensorOrientationDegrees;
  final int deviceOrientationDegrees;
  final bool isFrontCamera;
  final bool isIos;
  final DateTime timestamp;
  final Object? sourceImage;

  DeviceOrientation get deviceOrientation => switch (deviceOrientationDegrees) {
    90 => DeviceOrientation.landscapeLeft,
    180 => DeviceOrientation.portraitDown,
    270 => DeviceOrientation.landscapeRight,
    _ => DeviceOrientation.portraitUp,
  };
}
