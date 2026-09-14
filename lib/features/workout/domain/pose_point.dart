class PosePoint {
  const PosePoint({
    required this.x,
    required this.y,
    required this.z,
    required this.confidence,
  });

  final double x;
  final double y;
  final double z;
  final double confidence;

  bool get isFinite =>
      x.isFinite && y.isFinite && z.isFinite && confidence.isFinite;
}
