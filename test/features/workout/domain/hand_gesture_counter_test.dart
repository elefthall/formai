import 'package:flutter_test/flutter_test.dart';
import 'package:form_ai/features/workout/domain/hand_gesture_counter.dart';
import 'package:form_ai/features/workout/domain/joint_type.dart';
import 'package:form_ai/features/workout/domain/pose_frame.dart';
import 'package:form_ai/features/workout/domain/pose_point.dart';

void main() {
  test('counts one complete open closed open cycle', () {
    final counter = HandGestureCounter();

    _repeat(counter, score: 0.5, frames: 3);
    _repeat(counter, score: 0.18, frames: 3);
    final result = _repeat(counter, score: 0.5, frames: 3);

    expect(result.repCount, 1);
    expect(result.pose, HandPose.open);
    expect(result.phase, HandRepPhase.waitingForClose);
  });

  test('does not count an incomplete gesture', () {
    final counter = HandGestureCounter();

    _repeat(counter, score: 0.5, frames: 3);
    final result = _repeat(counter, score: 0.18, frames: 3);

    expect(result.repCount, 0);
    expect(result.phase, HandRepPhase.waitingForReopen);
  });

  test('ignores the hysteresis range and low-confidence landmarks', () {
    final counter = HandGestureCounter();

    final ambiguous = _repeat(counter, score: 0.3, frames: 5);
    final lowConfidence = counter.update(_frame(0.5, confidence: 0.3));

    expect(ambiguous.pose, HandPose.unknown);
    expect(lowConfidence.pose, HandPose.unknown);
    expect(lowConfidence.repCount, 0);
  });
}

HandGestureResult _repeat(
  HandGestureCounter counter, {
  required double score,
  required int frames,
}) {
  var result = counter.update(_frame(score));
  for (var index = 1; index < frames; index++) {
    result = counter.update(_frame(score));
  }
  return result;
}

PoseFrame _frame(double score, {double confidence = 0.9}) {
  const elbowX = 0.2;
  const wristX = 0.4;
  final fingertipX = wristX + (0.2 * score);
  PosePoint point(double x) =>
      PosePoint(x: x, y: 0.5, z: 0, confidence: confidence);

  return PoseFrame(
    timestamp: DateTime(2026),
    joints: {
      JointType.rightElbow: point(elbowX),
      JointType.rightWrist: point(wristX),
      JointType.rightThumb: point(fingertipX),
      JointType.rightIndex: point(fingertipX),
      JointType.rightPinky: point(fingertipX),
    },
  );
}
