// WYSIWYG label preview drawn from the same [LabelLayout] the PDF / ESC-POS /
// TSPL renderers use, so what the user sees matches what is printed.
// Feature: barcode-labels.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/printing/barcode_label/barcode_label_layout.dart';
import '../../../../core/printing/barcode_label/barcode_label_models.dart';

class BarcodeLabelPreview extends StatelessWidget {
  final LabelLayout layout;
  final LabelContent content;

  /// Builds the barcode / QR for a pixel size.
  final Widget Function(double width, double height) barcodeBuilder;
  final double maxWidth;
  final double maxHeight;

  const BarcodeLabelPreview({
    super.key,
    required this.layout,
    required this.content,
    required this.barcodeBuilder,
    this.maxWidth = 320,
    this.maxHeight = 240,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth.isFinite
            ? math.min(constraints.maxWidth, maxWidth)
            : maxWidth;
        final pxPerMm = math.min(
          availW / layout.widthMm,
          maxHeight / layout.heightMm,
        );
        double px(double mm) => mm * pxPerMm;

        Widget text(LabelLine l) => Text(
          l.text,
          maxLines: l.maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: px(l.pt * ptToMm),
            height: 1.2,
            fontWeight: l.bold ? FontWeight.w700 : FontWeight.w400,
            color: Colors.black,
          ),
        );

        final lines = layout.lines.map(text).toList();

        Widget body;
        if (layout.isQr) {
          final qr = SizedBox(
            width: px(layout.qrSizeMm),
            height: px(layout.qrSizeMm),
            child: barcodeBuilder(px(layout.qrSizeMm), px(layout.qrSizeMm)),
          );
          if (layout.qrLeft) {
            body = SizedBox(
              height: px(layout.innerHeightMm),
              child: Row(
                children: [
                  qr,
                  SizedBox(width: px(1.5)),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: lines,
                    ),
                  ),
                ],
              ),
            );
          } else {
            body = Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...lines,
                SizedBox(height: px(1)),
                qr,
              ],
            );
          }
        } else {
          body = Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...lines,
              if (lines.isNotEmpty) SizedBox(height: px(0.8)),
              SizedBox(
                width: px(layout.barcodeWidthMm),
                height: px(layout.barcodeHeightMm),
                child: barcodeBuilder(
                  px(layout.barcodeWidthMm),
                  px(layout.barcodeHeightMm),
                ),
              ),
              if (layout.showCodeText) ...[
                SizedBox(height: px(0.4)),
                Text(
                  content.code,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: px(layout.codeTextPt * ptToMm),
                    height: 1.1,
                    color: Colors.black,
                  ),
                ),
              ],
            ],
          );
        }

        return Container(
          width: px(layout.widthMm),
          height: px(layout.heightMm),
          padding: EdgeInsets.all(px(layout.padMm)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(math.min(6, px(1.2))),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          // Scales the content down instead of overflowing when the text needs
          // slightly more room than the label has.
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(width: px(layout.innerWidthMm), child: body),
            ),
          ),
        );
      },
    );
  }
}
