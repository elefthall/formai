import 'dart:typed_data';

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
}
