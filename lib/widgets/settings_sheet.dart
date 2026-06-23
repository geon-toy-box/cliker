import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:cliker/widgets/rgb_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The settings panel, shown as a modal bottom sheet from [HomeScreen].
///
/// Every control is bound directly to [settingsProvider]: toggling a switch or
/// tapping a chip/wheel calls the matching notifier setter, which updates state
/// and persists it immediately. The sheet keeps no local state of its own — it
/// is a thin view over the provider, so it always reflects the live settings.
///
/// Controls:
/// - Sound on/off ([SettingsNotifier.setSound]).
/// - Haptic on/off ([SettingsNotifier.setHaptic]).
/// - LED color: the [RgbWheel] hue picker ([SettingsNotifier.setLedColor]).
/// - LED mode: ripple / solid / rgbCycle / reactive chips
///   ([SettingsNotifier.setLedMode]).
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  /// Key on the sheet root, so tests can assert it opened.
  static const Key sheetKey = Key('settings-sheet');

  /// Key on the sound toggle ([Switch]).
  static const Key soundToggleKey = Key('settings-sound-toggle');

  /// Key on the haptic toggle ([Switch]).
  static const Key hapticToggleKey = Key('settings-haptic-toggle');

  /// Key for the LED-mode chip of [mode].
  static Key modeChipKey(LedMode mode) => Key('settings-mode-${mode.name}');

  /// Opens the sheet as a modal bottom sheet over [context]. Returns when the
  /// sheet is dismissed.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (BuildContext context) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Settings settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SafeArea(
      key: sheetKey,
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '설정',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Sound / haptic toggles.
            _ToggleRow(
              toggleKey: soundToggleKey,
              label: '사운드',
              value: settings.soundEnabled,
              onChanged: (bool v) => notifier.setSound(enabled: v),
            ),
            _ToggleRow(
              toggleKey: hapticToggleKey,
              label: '햅틱',
              value: settings.hapticEnabled,
              onChanged: (bool v) => notifier.setHaptic(enabled: v),
            ),
            const SizedBox(height: AppSpacing.lg),

            // LED color wheel.
            _SectionLabel(text: 'LED 색', textTheme: textTheme),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: RgbWheel(
                color: Color(settings.ledColorArgb),
                onColorChanged: (Color c) => notifier.setLedColor(c.toARGB32()),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // LED mode chips.
            _SectionLabel(text: 'LED 모드', textTheme: textTheme),
            const SizedBox(height: AppSpacing.sm),
            _ModeChips(
              selected: settings.ledMode,
              onSelect: notifier.setLedMode,
            ),
          ],
        ),
      ),
    );
  }
}

/// A labeled row with a trailing [Switch], used for the sound/haptic toggles.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.toggleKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key toggleKey;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
          ),
        ),
        Switch(
          key: toggleKey,
          value: value,
          activeThumbColor: AppColors.neonCyan,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A muted section caption above a group of controls.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.textTheme});

  final String text;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: textTheme.labelLarge?.copyWith(color: AppColors.textMuted),
    );
  }
}

/// The LED-mode selector: one [ChoiceChip] per [LedMode], single-select.
class _ModeChips extends StatelessWidget {
  const _ModeChips({required this.selected, required this.onSelect});

  final LedMode selected;
  final ValueChanged<LedMode> onSelect;

  /// Korean labels for each mode, in [LedMode.values] order.
  static const Map<LedMode, String> _labels = <LedMode, String>{
    LedMode.ripple: '리플',
    LedMode.solid: '솔리드',
    LedMode.rgbCycle: 'RGB 순환',
    LedMode.reactive: '반응형',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final LedMode mode in LedMode.values)
          ChoiceChip(
            key: SettingsSheet.modeChipKey(mode),
            label: Text(_labels[mode]!),
            selected: mode == selected,
            selectedColor: AppColors.neonCyan.withValues(alpha: 0.25),
            side: BorderSide(
              color: mode == selected
                  ? AppColors.neonCyan
                  : AppColors.surfaceHi,
            ),
            onSelected: (bool isSelected) {
              // Single-select: re-tapping the active chip is a no-op.
              if (isSelected) {
                onSelect(mode);
              }
            },
          ),
      ],
    );
  }
}
