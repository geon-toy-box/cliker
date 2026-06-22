import 'package:cliker/main.dart' as app;
import 'package:cliker/screens/home_screen.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end smoke (AC5): the whole real app, on a device.
///
/// Launches via the real `main` (preferences, audio preload, providers), then
/// drives the keycap and switch selector exactly as a user would and asserts
/// the counter and survival.
///
/// On a live device `pumpAndSettle` can hang (audio playback / vsync keep the
/// binding scheduling frames), so this test pumps fixed durations long enough
/// to cover the keycap press + ripple animations instead.
///
/// Sound is started disabled: the `audioplayers` plugin's per-player position
/// updater registers a persistent frame callback while a clip plays, and the
/// integration-test harness flags those as leftover transient callbacks at
/// teardown. Disabling sound keeps this end-to-end test (tap → counter, switch
/// selection, survival) deterministic; audio playback itself is covered by the
/// AC4 widget test (fake backend) and the AC6 runtime smoke on the device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Comfortably longer than the press + ripple lifetimes combined.
  const Duration settle = Duration(milliseconds: 600);

  testWidgets('tap keycap 5x → total 5, select red, tap once, app survives', (
    WidgetTester tester,
  ) async {
    // Start from a clean stats/settings slate so the assertion is deterministic
    // regardless of any prior run left on the device.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.soundEnabled': false,
    });

    await app.main();
    await tester.pump(settle);

    expect(find.byType(Keycap), findsOneWidget);

    Future<void> tapKeycap() async {
      await tester.tap(find.byKey(Keycap.innerCapKey));
      await tester.pump();
      // Drive the press + ripple animations to completion without settling.
      await tester.pump(settle);
    }

    for (int i = 0; i < 5; i++) {
      await tapKeycap();
    }

    // Total counter reads 5.
    expect(tester.widget<Text>(find.byKey(HomeScreen.totalStatKey)).data, '5');

    // Switch to red, then tap once more.
    await tester.tap(find.byKey(HomeScreen.switchChipKey('red')));
    await tester.pump(settle);
    await tapKeycap();

    expect(tester.widget<Text>(find.byKey(HomeScreen.totalStatKey)).data, '6');

    // App is alive with no uncaught exception.
    expect(tester.takeException(), isNull);
  });
}
