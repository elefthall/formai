import 'package:flutter_test/flutter_test.dart';
import 'package:form_ai/features/workout/domain/hand_gesture_counter.dart';

void main() {
  for (final side in [HandSide.left, HandSide.right]) {
    test('counts a complete cycle with ${side.name} hand', () {
      final counter = HandGestureCounter();

      _repeat(counter, side: side, pose: HandPose.open);
      _repeat(counter, side: side, pose: HandPose.closed);
      final result = _repeat(counter, side: side, pose: HandPose.open);

      expect(result.repCount, 1);
      expect(result.activeSide, side);
      expect(result.phase, HandRepPhase.waitingForClose);
    });
  }

  test('does not count an incomplete gesture', () {
    final counter = HandGestureCounter();

    _repeat(counter, side: HandSide.left, pose: HandPose.open);
    final result = _repeat(counter, side: HandSide.left, pose: HandPose.closed);

    expect(result.repCount, 0);
    expect(result.phase, HandRepPhase.waitingForReopen);
  });

  test('continues when handedness classification flips during a cycle', () {
    final counter = HandGestureCounter();

    _repeat(counter, side: HandSide.left, pose: HandPose.open);
    _repeat(counter, side: HandSide.right, pose: HandPose.closed);
    final result = _repeat(counter, side: HandSide.right, pose: HandPose.open);

    expect(result.repCount, 1);
    expect(result.activeSide, HandSide.left);
  });

  test('reports completion and duration for the first cycle', () {
    final counter = HandGestureCounter(requiredStableFrames: 1);

    counter.update(const [
      HandGestureObservation(
        side: HandSide.left,
        pose: HandPose.open,
        confidence: 0.9,
      ),
    ], timestampMs: 1000);
    counter.update(const [
      HandGestureObservation(
        side: HandSide.left,
        pose: HandPose.closed,
        confidence: 0.9,
      ),
    ], timestampMs: 1600);
    final result = counter.update(const [
      HandGestureObservation(
        side: HandSide.left,
        pose: HandPose.open,
        confidence: 0.9,
      ),
    ], timestampMs: 2200);

    expect(result.repCount, 1);
    expect(result.completedRep, isTrue);
    expect(result.repDurationMs, 1200);
  });
}

HandGestureResult _repeat(
  HandGestureCounter counter, {
  required HandSide side,
  required HandPose pose,
}) {
  const frameCount = 3;
  late HandGestureResult result;
  for (var index = 0; index < frameCount; index++) {
    result = counter.update([
      HandGestureObservation(side: side, pose: pose, confidence: 0.9),
    ]);
  }
  return result;
}
