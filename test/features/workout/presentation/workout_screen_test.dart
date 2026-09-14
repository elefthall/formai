import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_ai/features/workout/presentation/workout_screen.dart';

void main() {
  testWidgets('starts camera setup while showing the privacy rationale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WorkoutScreen())),
    );

    expect(find.text('카메라 영상은 기기에서 처리되며 서버에 저장되지 않습니다.'), findsOneWidget);
    expect(find.text('카메라 허용하고 시작'), findsNothing);
  });
}
