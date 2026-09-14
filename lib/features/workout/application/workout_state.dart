import 'package:camera/camera.dart';

import '../domain/pose_frame.dart';

enum WorkoutCameraPhase { idle, initializing, streaming, suspended, error }

class WorkoutState {
  const WorkoutState({
    required this.phase,
    this.cameraController,
    this.poseFrame,
    this.errorMessage,
    this.droppedFrameCount = 0,
  });

  const WorkoutState.idle() : this(phase: WorkoutCameraPhase.idle);

  final WorkoutCameraPhase phase;
  final CameraController? cameraController;
  final PoseFrame? poseFrame;
  final String? errorMessage;
  final int droppedFrameCount;

  bool get isStreaming => phase == WorkoutCameraPhase.streaming;

  WorkoutState copyWith({
    WorkoutCameraPhase? phase,
    CameraController? cameraController,
    PoseFrame? poseFrame,
    bool clearPoseFrame = false,
    String? errorMessage,
    bool clearError = false,
    int? droppedFrameCount,
  }) {
    return WorkoutState(
      phase: phase ?? this.phase,
      cameraController: cameraController ?? this.cameraController,
      poseFrame: clearPoseFrame ? null : poseFrame ?? this.poseFrame,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      droppedFrameCount: droppedFrameCount ?? this.droppedFrameCount,
    );
  }
}
