import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

// Shows a PDF with the browser viewer. Web has no native PDF rasterizer.
Widget buildWebPdfView(Uint8List bytes) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final viewType =
      'c-billing-pdf-${url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    return web.HTMLIFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
  });
  return HtmlElementView(viewType: viewType);
}

void downloadWebBytes(Uint8List bytes, String filename, String mimeType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
