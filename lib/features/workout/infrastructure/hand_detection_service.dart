import 'package:hand_detection/hand_detection.dart' as hand_detection;

import '../domain/hand_gesture_counter.dart';
import 'camera_frame.dart';

abstract interface class HandDetectionService {
  Future<void> initialize();
  Future<List<HandGestureObservation>> process(CameraFrame frame);
  Future<void> close();
}

class LiteRtHandDetectionService implements HandDetectionService {
  hand_detection.HandDetector? _detector;

  @override
  Future<void> initialize() async {
    _detector ??= await hand_detection.HandDetector.create(
      maxDetections: 2,
      minLandmarkScore: 0.5,
      enableTracking: true,
      enableGestures: true,
      gestureMinConfidence: 0.65,
    );
  }

  @override
  Future<List<HandGestureObservation>> process(CameraFrame frame) async {
    final detector = _detector;
    final sourceImage = frame.sourceImage;
    if (detector == null) {
      throw StateError('Hand detector is not initialized.');
    }
    if (sourceImage == null) return const [];

    final rotation = hand_detection.rotationForFrame(
      width: frame.width,
      height: frame.height,
      sensorOrientation: frame.sensorOrientationDegrees,
      isFrontCamera: frame.isFrontCamera,
      deviceOrientation: frame.deviceOrientation,
    );
    final hands = await detector.detectFromCameraImage(
      sourceImage,
      rotation: rotation,
      maxDim: 640,
    );
    return hands.map(_mapGesture).whereType<HandGestureObservation>().toList();
  }

  HandGestureObservation? _mapGesture(hand_detection.Hand hand) {
    final gesture = hand.gesture;
    if (gesture == null) return null;
    final pose = switch (gesture.type) {
      hand_detection.GestureType.openPalm => HandPose.open,
      hand_detection.GestureType.closedFist => HandPose.closed,
      _ => HandPose.unknown,
    };
    final side = switch (hand.handedness) {
      hand_detection.Handedness.left => HandSide.left,
      hand_detection.Handedness.right => HandSide.right,
      null => HandSide.unknown,
    };
    return HandGestureObservation(
      side: side,
      pose: pose,
      confidence: gesture.confidence,
    );
  }

  @override
  Future<void> close() async {
    final detector = _detector;
    _detector = null;
    await detector?.dispose();
  }
}
