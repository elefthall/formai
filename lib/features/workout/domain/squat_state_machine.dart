enum SquatPhase { unknown, standing, descending, bottom, ascending }

class CompletedSquatRep {
  const CompletedSquatRep({
    required this.repNumber,
    required this.bottomKneeAngleDeg,
    required this.rangeOfMotionDeg,
    required this.durationMs,
  });

  final int repNumber;
  final double bottomKneeAngleDeg;
  final double rangeOfMotionDeg;
  final int durationMs;
}

class SquatTransition {
  const SquatTransition({
    required this.phase,
    required this.repCount,
    this.completedRep,
  });

  final SquatPhase phase;
  final int repCount;
  final CompletedSquatRep? completedRep;
}

class SquatStateMachine {
  SquatStateMachine({
    this.standingThresholdDeg = 155,
    this.bottomThresholdDeg = 105,
    this.minimumRangeOfMotionDeg = 45,
    this.cooldownMs = 400,
    this.directionDeadbandDeg = 3,
    this.thresholdDwellFrames = 2,
  });

  final double standingThresholdDeg;
  final double bottomThresholdDeg;
  final double minimumRangeOfMotionDeg;
  final int cooldownMs;
  final double directionDeadbandDeg;
  final int thresholdDwellFrames;

  SquatPhase _phase = SquatPhase.unknown;
  int _repCount = 0;
  double? _standingPeakDeg;
  double? _bottomMinimumDeg;
  int? _attemptStartedAtMs;
  int? _lastRepAtMs;
  int _bottomDwell = 0;
  int _standingDwell = 0;

  SquatPhase get phase => _phase;
  int get repCount => _repCount;

  SquatTransition update(double angleDeg, int timestampMs) {
    CompletedSquatRep? completedRep;
    switch (_phase) {
      case SquatPhase.unknown:
        if (angleDeg >= standingThresholdDeg) {
          _phase = SquatPhase.standing;
          _standingPeakDeg = angleDeg;
        }
      case SquatPhase.standing:
        if (angleDeg >= standingThresholdDeg) {
          _standingPeakDeg = _max(_standingPeakDeg, angleDeg);
        } else if ((_standingPeakDeg ?? angleDeg) - angleDeg >=
            directionDeadbandDeg) {
          _phase = SquatPhase.descending;
          _attemptStartedAtMs = timestampMs;
          _bottomMinimumDeg = angleDeg;
          _bottomDwell = 0;
        }
      case SquatPhase.descending:
        _bottomMinimumDeg = _min(_bottomMinimumDeg, angleDeg);
        if (angleDeg <= bottomThresholdDeg) {
          _bottomDwell++;
          if (_bottomDwell >= thresholdDwellFrames) {
            _phase = SquatPhase.bottom;
          }
        } else {
          _bottomDwell = 0;
          if (angleDeg >= standingThresholdDeg) {
            _resetAttemptToStanding(angleDeg);
          }
        }
      case SquatPhase.bottom:
        _bottomMinimumDeg = _min(_bottomMinimumDeg, angleDeg);
        if (angleDeg > (_bottomMinimumDeg ?? angleDeg) + directionDeadbandDeg) {
          _phase = SquatPhase.ascending;
          _standingDwell = 0;
        }
      case SquatPhase.ascending:
        _bottomMinimumDeg = _min(_bottomMinimumDeg, angleDeg);
        if (angleDeg <= bottomThresholdDeg) {
          _phase = SquatPhase.bottom;
          _standingDwell = 0;
        } else if (angleDeg >= standingThresholdDeg) {
          _standingDwell++;
          if (_standingDwell >= thresholdDwellFrames) {
            final peak = _standingPeakDeg ?? angleDeg;
            final bottom = _bottomMinimumDeg ?? angleDeg;
            final range = peak - bottom;
            final cooldownSatisfied =
                _lastRepAtMs == null ||
                timestampMs - _lastRepAtMs! >= cooldownMs;
            if (range >= minimumRangeOfMotionDeg && cooldownSatisfied) {
              _repCount++;
              _lastRepAtMs = timestampMs;
              completedRep = CompletedSquatRep(
                repNumber: _repCount,
                bottomKneeAngleDeg: bottom,
                rangeOfMotionDeg: range,
                durationMs: timestampMs - (_attemptStartedAtMs ?? timestampMs),
              );
            }
            _resetAttemptToStanding(angleDeg);
          }
        } else {
          _standingDwell = 0;
        }
    }
    return SquatTransition(
      phase: _phase,
      repCount: _repCount,
      completedRep: completedRep,
    );
  }

  void cancelAttempt() {
    _phase = SquatPhase.unknown;
    _standingPeakDeg = null;
    _bottomMinimumDeg = null;
    _attemptStartedAtMs = null;
    _bottomDwell = 0;
    _standingDwell = 0;
  }

  void reset() {
    cancelAttempt();
    _repCount = 0;
    _lastRepAtMs = null;
  }

  void _resetAttemptToStanding(double angleDeg) {
    _phase = SquatPhase.standing;
    _standingPeakDeg = angleDeg;
    _bottomMinimumDeg = null;
    _attemptStartedAtMs = null;
    _bottomDwell = 0;
    _standingDwell = 0;
  }

  double _min(double? current, double value) =>
      current == null || value < current ? value : current;
  double _max(double? current, double value) =>
      current == null || value > current ? value : current;
}
