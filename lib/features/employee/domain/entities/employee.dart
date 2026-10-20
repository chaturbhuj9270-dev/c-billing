import '../../../../core/access/app_module.dart';

class Employee {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final String? counterLabel;
  final List<String> allowedModules;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Employee({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.counterLabel,
    this.allowedModules = const [],
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  List<AppModule> get modules => allowedModules
      .map(AppModule.fromKey)
      .whereType<AppModule>()
      .toList();

  Employee copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    String? counterLabel,
    List<String>? allowedModules,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      counterLabel: counterLabel ?? this.counterLabel,
      allowedModules: allowedModules ?? this.allowedModules,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'counterLabel': counterLabel,
      'allowedModules': allowedModules,
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json, {String? id}) {
    final modulesRaw = json['allowedModules'];
    final modules = modulesRaw is List
        ? modulesRaw.map((e) => e.toString()).toList()
        : <String>[];
    return Employee(
      id: id ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      phone: json['phone'] as String?,
      counterLabel: json['counterLabel'] as String?,
      allowedModules: modules,
      active: json['active'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      // Firestore Timestamp
      return (value as dynamic).toDate() as DateTime?;
    } catch (_) {
      return null;
    }
  }
}
