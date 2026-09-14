import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/workout_controller.dart';
import '../application/workout_state.dart';
import '../domain/hand_gesture_counter.dart';
import '../domain/squat_analyzer.dart';
import '../domain/squat_state_machine.dart';
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
    ref.listen<WorkoutState>(workoutControllerProvider, (previous, next) {
      final squatFeedback = next.squatFeedback != previous?.squatFeedback
          ? next.squatFeedback
          : null;
      final handFeedback = next.handFeedback != previous?.handFeedback
          ? next.handFeedback
          : null;
      final message = squatFeedback ?? handFeedback;
      if (message != null) {
        _showFeedbackPopup(message);
      }
    });

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
              _SquatPanel(state: state),
              const SizedBox(height: 12),
              _HandGesturePanel(state: state),
              const SizedBox(height: 12),
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

  void _showFeedbackPopup(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt, color: Color(0xFFFF2D2D)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 2800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF101010),
          elevation: 12,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFFF2D2D), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }
}

class _SquatPanel extends ConsumerWidget {
  const _SquatPanel({required this.state});

  final WorkoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phaseLabel = switch (state.squatPhase) {
      SquatPhase.unknown => '정렬 중',
      SquatPhase.standing => '서 있음',
      SquatPhase.descending => '내려가는 중',
      SquatPhase.bottom => '최하단',
      SquatPhase.ascending => '올라오는 중',
    };
    final sideLabel = switch (state.selectedSquatSide) {
      SquatSide.left => '왼쪽 기준',
      SquatSide.right => '오른쪽 기준',
      null => '측면 자동 선택',
    };
    final instruction =
        state.squatFeedback ??
        (state.squatPoseValid
            ? '서 있는 자세에서 시작해 충분히 앉았다 일어나세요.'
            : '전신과 엉덩이·무릎·발목이 보이게 서주세요.');
    final angle = state.kneeAngleDeg?.round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: Border.all(color: const Color(0x66FF2D2D)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFF2D2D),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${state.squatRepCount}',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '스쿼트 · $phaseLabel · $sideLabel${angle == null ? '' : ' · $angle°'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  instruction,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '스쿼트 카운트 초기화',
            onPressed: () =>
                ref.read(workoutControllerProvider.notifier).resetSquatReps(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _HandGesturePanel extends ConsumerWidget {
  const _HandGesturePanel({required this.state});

  final WorkoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instruction = switch (state.handRepPhase) {
      HandRepPhase.waitingForOpen => '왼손 또는 오른손을 카메라 쪽으로 펼쳐주세요',
      HandRepPhase.waitingForClose => '같은 손으로 주먹을 쥐어주세요',
      HandRepPhase.waitingForReopen => '같은 손을 다시 펼치면 1회 완료',
    };
    final poseLabel = switch (state.handPose) {
      HandPose.unknown => '손 확인 중',
      HandPose.open => '펼침',
      HandPose.closed => '주먹',
    };
    final sideLabel = switch (state.activeHandSide) {
      HandSide.left => '왼손',
      HandSide.right => '오른손',
      HandSide.unknown => '감지된 손',
      null => '좌우 자동',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFF2D2D),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${state.handRepCount}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '손 제스처 테스트 · $sideLabel · $poseLabel',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  state.handFeedback ?? instruction,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '손 카운트 초기화',
            onPressed: () =>
                ref.read(workoutControllerProvider.notifier).resetHandReps(),
            icon: const Icon(Icons.refresh),
          ),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 160) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 28, color: Colors.white54),
                  const SizedBox(width: 10),
                  Flexible(child: Text(message, textAlign: TextAlign.center)),
                ],
              ),
            ),
          );
        }
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
      },
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
