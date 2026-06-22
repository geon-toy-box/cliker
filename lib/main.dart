import 'package:cliker/app.dart';
import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/persistence/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App entry point.
///
/// Resolves the async startup dependencies once — the [SharedPreferences]
/// instance and a preloaded [ClickSoundPlayer] — then injects both into the
/// root [ProviderScope] so the synchronous notifiers/services downstream never
/// have to await.
///
/// Preloading the click sounds is best-effort: on a device with no audio
/// backend (or a failing plugin init) the app must still launch silently rather
/// than crash on a black screen, so [ClickSoundPlayer.init] is guarded.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final ClickSoundPlayer player = ClickSoundPlayer(AudioPlayersBackend());
  try {
    await player.init();
  } on Object catch (error, stackTrace) {
    // Audio is non-essential to launch; degrade to silent rather than crash.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'cliker',
        context: ErrorDescription('preloading click sounds at startup'),
      ),
    );
  }

  runApp(
    ProviderScope(
      // `Override` is not exported by flutter_riverpod 3; the element type is
      // inferred, matching the project's existing test setups.
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clickSoundPlayerProvider.overrideWithValue(player),
      ],
      child: const ClikerApp(),
    ),
  );
}
