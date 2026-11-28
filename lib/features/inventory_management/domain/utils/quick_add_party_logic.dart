// Pure helpers for the "quick add company / supplier" actions on the add
// product screen. No Flutter / Firebase imports. Feature: product-quick-add-party.

/// Lower-cased, whitespace-collapsed key used to detect an existing record
/// with the same name (so quick add never creates accidental duplicates).
String partyNameKey(String name) =>
    name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// First element whose name matches [name] (case/space-insensitive), or null.
T? findPartyByName<T>(
  Iterable<T> items,
  String name,
  String Function(T item) nameOf,
) {
  final key = partyNameKey(name);
  if (key.isEmpty) return null;
  for (final item in items) {
    if (partyNameKey(nameOf(item)) == key) return item;
  }
  return null;
}

/// Mobile number is optional in quick add; when given it must be 10 digits
/// (same rule as the full supplier / company forms).
bool isValidOptionalMobile(String value) {
  final v = value.trim();
  return v.isEmpty || RegExp(r'^\d{10}$').hasMatch(v);
}

/// Picker map for a company, same shape the add-product sheet already uses.
Map<String, dynamic> companyPickerMap({
  required String id,
  required String companyName,
}) => {'id': id, 'companyName': companyName};

/// Picker map for a supplier, same shape the add-product sheet already uses.
Map<String, dynamic> supplierPickerMap({
  required String id,
  required String firstName,
  required String lastName,
}) => {
  'id': id,
  'firstName': firstName,
  'lastName': lastName,
  'fullName': '$firstName $lastName'.trim(),
};

/// Adds [item] to [list] unless one with the same `id` is already present.
void addPickerItemIfAbsent(
  List<Map<String, dynamic>> list,
  Map<String, dynamic> item,
) {
  final id = item['id'];
  if (!list.any((e) => e['id'] == id)) list.add(item);
}
