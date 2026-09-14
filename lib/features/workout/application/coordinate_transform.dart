import '../domain/pose_point.dart';

PosePoint normalizePosePoint({
  required double x,
  required double y,
  required double z,
  required double confidence,
  required double imageWidth,
  required double imageHeight,
  required int rotationDegrees,
  required bool isFrontCamera,
  required bool isIos,
}) {
  if (imageWidth <= 0 || imageHeight <= 0) {
    throw ArgumentError('Image dimensions must be positive.');
  }

  final double normalizedX;
  final double normalizedY;

  switch (rotationDegrees) {
    case 90:
      normalizedX = x / (isIos ? imageWidth : imageHeight);
      normalizedY = y / (isIos ? imageHeight : imageWidth);
    case 270:
      normalizedX = 1 - x / (isIos ? imageWidth : imageHeight);
      normalizedY = y / (isIos ? imageHeight : imageWidth);
    case 0:
    case 180:
      final rawX = x / imageWidth;
      normalizedX = isFrontCamera ? 1 - rawX : rawX;
      normalizedY = y / imageHeight;
    default:
      throw ArgumentError.value(
        rotationDegrees,
        'rotationDegrees',
        'Must be 0, 90, 180, or 270.',
      );
  }

  return PosePoint(
    x: normalizedX,
    y: normalizedY,
    z: z / (imageWidth > imageHeight ? imageWidth : imageHeight),
    confidence: confidence,
  );
}
