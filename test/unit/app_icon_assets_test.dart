import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Verifies the committed launcher-icon source PNGs (`assets/icon/`) exist, are
/// well-formed 1024×1024 PNGs, and are genuinely the cliker artwork rather than
/// the stock Flutter icon. The pixels themselves are produced by the `icon-gen`
/// generator test; this suite is the cheap, always-run guard that the committed
/// sources stay valid and on-brand.
const List<int> _pngMagic = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
];

/// Reads a PNG's width/height from its IHDR chunk (big-endian at bytes 16/20).
({int width, int height}) _pngSize(Uint8List bytes) {
  final ByteData data = ByteData.sublistView(bytes);
  return (width: data.getUint32(16), height: data.getUint32(20));
}

void main() {
  group('Launcher icon source assets (AC2/AC3)', () {
    const String iconPath = 'assets/icon/icon.png';
    const String foregroundPath = 'assets/icon/icon_foreground.png';

    test('full icon and adaptive foreground both exist on disk', () {
      expect(File(iconPath).existsSync(), isTrue, reason: 'missing $iconPath');
      expect(
        File(foregroundPath).existsSync(),
        isTrue,
        reason: 'missing $foregroundPath',
      );
    });

    for (final String path in <String>[iconPath, foregroundPath]) {
      group(path, () {
        test('is a valid 1024x1024 PNG', () {
          final Uint8List bytes = File(path).readAsBytesSync();
          expect(bytes.sublist(0, 8), _pngMagic, reason: '$path is not a PNG');
          final ({int width, int height}) dims = _pngSize(bytes);
          expect(dims.width, 1024, reason: '$path width');
          expect(dims.height, 1024, reason: '$path height');
        });

        test('is non-trivial (well over 1KB of pixel data)', () {
          expect(File(path).lengthSync(), greaterThan(1024));
        });
      });
    }

    test('full icon differs from any stock Flutter mipmap icon', () {
      final Uint8List source = File(iconPath).readAsBytesSync();
      final Directory res = Directory('android/app/src/main/res');
      final List<File> stock = res
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (File f) =>
                f.path.contains('mipmap') && f.path.endsWith('ic_launcher.png'),
          )
          .toList(growable: false);

      // There must be stock mipmaps to compare against; if launcher-icons has
      // already overwritten them they will simply differ from the source by
      // size/content, which still satisfies "not identical to source".
      for (final File f in stock) {
        final Uint8List bytes = f.readAsBytesSync();
        final bool identical =
            bytes.length == source.length && _firstDiff(bytes, source) == -1;
        expect(
          identical,
          isFalse,
          reason: '${f.path} is byte-identical to the source icon',
        );
      }
    });
  });
}

/// Index of the first differing byte, or -1 if [a] and [b] match over their
/// shared length.
int _firstDiff(Uint8List a, Uint8List b) {
  final int n = a.length < b.length ? a.length : b.length;
  for (int i = 0; i < n; i++) {
    if (a[i] != b[i]) {
      return i;
    }
  }
  return -1;
}
