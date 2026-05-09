// Pure Dart Markdown parser（源自 universal_file_previewer）.

class MarkdownParser {
  static List<MarkdownNode> parse(String text) {
    final nodes = <MarkdownNode>[];
    final lines = text.split('\n');
    var inCodeBlock = false;
    var codeBuffer = '';
    var codeLang = '';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('```')) {
        if (inCodeBlock) {
          nodes.add(MarkdownNode.codeBlock(codeBuffer.trimRight(), codeLang));
          codeBuffer = '';
          codeLang = '';
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
          codeLang = line.substring(3).trim();
        }
        continue;
      }

      if (inCodeBlock) {
        codeBuffer += '$line\n';
        continue;
      }

      if (line.startsWith('### ')) {
        nodes.add(MarkdownNode.heading(line.substring(4), 3));
      } else if (line.startsWith('## ')) {
        nodes.add(MarkdownNode.heading(line.substring(3), 2));
      } else if (line.startsWith('# ')) {
        nodes.add(MarkdownNode.heading(line.substring(2), 1));
      } else if (line.startsWith('> ')) {
        nodes.add(MarkdownNode.blockquote(line.substring(2)));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        nodes.add(MarkdownNode.bullet(line.substring(2)));
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final content = line.replaceFirst(RegExp(r'^\d+\. '), '');
        nodes.add(MarkdownNode.numbered(content));
      } else if (line == '---' || line == '***' || line == '___') {
        nodes.add(MarkdownNode.divider());
      } else if (line.trim().isEmpty) {
        nodes.add(MarkdownNode.spacer());
      } else {
        nodes.add(MarkdownNode.paragraph(line));
      }
    }

    return nodes;
  }

  static List<InlineSegment> parseInline(String text) {
    final segments = <InlineSegment>[];
    final pattern = RegExp(
      r'(\*\*(.+?)\*\*)'
      r'|(\*(.+?)\*)'
      r'|(`(.+?)`)'
      r'|(\[(.+?)\]\((.+?)\))',
    );

    var last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        segments.add(InlineSegment.plain(text.substring(last, match.start)));
      }

      if (match.group(1) != null) {
        segments.add(InlineSegment.bold(match.group(2)!));
      } else if (match.group(3) != null) {
        segments.add(InlineSegment.italic(match.group(4)!));
      } else if (match.group(5) != null) {
        segments.add(InlineSegment.code(match.group(6)!));
      } else if (match.group(7) != null) {
        segments.add(InlineSegment.link(match.group(8)!, match.group(9)!));
      }

      last = match.end;
    }

    if (last < text.length) {
      segments.add(InlineSegment.plain(text.substring(last)));
    }

    return segments;
  }
}

enum NodeType {
  heading,
  paragraph,
  bullet,
  numbered,
  blockquote,
  codeBlock,
  divider,
  spacer,
}

class MarkdownNode {
  final NodeType type;
  final String text;
  final int level;
  final String lang;

  const MarkdownNode._({
    required this.type,
    this.text = '',
    this.level = 1,
    this.lang = '',
  });

  factory MarkdownNode.heading(String text, int level) =>
      MarkdownNode._(type: NodeType.heading, text: text, level: level);

  factory MarkdownNode.paragraph(String text) =>
      MarkdownNode._(type: NodeType.paragraph, text: text);

  factory MarkdownNode.bullet(String text) =>
      MarkdownNode._(type: NodeType.bullet, text: text);

  factory MarkdownNode.numbered(String text) =>
      MarkdownNode._(type: NodeType.numbered, text: text);

  factory MarkdownNode.blockquote(String text) =>
      MarkdownNode._(type: NodeType.blockquote, text: text);

  factory MarkdownNode.codeBlock(String text, String lang) =>
      MarkdownNode._(type: NodeType.codeBlock, text: text, lang: lang);

  factory MarkdownNode.divider() => const MarkdownNode._(type: NodeType.divider);

  factory MarkdownNode.spacer() => const MarkdownNode._(type: NodeType.spacer);
}

enum InlineType { plain, bold, italic, code, link }

class InlineSegment {
  final InlineType type;
  final String text;
  final String? href;

  const InlineSegment._(this.type, this.text, {this.href});

  factory InlineSegment.plain(String text) => InlineSegment._(InlineType.plain, text);
  factory InlineSegment.bold(String text) => InlineSegment._(InlineType.bold, text);
  factory InlineSegment.italic(String text) => InlineSegment._(InlineType.italic, text);
  factory InlineSegment.code(String text) => InlineSegment._(InlineType.code, text);
  factory InlineSegment.link(String text, String href) =>
      InlineSegment._(InlineType.link, text, href: href);
}
