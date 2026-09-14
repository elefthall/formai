import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_ai/features/workout/application/workout_controller.dart';
import 'package:form_ai/features/workout/application/workout_state.dart';
import 'package:form_ai/features/workout/domain/pose_frame.dart';
import 'package:form_ai/features/workout/domain/hand_gesture_counter.dart';
import 'package:form_ai/features/workout/infrastructure/camera_frame.dart';
import 'package:form_ai/features/workout/infrastructure/camera_service.dart';
import 'package:form_ai/features/workout/infrastructure/hand_detection_service.dart';
import 'package:form_ai/features/workout/infrastructure/pose_detection_service.dart';

void main() {
  test('drops a frame while pose inference is already running', () async {
    final camera = _FakeCameraService();
    final pose = _FakePoseDetectionService();
    final container = ProviderContainer(
      overrides: [
        cameraServiceProvider.overrideWithValue(camera),
        poseDetectionServiceProvider.overrideWithValue(pose),
        handDetectionServiceProvider.overrideWithValue(
          _FakeHandDetectionService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.start();
    expect(
      container.read(workoutControllerProvider).phase,
      WorkoutCameraPhase.streaming,
    );

    final timestamp = DateTime(2026);
    camera.emit(_frame(timestamp));
    camera.emit(_frame(timestamp.add(const Duration(milliseconds: 100))));

    expect(container.read(workoutControllerProvider).droppedFrameCount, 1);

    pose.complete();
    await Future<void>.delayed(Duration.zero);
    expect(pose.processCallCount, 1);
  });

  test('suspend releases camera stream, camera, and pose detector', () async {
    final camera = _FakeCameraService();
    final pose = _FakePoseDetectionService()..complete();
    final container = ProviderContainer(
      overrides: [
        cameraServiceProvider.overrideWithValue(camera),
        poseDetectionServiceProvider.overrideWithValue(pose),
        handDetectionServiceProvider.overrideWithValue(
          _FakeHandDetectionService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.start();
    await controller.suspend();

    expect(camera.stopCallCount, 1);
    expect(camera.disposeCallCount, 1);
    expect(pose.closeCallCount, 1);
    expect(
      container.read(workoutControllerProvider).phase,
      WorkoutCameraPhase.suspended,
    );
  });

  test('resumes after an in-flight lifecycle suspension completes', () async {
    final camera = _FakeCameraService();
    final pose = _FakePoseDetectionService()..complete();
    final container = ProviderContainer(
      overrides: [
        cameraServiceProvider.overrideWithValue(camera),
        poseDetectionServiceProvider.overrideWithValue(pose),
        handDetectionServiceProvider.overrideWithValue(
          _FakeHandDetectionService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.start();

    camera.pauseDispose();
    final suspension = controller.suspend();
    await Future<void>.delayed(Duration.zero);
    final resumption = controller.resume();

    camera.completeDispose();
    await Future.wait([suspension, resumption]);

    expect(camera.initializeCallCount, 2);
    expect(
      container.read(workoutControllerProvider).phase,
      WorkoutCameraPhase.streaming,
    );
  });
}

CameraFrame _frame(DateTime timestamp) {
  return CameraFrame(
    bytes: Uint8List(4),
    width: 2,
    height: 2,
    bytesPerRow: 2,
    formatRaw: 17,
    sensorOrientationDegrees: 90,
    deviceOrientationDegrees: 0,
    isFrontCamera: false,
    isIos: false,
    timestamp: timestamp,
  );
}

class _FakeCameraService implements CameraService {
  _FakeCameraService()
    : _controller = CameraController(
        const CameraDescription(
          name: 'fake',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        ResolutionPreset.low,
      );

  final CameraController _controller;
  CameraFrameCallback? _onFrame;
  int stopCallCount = 0;
  int disposeCallCount = 0;
  int initializeCallCount = 0;
  Completer<void>? _disposeCompleter;

  @override
  CameraController get controller => _controller;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
  }

  @override
  Future<void> startImageStream(CameraFrameCallback onFrame) async {
    _onFrame = onFrame;
  }

  void emit(CameraFrame frame) => _onFrame?.call(frame);

  void pauseDispose() {
    _disposeCompleter = Completer<void>();
  }

  void completeDispose() {
    _disposeCompleter?.complete();
    _disposeCompleter = null;
  }

  @override
  Future<void> stopImageStream() async {
    stopCallCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCallCount++;
    await _disposeCompleter?.future;
  }
}

class _FakePoseDetectionService implements PoseDetectionService {
  Completer<PoseFrame?> _completer = Completer<PoseFrame?>();
  int processCallCount = 0;
  int closeCallCount = 0;

  void complete() {
    if (!_completer.isCompleted) _completer.complete(null);
  }

  @override
  Future<void> initialize() async {
    if (_completer.isCompleted) {
      _completer = Completer<PoseFrame?>()..complete(null);
    }
  }

  @override
  Future<PoseFrame?> process(CameraFrame frame) {
    processCallCount++;
    return _completer.future;
  }

  @override
  Future<void> close() async {
    closeCallCount++;
  }
}

class _FakeHandDetectionService implements HandDetectionService {
  @override
  Future<void> initialize() async {}

  @override
  Future<List<HandGestureObservation>> process(CameraFrame frame) async => [];

  @override
  Future<void> close() async {}
}
