import 'package:camera/camera.dart';

import '../domain/pose_frame.dart';
import '../domain/hand_gesture_counter.dart';

enum WorkoutCameraPhase { idle, initializing, streaming, suspended, error }

class WorkoutState {
  const WorkoutState({
    required this.phase,
    this.cameraController,
    this.poseFrame,
    this.errorMessage,
    this.droppedFrameCount = 0,
    this.handRepCount = 0,
    this.handPose = HandPose.unknown,
    this.handRepPhase = HandRepPhase.waitingForOpen,
    this.activeHandSide,
  });

  const WorkoutState.idle() : this(phase: WorkoutCameraPhase.idle);

  final WorkoutCameraPhase phase;
  final CameraController? cameraController;
  final PoseFrame? poseFrame;
  final String? errorMessage;
  final int droppedFrameCount;
  final int handRepCount;
  final HandPose handPose;
  final HandRepPhase handRepPhase;
  final HandSide? activeHandSide;

  bool get isStreaming => phase == WorkoutCameraPhase.streaming;

  WorkoutState copyWith({
    WorkoutCameraPhase? phase,
    CameraController? cameraController,
    PoseFrame? poseFrame,
    bool clearPoseFrame = false,
    String? errorMessage,
    bool clearError = false,
    int? droppedFrameCount,
    int? handRepCount,
    HandPose? handPose,
    HandRepPhase? handRepPhase,
    HandSide? activeHandSide,
    bool clearActiveHandSide = false,
  }) {
    return WorkoutState(
      phase: phase ?? this.phase,
      cameraController: cameraController ?? this.cameraController,
      poseFrame: clearPoseFrame ? null : poseFrame ?? this.poseFrame,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      droppedFrameCount: droppedFrameCount ?? this.droppedFrameCount,
      handRepCount: handRepCount ?? this.handRepCount,
      handPose: handPose ?? this.handPose,
      handRepPhase: handRepPhase ?? this.handRepPhase,
      activeHandSide: clearActiveHandSide
          ? null
          : activeHandSide ?? this.activeHandSide,
    );
  }
}
