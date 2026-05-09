import 'package:flutter/material.dart';

import 'text_preview_config.dart';

/// Pure Dart syntax tokenizer（源自 universal_file_previewer）.
class SyntaxTokenizer {
  static const Map<String, List<String>> _keywords = {
    'dart': [
      'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case',
      'catch', 'class', 'const', 'continue', 'covariant', 'default', 'deferred',
      'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension',
      'external', 'factory', 'false', 'final', 'finally', 'for', 'function',
      'get', 'hide', 'if', 'implements', 'import', 'in', 'interface', 'is',
      'late', 'library', 'mixin', 'new', 'null', 'of', 'on', 'operator',
      'part', 'required', 'rethrow', 'return', 'sealed', 'set', 'show',
      'static', 'super', 'switch', 'sync', 'this', 'throw', 'true', 'try',
      'typedef', 'var', 'void', 'when', 'while', 'with', 'yield',
      'String', 'int', 'double', 'bool', 'List', 'Map', 'Set', 'Future',
      'Stream', 'Widget', 'BuildContext', 'StatelessWidget', 'StatefulWidget',
    ],
    'python': [
      'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue',
      'def', 'del', 'elif', 'else', 'except', 'False', 'finally', 'for',
      'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'None',
      'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'True', 'try',
      'while', 'with', 'yield', 'int', 'str', 'list', 'dict', 'set',
      'tuple', 'bool', 'float', 'print', 'len', 'range', 'type', 'self',
    ],
    'javascript': [
      'async', 'await', 'break', 'case', 'catch', 'class', 'const',
      'continue', 'debugger', 'default', 'delete', 'do', 'else', 'export',
      'extends', 'false', 'finally', 'for', 'function', 'if', 'import',
      'in', 'instanceof', 'let', 'new', 'null', 'of', 'return', 'static',
      'super', 'switch', 'this', 'throw', 'true', 'try', 'typeof', 'undefined',
      'var', 'void', 'while', 'with', 'yield', 'console', 'Promise',
    ],
    'kotlin': [
      'abstract', 'actual', 'annotation', 'as', 'break', 'by', 'catch',
      'class', 'companion', 'const', 'constructor', 'continue', 'crossinline',
      'data', 'do', 'dynamic', 'else', 'enum', 'expect', 'external', 'false',
      'final', 'finally', 'for', 'fun', 'get', 'if', 'import', 'in',
      'infix', 'init', 'inline', 'inner', 'interface', 'internal', 'is',
      'lateinit', 'noinline', 'null', 'object', 'open', 'operator', 'out',
      'override', 'package', 'private', 'protected', 'public', 'reified',
      'return', 'sealed', 'set', 'super', 'suspend', 'tailrec', 'this',
      'throw', 'true', 'try', 'typealias', 'typeof', 'val', 'var', 'vararg',
      'when', 'where', 'while', 'String', 'Int', 'Long', 'Double', 'Boolean',
      'List', 'Map', 'Set', 'Any', 'Unit', 'Nothing',
    ],
    'java': [
      'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch',
      'char', 'class', 'const', 'continue', 'default', 'do', 'double',
      'else', 'enum', 'extends', 'false', 'final', 'finally', 'float',
      'for', 'goto', 'if', 'implements', 'import', 'instanceof', 'int',
      'interface', 'long', 'native', 'new', 'null', 'package', 'private',
      'protected', 'public', 'return', 'short', 'static', 'strictfp',
      'super', 'switch', 'synchronized', 'this', 'throw', 'throws',
      'transient', 'true', 'try', 'void', 'volatile', 'while', 'String',
    ],
  };

  static String _languageFromExt(String ext) {
    return switch (ext.toLowerCase()) {
      'dart' => 'dart',
      'py' => 'python',
      'js' || 'ts' || 'jsx' || 'tsx' => 'javascript',
      'kt' || 'kts' => 'kotlin',
      'java' => 'java',
      _ => 'generic',
    };
  }

  static List<TextSpan> tokenize(
    String code,
    String ext,
    TextSyntaxTheme theme,
  ) {
    final language = _languageFromExt(ext);
    final keywords = _keywords[language] ?? [];
    final spans = <TextSpan>[];

    final pattern = RegExp(
      r'(//[^\n]*)'
      r'|(#[^\n]*)'
      r'|(/\*[\s\S]*?\*/)'
      r'|("(?:[^"\\]|\\.)*")'
      r"|('(?:[^'\\]|\\.)*')"
      r'|(`(?:[^`\\]|\\.)*`)'
      r'|(\b\d+\.?\d*\b)'
      r'|(\b[A-Z][a-zA-Z0-9_]*\b)'
      r'|(\b[a-zA-Z_]\w*\b)',
    );

    var last = 0;

    for (final match in pattern.allMatches(code)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: code.substring(last, match.start),
          style: TextStyle(color: theme.defaultText),
        ));
      }

      final word = match.group(0)!;
      late Color color;

      if (match.group(1) != null || match.group(2) != null || match.group(3) != null) {
        color = theme.comment;
      } else if (match.group(4) != null || match.group(5) != null || match.group(6) != null) {
        color = theme.string;
      } else if (match.group(7) != null) {
        color = theme.number;
      } else if (match.group(8) != null) {
        color = theme.className;
      } else if (keywords.contains(word)) {
        color = theme.keyword;
      } else {
        color = theme.defaultText;
      }

      spans.add(TextSpan(
        text: word,
        style: TextStyle(color: color),
      ));

      last = match.end;
    }

    if (last < code.length) {
      spans.add(TextSpan(
        text: code.substring(last),
        style: TextStyle(color: theme.defaultText),
      ));
    }

    return spans;
  }
}
