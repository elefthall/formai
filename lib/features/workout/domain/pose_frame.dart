import 'joint_type.dart';
import 'pose_point.dart';

class PoseFrame {
  PoseFrame({
    required this.timestamp,
    required Map<JointType, PosePoint> joints,
  }) : joints = Map.unmodifiable(joints);

  final DateTime timestamp;
  final Map<JointType, PosePoint> joints;
}
