import 'package:flutter/material.dart';

/// 文本 / 代码预览配置（源自 universal_file_previewer，纯 Dart 渲染使用）。
class TextPreviewConfig {
  final int maxTextFileSizeBytes;
  final TextSyntaxTheme syntaxTheme;

  const TextPreviewConfig({
    this.maxTextFileSizeBytes = 5 * 1024 * 1024,
    this.syntaxTheme = TextSyntaxTheme.dark,
  });
}

/// 代码高亮主题
enum TextSyntaxTheme {
  dark,
  light,
  dracula,
  monokai,
}

extension TextSyntaxThemeX on TextSyntaxTheme {
  Color get background => switch (this) {
        TextSyntaxTheme.dark => const Color(0xFF1E1E1E),
        TextSyntaxTheme.light => const Color(0xFFF5F5F5),
        TextSyntaxTheme.dracula => const Color(0xFF282A36),
        TextSyntaxTheme.monokai => const Color(0xFF272822),
      };

  Color get defaultText => switch (this) {
        TextSyntaxTheme.dark => const Color(0xFFD4D4D4),
        TextSyntaxTheme.light => const Color(0xFF1E1E1E),
        TextSyntaxTheme.dracula => const Color(0xFFF8F8F2),
        TextSyntaxTheme.monokai => const Color(0xFFF8F8F2),
      };

  Color get keyword => switch (this) {
        TextSyntaxTheme.dark => const Color(0xFF569CD6),
        TextSyntaxTheme.light => const Color(0xFF0000FF),
        TextSyntaxTheme.dracula => const Color(0xFFFF79C6),
        TextSyntaxTheme.monokai => const Color(0xFFF92672),
      };

  Color get string => switch (this) {
        TextSyntaxTheme.dark => const Color(0xFFCE9178),
        TextSyntaxTheme.light => const Color(0xFFA31515),
        TextSyntaxTheme.dracula => const Color(0xFFF1FA8C),
        TextSyntaxTheme.monokai => const Color(0xFFE6DB74),
      };

  Color get comment => switch (this) {
        TextSyntaxTheme.dark => const Color(0xFF6A9955),
        TextSyntaxTheme.light => const Color(0xFF008000),
        TextSyntaxTheme.dracula => const Color(0xFF6272A4),
        TextSyntaxTheme.monokai => const Color(0xFF75715E),
      };

  Color get number => switch (this) {
        TextSyntaxTheme.dark => const Color(0xFFB5CEA8),
        TextSyntaxTheme.light => const Color(0xFF098658),
        TextSyntaxTheme.dracula => const Color(0xFFBD93F9),
        TextSyntaxTheme.monokai => const Color(0xFFAE81FF),
      };

  Color get className => switch (this) {
        TextSyntaxTheme.dark => const Color(0xFF4EC9B0),
        TextSyntaxTheme.light => const Color(0xFF267F99),
        TextSyntaxTheme.dracula => const Color(0xFF8BE9FD),
        TextSyntaxTheme.monokai => const Color(0xFF66D9EF),
      };
}
