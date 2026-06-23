import 'package:cliker/domain/switch_type.dart';
import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The switch-selection menu, shown as a glassy modal bottom sheet.
///
/// Lists every catalog switch as an info-rich row carrying a stem-color preview
/// dot, the Korean name + English name, a meta line (actuation kind · force ·
/// a loudness bar), the one-line feel ([SwitchType.description]), and the
/// recommended use ([SwitchType.recommendedFor]). Tapping a row selects that
/// switch via [SettingsNotifier.selectSwitch] and closes the sheet; the home
/// keycap then updates its stem color and label.
///
/// Each row keeps the stable `Key('switch-chip-<id>')` so existing
/// switch-selection tests/callers reach it the same way they did when the chips
/// lived inline on the home screen.
class SwitchMenu extends ConsumerWidget {
  const SwitchMenu({super.key});

  /// Key on the sheet root, so tests can assert it opened.
  static const Key sheetKey = Key('switch-menu-sheet');

  /// Key for the row of switch [id]; full key is `Key('switch-chip-<id>')`.
  static Key switchChipKey(String id) => Key('switch-chip-$id');

  /// Short Korean label for each actuation family.
  static const Map<SwitchKind, String> _kindLabels = <SwitchKind, String>{
    SwitchKind.clicky: '클릭',
    SwitchKind.tactile: '텍타일',
    SwitchKind.linear: '리니어',
  };

  /// Opens the menu as a modal bottom sheet over [context]. Returns when the
  /// sheet is dismissed.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => const SwitchMenu(),
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
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        decoration: BoxDecoration(
          // Glass: a translucent white overlay on the dark surface, with a soft
          // holographic top glow and a hairline border.
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.10),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.holoViolet.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Drag handle.
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                '축 선택',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // A SingleChildScrollView + Column (rather than a lazy ListView)
            // keeps every row in the tree at once, so all thirteen switch chips
            // are present and reachable even while some are scrolled off-screen.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (
                      int i = 0;
                      i < SwitchCatalog.all.length;
                      i++
                    ) ...<Widget>[
                      if (i > 0) const SizedBox(height: AppSpacing.xs),
                      _SwitchRow(
                        switchType: SwitchCatalog.all[i],
                        kindLabel: _kindLabels[SwitchCatalog.all[i].kind]!,
                        selected:
                            SwitchCatalog.all[i].id ==
                            settings.selectedSwitchId,
                        onTap: () {
                          notifier.selectSwitch(SwitchCatalog.all[i].id);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One selectable switch row. Shows, top to bottom:
///
/// - a stem-color dot + `nameKo (nameEn)` heading (with the check on the
///   selected row),
/// - a meta line: `kindLabel · forceCn cN` followed by a 5-segment
///   loudness bar,
/// - the one-line feel ([SwitchType.description]),
/// - the recommended use, prefixed `추천: ` ([SwitchType.recommendedFor]).
///
/// The selected row is tinted/ringed in the stem color.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.switchType,
    required this.kindLabel,
    required this.selected,
    required this.onTap,
  });

  final SwitchType switchType;
  final String kindLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      key: SwitchMenu.switchChipKey(switchType.id),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? switchType.stemColor.withValues(alpha: 0.16)
              : AppColors.surfaceHi.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? switchType.stemColor
                : AppColors.textPrimary.withValues(alpha: 0.06),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Stem-color preview dot with a soft glow. Nudged down so it aligns
            // with the heading row rather than the multi-line block's center.
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: switchType.stemColor,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: switchType.stemColor.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Heading: nameKo (nameEn), with the check on the selected row.
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${switchType.nameKo} (${switchType.nameEn})',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_rounded,
                          color: switchType.stemColor,
                          size: 22,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Meta line: kind · force, then the loudness bar.
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '$kindLabel · ${switchType.forceCn}cN',
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _LoudnessBar(loudness: switchType.loudness),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Feel (느낌) one-liner.
                  Text(
                    switchType.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Recommended use.
                  Text(
                    '추천: ${switchType.recommendedFor}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact 5-segment "소리세기" (loudness) indicator. The first [loudness]
/// segments are lit in [AppColors.neonYellow]; the rest are dim. A leading mute
/// icon labels the bar so it reads as a sound-level meter.
class _LoudnessBar extends StatelessWidget {
  const _LoudnessBar({required this.loudness});

  /// Loudness on a 1–5 scale; clamped before rendering.
  final int loudness;

  /// Number of segments in the bar (the loudness scale max).
  static const int segments = 5;

  @override
  Widget build(BuildContext context) {
    final int lit = loudness.clamp(0, segments);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.volume_up_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        for (int i = 0; i < segments; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 2),
          Container(
            width: 4,
            height: 9,
            decoration: BoxDecoration(
              color: i < lit
                  ? AppColors.neonYellow
                  : AppColors.textMuted.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ],
    );
  }
}
