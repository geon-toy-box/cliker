import 'package:cliker/domain/switch_type.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SwitchCatalog.all (AC1)', () {
    test('exposes the four switches in canonical order', () {
      expect(SwitchCatalog.all.map((SwitchType s) => s.id).toList(), <String>[
        'blue',
        'brown',
        'red',
        'black',
      ]);
    });

    test('ids are unique', () {
      final Set<String> ids = SwitchCatalog.all
          .map((SwitchType s) => s.id)
          .toSet();
      expect(ids, hasLength(SwitchCatalog.all.length));
    });

    test('every switch has non-empty names and description', () {
      for (final SwitchType s in SwitchCatalog.all) {
        expect(s.nameKo, isNotEmpty, reason: '${s.id} nameKo');
        expect(s.nameEn, isNotEmpty, reason: '${s.id} nameEn');
        expect(s.description, isNotEmpty, reason: '${s.id} description');
      }
    });

    test('stemColor matches the corresponding AppColors.switch* token', () {
      final Map<String, Color> expectedStem = <String, Color>{
        'blue': AppColors.switchBlue,
        'brown': AppColors.switchBrown,
        'red': AppColors.switchRed,
        'black': AppColors.switchBlack,
      };
      for (final SwitchType s in SwitchCatalog.all) {
        expect(s.stemColor, same(expectedStem[s.id]), reason: '${s.id} stem');
      }
    });

    test('defaultLed is a member of AppColors.ledPalette', () {
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
        expect(
          s.hapticStrength,
          greaterThan(0.0),
          reason: '${s.id} haptic > 0',
        );
        expect(
          s.hapticStrength,
          lessThanOrEqualTo(1.0),
          reason: '${s.id} haptic <= 1',
        );
      }
    });
  });

  group('SwitchCatalog lookup (AC2)', () {
    test('byId returns the matching switch', () {
      expect(SwitchCatalog.byId('red'), same(SwitchCatalog.red));
      expect(SwitchCatalog.byId('blue'), same(SwitchCatalog.blue));
      expect(SwitchCatalog.byId('brown'), same(SwitchCatalog.brown));
      expect(SwitchCatalog.byId('black'), same(SwitchCatalog.black));
    });

    test('byId returns defaultSwitch for an unknown id', () {
      expect(SwitchCatalog.byId('bogus'), same(SwitchCatalog.defaultSwitch));
      expect(SwitchCatalog.byId(''), same(SwitchCatalog.defaultSwitch));
    });

    test('defaultSwitch equals the first catalog entry (blue)', () {
      expect(SwitchCatalog.defaultSwitch, same(SwitchCatalog.all.first));
      expect(SwitchCatalog.defaultSwitch.id, 'blue');
    });
  });

  group('SwitchType value semantics', () {
    test('equality and hashCode are keyed on id', () {
      const SwitchType a = SwitchType(
        id: 'blue',
        nameKo: 'x',
        nameEn: 'y',
        description: 'z',
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
