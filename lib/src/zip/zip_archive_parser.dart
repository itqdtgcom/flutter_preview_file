// ZIP local header parsing adapted from universal_file_previewer (MIT).
// https://github.com/.../universal_file_previewer

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:gbk_codec/gbk_codec.dart';

/// Pure Dart ZIP local file header scan (no `archive` package).
class ZipArchiveParser {
  static const int _localFileHeaderSig = 0x04034b50;
  static const int _headerSize = 30;

  /// PKZIP App Note: bit 11 = language encoding flag (UTF-8 file name / comment).
  static const int _gpbfUtf8 = 0x800;

  static Future<List<ZipArchiveEntry>> listEntries(File file) async {
    final bytes = await file.readAsBytes();
    return _parseEntries(bytes);
  }

  static List<ZipArchiveEntry> listEntriesFromBytes(Uint8List bytes) {
    return _parseEntries(bytes);
  }

  static List<ZipArchiveEntry> _parseEntries(Uint8List bytes) {
    final entries = <ZipArchiveEntry>[];
    var offset = 0;

    while (offset + _headerSize <= bytes.length) {
      final sig = _readUint32(bytes, offset);
      if (sig != _localFileHeaderSig) {
        offset++;
        continue;
      }

      final compressedSize = _readUint32(bytes, offset + 18);
      final uncompressedSize = _readUint32(bytes, offset + 22);
      final fileNameLen = _readUint16(bytes, offset + 26);
      final extraFieldLen = _readUint16(bytes, offset + 28);

      if (offset + _headerSize + fileNameLen > bytes.length) {
        break;
      }

      final nameBytes = bytes.sublist(
        offset + _headerSize,
        offset + _headerSize + fileNameLen,
      );

      final gpbf = _readUint16(bytes, offset + 6);
      final utf8Efs = (gpbf & _gpbfUtf8) != 0;
      String fileName;
      try {
        fileName = _decodeZipEntryFileName(nameBytes, utf8Efs);
      } catch (_) {
        fileName = 'unknown_${entries.length}';
      }
      fileName = fileName.replaceAll(r'\', '/');

      final compressionMethod = _readUint16(bytes, offset + 8);
      final lastModTime = _readUint16(bytes, offset + 10);
      final lastModDate = _readUint16(bytes, offset + 12);

      entries.add(
        ZipArchiveEntry(
          name: fileName,
          compressedSize: compressedSize,
          uncompressedSize: uncompressedSize,
          compressionMethod: compressionMethod,
          isDirectory:
              fileName.endsWith('/') || fileName.endsWith(r'\'),
          dataOffset: offset + _headerSize + fileNameLen + extraFieldLen,
          modifiedDate: _dosDateTimeToDateTime(lastModDate, lastModTime),
        ),
      );

      offset += _headerSize + fileNameLen + extraFieldLen + compressedSize;
    }

    return entries;
  }

  /// Decompresses one entry's payload from the full ZIP bytes (local header layout).
  ///
  /// Supports stored (0) and deflate (8). Throws on unsupported compression or
  /// out-of-range offsets.
  static Uint8List decodeEntryPayload(Uint8List zipBytes, ZipArchiveEntry entry) {
    if (entry.isDirectory) {
      throw FormatException('ZIP entry is a directory');
    }
    final start = entry.dataOffset;
    final end = start + entry.compressedSize;
    if (start < 0 || end > zipBytes.length || start > end) {
      throw FormatException('ZIP entry payload out of range');
    }
    final compressed = zipBytes.sublist(start, end);
    switch (entry.compressionMethod) {
      case 0:
        return Uint8List.fromList(compressed);
      case 8:
        final hint = entry.uncompressedSize > 0 ? entry.uncompressedSize : null;
        final out = Inflate(compressed, hint).getBytes();
        return Uint8List.fromList(out);
      default:
        throw UnsupportedError(
          'ZIP compression method ${entry.compressionMethod} is not supported',
        );
    }
  }

  /// Decodes entry path: EFS → UTF-8; legacy zip → strict UTF-8, else GBK (common
  /// on Chinese Windows) with [String.fromCharCodes] as last resort.
  static String _decodeZipEntryFileName(Uint8List raw, bool utf8Efs) {
    if (raw.isEmpty) return '';
    if (utf8Efs) {
      try {
        return utf8.decode(raw, allowMalformed: false);
      } catch (_) {
        return _decodeZipEntryFileNameLegacy(raw);
      }
    }
    return _decodeZipEntryFileNameLegacy(raw);
  }

  static String _decodeZipEntryFileNameLegacy(Uint8List raw) {
    try {
      return utf8.decode(raw, allowMalformed: false);
    } catch (_) {
      try {
        return gbk_bytes.decode(raw);
      } catch (_) {
        return String.fromCharCodes(raw);
      }
    }
  }

  static int _readUint16(Uint8List b, int o) => b[o] | (b[o + 1] << 8);

  static int _readUint32(Uint8List b, int o) =>
      b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

  static DateTime _dosDateTimeToDateTime(int date, int time) {
    try {
      final year = ((date >> 9) & 0x7f) + 1980;
      final month = (date >> 5) & 0x0f;
      final day = date & 0x1f;
      final hour = (time >> 11) & 0x1f;
      final minute = (time >> 5) & 0x3f;
      final second = (time & 0x1f) * 2;
      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return DateTime.now();
    }
  }
}

class ZipArchiveEntry {
  const ZipArchiveEntry({
    required this.name,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.compressionMethod,
    required this.isDirectory,
    required this.dataOffset,
    required this.modifiedDate,
  });

  final String name;
  final int compressedSize;
  final int uncompressedSize;
  final int compressionMethod;
  final bool isDirectory;
  final int dataOffset;
  final DateTime modifiedDate;

  String get displayName =>
      name.split('/').where((s) => s.isNotEmpty).last;

  String get extension => isDirectory
      ? ''
      : name.split('.').last.toLowerCase();

  double get compressionRatio => uncompressedSize == 0
      ? 0
      : (1 - compressedSize / uncompressedSize) * 100;
}
