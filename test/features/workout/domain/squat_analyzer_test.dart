import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:form_ai/features/workout/domain/joint_type.dart';
import 'package:form_ai/features/workout/domain/pose_frame.dart';
import 'package:form_ai/features/workout/domain/pose_point.dart';
import 'package:form_ai/features/workout/domain/squat_analyzer.dart';

void main() {
  test('returns feedback as soon as the first valid rep completes', () {
    final analyzer = SquatAnalyzer();
    final angles = <double>[
      ...List.filled(4, 170),
      ...List.filled(8, 140),
      ...List.filled(12, 95),
      ...List.filled(8, 125),
      ...List.filled(12, 170),
    ];
    SquatAnalysis? result;
    String? feedback;

    for (var i = 0; i < angles.length; i++) {
      result = analyzer.update(_frameForAngle(angles[i], i * 100), i * 100);
      feedback ??= result.feedback;
    }

    expect(result!.repCount, 1);
    expect(feedback, startsWith('첫 1회 완료!'));
    expect(result.poseValid, isTrue);
    expect(result.selectedSide, SquatSide.left);
  });

  test('invalidates tracking after landmarks are missing for 500ms', () {
    final analyzer = SquatAnalyzer();
    analyzer.update(_frameForAngle(170, 0), 0);

    final result = analyzer.update(null, 500);

    expect(result.poseValid, isFalse);
    expect(result.selectedSide, isNull);
  });
}

PoseFrame _frameForAngle(double angleDeg, int timestampMs) {
  const knee = PosePoint(x: 0.5, y: 0.5, z: 0, confidence: 0.9);
  const hip = PosePoint(x: 0.5, y: 0.3, z: 0, confidence: 0.9);
  final radians = angleDeg * math.pi / 180;
  final ankle = PosePoint(
    x: 0.5 + math.sin(radians) * 0.2,
    y: 0.5 - math.cos(radians) * 0.2,
    z: 0,
    confidence: 0.9,
  );
  return PoseFrame(
    timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    joints: {
      JointType.leftHip: hip,
      JointType.leftKnee: knee,
      JointType.leftAnkle: ankle,
    },
  );
}
