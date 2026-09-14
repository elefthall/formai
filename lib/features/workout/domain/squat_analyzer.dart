import 'angle.dart';
import 'ema.dart';
import 'joint_type.dart';
import 'pose_frame.dart';
import 'pose_point.dart';
import 'squat_state_machine.dart';

enum SquatSide { left, right }

class SquatAnalysis {
  const SquatAnalysis({
    required this.phase,
    required this.repCount,
    required this.poseValid,
    this.selectedSide,
    this.kneeAngleDeg,
    this.completedRep,
    this.feedback,
  });

  final SquatPhase phase;
  final int repCount;
  final bool poseValid;
  final SquatSide? selectedSide;
  final double? kneeAngleDeg;
  final CompletedSquatRep? completedRep;
  final String? feedback;
}

class SquatAnalyzer {
  SquatAnalyzer({this.minimumConfidence = 0.5, this.trackingLossResetMs = 500});

  final double minimumConfidence;
  final int trackingLossResetMs;
  final EmaFilter _angleFilter = EmaFilter(alpha: 0.35);
  final SquatStateMachine _stateMachine = SquatStateMachine();

  SquatSide? _selectedSide;
  int? _lastValidAtMs;

  SquatAnalysis update(PoseFrame? frame, int timestampMs) {
    final left = frame == null ? null : _sideMeasurement(frame, SquatSide.left);
    final right = frame == null
        ? null
        : _sideMeasurement(frame, SquatSide.right);

    if (_stateMachine.phase == SquatPhase.unknown ||
        _stateMachine.phase == SquatPhase.standing) {
      _selectedSide = _selectBestSide(left, right);
    }
    final selected = switch (_selectedSide) {
      SquatSide.left => left,
      SquatSide.right => right,
      null => null,
    };

    if (selected == null) {
      final lastValidAtMs = _lastValidAtMs;
      if (lastValidAtMs == null ||
          timestampMs - lastValidAtMs >= trackingLossResetMs) {
        cancelAttempt();
      }
      return SquatAnalysis(
        phase: _stateMachine.phase,
        repCount: _stateMachine.repCount,
        poseValid: false,
        selectedSide: _selectedSide,
      );
    }

    _lastValidAtMs = timestampMs;
    final smoothedAngle = _angleFilter.update(selected.angleDeg);
    final transition = _stateMachine.update(smoothedAngle, timestampMs);
    final rep = transition.completedRep;
    return SquatAnalysis(
      phase: transition.phase,
      repCount: transition.repCount,
      poseValid: true,
      selectedSide: _selectedSide,
      kneeAngleDeg: smoothedAngle,
      completedRep: rep,
      feedback: rep == null ? null : _feedbackFor(rep),
    );
  }

  void cancelAttempt() {
    _stateMachine.cancelAttempt();
    _angleFilter.reset();
    _selectedSide = null;
    _lastValidAtMs = null;
  }

  void reset() {
    _stateMachine.reset();
    _angleFilter.reset();
    _selectedSide = null;
    _lastValidAtMs = null;
  }

  _SideMeasurement? _sideMeasurement(PoseFrame frame, SquatSide side) {
    final hip =
        frame.joints[side == SquatSide.left
            ? JointType.leftHip
            : JointType.rightHip];
    final knee =
        frame.joints[side == SquatSide.left
            ? JointType.leftKnee
            : JointType.rightKnee];
    final ankle =
        frame.joints[side == SquatSide.left
            ? JointType.leftAnkle
            : JointType.rightAnkle];
    if (!_valid(hip) || !_valid(knee) || !_valid(ankle)) return null;
    final angle = calculateAngle(hip!, knee!, ankle!);
    if (angle == null) return null;
    return _SideMeasurement(
      angleDeg: angle,
      confidence: [
        hip.confidence,
        knee.confidence,
        ankle.confidence,
      ].reduce((a, b) => a < b ? a : b),
    );
  }

  SquatSide? _selectBestSide(_SideMeasurement? left, _SideMeasurement? right) {
    if (left == null) return right == null ? null : SquatSide.right;
    if (right == null) return SquatSide.left;
    return left.confidence >= right.confidence
        ? SquatSide.left
        : SquatSide.right;
  }

  bool _valid(PosePoint? point) =>
      point != null &&
      point.isFinite &&
      point.confidence >= minimumConfidence &&
      point.x >= 0 &&
      point.x <= 1 &&
      point.y >= 0 &&
      point.y <= 1;

  String _feedbackFor(CompletedSquatRep rep) {
    final depth = rep.bottomKneeAngleDeg >= 80
        ? '깊이가 목표 범위에 들어왔어요.'
        : '측정된 깊이가 목표보다 깊었어요.';
    final tempo = switch (rep.durationMs) {
      < 1200 => '동작이 빠른 편이니 다음 반복은 조금 천천히 해보세요.',
      > 5000 => '동작이 느린 편이니 편안하고 일정한 속도를 유지해보세요.',
      _ => '동작 속도가 안정적이에요.',
    };
    return '${rep.repNumber == 1 ? '첫 1회 완료! ' : ''}$depth $tempo';
  }
}

class _SideMeasurement {
  const _SideMeasurement({required this.angleDeg, required this.confidence});

  final double angleDeg;
  final double confidence;
}
