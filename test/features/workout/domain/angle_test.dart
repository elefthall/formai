import 'package:flutter_test/flutter_test.dart';
import 'package:form_ai/features/workout/domain/angle.dart';
import 'package:form_ai/features/workout/domain/pose_point.dart';

void main() {
  const center = PosePoint(x: 0, y: 0, z: 0, confidence: 1);

  test('calculates a right angle', () {
    const a = PosePoint(x: 0, y: -1, z: 0, confidence: 1);
    const c = PosePoint(x: 1, y: 0, z: 0, confidence: 1);
    expect(calculateAngle(a, center, c), closeTo(90, 0.0001));
  });

  test('calculates a straight angle', () {
    const a = PosePoint(x: 0, y: -1, z: 0, confidence: 1);
    const c = PosePoint(x: 0, y: 1, z: 0, confidence: 1);
    expect(calculateAngle(a, center, c), closeTo(180, 0.0001));
  });

  test('returns null for a zero-length vector', () {
    const c = PosePoint(x: 1, y: 0, z: 0, confidence: 1);
    expect(calculateAngle(center, center, c), isNull);
  });
}
