import '../../../../core/access/app_module.dart';

class Employee {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  // Auto-assigned sequential token used on bills (1, 2, 3…).
  final int tokenNumber;
  // When true, employee may use counter / billing.
  final bool counterAccess;
  // Cloth-collection style sales points (from attributed bill sale prices).
  final double points;
  final DateTime? dateOfBirth;
  final String? address;
  final String? pinCode;
  final String? govIdNumber;
  final String? govIdType;
  final double? salary;
  final DateTime? dateOfJoining;
  final List<String> allowedModules;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Employee({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.tokenNumber = 0,
    this.counterAccess = true,
    this.points = 0,
    this.dateOfBirth,
    this.address,
    this.pinCode,
    this.govIdNumber,
    this.govIdType,
    this.salary,
    this.dateOfJoining,
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
    int? tokenNumber,
    bool? counterAccess,
    double? points,
    DateTime? dateOfBirth,
    String? address,
    String? pinCode,
    String? govIdNumber,
    String? govIdType,
    double? salary,
    DateTime? dateOfJoining,
    List<String>? allowedModules,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDateOfBirth = false,
    bool clearDateOfJoining = false,
    bool clearSalary = false,
  }) {
    return Employee(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      counterAccess: counterAccess ?? this.counterAccess,
      points: points ?? this.points,
      dateOfBirth: clearDateOfBirth
          ? null
          : (dateOfBirth ?? this.dateOfBirth),
      address: address ?? this.address,
      pinCode: pinCode ?? this.pinCode,
      govIdNumber: govIdNumber ?? this.govIdNumber,
      govIdType: govIdType ?? this.govIdType,
      salary: clearSalary ? null : (salary ?? this.salary),
      dateOfJoining: clearDateOfJoining
          ? null
          : (dateOfJoining ?? this.dateOfJoining),
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
      'tokenNumber': tokenNumber,
      'counterAccess': counterAccess,
      'points': points,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'pinCode': pinCode,
      'govIdNumber': govIdNumber,
      'govIdType': govIdType,
      'salary': salary,
      'dateOfJoining': dateOfJoining?.toIso8601String(),
      'allowedModules': allowedModules,
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Profile fields only - used when merging into Firestore writes.
  Map<String, dynamic> profileToJson() {
    return {
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'pinCode': pinCode,
      'govIdNumber': govIdNumber,
      'govIdType': govIdType,
      'salary': salary,
      'dateOfJoining': dateOfJoining?.toIso8601String(),
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json, {String? id}) {
    final modulesRaw = json['allowedModules'];
    final modules = modulesRaw is List
        ? modulesRaw.map((e) => e.toString()).toList()
        : <String>[];
    final tokenRaw = json['tokenNumber'];
    final token = tokenRaw is int
        ? tokenRaw
        : int.tryParse('$tokenRaw') ?? 0;
    final pointsRaw = json['points'];
    final points = pointsRaw is num
        ? pointsRaw.toDouble()
        : double.tryParse('$pointsRaw') ?? 0;
    final salaryRaw = json['salary'];
    final salary = salaryRaw == null
        ? null
        : (salaryRaw is num
              ? salaryRaw.toDouble()
              : double.tryParse('$salaryRaw'));
    return Employee(
      id: id ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      phone: json['phone'] as String?,
      tokenNumber: token,
      counterAccess: json['counterAccess'] as bool? ?? true,
      points: points,
      dateOfBirth: _parseDate(json['dateOfBirth']),
      address: json['address'] as String?,
      pinCode: json['pinCode'] as String?,
      govIdNumber: json['govIdNumber'] as String?,
      govIdType: json['govIdType'] as String?,
      salary: salary,
      dateOfJoining: _parseDate(json['dateOfJoining']),
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
      return (value as dynamic).toDate() as DateTime?;
    } catch (_) {
      return null;
    }
  }
}
