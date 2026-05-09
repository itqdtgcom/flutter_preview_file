# flutter_preview_file

Flutter 插件：在应用内预览与轻量编辑常见办公与文本文件，并提供 ZIP 包目录浏览能力。适用于 IM 附件、文件助手等场景。

**仓库：** [github.com/itqdtgcom/flutter_preview_file](https://github.com/itqdtgcom/flutter_preview_file)

## 功能概览

| 能力 | 说明 |
|------|------|
| **PDF** | 基于 Syncfusion 的 `PdfFileView` 查看；支持选区、注解等（随导出 API）；平台侧支持转 Word、提取文本等（见 `FlutterPreviewFile`） |
| **Word（.doc / .docx）** | `WordFileView` + `WordFileController`，WebView 渲染；可编辑、保存（依赖平台通道） |
| **Excel（.xlsx 等）** | `ExcelFileView` + `ExcelFileController` 表格预览与编辑流 |
| **文本 / 代码** | `TextCodeFileView` 纯 Dart 渲染 Markdown、JSON、源码等（可配置 `TextPreviewConfig`） |
| **ZIP 目录树** | `ZipArchiveView` 仅解析目录结构（local header，不解压整包）；支持 UTF-8 EFS 与 GBK 文件名；可选 `onInnerFileReady` 解压单文件（stored / deflate）供宿主自行打开或转发 |
| **文档类型识别** | `PreviewDocumentKind` / `FlutterPreviewFile.detectPreviewDocumentKind` 按扩展名区分 pdf、word、excel、textCode、zip、unsupported |
| **文件工具** | `FileToolsService`：合并/拆分 PDF、图转 PDF、Word↔PDF 等（与业务配置相关） |

## 依赖与环境

- Dart SDK `>=3.4.0`，Flutter `>=3.3.0`
- 主要依赖：`syncfusion_flutter_pdfviewer`、`webview_flutter`、`archive`、`gbk_codec`（ZIP 中文名）、`excel` 等
- 插件注册平台：**Android / iOS**（`FlutterPreviewFilePlugin`）

## 安装

在宿主 `pubspec.yaml` 中：

```yaml
dependencies:
  flutter_preview_file:
    git:
      url: https://github.com/itqdtgcom/flutter_preview_file.git
      ref: main  # 或指定 tag/commit
```

或使用 path / pub.dev（若已发布）。

## 最小用法示例

```dart
import 'package:flutter_preview_file/flutter_preview_file.dart';

// 判断能否走统一预览
final kind = FlutterPreviewFile.detectPreviewDocumentKind('report.pdf');

// PDF
PdfFileView(filePath: localPath);

// ZIP 目录（可选：点击文件解压到临时路径再交给业务）
ZipArchiveView(
  filePath: zipPath,
  onInnerFileReady: (entry, extractedPath, size) async {
    // 打开图片 / FilePreview / 系统打开等
  },
);
```

## 说明与限制

- ZIP 列表为**整文件读入内存**解析，适合一般附件体积；超大压缩包请自行评估。
- ZIP 单文件解压目前支持 **stored (0)** 与 **deflate (8)**；其他压缩算法需宿主降级为「用其他应用打开」等。
- Word/Office 重度能力依赖**原生通道**与设备环境，请以真机验证。

## License

以项目根目录 `LICENSE` 为准；使用第三方 SDK（如 Syncfusion）时请遵守其许可条款。
