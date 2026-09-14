import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/camera_frame.dart';
import '../domain/hand_gesture_counter.dart';
import '../infrastructure/camera_service.dart';
import '../infrastructure/hand_detection_service.dart';
import '../infrastructure/ml_kit_pose_detection_service.dart';
import '../infrastructure/pose_detection_service.dart';
import 'workout_state.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = FlutterCameraService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final poseDetectionServiceProvider = Provider<PoseDetectionService>((ref) {
  final service = MlKitPoseDetectionService();
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

final handDetectionServiceProvider = Provider<HandDetectionService>((ref) {
  final service = LiteRtHandDetectionService();
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

final workoutControllerProvider =
    NotifierProvider<WorkoutController, WorkoutState>(WorkoutController.new);

class WorkoutController extends Notifier<WorkoutState> {
  static const _minimumInferenceInterval = Duration(milliseconds: 66);

  bool _isProcessingFrame = false;
  bool _shouldResume = false;
  DateTime? _lastInferenceAt;
  Future<void> _pendingOperation = Future<void>.value();
  late CameraService _cameraService;
  late PoseDetectionService _poseService;
  late HandDetectionService _handService;
  final HandGestureCounter _handGestureCounter = HandGestureCounter();

  @override
  WorkoutState build() {
    _cameraService = ref.watch(cameraServiceProvider);
    _poseService = ref.watch(poseDetectionServiceProvider);
    _handService = ref.watch(handDetectionServiceProvider);
    ref.onDispose(() {
      unawaited(_releaseResources());
    });
    return const WorkoutState.idle();
  }

  Future<void> start() => _enqueue(_start);

  Future<void> _start() async {
    if (state.phase == WorkoutCameraPhase.initializing ||
        state.phase == WorkoutCameraPhase.streaming) {
      return;
    }

    _shouldResume = true;
    state = const WorkoutState(phase: WorkoutCameraPhase.initializing);

    try {
      await _cameraService.initialize();
      await _poseService.initialize();
      await _handService.initialize();
      if (!ref.mounted) {
        await _releaseResources();
        return;
      }
      final cameraController = _cameraService.controller;
      if (cameraController == null) {
        throw StateError('Camera preview controller is unavailable.');
      }

      state = WorkoutState(
        phase: WorkoutCameraPhase.streaming,
        cameraController: cameraController,
      );
      await _cameraService.startImageStream(_onCameraFrame);
    } on CameraException catch (error, stackTrace) {
      debugPrint('Camera initialization failed (${error.code}): $error');
      debugPrintStack(stackTrace: stackTrace);
      await _handleFailure(_cameraErrorMessage(error.code));
    } catch (error, stackTrace) {
      debugPrint('Camera/Pose initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _handleFailure('카메라 또는 자세 인식기를 시작하지 못했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> suspend() => _enqueue(_suspend);

  Future<void> _suspend() async {
    if (state.phase == WorkoutCameraPhase.idle ||
        state.phase == WorkoutCameraPhase.suspended) {
      return;
    }
    await _releaseResources();
    if (!ref.mounted) return;
    state = const WorkoutState(phase: WorkoutCameraPhase.suspended);
  }

  Future<void> resume() => _enqueue(_resume);

  Future<void> _resume() async {
    if (!_shouldResume || state.phase != WorkoutCameraPhase.suspended) return;
    await _start();
  }

  Future<void> stop() {
    _shouldResume = false;
    return _enqueue(_stop);
  }

  Future<void> _stop() async {
    await _releaseResources();
    if (!ref.mounted) return;
    state = const WorkoutState.idle();
  }

  void _onCameraFrame(CameraFrame frame) {
    if (!ref.mounted) return;
    final now = frame.timestamp;
    final lastInferenceAt = _lastInferenceAt;
    if (_isProcessingFrame ||
        (lastInferenceAt != null &&
            now.difference(lastInferenceAt) < _minimumInferenceInterval)) {
      state = state.copyWith(droppedFrameCount: state.droppedFrameCount + 1);
      return;
    }

    _lastInferenceAt = now;
    _isProcessingFrame = true;
    unawaited(_processFrame(frame));
  }

  Future<void> _processFrame(CameraFrame frame) async {
    try {
      final poseFrame = await _poseService.process(frame);
      final handObservations = await _handService.process(frame);
      final gesture = _handGestureCounter.update(handObservations);
      if (!ref.mounted) return;
      if (state.phase != WorkoutCameraPhase.streaming) return;
      if (poseFrame == null) {
        state = state.copyWith(
          clearPoseFrame: true,
          handRepCount: gesture.repCount,
          handPose: gesture.pose,
          handRepPhase: gesture.phase,
          activeHandSide: gesture.activeSide,
        );
      } else {
        state = state.copyWith(
          poseFrame: poseFrame,
          handRepCount: gesture.repCount,
          handPose: gesture.pose,
          handRepPhase: gesture.phase,
          activeHandSide: gesture.activeSide,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Vision frame processing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (ref.mounted && state.phase == WorkoutCameraPhase.streaming) {
        state = state.copyWith(
          clearPoseFrame: true,
          errorMessage: '자세 인식이 잠시 중단됐어요. 화면을 다시 맞춰주세요.',
        );
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _handleFailure(String message) async {
    await _releaseResources();
    if (!ref.mounted) return;
    state = WorkoutState(
      phase: WorkoutCameraPhase.error,
      errorMessage: message,
    );
  }

  void resetHandReps() {
    _handGestureCounter.reset();
    state = state.copyWith(
      handRepCount: 0,
      handPose: HandPose.unknown,
      handRepPhase: HandRepPhase.waitingForOpen,
      clearActiveHandSide: true,
    );
  }

  Future<void> _releaseResources() async {
    _isProcessingFrame = false;
    _lastInferenceAt = null;
    try {
      await _cameraService.stopImageStream();
    } catch (_) {
      // Continue releasing the remaining camera resources.
    }
    await _poseService.close();
    await _handService.close();
    await _cameraService.dispose();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _pendingOperation.then((_) => operation());
    _pendingOperation = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  String _cameraErrorMessage(String code) {
    return switch (code) {
      'CameraAccessDenied' => '카메라 권한이 거부됐어요. 권한을 허용한 뒤 다시 시도해주세요.',
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' => '설정에서 FormAI의 카메라 권한을 허용해주세요.',
      'NoCamera' => '사용 가능한 카메라를 찾지 못했어요.',
      _ => '카메라를 사용할 수 없어요. 다른 앱이 카메라를 사용 중인지 확인해주세요.',
    };
  }
}
