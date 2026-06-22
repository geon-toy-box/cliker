import 'package:cliker/providers/stats_providers.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:cliker/util/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The stats panel shown at the top of [HomeScreen].
///
/// Subscribes to [statsProvider] and renders four live figures — lifetime total,
/// this-session count, current CPM, and best CPM — as labeled tiles inside a
/// surface card, with a reset button. Large numbers are thousands-separated via
/// [thousands]. This widget only displays and resets; all stats logic lives in
/// [StatsNotifier].
///
/// Resetting is guarded by a confirm dialog: tapping the reset button opens it,
/// "취소" dismisses it leaving the values untouched, and "초기화" calls
/// [StatsNotifier.resetStats], which zeroes every counter and clears the
/// persisted lifetime figures.
class StatsPanel extends ConsumerWidget {
  const StatsPanel({super.key});

  /// Key on the lifetime-total value [Text].
  static const Key totalStatKey = Key('stat-total');

  /// Key on the this-session value [Text].
  static const Key sessionStatKey = Key('stat-session');

  /// Key on the current-CPM value [Text].
  static const Key cpmStatKey = Key('stat-cpm');

  /// Key on the best-CPM value [Text].
  static const Key bestStatKey = Key('stat-best');

  /// Key on the reset button that opens the confirm dialog.
  static const Key resetButtonKey = Key('stats-reset-button');

  /// Key on the confirm dialog shown before resetting.
  static const Key resetDialogKey = Key('stats-reset-dialog');

  /// Key on the dialog's confirm ("초기화") action.
  static const Key resetConfirmKey = Key('stats-reset-confirm');

  /// Key on the dialog's cancel ("취소") action.
  static const Key resetCancelKey = Key('stats-reset-cancel');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Stats stats = ref.watch(statsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceHi),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  valueKey: totalStatKey,
                  label: '누적',
                  value: thousands(stats.totalClicks),
                  accent: AppColors.neonCyan,
                ),
              ),
              Expanded(
                child: _StatTile(
                  valueKey: sessionStatKey,
                  label: '세션',
                  value: thousands(stats.sessionClicks),
                  accent: AppColors.neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  valueKey: cpmStatKey,
                  label: 'CPM',
                  value: thousands(stats.cpm),
                  accent: AppColors.neonMagenta,
                ),
              ),
              Expanded(
                child: _StatTile(
                  valueKey: bestStatKey,
                  label: '최고 CPM',
                  value: thousands(stats.bestCpm),
                  accent: AppColors.neonOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: resetButtonKey,
              onPressed: () => _confirmReset(context, ref),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('초기화'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            ),
          ),
        ],
      ),
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
          content: const Text('정말 초기화할까요? 누적·최고 기록이 모두 0이 됩니다.'),
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

/// A single labeled stat: a large accent-colored number over a muted caption.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.valueKey,
    required this.label,
    required this.value,
    required this.accent,
  });

  final Key valueKey;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          key: valueKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineMedium?.copyWith(
            color: accent,
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
