/// Helpers for Indian GSTIN / place-of-supply logic used in billing & GSTR-1.
class GstUtils {
  GstUtils._();

  /// Indian state codes (first 2 digits of GSTIN) → name.
  static const Map<String, String> stateNames = {
    '01': 'Jammu & Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '26': 'Dadra & Nagar Haveli and Daman & Diu',
    '27': 'Maharashtra',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshadweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman & Nicobar Islands',
    '36': 'Telangana',
    '37': 'Andhra Pradesh',
    '38': 'Ladakh',
    '97': 'Other Territory',
  };

  /// Normalize GSTIN (uppercase, strip spaces).
  static String? normalizeGstin(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  /// Basic GSTIN format check (15 chars). Not a cryptographic checksum.
  static bool isValidGstinFormat(String? raw) {
    final g = normalizeGstin(raw);
    if (g == null || g.length != 15) return false;
    return RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$')
        .hasMatch(g);
  }

  /// First two characters of GSTIN = state code.
  static String? stateCodeFromGstin(String? raw) {
    final g = normalizeGstin(raw);
    if (g == null || g.length < 2) return null;
    final code = g.substring(0, 2);
    if (!RegExp(r'^\d{2}$').hasMatch(code)) return null;
    return code;
  }

  static String stateDisplay(String? stateCode) {
    if (stateCode == null || stateCode.isEmpty) return '-';
    final name = stateNames[stateCode];
    return name != null ? '$stateCode - $name' : stateCode;
  }

  /// Interstate when both GSTINs present and state codes differ.
  /// Returns null when comparison is not possible (missing GSTIN).
  static bool? isInterstate({
    required String? shopGstin,
    required String? customerGstin,
  }) {
    final shop = stateCodeFromGstin(shopGstin);
    final customer = stateCodeFromGstin(customerGstin);
    if (shop == null || customer == null) return null;
    return shop != customer;
  }

  /// Place of supply = customer state when B2B GSTIN present, else shop state.
  static String? placeOfSupplyStateCode({
    required String? shopGstin,
    required String? customerGstin,
  }) {
    return stateCodeFromGstin(customerGstin) ?? stateCodeFromGstin(shopGstin);
  }
}
