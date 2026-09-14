import 'package:flutter_test/flutter_test.dart';
import 'package:form_ai/features/workout/domain/squat_state_machine.dart';

void main() {
  test('counts one complete standing-bottom-standing cycle', () {
    final machine = SquatStateMachine();
    final angles = [170, 150, 125, 100, 100, 120, 145, 160, 160];
    CompletedSquatRep? completed;

    for (var i = 0; i < angles.length; i++) {
      completed =
          machine.update(angles[i].toDouble(), i * 100).completedRep ??
          completed;
    }

    expect(machine.repCount, 1);
    expect(completed, isNotNull);
    expect(completed!.rangeOfMotionDeg, 70);
  });

  test('does not count a shallow attempt', () {
    final machine = SquatStateMachine();
    final angles = [170, 145, 130, 165, 165];
    for (var i = 0; i < angles.length; i++) {
      machine.update(angles[i].toDouble(), i * 100);
    }
    expect(machine.repCount, 0);
  });

  test('does not duplicate a count while remaining upright', () {
    final machine = SquatStateMachine();
    final angles = [170, 150, 100, 100, 125, 160, 160, 170, 170, 170];
    for (var i = 0; i < angles.length; i++) {
      machine.update(angles[i].toDouble(), i * 100);
    }
    expect(machine.repCount, 1);
  });
}
