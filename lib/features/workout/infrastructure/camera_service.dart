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
          ? ImageFormatGroup.yuv420
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
      final mlKitFrame = _mlKitFrame(image);
      if (mlKitFrame == null) return;
      onFrame(
        CameraFrame(
          bytes: mlKitFrame.bytes,
          width: image.width,
          height: image.height,
          bytesPerRow: mlKitFrame.bytesPerRow,
          formatRaw: mlKitFrame.formatRaw,
          sensorOrientationDegrees: camera.sensorOrientation,
          deviceOrientationDegrees: _orientationDegrees(
            controller.value.deviceOrientation,
          ),
          isFrontCamera: camera.lensDirection == CameraLensDirection.front,
          isIos: Platform.isIOS,
          timestamp: DateTime.now(),
          sourceImage: image,
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

  _MlKitFrame? _mlKitFrame(CameraImage image) {
    if (Platform.isIOS) {
      if (image.planes.length != 1) return null;
      final plane = image.planes.first;
      return _MlKitFrame(
        bytes: plane.bytes,
        bytesPerRow: plane.bytesPerRow,
        formatRaw: image.format.raw,
      );
    }
    if (image.planes.length != 3) return null;
    return _packYuv420AsNv21(image);
  }

  _MlKitFrame _packYuv420AsNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final output = Uint8List(width * height * 3 ~/ 2);
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    var outputIndex = 0;
    for (var row = 0; row < height; row++) {
      final rowStart = row * yPlane.bytesPerRow;
      output.setRange(outputIndex, outputIndex + width, yPlane.bytes, rowStart);
      outputIndex += width;
    }

    final chromaWidth = width ~/ 2;
    final chromaHeight = height ~/ 2;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < chromaHeight; row++) {
      for (var column = 0; column < chromaWidth; column++) {
        output[outputIndex++] =
            vPlane.bytes[row * vPlane.bytesPerRow + column * vPixelStride];
        output[outputIndex++] =
            uPlane.bytes[row * uPlane.bytesPerRow + column * uPixelStride];
      }
    }
    return _MlKitFrame(bytes: output, bytesPerRow: width, formatRaw: 17);
  }
}

class _MlKitFrame {
  const _MlKitFrame({
    required this.bytes,
    required this.bytesPerRow,
    required this.formatRaw,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int formatRaw;
}
