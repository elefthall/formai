import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import 'camera_frame.dart';

typedef CameraFrameCallback = void Function(CameraFrame frame);

abstract interface class CameraService {
  CameraController? get controller;

  Future<void> initialize();
  Future<void> startImageStream(CameraFrameCallback onFrame);
  Future<void> stopImageStream();
  Future<void> dispose();
}

class FlutterCameraService implements CameraService {
  CameraController? _controller;
  CameraDescription? _camera;

  @override
  CameraController? get controller => _controller;

  @override
  Future<void> initialize() async {
    await dispose();
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('NoCamera', '사용 가능한 카메라가 없습니다.');
    }

    _camera = cameras.cast<CameraDescription?>().firstWhere(
      (camera) => camera?.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      _camera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    await controller.initialize();
  }

  @override
  Future<void> startImageStream(CameraFrameCallback onFrame) async {
    final controller = _controller;
    final camera = _camera;
    if (controller == null ||
        camera == null ||
        !controller.value.isInitialized) {
      throw StateError('Camera must be initialized before streaming.');
    }
    if (controller.value.isStreamingImages) return;

    await controller.startImageStream((image) {
      if (image.planes.length != 1) return;
      final plane = image.planes.first;
      onFrame(
        CameraFrame(
          bytes: plane.bytes,
          width: image.width,
          height: image.height,
          bytesPerRow: plane.bytesPerRow,
          formatRaw: image.format.raw,
          sensorOrientationDegrees: camera.sensorOrientation,
          deviceOrientationDegrees: _orientationDegrees(
            controller.value.deviceOrientation,
          ),
          isFrontCamera: camera.lensDirection == CameraLensDirection.front,
          isIos: Platform.isIOS,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Future<void> stopImageStream() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isStreamingImages) {
      return;
    }
    await controller.stopImageStream();
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    _camera = null;
    if (controller == null) return;
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.dispose();
  }

  int _orientationDegrees(DeviceOrientation orientation) {
    return switch (orientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };
  }
}
