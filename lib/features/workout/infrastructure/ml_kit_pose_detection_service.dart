import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../application/coordinate_transform.dart';
import '../domain/joint_type.dart';
import '../domain/pose_frame.dart';
import '../domain/pose_point.dart';
import 'camera_frame.dart';
import 'pose_detection_service.dart';

class MlKitPoseDetectionService implements PoseDetectionService {
  PoseDetector? _detector;

  @override
  Future<void> initialize() async {
    _detector ??= PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.base,
        mode: PoseDetectionMode.stream,
      ),
    );
  }

  @override
  Future<PoseFrame?> process(CameraFrame frame) async {
    final detector = _detector;
    if (detector == null) {
      throw StateError('Pose detector is not initialized.');
    }

    final rotation = _rotationFor(frame);
    final format = InputImageFormatValue.fromRawValue(frame.formatRaw);
    if (rotation == null || format == null) return null;
    if (!frame.isIos && format != InputImageFormat.nv21) return null;
    if (frame.isIos && format != InputImageFormat.bgra8888) return null;

    final inputImage = InputImage.fromBytes(
      bytes: frame.bytes,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: frame.bytesPerRow,
      ),
    );

    final poses = await detector.processImage(inputImage);
    final pose = poses.firstOrNull;
    if (pose == null) return null;

    final joints = <JointType, PosePoint>{};
    for (final entry in pose.landmarks.entries) {
      final joint = _jointType(entry.key);
      final landmark = entry.value;
      joints[joint] = normalizePosePoint(
        x: landmark.x,
        y: landmark.y,
        z: landmark.z,
        confidence: landmark.likelihood,
        imageWidth: frame.width.toDouble(),
        imageHeight: frame.height.toDouble(),
        rotationDegrees: rotation.rawValue,
        isFrontCamera: frame.isFrontCamera,
        isIos: frame.isIos,
      );
    }

    return PoseFrame(timestamp: frame.timestamp, joints: joints);
  }

  @override
  Future<void> close() async {
    final detector = _detector;
    _detector = null;
    await detector?.close();
  }

  InputImageRotation? _rotationFor(CameraFrame frame) {
    if (frame.isIos) {
      return InputImageRotationValue.fromRawValue(
        frame.sensorOrientationDegrees,
      );
    }

    final rotationCompensation = frame.isFrontCamera
        ? (frame.sensorOrientationDegrees + frame.deviceOrientationDegrees) %
              360
        : (frame.sensorOrientationDegrees -
                  frame.deviceOrientationDegrees +
                  360) %
              360;
    return InputImageRotationValue.fromRawValue(rotationCompensation);
  }

  JointType _jointType(PoseLandmarkType type) {
    return JointType.values.byName(type.name);
  }
}
