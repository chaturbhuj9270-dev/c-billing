// Pure text-layout helpers for receipts (no Flutter imports). Feature: print-formats.

/// Word-wraps [text] to [width] characters per line. Words longer than
/// [width] are split so no text is ever lost or pushed off the paper.
List<String> wrapReceiptText(String text, int width) {
  final w = width < 1 ? 1 : width;
  final lines = <String>[];
  var cur = '';

  void flush() {
    if (cur.isNotEmpty) lines.add(cur);
    cur = '';
  }

  for (final raw in text.split(' ')) {
    var word = raw;
    if (word.isEmpty) continue;
    while (word.length > w) {
      // Fill the current line first when there is a sensible amount of room,
      // otherwise start the long word on a fresh line.
      if (cur.isNotEmpty) flush();
      lines.add(word.substring(0, w));
      word = word.substring(w);
    }
    if (word.isEmpty) continue;
    if (cur.isEmpty) {
      cur = word;
    } else if (cur.length + 1 + word.length <= w) {
      cur = '$cur $word';
    } else {
      flush();
      cur = word;
    }
  }
  flush();
  return lines;
}

/// How the thermal header prints the shop name.
class ThermalShopNameLayout {
  final List<String> lines;

  /// true = double width+height; false = normal-size bold (long names).
  final bool large;
  const ThermalShopNameLayout(this.lines, this.large);
}

/// Prefers the big double-size look; falls back to normal-size bold text over
/// the full paper width when the name would need more than [maxLargeLines]
/// large lines, so a long shop name always prints in full.
ThermalShopNameLayout layoutThermalShopName(
  String name,
  int cols, {
  int maxLargeLines = 3,
}) {
  final text = name.trim();
  final large = wrapReceiptText(text, cols ~/ 2);
  if (large.length <= maxLargeLines) return ThermalShopNameLayout(large, true);
  return ThermalShopNameLayout(wrapReceiptText(text, cols), false);
}

/// Font size (pt) for the shop name on the POS PDF receipt: 11pt for normal
/// names, shrinking for long ones so the whole name stays visible.
double posShopNameFontSize(String name) {
  final n = name.trim().length;
  if (n <= 24) return 11;
  if (n <= 36) return 10;
  if (n <= 52) return 9;
  if (n <= 72) return 8;
  return 7;
}
