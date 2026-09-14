import '../domain/pose_frame.dart';
import 'camera_frame.dart';

abstract interface class PoseDetectionService {
  Future<void> initialize();
  Future<PoseFrame?> process(CameraFrame frame);
  Future<void> close();
}
