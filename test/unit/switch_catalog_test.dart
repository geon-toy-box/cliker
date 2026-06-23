import 'package:cliker/domain/switch_type.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The full expected catalog, in exact spec order, with every field the spec
/// pins down. Tests assert the real [SwitchCatalog.all] matches this row-for-row.
typedef _Row = ({
  String id,
  String nameKo,
  String nameEn,
  SwitchKind kind,
  int forceCn,
  int loudness,
  Color stem,
  Color led,
  double haptic,
});

const List<_Row> _expected = <_Row>[
  (
    id: 'blue',
    nameKo: '청축',
    nameEn: 'Blue',
    kind: SwitchKind.clicky,
    forceCn: 50,
    loudness: 5,
    stem: AppColors.switchBlue,
    led: AppColors.neonCyan,
    haptic: 1.0,
  ),
  (
    id: 'brown',
    nameKo: '갈축',
    nameEn: 'Brown',
    kind: SwitchKind.tactile,
    forceCn: 45,
    loudness: 3,
    stem: AppColors.switchBrown,
    led: AppColors.neonOrange,
    haptic: 0.7,
  ),
  (
    id: 'red',
    nameKo: '적축',
    nameEn: 'Red',
    kind: SwitchKind.linear,
    forceCn: 45,
    loudness: 2,
    stem: AppColors.switchRed,
    led: AppColors.neonMagenta,
    haptic: 0.45,
  ),
  (
    id: 'black',
    nameKo: '흑축',
    nameEn: 'Black',
    kind: SwitchKind.linear,
    forceCn: 60,
    loudness: 2,
    stem: AppColors.switchBlack,
    led: AppColors.neonGreen,
    haptic: 0.6,
  ),
  (
    id: 'white',
    nameKo: '백축',
    nameEn: 'White',
    kind: SwitchKind.clicky,
    forceCn: 55,
    loudness: 4,
    stem: AppColors.switchWhite,
    led: AppColors.neonCyan,
    haptic: 0.85,
  ),
  (
    id: 'gray',
    nameKo: '회축',
    nameEn: 'Gray',
    kind: SwitchKind.tactile,
    forceCn: 80,
    loudness: 3,
    stem: AppColors.switchGray,
    led: AppColors.neonYellow,
    haptic: 0.95,
  ),
  (
    id: 'clear',
    nameKo: '클리어축',
    nameEn: 'Clear',
    kind: SwitchKind.tactile,
    forceCn: 65,
    loudness: 3,
    stem: AppColors.switchClear,
    led: AppColors.neonPurple,
    haptic: 0.8,
  ),
  (
    id: 'silentRed',
    nameKo: '저소음 적축',
    nameEn: 'Silent Red',
    kind: SwitchKind.linear,
    forceCn: 45,
    loudness: 1,
    stem: AppColors.switchSilentRed,
    led: AppColors.neonMagenta,
    haptic: 0.4,
  ),
  (
    id: 'silentBlack',
    nameKo: '저소음 흑축',
    nameEn: 'Silent Black',
    kind: SwitchKind.linear,
    forceCn: 60,
    loudness: 1,
    stem: AppColors.switchSilentBlack,
    led: AppColors.neonGreen,
    haptic: 0.55,
  ),
  (
    id: 'speedSilver',
    nameKo: '스피드 은축',
    nameEn: 'Speed Silver',
    kind: SwitchKind.linear,
    forceCn: 45,
    loudness: 2,
    stem: AppColors.switchSpeedSilver,
    led: AppColors.neonCyan,
    haptic: 0.5,
  ),
  (
    id: 'darkGray',
    nameKo: '진회축',
    nameEn: 'Dark Gray',
    kind: SwitchKind.linear,
    forceCn: 80,
    loudness: 2,
    stem: AppColors.switchDarkGray,
    led: AppColors.neonYellow,
    haptic: 0.9,
  ),
  (
    id: 'yellow',
    nameKo: '황축',
    nameEn: 'Yellow',
    kind: SwitchKind.linear,
    forceCn: 50,
    loudness: 2,
    stem: AppColors.switchYellow,
    led: AppColors.neonYellow,
    haptic: 0.5,
  ),
  (
    id: 'magnetic',
    nameKo: '자석축',
    nameEn: 'Magnetic',
    kind: SwitchKind.linear,
    forceCn: 40,
    loudness: 1,
    stem: AppColors.switchMagnetic,
    led: AppColors.neonCyan,
    haptic: 0.45,
  ),
];

void main() {
  group('SwitchCatalog.all (AC1)', () {
    test('exposes the thirteen switches in canonical order', () {
      expect(
        SwitchCatalog.all.map((SwitchType s) => s.id).toList(),
        _expected.map((_Row r) => r.id).toList(),
      );
      expect(SwitchCatalog.all, hasLength(13));
    });

    test('the last two entries are yellow then magnetic (T014 additions)', () {
      expect(SwitchCatalog.all[11].id, 'yellow');
      expect(SwitchCatalog.all[12].id, 'magnetic');
    });

    test('ids are unique', () {
      final Set<String> ids = SwitchCatalog.all
          .map((SwitchType s) => s.id)
          .toSet();
      expect(ids, hasLength(SwitchCatalog.all.length));
    });

    test('every field matches the spec, row for row', () {
      for (int i = 0; i < _expected.length; i++) {
        final SwitchType s = SwitchCatalog.all[i];
        final _Row r = _expected[i];
        expect(s.id, r.id, reason: 'row $i id');
        expect(s.nameKo, r.nameKo, reason: '${r.id} nameKo');
        expect(s.nameEn, r.nameEn, reason: '${r.id} nameEn');
        expect(s.kind, r.kind, reason: '${r.id} kind');
        expect(s.forceCn, r.forceCn, reason: '${r.id} forceCn');
        expect(s.loudness, r.loudness, reason: '${r.id} loudness');
        expect(s.stemColor, same(r.stem), reason: '${r.id} stemColor token');
        expect(s.defaultLed, same(r.led), reason: '${r.id} defaultLed token');
        expect(s.hapticStrength, r.haptic, reason: '${r.id} haptic');
      }
    });

    test('every switch has non-empty names, description, recommendedFor', () {
      for (final SwitchType s in SwitchCatalog.all) {
        expect(s.nameKo, isNotEmpty, reason: '${s.id} nameKo');
        expect(s.nameEn, isNotEmpty, reason: '${s.id} nameEn');
        expect(s.description, isNotEmpty, reason: '${s.id} description');
        expect(s.recommendedFor, isNotEmpty, reason: '${s.id} recommendedFor');
      }
    });

    test('loudness is in [1, 5] for every switch (AC1)', () {
      for (final SwitchType s in SwitchCatalog.all) {
        expect(
          s.loudness,
          greaterThanOrEqualTo(1),
          reason: '${s.id} loudness >= 1',
        );
        expect(
          s.loudness,
          lessThanOrEqualTo(5),
          reason: '${s.id} loudness <= 5',
        );
      }
    });

    test('every defaultLed is a member of AppColors.ledPalette', () {
      for (final SwitchType s in SwitchCatalog.all) {
        expect(
          AppColors.ledPalette,
          contains(s.defaultLed),
          reason: '${s.id} defaultLed',
        );
      }
    });

    test('hapticStrength is in (0, 1]', () {
      for (final SwitchType s in SwitchCatalog.all) {
        expect(s.hapticStrength, greaterThan(0.0), reason: '${s.id} > 0');
        expect(
          s.hapticStrength,
          lessThanOrEqualTo(1.0),
          reason: '${s.id} <= 1',
        );
      }
    });

    test('forceCn is a sensible positive actuation force', () {
      for (final SwitchType s in SwitchCatalog.all) {
        expect(s.forceCn, greaterThan(0), reason: '${s.id} force > 0');
        expect(s.forceCn, lessThanOrEqualTo(120), reason: '${s.id} force sane');
      }
    });
  });

  group('SwitchCatalog lookup (AC1)', () {
    test('byId returns the matching switch for every catalog id', () {
      for (final SwitchType s in SwitchCatalog.all) {
        expect(SwitchCatalog.byId(s.id), same(s), reason: 'byId(${s.id})');
      }
    });

    test('byId returns defaultSwitch for an unknown id', () {
      expect(SwitchCatalog.byId('bogus'), same(SwitchCatalog.defaultSwitch));
      expect(SwitchCatalog.byId(''), same(SwitchCatalog.defaultSwitch));
    });

    test('defaultSwitch equals the first catalog entry (blue)', () {
      expect(SwitchCatalog.defaultSwitch, same(SwitchCatalog.all.first));
      expect(SwitchCatalog.defaultSwitch, same(SwitchCatalog.blue));
      expect(SwitchCatalog.defaultSwitch.id, 'blue');
    });
  });

  group('SwitchType value semantics', () {
    test('equality and hashCode are keyed on id', () {
      const SwitchType a = SwitchType(
        id: 'blue',
        nameKo: 'x',
        nameEn: 'y',
        kind: SwitchKind.linear,
        forceCn: 1,
        description: 'z',
        recommendedFor: 'w',
        loudness: 3,
        stemColor: AppColors.switchBlue,
        defaultLed: AppColors.neonCyan,
        downAsset: 'a',
        upAsset: 'b',
        hapticStrength: 0.5,
      );
      expect(a, equals(SwitchCatalog.blue));
      expect(a.hashCode, SwitchCatalog.blue.hashCode);
      expect(SwitchCatalog.blue == SwitchCatalog.red, isFalse);
    });
  });
}
