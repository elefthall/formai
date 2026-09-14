import 'package:flutter_test/flutter_test.dart';
import 'package:form_ai/features/workout/application/coordinate_transform.dart';

void main() {
  group('normalizePosePoint', () {
    test('normalizes a back camera point without rotation', () {
      final point = normalizePosePoint(
        x: 160,
        y: 120,
        z: 32,
        confidence: 0.9,
        imageWidth: 640,
        imageHeight: 480,
        rotationDegrees: 0,
        isFrontCamera: false,
        isIos: false,
      );

      expect(point.x, closeTo(0.25, 1e-9));
      expect(point.y, closeTo(0.25, 1e-9));
      expect(point.z, closeTo(0.05, 1e-9));
      expect(point.confidence, 0.9);
    });

    test('mirrors a front camera point at zero rotation', () {
      final point = normalizePosePoint(
        x: 160,
        y: 120,
        z: 0,
        confidence: 1,
        imageWidth: 640,
        imageHeight: 480,
        rotationDegrees: 0,
        isFrontCamera: true,
        isIos: false,
      );

      expect(point.x, closeTo(0.75, 1e-9));
      expect(point.y, closeTo(0.25, 1e-9));
    });

    test('uses rotated Android dimensions for portrait input', () {
      final point = normalizePosePoint(
        x: 240,
        y: 320,
        z: 0,
        confidence: 1,
        imageWidth: 640,
        imageHeight: 480,
        rotationDegrees: 90,
        isFrontCamera: false,
        isIos: false,
      );

      expect(point.x, closeTo(0.5, 1e-9));
      expect(point.y, closeTo(0.5, 1e-9));
    });

    test('rejects unsupported rotation metadata', () {
      expect(
        () => normalizePosePoint(
          x: 0,
          y: 0,
          z: 0,
          confidence: 1,
          imageWidth: 640,
          imageHeight: 480,
          rotationDegrees: 45,
          isFrontCamera: false,
          isIos: false,
        ),
        throwsArgumentError,
      );
    });
  });
}
