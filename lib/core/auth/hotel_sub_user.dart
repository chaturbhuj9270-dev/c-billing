import 'hotel_roles.dart';

/// Represents a sub-user created by the admin in the Hotel app.
class HotelSubUser {
  final String id;
  final String adminUid;
  final String name;
  final String email;
  final String phone;
  final String pin; // 4-digit PIN for quick login
  final HotelUserRole role;
  final List<HotelModule> allowedModules;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HotelSubUser({
    required this.id,
    required this.adminUid,
    required this.name,
    required this.email,
    this.phone = '',
    this.pin = '',
    required this.role,
    required this.allowedModules,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == HotelUserRole.admin;

  bool hasAccessTo(HotelModule module) {
    if (isAdmin) return true;
    return allowedModules.contains(module);
  }

  HotelSubUser copyWith({
    String? id,
    String? adminUid,
    String? name,
    String? email,
    String? phone,
    String? pin,
    HotelUserRole? role,
    List<HotelModule>? allowedModules,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HotelSubUser(
      id: id ?? this.id,
      adminUid: adminUid ?? this.adminUid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      allowedModules: allowedModules ?? this.allowedModules,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminUid': adminUid,
      'name': name,
      'email': email,
      'phone': phone,
      'pin': pin,
      'role': role.name,
      'allowedModules': allowedModules.map((m) => m.name).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HotelSubUser.fromJson(Map<String, dynamic> json) {
    return HotelSubUser(
      id: json['id'] as String? ?? '',
      adminUid: json['adminUid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      pin: json['pin'] as String? ?? '',
      role: HotelUserRoleX.fromString(json['role'] as String? ?? 'custom'),
      allowedModules:
          (json['allowedModules'] as List<dynamic>?)
              ?.map(
                (m) => HotelModule.values.firstWhere(
                  (v) => v.name == m,
                  orElse: () => HotelModule.dashboard,
                ),
              )
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
