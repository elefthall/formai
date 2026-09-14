import 'dart:math' as math;

import 'joint_type.dart';
import 'pose_frame.dart';
import 'pose_point.dart';

enum HandPose { unknown, open, closed }

enum HandRepPhase { waitingForOpen, waitingForClose, waitingForReopen }

class HandGestureResult {
  const HandGestureResult({
    required this.repCount,
    required this.pose,
    required this.phase,
    this.opennessScore,
  });

  final int repCount;
  final HandPose pose;
  final HandRepPhase phase;
  final double? opennessScore;
}

/// Test-only deterministic counter based on ML Kit Pose hand endpoints.
///
/// ML Kit Pose is not a finger-joint model. This counter estimates an open hand
/// from wrist-to-thumb/index/pinky distances normalized by forearm length.
class HandGestureCounter {
  HandGestureCounter({
    this.minimumConfidence = 0.55,
    this.openThreshold = 0.38,
    this.closedThreshold = 0.24,
    this.requiredStableFrames = 3,
  });

  final double minimumConfidence;
  final double openThreshold;
  final double closedThreshold;
  final int requiredStableFrames;

  int _repCount = 0;
  HandRepPhase _phase = HandRepPhase.waitingForOpen;
  HandPose _stablePose = HandPose.unknown;
  HandPose _candidatePose = HandPose.unknown;
  int _candidateFrames = 0;

  HandGestureResult update(PoseFrame frame) {
    final score = _preferredHandScore(frame);
    final observedPose = _classify(score);
    _stabilize(observedPose);

    if (_stablePose == HandPose.open) {
      if (_phase == HandRepPhase.waitingForOpen) {
        _phase = HandRepPhase.waitingForClose;
      } else if (_phase == HandRepPhase.waitingForReopen) {
        _repCount++;
        _phase = HandRepPhase.waitingForClose;
      }
    } else if (_stablePose == HandPose.closed &&
        _phase == HandRepPhase.waitingForClose) {
      _phase = HandRepPhase.waitingForReopen;
    }

    return HandGestureResult(
      repCount: _repCount,
      pose: _stablePose,
      phase: _phase,
      opennessScore: score,
    );
  }

  void reset() {
    _repCount = 0;
    _phase = HandRepPhase.waitingForOpen;
    _stablePose = HandPose.unknown;
    _candidatePose = HandPose.unknown;
    _candidateFrames = 0;
  }

  void _stabilize(HandPose pose) {
    if (pose == HandPose.unknown) return;
    if (pose != _candidatePose) {
      _candidatePose = pose;
      _candidateFrames = 1;
      return;
    }
    _candidateFrames++;
    if (_candidateFrames >= requiredStableFrames) _stablePose = pose;
  }

  HandPose _classify(double? score) {
    if (score == null) return HandPose.unknown;
    if (score >= openThreshold) return HandPose.open;
    if (score <= closedThreshold) return HandPose.closed;
    return HandPose.unknown;
  }

  double? _preferredHandScore(PoseFrame frame) {
    return _handScore(
          frame,
          elbow: JointType.rightElbow,
          wrist: JointType.rightWrist,
          thumb: JointType.rightThumb,
          index: JointType.rightIndex,
          pinky: JointType.rightPinky,
        ) ??
        _handScore(
          frame,
          elbow: JointType.leftElbow,
          wrist: JointType.leftWrist,
          thumb: JointType.leftThumb,
          index: JointType.leftIndex,
          pinky: JointType.leftPinky,
        );
  }

  double? _handScore(
    PoseFrame frame, {
    required JointType elbow,
    required JointType wrist,
    required JointType thumb,
    required JointType index,
    required JointType pinky,
  }) {
    final points = [
      frame.joints[elbow],
      frame.joints[wrist],
      frame.joints[thumb],
      frame.joints[index],
      frame.joints[pinky],
    ];
    if (points.any((point) => !_isValid(point))) return null;

    final elbowPoint = points[0]!;
    final wristPoint = points[1]!;
    final forearmLength = _distance(elbowPoint, wristPoint);
    if (forearmLength < 0.02) return null;

    final fingertipDistance =
        (_distance(wristPoint, points[2]!) +
            _distance(wristPoint, points[3]!) +
            _distance(wristPoint, points[4]!)) /
        3;
    return fingertipDistance / forearmLength;
  }

  bool _isValid(PosePoint? point) =>
      point != null && point.isFinite && point.confidence >= minimumConfidence;

  double _distance(PosePoint a, PosePoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}
