/// Switches the web app's content pane without pushing a new route.
class WebShell {
  static const int dashboard = 0;
  static const int customers = 1;
  static const int billing = 2;
  static const int availability = 3;
  static const int purchase = 4;
  static const int invoices = 5;
  static const int products = 6;
  static const int suppliers = 7;
  static const int companies = 8;
  static const int purchaseReturn = 9;
  static const int events = 10;
  static const int quotations = 11;
  static const int barcode = 12;
  static const int expenses = 13;
  static const int shop = 14;
  static const int profile = 15;
  static const int password = 16;
  static const int count = 17;

  static void Function(int index)? _select;

  static void register(void Function(int index)? select) {
    _select = select;
  }

  /// Returns true when the web shell handled the section.
  static bool open(int index) {
    final select = _select;
    if (select == null) return false;
    select(index);
    return true;
  }
}
