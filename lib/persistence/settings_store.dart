import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the app-wide [SharedPreferences] instance.
///
/// The plugin's [SharedPreferences.getInstance] is asynchronous, so the
/// instance is resolved once during app startup and injected here as a
/// synchronous dependency. This lets the settings/stats notifiers read and
/// write prefs without awaiting in their `build`/setters.
///
/// This base definition intentionally throws: it must be overridden before any
/// dependent provider is read. In `main` do:
///
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// runApp(ProviderScope(
///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
///   child: const App(),
/// ));
/// ```
///
/// Tests override it with a mock instance:
///
/// ```dart
/// SharedPreferences.setMockInitialValues(<String, Object>{});
/// final prefs = await SharedPreferences.getInstance();
/// final container = ProviderContainer(
///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
/// );
/// ```
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (Ref ref) => throw UnimplementedError(
        'override sharedPreferencesProvider in main',
      ),
    );
