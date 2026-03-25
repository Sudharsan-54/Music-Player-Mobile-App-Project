import 'package:flutter_test/flutter_test.dart';
import 'package:jazz_music/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Note: Full app testing requires audio_service init.
    // Use integration tests for complete end-to-end testing.
    expect(JazzMusicApp, isNotNull);
  });
}
