import 'dart:math' as math;

import 'pose_point.dart';

double? calculateAngle(PosePoint a, PosePoint b, PosePoint c) {
  final bax = a.x - b.x;
  final bay = a.y - b.y;
  final bcx = c.x - b.x;
  final bcy = c.y - b.y;
  final denominator =
      math.sqrt(bax * bax + bay * bay) * math.sqrt(bcx * bcx + bcy * bcy);
  if (!denominator.isFinite || denominator <= 1e-8) return null;
  final cosine = ((bax * bcx + bay * bcy) / denominator).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}
