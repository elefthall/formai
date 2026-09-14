class EmaFilter {
  EmaFilter({required this.alpha})
    : assert(alpha > 0 && alpha <= 1, 'alpha must be in (0, 1].');

  final double alpha;
  double? _value;

  double update(double current) {
    final previous = _value;
    final next = previous == null
        ? current
        : alpha * current + (1 - alpha) * previous;
    _value = next;
    return next;
  }

  void reset() => _value = null;
}
