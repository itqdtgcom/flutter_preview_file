// UI adapted from universal_file_previewer ZipRenderer (MIT).

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'zip_archive_parser.dart';

/// Called after a non-directory entry is extracted to a temp file.
/// [size] is the uncompressed byte length written to [extractedPath].
typedef ZipArchiveInnerFileReady = Future<void> Function(
  ZipArchiveEntry entry,
  String extractedPath,
  int size,
);

/// Browsable ZIP directory tree (local headers only; listing / navigation).
///
/// Optional [onInnerFileReady]: when set, tapping a file extracts it (stored /
/// deflate) to a temp path and invokes the callback. Large archives load the
/// whole file into memory — suitable for typical chat attachments.
class ZipArchiveView extends StatefulWidget {
  const ZipArchiveView({
    super.key,
    required this.filePath,
    this.onInnerFileReady,
  });

  final String filePath;

  /// Host handles media / document preview / external open.
  final ZipArchiveInnerFileReady? onInnerFileReady;

  @override
  State<ZipArchiveView> createState() => _ZipArchiveViewState();
}

class _ZipArchiveViewState extends State<ZipArchiveView> {
  Uint8List? _zipBytes;
  List<ZipArchiveEntry>? _entries;
  String? _error;
  String _currentPath = '';
  final List<String> _pathStack = [];
  bool _extracting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _safeFileName(String name) {
    var s = name.replaceAll(RegExp(r'[/\\]'), '_').trim();
    if (s.isEmpty) s = 'file';
    if (s.length > 160) s = s.substring(s.length - 160);
    return s;
  }

  Future<void> _load() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        if (mounted) {
          setState(() => _error = 'File not found');
        }
        return;
      }
      final bytes = await file.readAsBytes();
      final entries = ZipArchiveParser.listEntriesFromBytes(bytes);
      if (mounted) {
        setState(() {
          _zipBytes = bytes;
          _entries = entries;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _handleFileTap(ZipArchiveEntry entry) async {
    final cb = widget.onInnerFileReady;
    if (cb == null || entry.isDirectory) return;
    final bytes = _zipBytes;
    if (bytes == null) return;
    setState(() => _extracting = true);
    try {
      final raw = ZipArchiveParser.decodeEntryPayload(bytes, entry);
      final tmp = File(
        '${Directory.systemTemp.path}/flutter_preview_zip_'
        '${DateTime.now().microsecondsSinceEpoch}_${_safeFileName(entry.displayName)}',
      );
      await tmp.writeAsBytes(raw);
      if (!mounted) return;
      setState(() => _extracting = false);
      await cb(entry, tmp.path, raw.length);
    } catch (e) {
      if (mounted) {
        setState(() => _extracting = false);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  List<ZipArchiveEntry> get _visibleEntries {
    if (_entries == null) return [];
    return _entries!.where((e) {
      if (_currentPath.isEmpty) {
        final parts = e.name.split('/').where((s) => s.isNotEmpty).toList();
        return parts.length == 1 || (e.isDirectory && parts.length == 1);
      }
      if (!e.name.startsWith(_currentPath)) return false;
      final relative = e.name.substring(_currentPath.length);
      final parts = relative.split('/').where((s) => s.isNotEmpty).toList();
      return parts.length == 1 || (e.isDirectory && parts.length == 1);
    }).toList();
  }

  void _enterFolder(ZipArchiveEntry entry) {
    _pathStack.add(_currentPath);
    setState(() => _currentPath = entry.name);
  }

  void _goBack() {
    if (_pathStack.isEmpty) return;
    setState(() => _currentPath = _pathStack.removeLast());
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  String get _archiveBaseName {
    final p = widget.filePath.replaceAll(r'\', '/');
    final i = p.lastIndexOf('/');
    return i < 0 ? p : p.substring(i + 1);
  }

  IconData _iconFor(ZipArchiveEntry e) {
    if (e.isDirectory) return Icons.folder_outlined;
    final ext = e.extension;
    return switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image_outlined,
      'mp4' || 'mov' || 'avi' || 'mkv' => Icons.video_file_outlined,
      'mp3' || 'wav' || 'aac' || 'flac' => Icons.audio_file_outlined,
      'pdf' => Icons.picture_as_pdf_outlined,
      'dart' || 'py' || 'js' || 'ts' || 'kt' => Icons.code_outlined,
      'txt' || 'md' || 'log' => Icons.article_outlined,
      'json' || 'xml' || 'yaml' || 'yml' => Icons.data_object_outlined,
      'zip' || 'rar' || 'tar' || 'gz' => Icons.folder_zip_outlined,
      'docx' || 'doc' => Icons.description_outlined,
      'xlsx' || 'xls' => Icons.table_chart_outlined,
      'pptx' || 'ppt' => Icons.slideshow_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: scheme.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurface),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final visible = _visibleEntries;
    final totalFiles = _entries!.where((e) => !e.isDirectory).length;
    final totalSize =
        _entries!.fold<int>(0, (s, e) => s + e.uncompressedSize);

    return Stack(
      children: [
        Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (_pathStack.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 22),
                    onPressed: _goBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40),
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(Icons.folder_zip_outlined, size: 22, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentPath.isEmpty
                        ? '$_archiveBaseName · $totalFiles files · ${_formatSize(totalSize)}'
                        : _currentPath,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    'Empty',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: scheme.outlineVariant),
                  itemBuilder: (ctx, i) {
                    final entry = visible[i];
                    return ListTile(
                      leading: Icon(
                        _iconFor(entry),
                        color: scheme.primary,
                      ),
                      title: Text(
                        entry.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        entry.isDirectory
                            ? 'Folder'
                            : '${_formatSize(entry.uncompressedSize)}'
                                '${entry.compressionRatio > 0 ? ' · ${entry.compressionRatio.toStringAsFixed(0)}% smaller' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: entry.isDirectory
                          ? Icon(Icons.chevron_right, color: scheme.outline)
                          : null,
                      onTap: entry.isDirectory
                          ? () => _enterFolder(entry)
                          : (widget.onInnerFileReady != null
                              ? () => unawaited(_handleFileTap(entry))
                              : null),
                    );
                  },
                ),
        ),
      ],
    ),
        if (_extracting)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: const Color(0x33000000),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
