import 'package:cliker/providers/stats_providers.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:cliker/util/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The MZ stats hero shown below the top bar on [HomeScreen].
///
/// Subscribes to [statsProvider] and renders exactly two live figures — the
/// lifetime total ([Stats.totalClicks]) and the current RPM (clicks-per-minute,
/// from [Stats.cpm]). The total is the hero: a giant, ultra-heavy number filled
/// with the holographic [AppColors.holoSweep] gradient via a [ShaderMask], that
/// pops with a small scale-bounce as it grows. RPM sits beneath it as a small
/// glass pill. A compact reset button sits in the corner.
///
/// Large numbers are thousands-separated via [thousands]. This widget only
/// displays and resets; all stats logic lives in [StatsNotifier].
///
/// Resetting is guarded by a confirm dialog: tapping reset opens it, "취소"
/// dismisses it leaving the values untouched, and "초기화" calls
/// [StatsNotifier.resetStats], which zeroes every counter and clears the
/// persisted lifetime figures.
class StatsPanel extends ConsumerWidget {
  const StatsPanel({super.key});

  /// Key on the lifetime-total value [Text] (the holographic hero number).
  static const Key totalStatKey = Key('stat-total');

  /// Key on the RPM (clicks-per-minute) value [Text].
  static const Key rpmStatKey = Key('stat-rpm');

  /// Key on the reset button that opens the confirm dialog.
  static const Key resetButtonKey = Key('stats-reset-button');

  /// Key on the confirm dialog shown before resetting.
  static const Key resetDialogKey = Key('stats-reset-dialog');

  /// Key on the dialog's confirm ("초기화") action.
  static const Key resetConfirmKey = Key('stats-reset-confirm');

  /// Key on the dialog's cancel ("취소") action.
  static const Key resetCancelKey = Key('stats-reset-cancel');

  /// Reduce-motion respecting: the hero pop is disabled when the platform asks
  /// for fewer animations.
  bool _animationsOff(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Stats stats = ref.watch(statsProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Caption above the hero number.
        Text(
          '전체 클릭수',
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Hero number: holographic gradient fill, with a per-increment pop.
        _HeroNumber(
          value: thousands(stats.totalClicks),
          animate: !_animationsOff(context),
        ),
        const SizedBox(height: AppSpacing.md),
        // RPM glass pill + reset, side by side.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _RpmPill(value: thousands(stats.cpm)),
            const SizedBox(width: AppSpacing.sm),
            _ResetButton(onPressed: () => _confirmReset(context, ref)),
          ],
        ),
      ],
    );
  }

  /// Shows the reset confirm dialog. On "초기화" calls
  /// [StatsNotifier.resetStats]; on "취소" (or barrier dismiss) leaves the
  /// stats untouched.
  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          key: resetDialogKey,
          backgroundColor: AppColors.surface,
          title: const Text('통계 초기화'),
          content: const Text('정말 초기화할까요? 누적 기록이 모두 0이 됩니다.'),
          actions: <Widget>[
            TextButton(
              key: resetCancelKey,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              key: resetConfirmKey,
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.switchRed),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      ref.read(statsProvider.notifier).resetStats();
    }
  }
}

/// The giant holographic hero number: an ultra-heavy [Text] filled with the
/// [AppColors.holoSweep] gradient via [ShaderMask], that pops with a brief
/// scale-bounce whenever its [value] changes (unless [animate] is false).
class _HeroNumber extends StatefulWidget {
  const _HeroNumber({required this.value, required this.animate});

  final String value;
  final bool animate;

  @override
  State<_HeroNumber> createState() => _HeroNumberState();
}

class _HeroNumberState extends State<_HeroNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void didUpdateWidget(_HeroNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.animate) {
      _pop
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.sizeOf(context).width;
    final double fontSize = (size * 0.20).clamp(48.0, 96.0);

    final Text number = Text(
      widget.value,
      key: StatsPanel.totalStatKey,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        // White base so the ShaderMask gradient shows through unmodulated.
        color: AppColors.textPrimary,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
        height: 1.0,
      ),
    );

    final Widget holo = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) => const LinearGradient(
        colors: AppColors.holoSweep,
      ).createShader(bounds),
      child: number,
    );

    if (!widget.animate) {
      return holo;
    }
    return ScaleTransition(
      scale: Tween<double>(
        begin: 1.0,
        end: 1.12,
      ).animate(CurvedAnimation(parent: _pop, curve: Curves.elasticOut)),
      child: holo,
    );
  }
}

/// A small glass pill showing the live RPM figure.
class _RpmPill extends StatelessWidget {
  const _RpmPill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.holoCyan.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'RPM',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            key: StatsPanel.rpmStatKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.holoCyan,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// The compact reset affordance, kept small so the hero figures dominate.
class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: StatsPanel.resetButtonKey,
      onPressed: onPressed,
      icon: const Icon(Icons.refresh, size: 20),
      color: AppColors.textMuted,
      tooltip: '통계 초기화',
      visualDensity: VisualDensity.compact,
    );
  }
}
