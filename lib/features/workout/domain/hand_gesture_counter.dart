enum HandPose { unknown, open, closed }

enum HandSide { left, right, unknown }

enum HandRepPhase { waitingForOpen, waitingForClose, waitingForReopen }

class HandGestureObservation {
  const HandGestureObservation({
    required this.side,
    required this.pose,
    required this.confidence,
  });

  final HandSide side;
  final HandPose pose;
  final double confidence;
}

class HandGestureResult {
  const HandGestureResult({
    required this.repCount,
    required this.pose,
    required this.phase,
    this.activeSide,
  });

  final int repCount;
  final HandPose pose;
  final HandRepPhase phase;
  final HandSide? activeSide;
}

/// Counts one complete open-palm → closed-fist → open-palm cycle.
class HandGestureCounter {
  HandGestureCounter({this.requiredStableFrames = 3});

  final int requiredStableFrames;

  int _repCount = 0;
  HandRepPhase _phase = HandRepPhase.waitingForOpen;
  HandSide? _activeSide;
  HandPose _stablePose = HandPose.unknown;
  HandPose _candidatePose = HandPose.unknown;
  int _candidateFrames = 0;

  HandGestureResult update(List<HandGestureObservation> observations) {
    final observation = _selectObservation(observations);
    final observedPose = observation?.pose ?? HandPose.unknown;
    _stabilize(observedPose);

    if (_stablePose == HandPose.open) {
      if (_phase == HandRepPhase.waitingForOpen) {
        _activeSide = observation?.side;
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
      activeSide: _activeSide,
    );
  }

  void reset() {
    _repCount = 0;
    _phase = HandRepPhase.waitingForOpen;
    _activeSide = null;
    _stablePose = HandPose.unknown;
    _candidatePose = HandPose.unknown;
    _candidateFrames = 0;
  }

  HandGestureObservation? _selectObservation(
    List<HandGestureObservation> observations,
  ) {
    final supported =
        observations
            .where((item) => item.pose != HandPose.unknown)
            .where((item) => _activeSide == null || item.side == _activeSide)
            .toList()
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return supported.firstOrNull;
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
}
