import 'package:cliker/services/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Records the `arg` of every `HapticFeedback.vibrate` call routed through
  /// [SystemChannels.platform]. The arg is the `HapticFeedbackType.*` string
  /// that distinguishes light/medium/heavy.
  late List<String?> vibrateArgs;

  setUp(() {
    vibrateArgs = <String?>[];
    final TestDefaultBinaryMessenger messenger =
        TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (
      MethodCall call,
    ) async {
      if (call.method == 'HapticFeedback.vibrate') {
        vibrateArgs.add(call.arguments as String?);
      }
      return null;
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('Haptics.click bucket mapping (AC4)', () {
    testWidgets('strength < 0.5 fires lightImpact', (
      WidgetTester tester,
    ) async {
      await Haptics().click(0.2);
      expect(vibrateArgs, <String>['HapticFeedbackType.lightImpact']);
    });

    testWidgets('strength just below 0.5 fires lightImpact (boundary)', (
      WidgetTester tester,
    ) async {
      await Haptics().click(0.49);
      expect(vibrateArgs, <String>['HapticFeedbackType.lightImpact']);
    });

    testWidgets('strength == 0.5 fires mediumImpact (lower boundary)', (
      WidgetTester tester,
    ) async {
      await Haptics().click(0.5);
      expect(vibrateArgs, <String>['HapticFeedbackType.mediumImpact']);
    });

    testWidgets('strength in (0.5, 0.8] fires mediumImpact', (
      WidgetTester tester,
    ) async {
      await Haptics().click(0.7);
      expect(vibrateArgs, <String>['HapticFeedbackType.mediumImpact']);
    });

    testWidgets('strength == 0.8 fires mediumImpact (upper boundary)', (
      WidgetTester tester,
    ) async {
      await Haptics().click(0.8);
      expect(vibrateArgs, <String>['HapticFeedbackType.mediumImpact']);
    });

    testWidgets('strength > 0.8 fires heavyImpact', (
      WidgetTester tester,
    ) async {
      await Haptics().click(0.9);
      expect(vibrateArgs, <String>['HapticFeedbackType.heavyImpact']);
    });

    testWidgets('strength == 1.0 fires heavyImpact', (
      WidgetTester tester,
    ) async {
      await Haptics().click(1);
      expect(vibrateArgs, <String>['HapticFeedbackType.heavyImpact']);
    });
  });

  group('Haptics.enabled gate (AC4)', () {
    testWidgets('enabled=false makes click() a no-op (zero platform calls)', (
      WidgetTester tester,
    ) async {
      final Haptics haptics = Haptics(enabled: false);

      await haptics.click(0.2);
      await haptics.click(0.7);
      await haptics.click(0.95);

      expect(vibrateArgs, isEmpty);
    });

    testWidgets('re-enabling resumes platform calls', (
      WidgetTester tester,
    ) async {
      final Haptics haptics = Haptics(enabled: false);
      await haptics.click(0.9);
      expect(vibrateArgs, isEmpty);

      haptics.enabled = true;
      await haptics.click(0.9);
      expect(vibrateArgs, <String>['HapticFeedbackType.heavyImpact']);
    });
  });
}
