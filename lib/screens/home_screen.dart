import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/domain/switch_type.dart';
import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/providers/stats_providers.dart';
import 'package:cliker/services/haptics.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:cliker/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single screen of the app: a tappable [Keycap] flanked by a stats readout
/// above and a switch selector below.
///
/// Tapping the keycap plays the selected switch's press/release click, fires a
/// matching haptic, and registers the click in [statsProvider]. The sound/haptic
/// toggles in [settingsProvider] are mirrored onto the shared
/// [ClickSoundPlayer.muted] / [Haptics.enabled] flags so a disabled toggle is a
/// true no-op at the source. Full settings and stats panels arrive in M2.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Keys on the three stat values, so tests can read each independently.
  static const Key totalStatKey = Key('stat-total');
  static const Key sessionStatKey = Key('stat-session');
  static const Key cpmStatKey = Key('stat-cpm');

  /// Key prefix for switch-selector chips; full key is `Key('switch-chip-<id>')`.
  static Key switchChipKey(String id) => Key('switch-chip-$id');

  /// Key on the settings entry-point button (opens [SettingsSheet]).
  static const Key settingsButtonKey = Key('settings-button');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Settings settings = ref.watch(settingsProvider);
    final Stats stats = ref.watch(statsProvider);
    final SwitchType selected = SwitchCatalog.byId(settings.selectedSwitchId);

    // Mirror the persisted toggles onto the shared services. Reading the
    // providers here keeps the flags in sync on every settings change without a
    // separate listener; the services are cheap plain objects.
    final ClickSoundPlayer player = ref.watch(clickSoundPlayerProvider)
      ..muted = !settings.soundEnabled;
    final Haptics haptics = ref.watch(hapticsProvider)
      ..enabled = settings.hapticEnabled;

    void handlePressDown() {
      if (settings.soundEnabled) {
        player.playDown(selected);
      }
      if (settings.hapticEnabled) {
        haptics.click(selected.hapticStrength);
      }
      ref.read(statsProvider.notifier).registerClick(DateTime.now());
    }

    void handlePressUp() {
      if (settings.soundEnabled) {
        player.playUp(selected);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: <Widget>[
              // Top bar: the settings entry point, right-aligned above the
              // stats so it stays clear of the central keycap.
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: HomeScreen.settingsButtonKey,
                  icon: const Icon(Icons.settings_outlined),
                  color: AppColors.textMuted,
                  tooltip: '설정',
                  onPressed: () => SettingsSheet.show(context),
                ),
              ),
              _StatsReadout(stats: stats),
              Expanded(
                child: Center(
                  child: Keycap(
                    ledColor: Color(settings.ledColorArgb),
                    ledMode: settings.ledMode,
                    label: selected.nameEn,
                    onPressDown: handlePressDown,
                    onPressUp: handlePressUp,
                  ),
                ),
              ),
              _SwitchSelector(
                selectedId: settings.selectedSwitchId,
                onSelect: (String id) =>
                    ref.read(settingsProvider.notifier).selectSwitch(id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The top readout: lifetime total, this-session count, and current CPM.
class _StatsReadout extends StatelessWidget {
  const _StatsReadout({required this.stats});

  final Stats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _StatTile(
          valueKey: HomeScreen.totalStatKey,
          label: '누적',
          value: '${stats.totalClicks}',
        ),
        _StatTile(
          valueKey: HomeScreen.sessionStatKey,
          label: '세션',
          value: '${stats.sessionClicks}',
        ),
        _StatTile(
          valueKey: HomeScreen.cpmStatKey,
          label: 'CPM',
          value: '${stats.cpm}',
        ),
      ],
    );
  }
}

/// A single labeled stat: large number over a muted caption.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.valueKey,
    required this.label,
    required this.value,
  });

  final Key valueKey;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          key: valueKey,
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// The bottom row of switch chips. The selected chip is highlighted with the
/// switch's stem color; tapping another chip reports it via [onSelect].
class _SwitchSelector extends StatelessWidget {
  const _SwitchSelector({required this.selectedId, required this.onSelect});

  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        for (final SwitchType switchType in SwitchCatalog.all)
          _SwitchChip(
            switchType: switchType,
            selected: switchType.id == selectedId,
            onTap: () => onSelect(switchType.id),
          ),
      ],
    );
  }
}

/// One selectable switch chip: a stem-color dot above the Korean name, in a
/// pill that lights up in the stem color when selected.
class _SwitchChip extends StatelessWidget {
  const _SwitchChip({
    required this.switchType,
    required this.selected,
    required this.onTap,
  });

  final SwitchType switchType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      key: HomeScreen.switchChipKey(switchType.id),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? switchType.stemColor.withValues(alpha: 0.22)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? switchType.stemColor : AppColors.surfaceHi,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: switchType.stemColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              switchType.nameKo,
              style: textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
