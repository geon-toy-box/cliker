import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:cliker/persistence/settings_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable click statistics.
///
/// [totalClicks] and [bestCpm] are persisted (lifetime figures); [sessionClicks]
/// and [cpm] are in-memory only and reset to 0 on each app launch.
///
/// Compared by value so Riverpod can skip rebuilds when nothing changed.
@immutable
class Stats {
  const Stats({
    required this.totalClicks,
    required this.sessionClicks,
    required this.cpm,
    required this.bestCpm,
  });

  /// Lifetime click count (persisted).
  final int totalClicks;

  /// Clicks since the app launched (in-memory).
  final int sessionClicks;

  /// Clicks in the most recent trailing 60-second window (in-memory).
  final int cpm;

  /// Highest [cpm] ever observed (persisted).
  final int bestCpm;

  Stats copyWith({
    int? totalClicks,
    int? sessionClicks,
    int? cpm,
    int? bestCpm,
  }) {
    return Stats(
      totalClicks: totalClicks ?? this.totalClicks,
      sessionClicks: sessionClicks ?? this.sessionClicks,
      cpm: cpm ?? this.cpm,
      bestCpm: bestCpm ?? this.bestCpm,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stats &&
          other.totalClicks == totalClicks &&
          other.sessionClicks == sessionClicks &&
          other.cpm == cpm &&
          other.bestCpm == bestCpm);

  @override
  int get hashCode => Object.hash(totalClicks, sessionClicks, cpm, bestCpm);

  @override
  String toString() =>
      'Stats(totalClicks: $totalClicks, sessionClicks: $sessionClicks, '
      'cpm: $cpm, bestCpm: $bestCpm)';
}

/// Tracks click statistics, persisting lifetime figures to [SharedPreferences].
///
/// CPM is computed over a trailing 60-second window: each click's timestamp is
/// remembered, stale timestamps are dropped, and [Stats.cpm] is the number of
/// timestamps still inside the window. Timestamps are injected via
/// [registerClick] so the window is deterministic under test.
class StatsNotifier extends Notifier<Stats> {
  static const String _keyTotalClicks = 'stats.totalClicks';
  static const String _keyBestCpm = 'stats.bestCpm';

  /// Width of the CPM trailing window.
  static const Duration _cpmWindow = Duration(seconds: 60);

  /// Timestamps of recent clicks within [_cpmWindow] (in-memory, oldest first).
  final Queue<DateTime> _recentClicks = Queue<DateTime>();

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Stats build() {
    final SharedPreferences prefs = _prefs;
    return Stats(
      totalClicks: prefs.getInt(_keyTotalClicks) ?? 0,
      sessionClicks: 0,
      cpm: 0,
      bestCpm: prefs.getInt(_keyBestCpm) ?? 0,
    );
  }

  /// Records one click at [now]: increments total/session counts, recomputes
  /// the trailing-60s [Stats.cpm], and raises [Stats.bestCpm] if exceeded.
  ///
  /// [totalClicks] and [bestCpm] are persisted; [sessionClicks] and [cpm] stay
  /// in memory.
  void registerClick(DateTime now) {
    _recentClicks.addLast(now);
    _pruneTo(now);
    final int cpm = _recentClicks.length;
    final int bestCpm = math.max(state.bestCpm, cpm);

    state = state.copyWith(
      totalClicks: state.totalClicks + 1,
      sessionClicks: state.sessionClicks + 1,
      cpm: cpm,
      bestCpm: bestCpm,
    );

    unawaited(_prefs.setInt(_keyTotalClicks, state.totalClicks));
    if (bestCpm != _prefs.getInt(_keyBestCpm)) {
      unawaited(_prefs.setInt(_keyBestCpm, bestCpm));
    }
  }

  /// Resets all four counters to 0 and persists the lifetime figures.
  void resetStats() {
    _recentClicks.clear();
    state = const Stats(totalClicks: 0, sessionClicks: 0, cpm: 0, bestCpm: 0);
    unawaited(_prefs.setInt(_keyTotalClicks, 0));
    unawaited(_prefs.setInt(_keyBestCpm, 0));
  }

  /// Drops timestamps older than [_cpmWindow] relative to [now]. A click is in
  /// the window when it is strictly newer than `now - 60s` (a 60s-old click has
  /// just aged out).
  void _pruneTo(DateTime now) {
    final DateTime cutoff = now.subtract(_cpmWindow);
    while (_recentClicks.isNotEmpty && !_recentClicks.first.isAfter(cutoff)) {
      _recentClicks.removeFirst();
    }
  }
}

/// App-wide click statistics state.
final NotifierProvider<StatsNotifier, Stats> statsProvider =
    NotifierProvider<StatsNotifier, Stats>(StatsNotifier.new);
