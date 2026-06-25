import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/audio/dynamic_click_engine.dart';
import 'package:cliker/domain/switch_type.dart';
import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/providers/stats_providers.dart';
import 'package:cliker/services/haptics.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:cliker/widgets/rgb_wheel.dart';
import 'package:cliker/widgets/settings_sheet.dart';
import 'package:cliker/widgets/stats_panel.dart';
import 'package:cliker/widgets/switch_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single screen of the app, in the MZ (holographic / glossy / bubbly)
/// visual language.
///
/// Top bar: a holographic "cliker" wordmark, a right-aligned switch-menu button
/// (opens [SwitchMenu]) and a settings gear (opens [SettingsSheet]). Below it
/// the [StatsPanel] hero shows the giant holographic click total and the RPM
/// pill. The center is the realistic switch+keycap; the bottom is the
/// [RgbWheel] LED color picker.
///
/// Tapping the keycap plays the selected switch's press/release click, fires a
/// matching haptic, and registers the click in [statsProvider]. The sound/haptic
/// toggles in [settingsProvider] are mirrored onto the shared
/// [ClickSoundPlayer.muted] / [Haptics.enabled] flags so a disabled toggle is a
/// true no-op at the source.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Keys on the stat values, re-exported from [StatsPanel] so callers/tests can
  /// reach them via either type.
  static const Key totalStatKey = StatsPanel.totalStatKey;
  static const Key rpmStatKey = StatsPanel.rpmStatKey;

  /// Key prefix for switch-menu rows; re-exported from [SwitchMenu] so existing
  /// switch-selection tests keep reaching chips by the same key.
  static Key switchChipKey(String id) => SwitchMenu.switchChipKey(id);

  /// Key on the switch-menu entry-point button (opens [SwitchMenu]).
  static const Key switchMenuButtonKey = Key('switch-menu-button');

  /// Key on the settings entry-point button (opens [SettingsSheet]).
  static const Key settingsButtonKey = Key('settings-button');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Settings settings = ref.watch(settingsProvider);
    final SwitchType selected = SwitchCatalog.byId(settings.selectedSwitchId);
    final Color ledColor = Color(settings.ledColorArgb);

    // Mirror the persisted toggles onto the shared services. Reading the
    // providers here keeps the flags in sync on every settings change without a
    // separate listener; the services are cheap plain objects.
    final ClickSoundPlayer player = ref.watch(clickSoundPlayerProvider)
      ..muted = !settings.soundEnabled;
    final DynamicClickEngine engine = ref.watch(dynamicClickEngineProvider);
    final Haptics haptics = ref.watch(hapticsProvider)
      ..enabled = settings.hapticEnabled;

    void handlePressDown(double? force) {
      // The dynamic engine drives playback whenever it is on (it routes through
      // the same muted player, so a disabled-sound press is silent but still
      // balances its schedule); otherwise the classic single-clip path runs.
      if (settings.dynamicClickEnabled) {
        engine.pressDown(
          selected,
          force: force,
          intensity: settings.dynamicClickIntensity,
        );
      } else {
        // Drop any schedule a prior dynamic press may have stranded (e.g. the
        // toggle was flipped off mid-press), then play the single down clip.
        engine.cancel();
        if (settings.soundEnabled) {
          player.playDown(selected);
        }
      }
      if (settings.hapticEnabled) {
        haptics.click(selected.hapticStrength);
      }
      ref.read(statsProvider.notifier).registerClick(DateTime.now());
    }

    void handlePressUp() {
      // Route the release by *who owns this press*, not the live toggle: if the
      // engine started it (dynamic path), let it finish even if the toggle was
      // since turned off. isPressing is false for a classic press, so we fall
      // through to the single up clip. This keeps every pressDown balanced.
      if (engine.isPressing) {
        engine.pressUp();
      } else if (settings.soundEnabled) {
        player.playUp(selected);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: <Widget>[
              _TopBar(ledColor: ledColor),
              const SizedBox(height: AppSpacing.md),
              const StatsPanel(),
              Expanded(
                child: Center(
                  child: Keycap(
                    ledColor: ledColor,
                    stemColor: selected.stemColor,
                    ledMode: settings.ledMode,
                    label: selected.nameKo,
                    onPressDown: handlePressDown,
                    onPressUp: handlePressUp,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // LED color wheel — picks a vivid hue and pushes it into settings,
              // so the keycap glow/accents follow live and persist.
              _LedWheelPanel(
                color: ledColor,
                onColorChanged: (Color c) => ref
                    .read(settingsProvider.notifier)
                    .setLedColor(c.toARGB32()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The top bar: the holographic wordmark on the left, the switch-menu button and
/// settings gear on the right.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.ledColor});

  final Color ledColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const _Wordmark(),
        const Spacer(),
        // Switch ("축") menu button — glassy pill so it reads as tappable.
        _GlassIconButton(
          buttonKey: HomeScreen.switchMenuButtonKey,
          icon: Icons.tune_rounded,
          label: '축',
          tooltip: '축 선택',
          accent: ledColor,
          onPressed: () => SwitchMenu.show(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          key: HomeScreen.settingsButtonKey,
          icon: const Icon(Icons.settings_outlined),
          color: AppColors.textMuted,
          tooltip: '설정',
          onPressed: () => SettingsSheet.show(context),
        ),
      ],
    );
  }
}

/// The "cliker" wordmark filled with the holographic [AppColors.holoSweep]
/// gradient via a [ShaderMask].
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) => const LinearGradient(
        colors: AppColors.holoSweep,
      ).createShader(bounds),
      child: const Text(
        'cliker',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

/// A glassy pill icon-button used for the switch-menu entry point.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.accent,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final String tooltip;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: buttonKey,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bottom LED panel: a glass card framing the [RgbWheel] with a caption.
class _LedWheelPanel extends StatelessWidget {
  const _LedWheelPanel({required this.color, required this.onColorChanged});

  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'LED 색',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '휠을 돌려 색을 골라보세요',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          RgbWheel(color: color, onColorChanged: onColorChanged, size: 120),
        ],
      ),
    );
  }
}
