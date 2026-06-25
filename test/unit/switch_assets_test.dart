import 'dart:io';
import 'dart:typed_data';

import 'package:cliker/domain/switch_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal WAV header fields parsed from raw bytes for verification.
class _WavHeader {
  const _WavHeader({
    required this.audioFormat,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
  });

  final int audioFormat;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
}

/// Parses the canonical RIFF/WAVE header from [bytes].
///
/// Validates the `RIFF`/`WAVE` magic, locates the `fmt ` chunk, and reads the
/// audio-format fields. Throws a [FormatException] if the structure is invalid.
_WavHeader _parseWavHeader(Uint8List bytes) {
  if (bytes.length < 44) {
    throw const FormatException('file too short to hold a WAV header');
  }
  final ByteData data = ByteData.sublistView(bytes);

  String tag(int offset) =>
      String.fromCharCodes(bytes.sublist(offset, offset + 4));

  if (tag(0) != 'RIFF') {
    throw FormatException('missing RIFF magic, got "${tag(0)}"');
  }
  if (tag(8) != 'WAVE') {
    throw FormatException('missing WAVE magic, got "${tag(8)}"');
  }

  // Walk chunks starting after the 12-byte RIFF header to find "fmt ".
  int offset = 12;
  while (offset + 8 <= bytes.length) {
    final String chunkId = tag(offset);
    final int chunkSize = data.getUint32(offset + 4, Endian.little);
    if (chunkId == 'fmt ') {
      final int body = offset + 8;
      if (body + 16 > bytes.length) {
        throw const FormatException('fmt chunk truncated');
      }
      return _WavHeader(
        audioFormat: data.getUint16(body, Endian.little),
        channels: data.getUint16(body + 2, Endian.little),
        sampleRate: data.getUint32(body + 4, Endian.little),
        bitsPerSample: data.getUint16(body + 14, Endian.little),
      );
    }
    // Chunks are word-aligned: skip the body plus a pad byte for odd sizes.
    offset += 8 + chunkSize + (chunkSize.isOdd ? 1 : 0);
  }
  throw const FormatException('no fmt chunk found');
}

/// The phase label of a clip path, e.g. `assets/sounds/blue_onset.wav` → `onset`
/// (the filename stem with the leading `<id>_` removed).
String _labelOf(String path, String id) {
  final String stem = path.split('/').last.replaceAll('.wav', '');
  return stem.replaceFirst('${id}_', '');
}

void main() {
  group('Switch sound assets exist and are valid WAV (AC3)', () {
    // Every clip every switch needs: the combined down/up plus the dynamic
    // onset/click/bottom component stems (clickAsset is null for pure linears).
    final List<({String id, String label, String path})> clips =
        <({String id, String label, String path})>[
          for (final SwitchType s in SwitchCatalog.all)
            for (final String path in s.soundAssets)
              (id: s.id, label: _labelOf(path, s.id), path: path),
        ];

    test('expects 57 clips: 13×(down,up,onset,bottom) + 5×click', () {
      // 13 switches × 4 always-present stems = 52, plus a click stem for the
      // 5 clicky/tactile switches (blue, white, brown, gray, clear) = 57.
      expect(clips, hasLength(57));
      final int clickClips = SwitchCatalog.all
          .where((SwitchType s) => s.clickAsset != null)
          .length;
      expect(clickClips, 5);
    });

    for (final ({String id, String label, String path}) clip in clips) {
      group('${clip.id}_${clip.label} (${clip.path})', () {
        test('exists on disk', () {
          expect(
            File(clip.path).existsSync(),
            isTrue,
            reason: 'missing asset: ${clip.path}',
          );
        });

        test('is larger than 1KB', () {
          final int size = File(clip.path).lengthSync();
          expect(
            size,
            greaterThan(1024),
            reason: '${clip.path} is only $size bytes',
          );
        });

        test('has a valid mono 44100Hz 16-bit WAV header', () {
          final Uint8List bytes = File(clip.path).readAsBytesSync();
          final _WavHeader header = _parseWavHeader(bytes);
          expect(header.audioFormat, 1, reason: 'PCM format expected');
          expect(header.channels, 1, reason: 'mono expected');
          expect(header.sampleRate, 44100, reason: 'sample rate');
          expect(header.bitsPerSample, 16, reason: 'bit depth');
        });
      });
    }
  });
}
