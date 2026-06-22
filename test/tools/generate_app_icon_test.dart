@Tags(<String>['icon-gen'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cliker/icon/app_icon.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Generates the committed 1024×1024 launcher-icon source PNGs by rendering the
/// pure-code [AppIcon] widget through a [RepaintBoundary] and writing the
/// encoded bytes to `assets/icon/`.
///
/// This is a *generator* test, not a behavioral one: re-running it regenerates
/// `assets/icon/icon.png` (full legacy icon) and `assets/icon/icon_foreground.png`
/// (adaptive foreground). Because [AppIcon] is deterministic, the bytes are
/// stable across runs (same Flutter engine). It is tagged `icon-gen` so it can
/// be selected (`flutter test --tags icon-gen`) without affecting the main
/// unit/widget suites, and it still asserts the produced files are real PNGs of
/// the expected dimensions.
///
/// Both layers are rendered inside a single test so the view sizing and raster
/// pipeline are set up exactly once; `toImage` is awaited under
/// [WidgetTester.runAsync] so the rasterization future actually completes.
const double _edge = AppIcon.defaultSize;

/// PNG 8-byte signature.
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

/// Mounts [child] under a fixed 1:1 [_edge]-square surface, pumps a frame, and
/// rasterizes its [RepaintBoundary] to PNG bytes (under [runAsync] so the raster
/// future resolves). Asserts the result is a 1024×1024 PNG, then writes it to
/// [outPath].
Future<void> _renderTo(
  WidgetTester tester,
  Widget child,
  String outPath,
) async {
  final GlobalKey boundaryKey = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: boundaryKey, child: child));
  await tester.pump();

  final RenderRepaintBoundary boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  late Uint8List png;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    try {
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      expect(data, isNotNull, reason: 'PNG encoding returned null');
      png = data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  });

  expect(png.sublist(0, 8), _pngMagic, reason: '$outPath is not a PNG');
  final ByteData header = ByteData.sublistView(png);
  expect(header.getUint32(16), 1024, reason: '$outPath width');
  expect(header.getUint32(20), 1024, reason: '$outPath height');

  File(outPath).writeAsBytesSync(png, flush: true);
}

void main() {
  testWidgets('renders the launcher-icon source PNGs at 1024x1024 (AC3)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(_edge, _edge);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _renderTo(tester, const AppIcon(), 'assets/icon/icon.png');
    await _renderTo(
      tester,
      const AppIcon.foreground(),
      'assets/icon/icon_foreground.png',
    );
  });
}
