import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/workout_controller.dart';
import '../application/workout_state.dart';
import 'widgets/pose_painter.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen>
    with WidgetsBindingObserver {
  late final WorkoutController _workoutController;

  @override
  void initState() {
    super.initState();
    _workoutController = ref.read(workoutControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_workoutController.start());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_workoutController.resume());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_workoutController.suspend());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_workoutController.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FormAI'),
        actions: [
          if (state.phase == WorkoutCameraPhase.streaming)
            IconButton(
              tooltip: '카메라 종료',
              onPressed: () =>
                  ref.read(workoutControllerProvider.notifier).stop(),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '실시간 자세 인식',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '카메라 영상은 기기에서 처리되며 서버에 저장되지 않습니다.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 20),
              Expanded(child: _CameraStage(state: state)),
              const SizedBox(height: 16),
              _StatusCard(state: state),
              const SizedBox(height: 16),
              if (state.phase == WorkoutCameraPhase.error)
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(workoutControllerProvider.notifier).start(),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('다시 시도'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraStage extends StatelessWidget {
  const _CameraStage({required this.state});

  final WorkoutState state;

  @override
  Widget build(BuildContext context) {
    final controller = state.cameraController;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: const Color(0xFF090909),
        child: switch (state.phase) {
          WorkoutCameraPhase.initializing => const Center(
            child: CircularProgressIndicator(),
          ),
          WorkoutCameraPhase.streaming when controller != null =>
            _CameraPreviewWithOverlay(controller: controller, state: state),
          WorkoutCameraPhase.suspended => const _StageMessage(
            icon: Icons.pause_circle_outline,
            message: '앱으로 돌아오면 카메라를 다시 준비합니다.',
          ),
          WorkoutCameraPhase.error => const _StageMessage(
            icon: Icons.camera_alt_outlined,
            message: '카메라를 준비하지 못했습니다.',
          ),
          _ => const _StageMessage(
            icon: Icons.accessibility_new,
            message: '스마트폰을 고정하고 전신이 보이게 서주세요.',
          ),
        },
      ),
    );
  }
}

class _CameraPreviewWithOverlay extends StatelessWidget {
  const _CameraPreviewWithOverlay({
    required this.controller,
    required this.state,
  });

  final CameraController controller;
  final WorkoutState state;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
        if (state.poseFrame case final poseFrame?)
          IgnorePointer(
            child: CustomPaint(painter: PosePainter(poseFrame: poseFrame)),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xCC000000),
              border: Border.all(color: const Color(0x66FF2D2D)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              state.poseFrame == null ? '카메라 켜짐 · 사람 미감지' : 'Pose 감지됨',
            ),
          ),
        ),
      ],
    );
  }
}

class _StageMessage extends StatelessWidget {
  const _StageMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white54),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final WorkoutState state;

  @override
  Widget build(BuildContext context) {
    final message =
        state.errorMessage ??
        switch (state.phase) {
          WorkoutCameraPhase.idle => '버튼을 누르면 운영체제의 카메라 권한 요청이 표시됩니다.',
          WorkoutCameraPhase.initializing => '카메라와 Pose 모델을 준비하고 있어요.',
          WorkoutCameraPhase.streaming when state.poseFrame == null =>
            '카메라는 실행 중입니다. 전신이 보이면 Skeleton이 표시됩니다.',
          WorkoutCameraPhase.streaming => '관절을 기기에서 실시간으로 추적하고 있어요.',
          WorkoutCameraPhase.suspended => '카메라가 일시 중지됐어요.',
          WorkoutCameraPhase.error => '카메라 설정을 확인해주세요.',
        };

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          border: Border.all(color: const Color(0xFF2A2A2A)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message, style: const TextStyle(height: 1.4)),
      ),
    );
  }
}
