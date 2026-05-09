import 'dart:io';

import 'package:flutter/material.dart';

import '../common/preview_builders.dart';
import '../common/preview_placeholder.dart';
import 'text_preview_config.dart';
import 'text_renderers.dart';

enum _TextBodyKind {
  plain,
  markdown,
  json,
  csv,
  code,
}

/// 纯 Dart 文本 / 代码预览（整合自 universal_file_previewer 能力）。
///
/// 支持：常见源码扩展名、TXT/LOG/INI、Markdown、JSON 树、CSV 表格、XML/HTML 按纯文本。
class TextCodeFileView extends StatelessWidget {
  const TextCodeFileView({
    super.key,
    required this.filePath,
    this.config = const TextPreviewConfig(),
    this.loadingBuilder,
    this.messageBuilder,
  });

  final String filePath;
  final TextPreviewConfig config;
  final PreviewLoadingBuilder? loadingBuilder;
  final PreviewMessageBuilder? messageBuilder;

  static final Set<String> _codeExtensions = {
    'dart', 'py', 'js', 'ts', 'jsx', 'tsx', 'kt', 'kts', 'java', 'cpp', 'c', 'h',
    'cs', 'go', 'rs', 'rb', 'php', 'sh', 'swift', 'gradle', 'sql', 'm', 'mm',
    'yaml', 'yml', 'vue', 'svelte', 'scss', 'less', 'css',
    'toml', 'proto', 'proto3', 'pb',
  };

  /// 是否可按文本 / 代码内嵌预览（用于路由）。
  static bool supportsFileName(String fileName) {
    final ext = _extension(fileName);
    if (ext.isEmpty) return false;
    return _bodyKindForExtension(ext) != null;
  }

  static String _extension(String path) {
    final name = path.replaceAll('\\', '/').split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static _TextBodyKind? _bodyKindForExtension(String ext) {
    switch (ext) {
      case 'md':
      case 'markdown':
        return _TextBodyKind.markdown;
      case 'json':
        return _TextBodyKind.json;
      case 'csv':
        return _TextBodyKind.csv;
      case 'txt':
      case 'log':
      case 'ini':
      case 'conf':
      case 'cfg':
      case 'xml':
      case 'html':
      case 'htm':
      case 'svg':
      case 'json5':
      case 'jsonc':
        return _TextBodyKind.plain;
      default:
        if (_codeExtensions.contains(ext)) {
          return _TextBodyKind.code;
        }
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (filePath.isEmpty) {
      return _message(context, 'File path is empty.');
    }
    final file = File(filePath);
    if (!file.existsSync()) {
      return _message(context, 'The source file is no longer available.');
    }

    final ext = _extension(filePath);
    final kind = _bodyKindForExtension(ext);
    if (kind == null) {
      return _message(context, 'Unsupported text format: .$ext');
    }

    return switch (kind) {
      _TextBodyKind.plain => TextRenderer(file: file, config: config),
      _TextBodyKind.markdown => MarkdownRenderer(file: file, config: config),
      _TextBodyKind.json => JsonRenderer(file: file, config: config),
      _TextBodyKind.csv => CsvRenderer(file: file, config: config),
      _TextBodyKind.code => CodeRenderer(file: file, config: config),
    };
  }

  Widget _message(BuildContext context, String message) {
    return messageBuilder?.call(context, message) ??
        PreviewPlaceholder(message: message);
  }
}
