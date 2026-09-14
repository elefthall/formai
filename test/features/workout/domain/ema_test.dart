import 'package:flutter_test/flutter_test.dart';
import 'package:form_ai/features/workout/domain/ema.dart';

void main() {
  test('uses the first sample without introducing startup bias', () {
    final filter = EmaFilter(alpha: 0.35);
    expect(filter.update(100), 100);
  });

  test('smooths subsequent samples with alpha 0.35', () {
    final filter = EmaFilter(alpha: 0.35)..update(100);
    expect(filter.update(80), closeTo(93, 0.0001));
  });

  test('reset makes the next sample the new baseline', () {
    final filter = EmaFilter(alpha: 0.35)..update(100);
    filter.reset();
    expect(filter.update(70), 70);
  });
}
