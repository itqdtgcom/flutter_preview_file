import '../text_code/text_code_file_view.dart';

/// 应用内可预览的文档类别（供宿主映射路由 / 工具栏，与 [FileToolsDocumentType] 独立）。
enum PreviewDocumentKind {
  pdf,
  word,
  excel,
  textCode,
  zipArchive,
  unsupported,
}

/// 按文件名后缀与 [TextCodeFileView] 规则判断预览类型。
PreviewDocumentKind resolvePreviewDocumentKind(String fileName) {
  if (TextCodeFileView.supportsFileName(fileName)) {
    return PreviewDocumentKind.textCode;
  }
  final lower = fileName.toLowerCase();
  final dot = lower.lastIndexOf('.');
  if (dot < 0 || dot == lower.length - 1) {
    return PreviewDocumentKind.unsupported;
  }
  final ext = lower.substring(dot);
  switch (ext) {
    case '.pdf':
      return PreviewDocumentKind.pdf;
    case '.doc':
    case '.docx':
      return PreviewDocumentKind.word;
    case '.xlsx':
    case '.xltx':
      return PreviewDocumentKind.excel;
    case '.zip':
      return PreviewDocumentKind.zipArchive;
    default:
      return PreviewDocumentKind.unsupported;
  }
}
