import 'package:flutter/material.dart';

import '../../domain/joint_type.dart';
import '../../domain/pose_frame.dart';
import '../../domain/pose_point.dart';

class PosePainter extends CustomPainter {
  PosePainter({required this.poseFrame});

  static const minimumConfidence = 0.5;

  static const connections = <(JointType, JointType)>[
    (JointType.leftShoulder, JointType.rightShoulder),
    (JointType.leftShoulder, JointType.leftElbow),
    (JointType.leftElbow, JointType.leftWrist),
    (JointType.rightShoulder, JointType.rightElbow),
    (JointType.rightElbow, JointType.rightWrist),
    (JointType.leftShoulder, JointType.leftHip),
    (JointType.rightShoulder, JointType.rightHip),
    (JointType.leftHip, JointType.rightHip),
    (JointType.leftHip, JointType.leftKnee),
    (JointType.leftKnee, JointType.leftAnkle),
    (JointType.rightHip, JointType.rightKnee),
    (JointType.rightKnee, JointType.rightAnkle),
  ];

  final PoseFrame poseFrame;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFFF2D2D)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = Colors.white;

    for (final connection in connections) {
      final start = poseFrame.joints[connection.$1];
      final end = poseFrame.joints[connection.$2];
      if (!_isVisible(start) || !_isVisible(end)) continue;
      canvas.drawLine(_offset(start!, size), _offset(end!, size), linePaint);
    }

    for (final point in poseFrame.joints.values) {
      if (!_isVisible(point)) continue;
      canvas.drawCircle(_offset(point, size), 4, pointPaint);
    }
  }

  bool _isVisible(PosePoint? point) {
    return point != null &&
        point.isFinite &&
        point.confidence >= minimumConfidence;
  }

  Offset _offset(PosePoint point, Size size) {
    return Offset(point.x * size.width, point.y * size.height);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poseFrame != poseFrame;
  }
}
