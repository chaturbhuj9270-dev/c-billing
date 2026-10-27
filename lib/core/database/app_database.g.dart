// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CompanyRecordsTable extends CompanyRecords
    with TableInfo<$CompanyRecordsTable, CompanyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompanyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyCodeMeta = const VerificationMeta(
    'companyCode',
  );
  @override
  late final GeneratedColumn<String> companyCode = GeneratedColumn<String>(
    'company_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _gstCodeMeta = const VerificationMeta(
    'gstCode',
  );
  @override
  late final GeneratedColumn<String> gstCode = GeneratedColumn<String>(
    'gst_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contactMeta = const VerificationMeta(
    'contact',
  );
  @override
  late final GeneratedColumn<String> contact = GeneratedColumn<String>(
    'contact',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    companyName,
    companyCode,
    gstCode,
    contact,
    address,
    isActive,
    syncStatus,
    updatedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'companies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompanyRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_companyNameMeta);
    }
    if (data.containsKey('company_code')) {
      context.handle(
        _companyCodeMeta,
        companyCode.isAcceptableOrUnknown(
          data['company_code']!,
          _companyCodeMeta,
        ),
      );
    }
    if (data.containsKey('gst_code')) {
      context.handle(
        _gstCodeMeta,
        gstCode.isAcceptableOrUnknown(data['gst_code']!, _gstCodeMeta),
      );
    }
    if (data.containsKey('contact')) {
      context.handle(
        _contactMeta,
        contact.isAcceptableOrUnknown(data['contact']!, _contactMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompanyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompanyRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      )!,
      companyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_code'],
      )!,
      gstCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gst_code'],
      )!,
      contact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CompanyRecordsTable createAlias(String alias) {
    return $CompanyRecordsTable(attachedDatabase, alias);
  }
}

class CompanyRecord extends DataClass implements Insertable<CompanyRecord> {
  final int id;
  final String? serverId;
  final String companyName;
  final String companyCode;
  final String gstCode;
  final String contact;
  final String address;
  final bool isActive;
  final int syncStatus;
  final DateTime updatedAt;
  final DateTime createdAt;
  const CompanyRecord({
    required this.id,
    this.serverId,
    required this.companyName,
    required this.companyCode,
    required this.gstCode,
    required this.contact,
    required this.address,
    required this.isActive,
    required this.syncStatus,
    required this.updatedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['company_name'] = Variable<String>(companyName);
    map['company_code'] = Variable<String>(companyCode);
    map['gst_code'] = Variable<String>(gstCode);
    map['contact'] = Variable<String>(contact);
    map['address'] = Variable<String>(address);
    map['is_active'] = Variable<bool>(isActive);
    map['sync_status'] = Variable<int>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CompanyRecordsCompanion toCompanion(bool nullToAbsent) {
    return CompanyRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      companyName: Value(companyName),
      companyCode: Value(companyCode),
      gstCode: Value(gstCode),
      contact: Value(contact),
      address: Value(address),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory CompanyRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompanyRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      companyName: serializer.fromJson<String>(json['companyName']),
      companyCode: serializer.fromJson<String>(json['companyCode']),
      gstCode: serializer.fromJson<String>(json['gstCode']),
      contact: serializer.fromJson<String>(json['contact']),
      address: serializer.fromJson<String>(json['address']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'companyName': serializer.toJson<String>(companyName),
      'companyCode': serializer.toJson<String>(companyCode),
      'gstCode': serializer.toJson<String>(gstCode),
      'contact': serializer.toJson<String>(contact),
      'address': serializer.toJson<String>(address),
      'isActive': serializer.toJson<bool>(isActive),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CompanyRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? companyName,
    String? companyCode,
    String? gstCode,
    String? contact,
    String? address,
    bool? isActive,
    int? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) => CompanyRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    companyName: companyName ?? this.companyName,
    companyCode: companyCode ?? this.companyCode,
    gstCode: gstCode ?? this.gstCode,
    contact: contact ?? this.contact,
    address: address ?? this.address,
    isActive: isActive ?? this.isActive,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  CompanyRecord copyWithCompanion(CompanyRecordsCompanion data) {
    return CompanyRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      companyCode: data.companyCode.present
          ? data.companyCode.value
          : this.companyCode,
      gstCode: data.gstCode.present ? data.gstCode.value : this.gstCode,
      contact: data.contact.present ? data.contact.value : this.contact,
      address: data.address.present ? data.address.value : this.address,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompanyRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('companyName: $companyName, ')
          ..write('companyCode: $companyCode, ')
          ..write('gstCode: $gstCode, ')
          ..write('contact: $contact, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    companyName,
    companyCode,
    gstCode,
    contact,
    address,
    isActive,
    syncStatus,
    updatedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompanyRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.companyName == this.companyName &&
          other.companyCode == this.companyCode &&
          other.gstCode == this.gstCode &&
          other.contact == this.contact &&
          other.address == this.address &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt);
}

class CompanyRecordsCompanion extends UpdateCompanion<CompanyRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> companyName;
  final Value<String> companyCode;
  final Value<String> gstCode;
  final Value<String> contact;
  final Value<String> address;
  final Value<bool> isActive;
  final Value<int> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  const CompanyRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.companyName = const Value.absent(),
    this.companyCode = const Value.absent(),
    this.gstCode = const Value.absent(),
    this.contact = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CompanyRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String companyName,
    this.companyCode = const Value.absent(),
    this.gstCode = const Value.absent(),
    this.contact = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    required int syncStatus,
    required DateTime updatedAt,
    required DateTime createdAt,
  }) : companyName = Value(companyName),
       syncStatus = Value(syncStatus),
       updatedAt = Value(updatedAt),
       createdAt = Value(createdAt);
  static Insertable<CompanyRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? companyName,
    Expression<String>? companyCode,
    Expression<String>? gstCode,
    Expression<String>? contact,
    Expression<String>? address,
    Expression<bool>? isActive,
    Expression<int>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (companyName != null) 'company_name': companyName,
      if (companyCode != null) 'company_code': companyCode,
      if (gstCode != null) 'gst_code': gstCode,
      if (contact != null) 'contact': contact,
      if (address != null) 'address': address,
      if (isActive != null) 'is_active': isActive,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CompanyRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? companyName,
    Value<String>? companyCode,
    Value<String>? gstCode,
    Value<String>? contact,
    Value<String>? address,
    Value<bool>? isActive,
    Value<int>? syncStatus,
    Value<DateTime>? updatedAt,
    Value<DateTime>? createdAt,
  }) {
    return CompanyRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      companyName: companyName ?? this.companyName,
      companyCode: companyCode ?? this.companyCode,
      gstCode: gstCode ?? this.gstCode,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (companyCode.present) {
      map['company_code'] = Variable<String>(companyCode.value);
    }
    if (gstCode.present) {
      map['gst_code'] = Variable<String>(gstCode.value);
    }
    if (contact.present) {
      map['contact'] = Variable<String>(contact.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompanyRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('companyName: $companyName, ')
          ..write('companyCode: $companyCode, ')
          ..write('gstCode: $gstCode, ')
          ..write('contact: $contact, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CustomerRecordsTable extends CustomerRecords
    with TableInfo<$CustomerRecordsTable, CustomerRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gstinMeta = const VerificationMeta('gstin');
  @override
  late final GeneratedColumn<String> gstin = GeneratedColumn<String>(
    'gstin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentPendingAmountMeta =
      const VerificationMeta('currentPendingAmount');
  @override
  late final GeneratedColumn<double> currentPendingAmount =
      GeneratedColumn<double>(
        'current_pending_amount',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _totalPurchasesMeta = const VerificationMeta(
    'totalPurchases',
  );
  @override
  late final GeneratedColumn<double> totalPurchases = GeneratedColumn<double>(
    'total_purchases',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    mobile,
    address,
    email,
    gstin,
    currentPendingAmount,
    totalPurchases,
    isSynced,
    isDeleted,
    updatedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    } else if (isInserting) {
      context.missing(_mobileMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('gstin')) {
      context.handle(
        _gstinMeta,
        gstin.isAcceptableOrUnknown(data['gstin']!, _gstinMeta),
      );
    }
    if (data.containsKey('current_pending_amount')) {
      context.handle(
        _currentPendingAmountMeta,
        currentPendingAmount.isAcceptableOrUnknown(
          data['current_pending_amount']!,
          _currentPendingAmountMeta,
        ),
      );
    }
    if (data.containsKey('total_purchases')) {
      context.handle(
        _totalPurchasesMeta,
        totalPurchases.isAcceptableOrUnknown(
          data['total_purchases']!,
          _totalPurchasesMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      gstin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gstin'],
      ),
      currentPendingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_pending_amount'],
      )!,
      totalPurchases: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_purchases'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomerRecordsTable createAlias(String alias) {
    return $CustomerRecordsTable(attachedDatabase, alias);
  }
}

class CustomerRecord extends DataClass implements Insertable<CustomerRecord> {
  final int id;
  final String? serverId;
  final String name;
  final String mobile;
  final String? address;
  final String? email;
  final String? gstin;
  final double currentPendingAmount;
  final double totalPurchases;
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;
  final DateTime createdAt;
  const CustomerRecord({
    required this.id,
    this.serverId,
    required this.name,
    required this.mobile,
    this.address,
    this.email,
    this.gstin,
    required this.currentPendingAmount,
    required this.totalPurchases,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['name'] = Variable<String>(name);
    map['mobile'] = Variable<String>(mobile);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || gstin != null) {
      map['gstin'] = Variable<String>(gstin);
    }
    map['current_pending_amount'] = Variable<double>(currentPendingAmount);
    map['total_purchases'] = Variable<double>(totalPurchases);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomerRecordsCompanion toCompanion(bool nullToAbsent) {
    return CustomerRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      mobile: Value(mobile),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      gstin: gstin == null && nullToAbsent
          ? const Value.absent()
          : Value(gstin),
      currentPendingAmount: Value(currentPendingAmount),
      totalPurchases: Value(totalPurchases),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory CustomerRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      mobile: serializer.fromJson<String>(json['mobile']),
      address: serializer.fromJson<String?>(json['address']),
      email: serializer.fromJson<String?>(json['email']),
      gstin: serializer.fromJson<String?>(json['gstin']),
      currentPendingAmount: serializer.fromJson<double>(
        json['currentPendingAmount'],
      ),
      totalPurchases: serializer.fromJson<double>(json['totalPurchases']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'name': serializer.toJson<String>(name),
      'mobile': serializer.toJson<String>(mobile),
      'address': serializer.toJson<String?>(address),
      'email': serializer.toJson<String?>(email),
      'gstin': serializer.toJson<String?>(gstin),
      'currentPendingAmount': serializer.toJson<double>(currentPendingAmount),
      'totalPurchases': serializer.toJson<double>(totalPurchases),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomerRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? name,
    String? mobile,
    Value<String?> address = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> gstin = const Value.absent(),
    double? currentPendingAmount,
    double? totalPurchases,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) => CustomerRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    name: name ?? this.name,
    mobile: mobile ?? this.mobile,
    address: address.present ? address.value : this.address,
    email: email.present ? email.value : this.email,
    gstin: gstin.present ? gstin.value : this.gstin,
    currentPendingAmount: currentPendingAmount ?? this.currentPendingAmount,
    totalPurchases: totalPurchases ?? this.totalPurchases,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomerRecord copyWithCompanion(CustomerRecordsCompanion data) {
    return CustomerRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      address: data.address.present ? data.address.value : this.address,
      email: data.email.present ? data.email.value : this.email,
      gstin: data.gstin.present ? data.gstin.value : this.gstin,
      currentPendingAmount: data.currentPendingAmount.present
          ? data.currentPendingAmount.value
          : this.currentPendingAmount,
      totalPurchases: data.totalPurchases.present
          ? data.totalPurchases.value
          : this.totalPurchases,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('mobile: $mobile, ')
          ..write('address: $address, ')
          ..write('email: $email, ')
          ..write('gstin: $gstin, ')
          ..write('currentPendingAmount: $currentPendingAmount, ')
          ..write('totalPurchases: $totalPurchases, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    name,
    mobile,
    address,
    email,
    gstin,
    currentPendingAmount,
    totalPurchases,
    isSynced,
    isDeleted,
    updatedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.mobile == this.mobile &&
          other.address == this.address &&
          other.email == this.email &&
          other.gstin == this.gstin &&
          other.currentPendingAmount == this.currentPendingAmount &&
          other.totalPurchases == this.totalPurchases &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt);
}

class CustomerRecordsCompanion extends UpdateCompanion<CustomerRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> name;
  final Value<String> mobile;
  final Value<String?> address;
  final Value<String?> email;
  final Value<String?> gstin;
  final Value<double> currentPendingAmount;
  final Value<double> totalPurchases;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  const CustomerRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.mobile = const Value.absent(),
    this.address = const Value.absent(),
    this.email = const Value.absent(),
    this.gstin = const Value.absent(),
    this.currentPendingAmount = const Value.absent(),
    this.totalPurchases = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomerRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    required String mobile,
    this.address = const Value.absent(),
    this.email = const Value.absent(),
    this.gstin = const Value.absent(),
    this.currentPendingAmount = const Value.absent(),
    this.totalPurchases = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime updatedAt,
    required DateTime createdAt,
  }) : name = Value(name),
       mobile = Value(mobile),
       updatedAt = Value(updatedAt),
       createdAt = Value(createdAt);
  static Insertable<CustomerRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? name,
    Expression<String>? mobile,
    Expression<String>? address,
    Expression<String>? email,
    Expression<String>? gstin,
    Expression<double>? currentPendingAmount,
    Expression<double>? totalPurchases,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (mobile != null) 'mobile': mobile,
      if (address != null) 'address': address,
      if (email != null) 'email': email,
      if (gstin != null) 'gstin': gstin,
      if (currentPendingAmount != null)
        'current_pending_amount': currentPendingAmount,
      if (totalPurchases != null) 'total_purchases': totalPurchases,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomerRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? name,
    Value<String>? mobile,
    Value<String?>? address,
    Value<String?>? email,
    Value<String?>? gstin,
    Value<double>? currentPendingAmount,
    Value<double>? totalPurchases,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<DateTime>? updatedAt,
    Value<DateTime>? createdAt,
  }) {
    return CustomerRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      currentPendingAmount: currentPendingAmount ?? this.currentPendingAmount,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (gstin.present) {
      map['gstin'] = Variable<String>(gstin.value);
    }
    if (currentPendingAmount.present) {
      map['current_pending_amount'] = Variable<double>(
        currentPendingAmount.value,
      );
    }
    if (totalPurchases.present) {
      map['total_purchases'] = Variable<double>(totalPurchases.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('mobile: $mobile, ')
          ..write('address: $address, ')
          ..write('email: $email, ')
          ..write('gstin: $gstin, ')
          ..write('currentPendingAmount: $currentPendingAmount, ')
          ..write('totalPurchases: $totalPurchases, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SupplierRecordsTable extends SupplierRecords
    with TableInfo<$SupplierRecordsTable, SupplierRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SupplierRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _middleNameMeta = const VerificationMeta(
    'middleName',
  );
  @override
  late final GeneratedColumn<String> middleName = GeneratedColumn<String>(
    'middle_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _supplierCodeMeta = const VerificationMeta(
    'supplierCode',
  );
  @override
  late final GeneratedColumn<String> supplierCode = GeneratedColumn<String>(
    'supplier_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contactMeta = const VerificationMeta(
    'contact',
  );
  @override
  late final GeneratedColumn<String> contact = GeneratedColumn<String>(
    'contact',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    firstName,
    middleName,
    lastName,
    supplierCode,
    contact,
    address,
    isActive,
    syncStatus,
    updatedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suppliers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SupplierRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('middle_name')) {
      context.handle(
        _middleNameMeta,
        middleName.isAcceptableOrUnknown(data['middle_name']!, _middleNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('supplier_code')) {
      context.handle(
        _supplierCodeMeta,
        supplierCode.isAcceptableOrUnknown(
          data['supplier_code']!,
          _supplierCodeMeta,
        ),
      );
    }
    if (data.containsKey('contact')) {
      context.handle(
        _contactMeta,
        contact.isAcceptableOrUnknown(data['contact']!, _contactMeta),
      );
    } else if (isInserting) {
      context.missing(_contactMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SupplierRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SupplierRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      middleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}middle_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      supplierCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_code'],
      )!,
      contact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SupplierRecordsTable createAlias(String alias) {
    return $SupplierRecordsTable(attachedDatabase, alias);
  }
}

class SupplierRecord extends DataClass implements Insertable<SupplierRecord> {
  final int id;
  final String? serverId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String supplierCode;
  final String contact;
  final String address;
  final bool isActive;
  final int syncStatus;
  final DateTime updatedAt;
  final DateTime createdAt;
  const SupplierRecord({
    required this.id,
    this.serverId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.supplierCode,
    required this.contact,
    required this.address,
    required this.isActive,
    required this.syncStatus,
    required this.updatedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['first_name'] = Variable<String>(firstName);
    map['middle_name'] = Variable<String>(middleName);
    map['last_name'] = Variable<String>(lastName);
    map['supplier_code'] = Variable<String>(supplierCode);
    map['contact'] = Variable<String>(contact);
    map['address'] = Variable<String>(address);
    map['is_active'] = Variable<bool>(isActive);
    map['sync_status'] = Variable<int>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SupplierRecordsCompanion toCompanion(bool nullToAbsent) {
    return SupplierRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      firstName: Value(firstName),
      middleName: Value(middleName),
      lastName: Value(lastName),
      supplierCode: Value(supplierCode),
      contact: Value(contact),
      address: Value(address),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory SupplierRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SupplierRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      firstName: serializer.fromJson<String>(json['firstName']),
      middleName: serializer.fromJson<String>(json['middleName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      supplierCode: serializer.fromJson<String>(json['supplierCode']),
      contact: serializer.fromJson<String>(json['contact']),
      address: serializer.fromJson<String>(json['address']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'firstName': serializer.toJson<String>(firstName),
      'middleName': serializer.toJson<String>(middleName),
      'lastName': serializer.toJson<String>(lastName),
      'supplierCode': serializer.toJson<String>(supplierCode),
      'contact': serializer.toJson<String>(contact),
      'address': serializer.toJson<String>(address),
      'isActive': serializer.toJson<bool>(isActive),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SupplierRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? firstName,
    String? middleName,
    String? lastName,
    String? supplierCode,
    String? contact,
    String? address,
    bool? isActive,
    int? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) => SupplierRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    firstName: firstName ?? this.firstName,
    middleName: middleName ?? this.middleName,
    lastName: lastName ?? this.lastName,
    supplierCode: supplierCode ?? this.supplierCode,
    contact: contact ?? this.contact,
    address: address ?? this.address,
    isActive: isActive ?? this.isActive,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  SupplierRecord copyWithCompanion(SupplierRecordsCompanion data) {
    return SupplierRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      middleName: data.middleName.present
          ? data.middleName.value
          : this.middleName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      supplierCode: data.supplierCode.present
          ? data.supplierCode.value
          : this.supplierCode,
      contact: data.contact.present ? data.contact.value : this.contact,
      address: data.address.present ? data.address.value : this.address,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SupplierRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('lastName: $lastName, ')
          ..write('supplierCode: $supplierCode, ')
          ..write('contact: $contact, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    firstName,
    middleName,
    lastName,
    supplierCode,
    contact,
    address,
    isActive,
    syncStatus,
    updatedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplierRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.firstName == this.firstName &&
          other.middleName == this.middleName &&
          other.lastName == this.lastName &&
          other.supplierCode == this.supplierCode &&
          other.contact == this.contact &&
          other.address == this.address &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt);
}

class SupplierRecordsCompanion extends UpdateCompanion<SupplierRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> firstName;
  final Value<String> middleName;
  final Value<String> lastName;
  final Value<String> supplierCode;
  final Value<String> contact;
  final Value<String> address;
  final Value<bool> isActive;
  final Value<int> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  const SupplierRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.firstName = const Value.absent(),
    this.middleName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.supplierCode = const Value.absent(),
    this.contact = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SupplierRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String firstName,
    this.middleName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.supplierCode = const Value.absent(),
    required String contact,
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    required int syncStatus,
    required DateTime updatedAt,
    required DateTime createdAt,
  }) : firstName = Value(firstName),
       contact = Value(contact),
       syncStatus = Value(syncStatus),
       updatedAt = Value(updatedAt),
       createdAt = Value(createdAt);
  static Insertable<SupplierRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? firstName,
    Expression<String>? middleName,
    Expression<String>? lastName,
    Expression<String>? supplierCode,
    Expression<String>? contact,
    Expression<String>? address,
    Expression<bool>? isActive,
    Expression<int>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (firstName != null) 'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      if (lastName != null) 'last_name': lastName,
      if (supplierCode != null) 'supplier_code': supplierCode,
      if (contact != null) 'contact': contact,
      if (address != null) 'address': address,
      if (isActive != null) 'is_active': isActive,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SupplierRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? firstName,
    Value<String>? middleName,
    Value<String>? lastName,
    Value<String>? supplierCode,
    Value<String>? contact,
    Value<String>? address,
    Value<bool>? isActive,
    Value<int>? syncStatus,
    Value<DateTime>? updatedAt,
    Value<DateTime>? createdAt,
  }) {
    return SupplierRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      supplierCode: supplierCode ?? this.supplierCode,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (middleName.present) {
      map['middle_name'] = Variable<String>(middleName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (supplierCode.present) {
      map['supplier_code'] = Variable<String>(supplierCode.value);
    }
    if (contact.present) {
      map['contact'] = Variable<String>(contact.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SupplierRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('lastName: $lastName, ')
          ..write('supplierCode: $supplierCode, ')
          ..write('contact: $contact, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProductRecordsTable extends ProductRecords
    with TableInfo<$ProductRecordsTable, ProductRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indexNoMeta = const VerificationMeta(
    'indexNo',
  );
  @override
  late final GeneratedColumn<int> indexNo = GeneratedColumn<int>(
    'index_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceMeta = const VerificationMeta(
    'purchasePrice',
  );
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
    'purchase_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _salesPriceMeta = const VerificationMeta(
    'salesPrice',
  );
  @override
  late final GeneratedColumn<double> salesPrice = GeneratedColumn<double>(
    'sales_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentStockMeta = const VerificationMeta(
    'currentStock',
  );
  @override
  late final GeneratedColumn<int> currentStock = GeneratedColumn<int>(
    'current_stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minStockLevelMeta = const VerificationMeta(
    'minStockLevel',
  );
  @override
  late final GeneratedColumn<int> minStockLevel = GeneratedColumn<int>(
    'min_stock_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultSupplierIdMeta = const VerificationMeta(
    'defaultSupplierId',
  );
  @override
  late final GeneratedColumn<String> defaultSupplierId =
      GeneratedColumn<String>(
        'default_supplier_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _defaultSupplierNameMeta =
      const VerificationMeta('defaultSupplierName');
  @override
  late final GeneratedColumn<String> defaultSupplierName =
      GeneratedColumn<String>(
        'default_supplier_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cgstPercentMeta = const VerificationMeta(
    'cgstPercent',
  );
  @override
  late final GeneratedColumn<double> cgstPercent = GeneratedColumn<double>(
    'cgst_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sgstPercentMeta = const VerificationMeta(
    'sgstPercent',
  );
  @override
  late final GeneratedColumn<double> sgstPercent = GeneratedColumn<double>(
    'sgst_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hsnCodeMeta = const VerificationMeta(
    'hsnCode',
  );
  @override
  late final GeneratedColumn<String> hsnCode = GeneratedColumn<String>(
    'hsn_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customFieldsJsonMeta = const VerificationMeta(
    'customFieldsJson',
  );
  @override
  late final GeneratedColumn<String> customFieldsJson = GeneratedColumn<String>(
    'custom_fields_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<String> size = GeneratedColumn<String>(
    'size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mrpMeta = const VerificationMeta('mrp');
  @override
  late final GeneratedColumn<double> mrp = GeneratedColumn<double>(
    'mrp',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _compositionMeta = const VerificationMeta(
    'composition',
  );
  @override
  late final GeneratedColumn<String> composition = GeneratedColumn<String>(
    'composition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _drugScheduleMeta = const VerificationMeta(
    'drugSchedule',
  );
  @override
  late final GeneratedColumn<String> drugSchedule = GeneratedColumn<String>(
    'drug_schedule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packUnitMeta = const VerificationMeta(
    'packUnit',
  );
  @override
  late final GeneratedColumn<String> packUnit = GeneratedColumn<String>(
    'pack_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitsPerPackMeta = const VerificationMeta(
    'unitsPerPack',
  );
  @override
  late final GeneratedColumn<int> unitsPerPack = GeneratedColumn<int>(
    'units_per_pack',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    indexNo,
    name,
    companyName,
    category,
    barcode,
    purchasePrice,
    salesPrice,
    currentStock,
    unit,
    isActive,
    syncStatus,
    updatedAt,
    createdAt,
    minStockLevel,
    description,
    imageUrl,
    defaultSupplierId,
    defaultSupplierName,
    cgstPercent,
    sgstPercent,
    hsnCode,
    customFieldsJson,
    size,
    color,
    mrp,
    composition,
    drugSchedule,
    packUnit,
    unitsPerPack,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('index_no')) {
      context.handle(
        _indexNoMeta,
        indexNo.isAcceptableOrUnknown(data['index_no']!, _indexNoMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
        _purchasePriceMeta,
        purchasePrice.isAcceptableOrUnknown(
          data['purchase_price']!,
          _purchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('sales_price')) {
      context.handle(
        _salesPriceMeta,
        salesPrice.isAcceptableOrUnknown(data['sales_price']!, _salesPriceMeta),
      );
    }
    if (data.containsKey('current_stock')) {
      context.handle(
        _currentStockMeta,
        currentStock.isAcceptableOrUnknown(
          data['current_stock']!,
          _currentStockMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('min_stock_level')) {
      context.handle(
        _minStockLevelMeta,
        minStockLevel.isAcceptableOrUnknown(
          data['min_stock_level']!,
          _minStockLevelMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('default_supplier_id')) {
      context.handle(
        _defaultSupplierIdMeta,
        defaultSupplierId.isAcceptableOrUnknown(
          data['default_supplier_id']!,
          _defaultSupplierIdMeta,
        ),
      );
    }
    if (data.containsKey('default_supplier_name')) {
      context.handle(
        _defaultSupplierNameMeta,
        defaultSupplierName.isAcceptableOrUnknown(
          data['default_supplier_name']!,
          _defaultSupplierNameMeta,
        ),
      );
    }
    if (data.containsKey('cgst_percent')) {
      context.handle(
        _cgstPercentMeta,
        cgstPercent.isAcceptableOrUnknown(
          data['cgst_percent']!,
          _cgstPercentMeta,
        ),
      );
    }
    if (data.containsKey('sgst_percent')) {
      context.handle(
        _sgstPercentMeta,
        sgstPercent.isAcceptableOrUnknown(
          data['sgst_percent']!,
          _sgstPercentMeta,
        ),
      );
    }
    if (data.containsKey('hsn_code')) {
      context.handle(
        _hsnCodeMeta,
        hsnCode.isAcceptableOrUnknown(data['hsn_code']!, _hsnCodeMeta),
      );
    }
    if (data.containsKey('custom_fields_json')) {
      context.handle(
        _customFieldsJsonMeta,
        customFieldsJson.isAcceptableOrUnknown(
          data['custom_fields_json']!,
          _customFieldsJsonMeta,
        ),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('mrp')) {
      context.handle(
        _mrpMeta,
        mrp.isAcceptableOrUnknown(data['mrp']!, _mrpMeta),
      );
    }
    if (data.containsKey('composition')) {
      context.handle(
        _compositionMeta,
        composition.isAcceptableOrUnknown(
          data['composition']!,
          _compositionMeta,
        ),
      );
    }
    if (data.containsKey('drug_schedule')) {
      context.handle(
        _drugScheduleMeta,
        drugSchedule.isAcceptableOrUnknown(
          data['drug_schedule']!,
          _drugScheduleMeta,
        ),
      );
    }
    if (data.containsKey('pack_unit')) {
      context.handle(
        _packUnitMeta,
        packUnit.isAcceptableOrUnknown(data['pack_unit']!, _packUnitMeta),
      );
    }
    if (data.containsKey('units_per_pack')) {
      context.handle(
        _unitsPerPackMeta,
        unitsPerPack.isAcceptableOrUnknown(
          data['units_per_pack']!,
          _unitsPerPackMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      indexNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}index_no'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      purchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_price'],
      )!,
      salesPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sales_price'],
      )!,
      currentStock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_stock'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      minStockLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_stock_level'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      defaultSupplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_supplier_id'],
      ),
      defaultSupplierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_supplier_name'],
      ),
      cgstPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cgst_percent'],
      )!,
      sgstPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sgst_percent'],
      )!,
      hsnCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hsn_code'],
      ),
      customFieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_fields_json'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      mrp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mrp'],
      ),
      composition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composition'],
      ),
      drugSchedule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drug_schedule'],
      ),
      packUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_unit'],
      ),
      unitsPerPack: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}units_per_pack'],
      )!,
    );
  }

  @override
  $ProductRecordsTable createAlias(String alias) {
    return $ProductRecordsTable(attachedDatabase, alias);
  }
}

class ProductRecord extends DataClass implements Insertable<ProductRecord> {
  final int id;
  final String? serverId;
  final int indexNo;
  final String name;
  final String companyName;
  final String category;
  final String? barcode;
  final double purchasePrice;
  final double salesPrice;
  final int currentStock;
  final String? unit;
  final bool isActive;
  final int syncStatus;
  final DateTime updatedAt;
  final DateTime createdAt;
  final int? minStockLevel;
  final String? description;
  final String? imageUrl;
  final String? defaultSupplierId;
  final String? defaultSupplierName;
  final double cgstPercent;
  final double sgstPercent;
  final String? hsnCode;
  final String? customFieldsJson;
  final String? size;
  final String? color;
  final double? mrp;
  final String? composition;
  final String? drugSchedule;

  /// Pack / strip / bag label when buying bulk and selling loose (e.g. Strip, Bag).
  final String? packUnit;

  /// How many base [unit] items are in one pack (e.g. 10 tablets per strip).
  final int unitsPerPack;
  const ProductRecord({
    required this.id,
    this.serverId,
    required this.indexNo,
    required this.name,
    required this.companyName,
    required this.category,
    this.barcode,
    required this.purchasePrice,
    required this.salesPrice,
    required this.currentStock,
    this.unit,
    required this.isActive,
    required this.syncStatus,
    required this.updatedAt,
    required this.createdAt,
    this.minStockLevel,
    this.description,
    this.imageUrl,
    this.defaultSupplierId,
    this.defaultSupplierName,
    required this.cgstPercent,
    required this.sgstPercent,
    this.hsnCode,
    this.customFieldsJson,
    this.size,
    this.color,
    this.mrp,
    this.composition,
    this.drugSchedule,
    this.packUnit,
    required this.unitsPerPack,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['index_no'] = Variable<int>(indexNo);
    map['name'] = Variable<String>(name);
    map['company_name'] = Variable<String>(companyName);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['purchase_price'] = Variable<double>(purchasePrice);
    map['sales_price'] = Variable<double>(salesPrice);
    map['current_stock'] = Variable<int>(currentStock);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['sync_status'] = Variable<int>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || minStockLevel != null) {
      map['min_stock_level'] = Variable<int>(minStockLevel);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || defaultSupplierId != null) {
      map['default_supplier_id'] = Variable<String>(defaultSupplierId);
    }
    if (!nullToAbsent || defaultSupplierName != null) {
      map['default_supplier_name'] = Variable<String>(defaultSupplierName);
    }
    map['cgst_percent'] = Variable<double>(cgstPercent);
    map['sgst_percent'] = Variable<double>(sgstPercent);
    if (!nullToAbsent || hsnCode != null) {
      map['hsn_code'] = Variable<String>(hsnCode);
    }
    if (!nullToAbsent || customFieldsJson != null) {
      map['custom_fields_json'] = Variable<String>(customFieldsJson);
    }
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<String>(size);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || mrp != null) {
      map['mrp'] = Variable<double>(mrp);
    }
    if (!nullToAbsent || composition != null) {
      map['composition'] = Variable<String>(composition);
    }
    if (!nullToAbsent || drugSchedule != null) {
      map['drug_schedule'] = Variable<String>(drugSchedule);
    }
    if (!nullToAbsent || packUnit != null) {
      map['pack_unit'] = Variable<String>(packUnit);
    }
    map['units_per_pack'] = Variable<int>(unitsPerPack);
    return map;
  }

  ProductRecordsCompanion toCompanion(bool nullToAbsent) {
    return ProductRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      indexNo: Value(indexNo),
      name: Value(name),
      companyName: Value(companyName),
      category: Value(category),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      purchasePrice: Value(purchasePrice),
      salesPrice: Value(salesPrice),
      currentStock: Value(currentStock),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
      minStockLevel: minStockLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(minStockLevel),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      defaultSupplierId: defaultSupplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultSupplierId),
      defaultSupplierName: defaultSupplierName == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultSupplierName),
      cgstPercent: Value(cgstPercent),
      sgstPercent: Value(sgstPercent),
      hsnCode: hsnCode == null && nullToAbsent
          ? const Value.absent()
          : Value(hsnCode),
      customFieldsJson: customFieldsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(customFieldsJson),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      mrp: mrp == null && nullToAbsent ? const Value.absent() : Value(mrp),
      composition: composition == null && nullToAbsent
          ? const Value.absent()
          : Value(composition),
      drugSchedule: drugSchedule == null && nullToAbsent
          ? const Value.absent()
          : Value(drugSchedule),
      packUnit: packUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(packUnit),
      unitsPerPack: Value(unitsPerPack),
    );
  }

  factory ProductRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      indexNo: serializer.fromJson<int>(json['indexNo']),
      name: serializer.fromJson<String>(json['name']),
      companyName: serializer.fromJson<String>(json['companyName']),
      category: serializer.fromJson<String>(json['category']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      purchasePrice: serializer.fromJson<double>(json['purchasePrice']),
      salesPrice: serializer.fromJson<double>(json['salesPrice']),
      currentStock: serializer.fromJson<int>(json['currentStock']),
      unit: serializer.fromJson<String?>(json['unit']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      minStockLevel: serializer.fromJson<int?>(json['minStockLevel']),
      description: serializer.fromJson<String?>(json['description']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      defaultSupplierId: serializer.fromJson<String?>(
        json['defaultSupplierId'],
      ),
      defaultSupplierName: serializer.fromJson<String?>(
        json['defaultSupplierName'],
      ),
      cgstPercent: serializer.fromJson<double>(json['cgstPercent']),
      sgstPercent: serializer.fromJson<double>(json['sgstPercent']),
      hsnCode: serializer.fromJson<String?>(json['hsnCode']),
      customFieldsJson: serializer.fromJson<String?>(json['customFieldsJson']),
      size: serializer.fromJson<String?>(json['size']),
      color: serializer.fromJson<String?>(json['color']),
      mrp: serializer.fromJson<double?>(json['mrp']),
      composition: serializer.fromJson<String?>(json['composition']),
      drugSchedule: serializer.fromJson<String?>(json['drugSchedule']),
      packUnit: serializer.fromJson<String?>(json['packUnit']),
      unitsPerPack: serializer.fromJson<int>(json['unitsPerPack']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'indexNo': serializer.toJson<int>(indexNo),
      'name': serializer.toJson<String>(name),
      'companyName': serializer.toJson<String>(companyName),
      'category': serializer.toJson<String>(category),
      'barcode': serializer.toJson<String?>(barcode),
      'purchasePrice': serializer.toJson<double>(purchasePrice),
      'salesPrice': serializer.toJson<double>(salesPrice),
      'currentStock': serializer.toJson<int>(currentStock),
      'unit': serializer.toJson<String?>(unit),
      'isActive': serializer.toJson<bool>(isActive),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'minStockLevel': serializer.toJson<int?>(minStockLevel),
      'description': serializer.toJson<String?>(description),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'defaultSupplierId': serializer.toJson<String?>(defaultSupplierId),
      'defaultSupplierName': serializer.toJson<String?>(defaultSupplierName),
      'cgstPercent': serializer.toJson<double>(cgstPercent),
      'sgstPercent': serializer.toJson<double>(sgstPercent),
      'hsnCode': serializer.toJson<String?>(hsnCode),
      'customFieldsJson': serializer.toJson<String?>(customFieldsJson),
      'size': serializer.toJson<String?>(size),
      'color': serializer.toJson<String?>(color),
      'mrp': serializer.toJson<double?>(mrp),
      'composition': serializer.toJson<String?>(composition),
      'drugSchedule': serializer.toJson<String?>(drugSchedule),
      'packUnit': serializer.toJson<String?>(packUnit),
      'unitsPerPack': serializer.toJson<int>(unitsPerPack),
    };
  }

  ProductRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    int? indexNo,
    String? name,
    String? companyName,
    String? category,
    Value<String?> barcode = const Value.absent(),
    double? purchasePrice,
    double? salesPrice,
    int? currentStock,
    Value<String?> unit = const Value.absent(),
    bool? isActive,
    int? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
    Value<int?> minStockLevel = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> defaultSupplierId = const Value.absent(),
    Value<String?> defaultSupplierName = const Value.absent(),
    double? cgstPercent,
    double? sgstPercent,
    Value<String?> hsnCode = const Value.absent(),
    Value<String?> customFieldsJson = const Value.absent(),
    Value<String?> size = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<double?> mrp = const Value.absent(),
    Value<String?> composition = const Value.absent(),
    Value<String?> drugSchedule = const Value.absent(),
    Value<String?> packUnit = const Value.absent(),
    int? unitsPerPack,
  }) => ProductRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    indexNo: indexNo ?? this.indexNo,
    name: name ?? this.name,
    companyName: companyName ?? this.companyName,
    category: category ?? this.category,
    barcode: barcode.present ? barcode.value : this.barcode,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    salesPrice: salesPrice ?? this.salesPrice,
    currentStock: currentStock ?? this.currentStock,
    unit: unit.present ? unit.value : this.unit,
    isActive: isActive ?? this.isActive,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
    minStockLevel: minStockLevel.present
        ? minStockLevel.value
        : this.minStockLevel,
    description: description.present ? description.value : this.description,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    defaultSupplierId: defaultSupplierId.present
        ? defaultSupplierId.value
        : this.defaultSupplierId,
    defaultSupplierName: defaultSupplierName.present
        ? defaultSupplierName.value
        : this.defaultSupplierName,
    cgstPercent: cgstPercent ?? this.cgstPercent,
    sgstPercent: sgstPercent ?? this.sgstPercent,
    hsnCode: hsnCode.present ? hsnCode.value : this.hsnCode,
    customFieldsJson: customFieldsJson.present
        ? customFieldsJson.value
        : this.customFieldsJson,
    size: size.present ? size.value : this.size,
    color: color.present ? color.value : this.color,
    mrp: mrp.present ? mrp.value : this.mrp,
    composition: composition.present ? composition.value : this.composition,
    drugSchedule: drugSchedule.present ? drugSchedule.value : this.drugSchedule,
    packUnit: packUnit.present ? packUnit.value : this.packUnit,
    unitsPerPack: unitsPerPack ?? this.unitsPerPack,
  );
  ProductRecord copyWithCompanion(ProductRecordsCompanion data) {
    return ProductRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      indexNo: data.indexNo.present ? data.indexNo.value : this.indexNo,
      name: data.name.present ? data.name.value : this.name,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      category: data.category.present ? data.category.value : this.category,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      salesPrice: data.salesPrice.present
          ? data.salesPrice.value
          : this.salesPrice,
      currentStock: data.currentStock.present
          ? data.currentStock.value
          : this.currentStock,
      unit: data.unit.present ? data.unit.value : this.unit,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      minStockLevel: data.minStockLevel.present
          ? data.minStockLevel.value
          : this.minStockLevel,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      defaultSupplierId: data.defaultSupplierId.present
          ? data.defaultSupplierId.value
          : this.defaultSupplierId,
      defaultSupplierName: data.defaultSupplierName.present
          ? data.defaultSupplierName.value
          : this.defaultSupplierName,
      cgstPercent: data.cgstPercent.present
          ? data.cgstPercent.value
          : this.cgstPercent,
      sgstPercent: data.sgstPercent.present
          ? data.sgstPercent.value
          : this.sgstPercent,
      hsnCode: data.hsnCode.present ? data.hsnCode.value : this.hsnCode,
      customFieldsJson: data.customFieldsJson.present
          ? data.customFieldsJson.value
          : this.customFieldsJson,
      size: data.size.present ? data.size.value : this.size,
      color: data.color.present ? data.color.value : this.color,
      mrp: data.mrp.present ? data.mrp.value : this.mrp,
      composition: data.composition.present
          ? data.composition.value
          : this.composition,
      drugSchedule: data.drugSchedule.present
          ? data.drugSchedule.value
          : this.drugSchedule,
      packUnit: data.packUnit.present ? data.packUnit.value : this.packUnit,
      unitsPerPack: data.unitsPerPack.present
          ? data.unitsPerPack.value
          : this.unitsPerPack,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('indexNo: $indexNo, ')
          ..write('name: $name, ')
          ..write('companyName: $companyName, ')
          ..write('category: $category, ')
          ..write('barcode: $barcode, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('salesPrice: $salesPrice, ')
          ..write('currentStock: $currentStock, ')
          ..write('unit: $unit, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('minStockLevel: $minStockLevel, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('defaultSupplierId: $defaultSupplierId, ')
          ..write('defaultSupplierName: $defaultSupplierName, ')
          ..write('cgstPercent: $cgstPercent, ')
          ..write('sgstPercent: $sgstPercent, ')
          ..write('hsnCode: $hsnCode, ')
          ..write('customFieldsJson: $customFieldsJson, ')
          ..write('size: $size, ')
          ..write('color: $color, ')
          ..write('mrp: $mrp, ')
          ..write('composition: $composition, ')
          ..write('drugSchedule: $drugSchedule, ')
          ..write('packUnit: $packUnit, ')
          ..write('unitsPerPack: $unitsPerPack')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    indexNo,
    name,
    companyName,
    category,
    barcode,
    purchasePrice,
    salesPrice,
    currentStock,
    unit,
    isActive,
    syncStatus,
    updatedAt,
    createdAt,
    minStockLevel,
    description,
    imageUrl,
    defaultSupplierId,
    defaultSupplierName,
    cgstPercent,
    sgstPercent,
    hsnCode,
    customFieldsJson,
    size,
    color,
    mrp,
    composition,
    drugSchedule,
    packUnit,
    unitsPerPack,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.indexNo == this.indexNo &&
          other.name == this.name &&
          other.companyName == this.companyName &&
          other.category == this.category &&
          other.barcode == this.barcode &&
          other.purchasePrice == this.purchasePrice &&
          other.salesPrice == this.salesPrice &&
          other.currentStock == this.currentStock &&
          other.unit == this.unit &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt &&
          other.minStockLevel == this.minStockLevel &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl &&
          other.defaultSupplierId == this.defaultSupplierId &&
          other.defaultSupplierName == this.defaultSupplierName &&
          other.cgstPercent == this.cgstPercent &&
          other.sgstPercent == this.sgstPercent &&
          other.hsnCode == this.hsnCode &&
          other.customFieldsJson == this.customFieldsJson &&
          other.size == this.size &&
          other.color == this.color &&
          other.mrp == this.mrp &&
          other.composition == this.composition &&
          other.drugSchedule == this.drugSchedule &&
          other.packUnit == this.packUnit &&
          other.unitsPerPack == this.unitsPerPack);
}

class ProductRecordsCompanion extends UpdateCompanion<ProductRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<int> indexNo;
  final Value<String> name;
  final Value<String> companyName;
  final Value<String> category;
  final Value<String?> barcode;
  final Value<double> purchasePrice;
  final Value<double> salesPrice;
  final Value<int> currentStock;
  final Value<String?> unit;
  final Value<bool> isActive;
  final Value<int> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  final Value<int?> minStockLevel;
  final Value<String?> description;
  final Value<String?> imageUrl;
  final Value<String?> defaultSupplierId;
  final Value<String?> defaultSupplierName;
  final Value<double> cgstPercent;
  final Value<double> sgstPercent;
  final Value<String?> hsnCode;
  final Value<String?> customFieldsJson;
  final Value<String?> size;
  final Value<String?> color;
  final Value<double?> mrp;
  final Value<String?> composition;
  final Value<String?> drugSchedule;
  final Value<String?> packUnit;
  final Value<int> unitsPerPack;
  const ProductRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.indexNo = const Value.absent(),
    this.name = const Value.absent(),
    this.companyName = const Value.absent(),
    this.category = const Value.absent(),
    this.barcode = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.salesPrice = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.unit = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.minStockLevel = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.defaultSupplierId = const Value.absent(),
    this.defaultSupplierName = const Value.absent(),
    this.cgstPercent = const Value.absent(),
    this.sgstPercent = const Value.absent(),
    this.hsnCode = const Value.absent(),
    this.customFieldsJson = const Value.absent(),
    this.size = const Value.absent(),
    this.color = const Value.absent(),
    this.mrp = const Value.absent(),
    this.composition = const Value.absent(),
    this.drugSchedule = const Value.absent(),
    this.packUnit = const Value.absent(),
    this.unitsPerPack = const Value.absent(),
  });
  ProductRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.indexNo = const Value.absent(),
    required String name,
    this.companyName = const Value.absent(),
    this.category = const Value.absent(),
    this.barcode = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.salesPrice = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.unit = const Value.absent(),
    this.isActive = const Value.absent(),
    required int syncStatus,
    required DateTime updatedAt,
    required DateTime createdAt,
    this.minStockLevel = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.defaultSupplierId = const Value.absent(),
    this.defaultSupplierName = const Value.absent(),
    this.cgstPercent = const Value.absent(),
    this.sgstPercent = const Value.absent(),
    this.hsnCode = const Value.absent(),
    this.customFieldsJson = const Value.absent(),
    this.size = const Value.absent(),
    this.color = const Value.absent(),
    this.mrp = const Value.absent(),
    this.composition = const Value.absent(),
    this.drugSchedule = const Value.absent(),
    this.packUnit = const Value.absent(),
    this.unitsPerPack = const Value.absent(),
  }) : name = Value(name),
       syncStatus = Value(syncStatus),
       updatedAt = Value(updatedAt),
       createdAt = Value(createdAt);
  static Insertable<ProductRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<int>? indexNo,
    Expression<String>? name,
    Expression<String>? companyName,
    Expression<String>? category,
    Expression<String>? barcode,
    Expression<double>? purchasePrice,
    Expression<double>? salesPrice,
    Expression<int>? currentStock,
    Expression<String>? unit,
    Expression<bool>? isActive,
    Expression<int>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? minStockLevel,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<String>? defaultSupplierId,
    Expression<String>? defaultSupplierName,
    Expression<double>? cgstPercent,
    Expression<double>? sgstPercent,
    Expression<String>? hsnCode,
    Expression<String>? customFieldsJson,
    Expression<String>? size,
    Expression<String>? color,
    Expression<double>? mrp,
    Expression<String>? composition,
    Expression<String>? drugSchedule,
    Expression<String>? packUnit,
    Expression<int>? unitsPerPack,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (indexNo != null) 'index_no': indexNo,
      if (name != null) 'name': name,
      if (companyName != null) 'company_name': companyName,
      if (category != null) 'category': category,
      if (barcode != null) 'barcode': barcode,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (salesPrice != null) 'sales_price': salesPrice,
      if (currentStock != null) 'current_stock': currentStock,
      if (unit != null) 'unit': unit,
      if (isActive != null) 'is_active': isActive,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (minStockLevel != null) 'min_stock_level': minStockLevel,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (defaultSupplierId != null) 'default_supplier_id': defaultSupplierId,
      if (defaultSupplierName != null)
        'default_supplier_name': defaultSupplierName,
      if (cgstPercent != null) 'cgst_percent': cgstPercent,
      if (sgstPercent != null) 'sgst_percent': sgstPercent,
      if (hsnCode != null) 'hsn_code': hsnCode,
      if (customFieldsJson != null) 'custom_fields_json': customFieldsJson,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      if (mrp != null) 'mrp': mrp,
      if (composition != null) 'composition': composition,
      if (drugSchedule != null) 'drug_schedule': drugSchedule,
      if (packUnit != null) 'pack_unit': packUnit,
      if (unitsPerPack != null) 'units_per_pack': unitsPerPack,
    });
  }

  ProductRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<int>? indexNo,
    Value<String>? name,
    Value<String>? companyName,
    Value<String>? category,
    Value<String?>? barcode,
    Value<double>? purchasePrice,
    Value<double>? salesPrice,
    Value<int>? currentStock,
    Value<String?>? unit,
    Value<bool>? isActive,
    Value<int>? syncStatus,
    Value<DateTime>? updatedAt,
    Value<DateTime>? createdAt,
    Value<int?>? minStockLevel,
    Value<String?>? description,
    Value<String?>? imageUrl,
    Value<String?>? defaultSupplierId,
    Value<String?>? defaultSupplierName,
    Value<double>? cgstPercent,
    Value<double>? sgstPercent,
    Value<String?>? hsnCode,
    Value<String?>? customFieldsJson,
    Value<String?>? size,
    Value<String?>? color,
    Value<double?>? mrp,
    Value<String?>? composition,
    Value<String?>? drugSchedule,
    Value<String?>? packUnit,
    Value<int>? unitsPerPack,
  }) {
    return ProductRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      indexNo: indexNo ?? this.indexNo,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      defaultSupplierId: defaultSupplierId ?? this.defaultSupplierId,
      defaultSupplierName: defaultSupplierName ?? this.defaultSupplierName,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      hsnCode: hsnCode ?? this.hsnCode,
      customFieldsJson: customFieldsJson ?? this.customFieldsJson,
      size: size ?? this.size,
      color: color ?? this.color,
      mrp: mrp ?? this.mrp,
      composition: composition ?? this.composition,
      drugSchedule: drugSchedule ?? this.drugSchedule,
      packUnit: packUnit ?? this.packUnit,
      unitsPerPack: unitsPerPack ?? this.unitsPerPack,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (indexNo.present) {
      map['index_no'] = Variable<int>(indexNo.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (salesPrice.present) {
      map['sales_price'] = Variable<double>(salesPrice.value);
    }
    if (currentStock.present) {
      map['current_stock'] = Variable<int>(currentStock.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (minStockLevel.present) {
      map['min_stock_level'] = Variable<int>(minStockLevel.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (defaultSupplierId.present) {
      map['default_supplier_id'] = Variable<String>(defaultSupplierId.value);
    }
    if (defaultSupplierName.present) {
      map['default_supplier_name'] = Variable<String>(
        defaultSupplierName.value,
      );
    }
    if (cgstPercent.present) {
      map['cgst_percent'] = Variable<double>(cgstPercent.value);
    }
    if (sgstPercent.present) {
      map['sgst_percent'] = Variable<double>(sgstPercent.value);
    }
    if (hsnCode.present) {
      map['hsn_code'] = Variable<String>(hsnCode.value);
    }
    if (customFieldsJson.present) {
      map['custom_fields_json'] = Variable<String>(customFieldsJson.value);
    }
    if (size.present) {
      map['size'] = Variable<String>(size.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (mrp.present) {
      map['mrp'] = Variable<double>(mrp.value);
    }
    if (composition.present) {
      map['composition'] = Variable<String>(composition.value);
    }
    if (drugSchedule.present) {
      map['drug_schedule'] = Variable<String>(drugSchedule.value);
    }
    if (packUnit.present) {
      map['pack_unit'] = Variable<String>(packUnit.value);
    }
    if (unitsPerPack.present) {
      map['units_per_pack'] = Variable<int>(unitsPerPack.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('indexNo: $indexNo, ')
          ..write('name: $name, ')
          ..write('companyName: $companyName, ')
          ..write('category: $category, ')
          ..write('barcode: $barcode, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('salesPrice: $salesPrice, ')
          ..write('currentStock: $currentStock, ')
          ..write('unit: $unit, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('minStockLevel: $minStockLevel, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('defaultSupplierId: $defaultSupplierId, ')
          ..write('defaultSupplierName: $defaultSupplierName, ')
          ..write('cgstPercent: $cgstPercent, ')
          ..write('sgstPercent: $sgstPercent, ')
          ..write('hsnCode: $hsnCode, ')
          ..write('customFieldsJson: $customFieldsJson, ')
          ..write('size: $size, ')
          ..write('color: $color, ')
          ..write('mrp: $mrp, ')
          ..write('composition: $composition, ')
          ..write('drugSchedule: $drugSchedule, ')
          ..write('packUnit: $packUnit, ')
          ..write('unitsPerPack: $unitsPerPack')
          ..write(')'))
        .toString();
  }
}

class $PurchaseRecordsTable extends PurchaseRecords
    with TableInfo<$PurchaseRecordsTable, PurchaseRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierNameMeta = const VerificationMeta(
    'supplierName',
  );
  @override
  late final GeneratedColumn<String> supplierName = GeneratedColumn<String>(
    'supplier_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _purchasePriceMeta = const VerificationMeta(
    'purchasePrice',
  );
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
    'purchase_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _salesPriceMeta = const VerificationMeta(
    'salesPrice',
  );
  @override
  late final GeneratedColumn<double> salesPrice = GeneratedColumn<double>(
    'sales_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _productionDateMeta = const VerificationMeta(
    'productionDate',
  );
  @override
  late final GeneratedColumn<DateTime> productionDate =
      GeneratedColumn<DateTime>(
        'production_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warrantyMonthsMeta = const VerificationMeta(
    'warrantyMonths',
  );
  @override
  late final GeneratedColumn<int> warrantyMonths = GeneratedColumn<int>(
    'warranty_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    productId,
    productName,
    supplierId,
    supplierName,
    companyId,
    companyName,
    quantity,
    unit,
    purchasePrice,
    salesPrice,
    totalAmount,
    productionDate,
    expiryDate,
    warrantyMonths,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    }
    if (data.containsKey('supplier_name')) {
      context.handle(
        _supplierNameMeta,
        supplierName.isAcceptableOrUnknown(
          data['supplier_name']!,
          _supplierNameMeta,
        ),
      );
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
        _purchasePriceMeta,
        purchasePrice.isAcceptableOrUnknown(
          data['purchase_price']!,
          _purchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('sales_price')) {
      context.handle(
        _salesPriceMeta,
        salesPrice.isAcceptableOrUnknown(data['sales_price']!, _salesPriceMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('production_date')) {
      context.handle(
        _productionDateMeta,
        productionDate.isAcceptableOrUnknown(
          data['production_date']!,
          _productionDateMeta,
        ),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('warranty_months')) {
      context.handle(
        _warrantyMonthsMeta,
        warrantyMonths.isAcceptableOrUnknown(
          data['warranty_months']!,
          _warrantyMonthsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      ),
      supplierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_name'],
      ),
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      purchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_price'],
      )!,
      salesPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sales_price'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      productionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}production_date'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      warrantyMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warranty_months'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PurchaseRecordsTable createAlias(String alias) {
    return $PurchaseRecordsTable(attachedDatabase, alias);
  }
}

class PurchaseRecord extends DataClass implements Insertable<PurchaseRecord> {
  final int id;
  final String? serverId;
  final String productId;
  final String productName;
  final String? supplierId;
  final String? supplierName;
  final String? companyId;
  final String? companyName;
  final int quantity;
  final String unit;
  final double purchasePrice;
  final double salesPrice;
  final double totalAmount;
  final DateTime? productionDate;
  final DateTime? expiryDate;
  final int? warrantyMonths;
  final String? notes;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PurchaseRecord({
    required this.id,
    this.serverId,
    required this.productId,
    required this.productName,
    this.supplierId,
    this.supplierName,
    this.companyId,
    this.companyName,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.salesPrice,
    required this.totalAmount,
    this.productionDate,
    this.expiryDate,
    this.warrantyMonths,
    this.notes,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || supplierId != null) {
      map['supplier_id'] = Variable<String>(supplierId);
    }
    if (!nullToAbsent || supplierName != null) {
      map['supplier_name'] = Variable<String>(supplierName);
    }
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    map['quantity'] = Variable<int>(quantity);
    map['unit'] = Variable<String>(unit);
    map['purchase_price'] = Variable<double>(purchasePrice);
    map['sales_price'] = Variable<double>(salesPrice);
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || productionDate != null) {
      map['production_date'] = Variable<DateTime>(productionDate);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    if (!nullToAbsent || warrantyMonths != null) {
      map['warranty_months'] = Variable<int>(warrantyMonths);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PurchaseRecordsCompanion toCompanion(bool nullToAbsent) {
    return PurchaseRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      productId: Value(productId),
      productName: Value(productName),
      supplierId: supplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierId),
      supplierName: supplierName == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierName),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
      quantity: Value(quantity),
      unit: Value(unit),
      purchasePrice: Value(purchasePrice),
      salesPrice: Value(salesPrice),
      totalAmount: Value(totalAmount),
      productionDate: productionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(productionDate),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      warrantyMonths: warrantyMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyMonths),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PurchaseRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      supplierId: serializer.fromJson<String?>(json['supplierId']),
      supplierName: serializer.fromJson<String?>(json['supplierName']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      purchasePrice: serializer.fromJson<double>(json['purchasePrice']),
      salesPrice: serializer.fromJson<double>(json['salesPrice']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      productionDate: serializer.fromJson<DateTime?>(json['productionDate']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      warrantyMonths: serializer.fromJson<int?>(json['warrantyMonths']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'supplierId': serializer.toJson<String?>(supplierId),
      'supplierName': serializer.toJson<String?>(supplierName),
      'companyId': serializer.toJson<String?>(companyId),
      'companyName': serializer.toJson<String?>(companyName),
      'quantity': serializer.toJson<int>(quantity),
      'unit': serializer.toJson<String>(unit),
      'purchasePrice': serializer.toJson<double>(purchasePrice),
      'salesPrice': serializer.toJson<double>(salesPrice),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'productionDate': serializer.toJson<DateTime?>(productionDate),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'warrantyMonths': serializer.toJson<int?>(warrantyMonths),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PurchaseRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? productId,
    String? productName,
    Value<String?> supplierId = const Value.absent(),
    Value<String?> supplierName = const Value.absent(),
    Value<String?> companyId = const Value.absent(),
    Value<String?> companyName = const Value.absent(),
    int? quantity,
    String? unit,
    double? purchasePrice,
    double? salesPrice,
    double? totalAmount,
    Value<DateTime?> productionDate = const Value.absent(),
    Value<DateTime?> expiryDate = const Value.absent(),
    Value<int?> warrantyMonths = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PurchaseRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    supplierId: supplierId.present ? supplierId.value : this.supplierId,
    supplierName: supplierName.present ? supplierName.value : this.supplierName,
    companyId: companyId.present ? companyId.value : this.companyId,
    companyName: companyName.present ? companyName.value : this.companyName,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    salesPrice: salesPrice ?? this.salesPrice,
    totalAmount: totalAmount ?? this.totalAmount,
    productionDate: productionDate.present
        ? productionDate.value
        : this.productionDate,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    warrantyMonths: warrantyMonths.present
        ? warrantyMonths.value
        : this.warrantyMonths,
    notes: notes.present ? notes.value : this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PurchaseRecord copyWithCompanion(PurchaseRecordsCompanion data) {
    return PurchaseRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      supplierName: data.supplierName.present
          ? data.supplierName.value
          : this.supplierName,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      salesPrice: data.salesPrice.present
          ? data.salesPrice.value
          : this.salesPrice,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      productionDate: data.productionDate.present
          ? data.productionDate.value
          : this.productionDate,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      warrantyMonths: data.warrantyMonths.present
          ? data.warrantyMonths.value
          : this.warrantyMonths,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('supplierId: $supplierId, ')
          ..write('supplierName: $supplierName, ')
          ..write('companyId: $companyId, ')
          ..write('companyName: $companyName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('salesPrice: $salesPrice, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('productionDate: $productionDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    productId,
    productName,
    supplierId,
    supplierName,
    companyId,
    companyName,
    quantity,
    unit,
    purchasePrice,
    salesPrice,
    totalAmount,
    productionDate,
    expiryDate,
    warrantyMonths,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.supplierId == this.supplierId &&
          other.supplierName == this.supplierName &&
          other.companyId == this.companyId &&
          other.companyName == this.companyName &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.purchasePrice == this.purchasePrice &&
          other.salesPrice == this.salesPrice &&
          other.totalAmount == this.totalAmount &&
          other.productionDate == this.productionDate &&
          other.expiryDate == this.expiryDate &&
          other.warrantyMonths == this.warrantyMonths &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PurchaseRecordsCompanion extends UpdateCompanion<PurchaseRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String?> supplierId;
  final Value<String?> supplierName;
  final Value<String?> companyId;
  final Value<String?> companyName;
  final Value<int> quantity;
  final Value<String> unit;
  final Value<double> purchasePrice;
  final Value<double> salesPrice;
  final Value<double> totalAmount;
  final Value<DateTime?> productionDate;
  final Value<DateTime?> expiryDate;
  final Value<int?> warrantyMonths;
  final Value<String?> notes;
  final Value<int> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PurchaseRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.supplierName = const Value.absent(),
    this.companyId = const Value.absent(),
    this.companyName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.salesPrice = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.productionDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PurchaseRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String productId,
    this.productName = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.supplierName = const Value.absent(),
    this.companyId = const Value.absent(),
    this.companyName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.salesPrice = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.productionDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.notes = const Value.absent(),
    required int syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : productId = Value(productId),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PurchaseRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? supplierId,
    Expression<String>? supplierName,
    Expression<String>? companyId,
    Expression<String>? companyName,
    Expression<int>? quantity,
    Expression<String>? unit,
    Expression<double>? purchasePrice,
    Expression<double>? salesPrice,
    Expression<double>? totalAmount,
    Expression<DateTime>? productionDate,
    Expression<DateTime>? expiryDate,
    Expression<int>? warrantyMonths,
    Expression<String>? notes,
    Expression<int>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (supplierId != null) 'supplier_id': supplierId,
      if (supplierName != null) 'supplier_name': supplierName,
      if (companyId != null) 'company_id': companyId,
      if (companyName != null) 'company_name': companyName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (salesPrice != null) 'sales_price': salesPrice,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (productionDate != null) 'production_date': productionDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (warrantyMonths != null) 'warranty_months': warrantyMonths,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PurchaseRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? productId,
    Value<String>? productName,
    Value<String?>? supplierId,
    Value<String?>? supplierName,
    Value<String?>? companyId,
    Value<String?>? companyName,
    Value<int>? quantity,
    Value<String>? unit,
    Value<double>? purchasePrice,
    Value<double>? salesPrice,
    Value<double>? totalAmount,
    Value<DateTime?>? productionDate,
    Value<DateTime?>? expiryDate,
    Value<int?>? warrantyMonths,
    Value<String?>? notes,
    Value<int>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PurchaseRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      productionDate: productionDate ?? this.productionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (supplierName.present) {
      map['supplier_name'] = Variable<String>(supplierName.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (salesPrice.present) {
      map['sales_price'] = Variable<double>(salesPrice.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (productionDate.present) {
      map['production_date'] = Variable<DateTime>(productionDate.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (warrantyMonths.present) {
      map['warranty_months'] = Variable<int>(warrantyMonths.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('supplierId: $supplierId, ')
          ..write('supplierName: $supplierName, ')
          ..write('companyId: $companyId, ')
          ..write('companyName: $companyName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('salesPrice: $salesPrice, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('productionDate: $productionDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PurchaseBatchRecordsTable extends PurchaseBatchRecords
    with TableInfo<$PurchaseBatchRecordsTable, PurchaseBatchRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseBatchRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _productUniqueKeyMeta = const VerificationMeta(
    'productUniqueKey',
  );
  @override
  late final GeneratedColumn<String> productUniqueKey = GeneratedColumn<String>(
    'product_unique_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _purchasePriceMeta = const VerificationMeta(
    'purchasePrice',
  );
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
    'purchase_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellingPriceMeta = const VerificationMeta(
    'sellingPrice',
  );
  @override
  late final GeneratedColumn<double> sellingPrice = GeneratedColumn<double>(
    'selling_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quantityPurchasedMeta = const VerificationMeta(
    'quantityPurchased',
  );
  @override
  late final GeneratedColumn<int> quantityPurchased = GeneratedColumn<int>(
    'quantity_purchased',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quantityRemainingMeta = const VerificationMeta(
    'quantityRemaining',
  );
  @override
  late final GeneratedColumn<int> quantityRemaining = GeneratedColumn<int>(
    'quantity_remaining',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierNameMeta = const VerificationMeta(
    'supplierName',
  );
  @override
  late final GeneratedColumn<String> supplierName = GeneratedColumn<String>(
    'supplier_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _batchNumberMeta = const VerificationMeta(
    'batchNumber',
  );
  @override
  late final GeneratedColumn<String> batchNumber = GeneratedColumn<String>(
    'batch_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productionDateMeta = const VerificationMeta(
    'productionDate',
  );
  @override
  late final GeneratedColumn<DateTime> productionDate =
      GeneratedColumn<DateTime>(
        'production_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _warrantyMonthsMeta = const VerificationMeta(
    'warrantyMonths',
  );
  @override
  late final GeneratedColumn<int> warrantyMonths = GeneratedColumn<int>(
    'warranty_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isConsumedMeta = const VerificationMeta(
    'isConsumed',
  );
  @override
  late final GeneratedColumn<bool> isConsumed = GeneratedColumn<bool>(
    'is_consumed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_consumed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    productId,
    productName,
    companyName,
    modelName,
    category,
    productUniqueKey,
    purchasePrice,
    sellingPrice,
    quantityPurchased,
    quantityRemaining,
    purchaseDate,
    supplierId,
    supplierName,
    unit,
    batchNumber,
    expiryDate,
    productionDate,
    warrantyMonths,
    notes,
    isConsumed,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseBatchRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('product_unique_key')) {
      context.handle(
        _productUniqueKeyMeta,
        productUniqueKey.isAcceptableOrUnknown(
          data['product_unique_key']!,
          _productUniqueKeyMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
        _purchasePriceMeta,
        purchasePrice.isAcceptableOrUnknown(
          data['purchase_price']!,
          _purchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('selling_price')) {
      context.handle(
        _sellingPriceMeta,
        sellingPrice.isAcceptableOrUnknown(
          data['selling_price']!,
          _sellingPriceMeta,
        ),
      );
    }
    if (data.containsKey('quantity_purchased')) {
      context.handle(
        _quantityPurchasedMeta,
        quantityPurchased.isAcceptableOrUnknown(
          data['quantity_purchased']!,
          _quantityPurchasedMeta,
        ),
      );
    }
    if (data.containsKey('quantity_remaining')) {
      context.handle(
        _quantityRemainingMeta,
        quantityRemaining.isAcceptableOrUnknown(
          data['quantity_remaining']!,
          _quantityRemainingMeta,
        ),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    }
    if (data.containsKey('supplier_name')) {
      context.handle(
        _supplierNameMeta,
        supplierName.isAcceptableOrUnknown(
          data['supplier_name']!,
          _supplierNameMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('batch_number')) {
      context.handle(
        _batchNumberMeta,
        batchNumber.isAcceptableOrUnknown(
          data['batch_number']!,
          _batchNumberMeta,
        ),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('production_date')) {
      context.handle(
        _productionDateMeta,
        productionDate.isAcceptableOrUnknown(
          data['production_date']!,
          _productionDateMeta,
        ),
      );
    }
    if (data.containsKey('warranty_months')) {
      context.handle(
        _warrantyMonthsMeta,
        warrantyMonths.isAcceptableOrUnknown(
          data['warranty_months']!,
          _warrantyMonthsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_consumed')) {
      context.handle(
        _isConsumedMeta,
        isConsumed.isAcceptableOrUnknown(data['is_consumed']!, _isConsumedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseBatchRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseBatchRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      )!,
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      productUniqueKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_unique_key'],
      )!,
      purchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_price'],
      )!,
      sellingPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}selling_price'],
      )!,
      quantityPurchased: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_purchased'],
      )!,
      quantityRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_remaining'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      )!,
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      ),
      supplierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_name'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      batchNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_number'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      productionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}production_date'],
      ),
      warrantyMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warranty_months'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_consumed'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PurchaseBatchRecordsTable createAlias(String alias) {
    return $PurchaseBatchRecordsTable(attachedDatabase, alias);
  }
}

class PurchaseBatchRecord extends DataClass
    implements Insertable<PurchaseBatchRecord> {
  final int id;
  final String? serverId;
  final String productId;
  final String productName;
  final String companyName;
  final String modelName;
  final String category;
  final String productUniqueKey;
  final double purchasePrice;
  final double sellingPrice;
  final int quantityPurchased;
  final int quantityRemaining;
  final DateTime purchaseDate;
  final String? supplierId;
  final String? supplierName;
  final String unit;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime? productionDate;
  final int? warrantyMonths;
  final String? notes;
  final bool isConsumed;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PurchaseBatchRecord({
    required this.id,
    this.serverId,
    required this.productId,
    required this.productName,
    required this.companyName,
    required this.modelName,
    required this.category,
    required this.productUniqueKey,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantityPurchased,
    required this.quantityRemaining,
    required this.purchaseDate,
    this.supplierId,
    this.supplierName,
    required this.unit,
    this.batchNumber,
    this.expiryDate,
    this.productionDate,
    this.warrantyMonths,
    this.notes,
    required this.isConsumed,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['company_name'] = Variable<String>(companyName);
    map['model_name'] = Variable<String>(modelName);
    map['category'] = Variable<String>(category);
    map['product_unique_key'] = Variable<String>(productUniqueKey);
    map['purchase_price'] = Variable<double>(purchasePrice);
    map['selling_price'] = Variable<double>(sellingPrice);
    map['quantity_purchased'] = Variable<int>(quantityPurchased);
    map['quantity_remaining'] = Variable<int>(quantityRemaining);
    map['purchase_date'] = Variable<DateTime>(purchaseDate);
    if (!nullToAbsent || supplierId != null) {
      map['supplier_id'] = Variable<String>(supplierId);
    }
    if (!nullToAbsent || supplierName != null) {
      map['supplier_name'] = Variable<String>(supplierName);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || batchNumber != null) {
      map['batch_number'] = Variable<String>(batchNumber);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    if (!nullToAbsent || productionDate != null) {
      map['production_date'] = Variable<DateTime>(productionDate);
    }
    if (!nullToAbsent || warrantyMonths != null) {
      map['warranty_months'] = Variable<int>(warrantyMonths);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_consumed'] = Variable<bool>(isConsumed);
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PurchaseBatchRecordsCompanion toCompanion(bool nullToAbsent) {
    return PurchaseBatchRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      productId: Value(productId),
      productName: Value(productName),
      companyName: Value(companyName),
      modelName: Value(modelName),
      category: Value(category),
      productUniqueKey: Value(productUniqueKey),
      purchasePrice: Value(purchasePrice),
      sellingPrice: Value(sellingPrice),
      quantityPurchased: Value(quantityPurchased),
      quantityRemaining: Value(quantityRemaining),
      purchaseDate: Value(purchaseDate),
      supplierId: supplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierId),
      supplierName: supplierName == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierName),
      unit: Value(unit),
      batchNumber: batchNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(batchNumber),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      productionDate: productionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(productionDate),
      warrantyMonths: warrantyMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyMonths),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isConsumed: Value(isConsumed),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PurchaseBatchRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseBatchRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      companyName: serializer.fromJson<String>(json['companyName']),
      modelName: serializer.fromJson<String>(json['modelName']),
      category: serializer.fromJson<String>(json['category']),
      productUniqueKey: serializer.fromJson<String>(json['productUniqueKey']),
      purchasePrice: serializer.fromJson<double>(json['purchasePrice']),
      sellingPrice: serializer.fromJson<double>(json['sellingPrice']),
      quantityPurchased: serializer.fromJson<int>(json['quantityPurchased']),
      quantityRemaining: serializer.fromJson<int>(json['quantityRemaining']),
      purchaseDate: serializer.fromJson<DateTime>(json['purchaseDate']),
      supplierId: serializer.fromJson<String?>(json['supplierId']),
      supplierName: serializer.fromJson<String?>(json['supplierName']),
      unit: serializer.fromJson<String>(json['unit']),
      batchNumber: serializer.fromJson<String?>(json['batchNumber']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      productionDate: serializer.fromJson<DateTime?>(json['productionDate']),
      warrantyMonths: serializer.fromJson<int?>(json['warrantyMonths']),
      notes: serializer.fromJson<String?>(json['notes']),
      isConsumed: serializer.fromJson<bool>(json['isConsumed']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'companyName': serializer.toJson<String>(companyName),
      'modelName': serializer.toJson<String>(modelName),
      'category': serializer.toJson<String>(category),
      'productUniqueKey': serializer.toJson<String>(productUniqueKey),
      'purchasePrice': serializer.toJson<double>(purchasePrice),
      'sellingPrice': serializer.toJson<double>(sellingPrice),
      'quantityPurchased': serializer.toJson<int>(quantityPurchased),
      'quantityRemaining': serializer.toJson<int>(quantityRemaining),
      'purchaseDate': serializer.toJson<DateTime>(purchaseDate),
      'supplierId': serializer.toJson<String?>(supplierId),
      'supplierName': serializer.toJson<String?>(supplierName),
      'unit': serializer.toJson<String>(unit),
      'batchNumber': serializer.toJson<String?>(batchNumber),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'productionDate': serializer.toJson<DateTime?>(productionDate),
      'warrantyMonths': serializer.toJson<int?>(warrantyMonths),
      'notes': serializer.toJson<String?>(notes),
      'isConsumed': serializer.toJson<bool>(isConsumed),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PurchaseBatchRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? productId,
    String? productName,
    String? companyName,
    String? modelName,
    String? category,
    String? productUniqueKey,
    double? purchasePrice,
    double? sellingPrice,
    int? quantityPurchased,
    int? quantityRemaining,
    DateTime? purchaseDate,
    Value<String?> supplierId = const Value.absent(),
    Value<String?> supplierName = const Value.absent(),
    String? unit,
    Value<String?> batchNumber = const Value.absent(),
    Value<DateTime?> expiryDate = const Value.absent(),
    Value<DateTime?> productionDate = const Value.absent(),
    Value<int?> warrantyMonths = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isConsumed,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PurchaseBatchRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    companyName: companyName ?? this.companyName,
    modelName: modelName ?? this.modelName,
    category: category ?? this.category,
    productUniqueKey: productUniqueKey ?? this.productUniqueKey,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    quantityPurchased: quantityPurchased ?? this.quantityPurchased,
    quantityRemaining: quantityRemaining ?? this.quantityRemaining,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    supplierId: supplierId.present ? supplierId.value : this.supplierId,
    supplierName: supplierName.present ? supplierName.value : this.supplierName,
    unit: unit ?? this.unit,
    batchNumber: batchNumber.present ? batchNumber.value : this.batchNumber,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    productionDate: productionDate.present
        ? productionDate.value
        : this.productionDate,
    warrantyMonths: warrantyMonths.present
        ? warrantyMonths.value
        : this.warrantyMonths,
    notes: notes.present ? notes.value : this.notes,
    isConsumed: isConsumed ?? this.isConsumed,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PurchaseBatchRecord copyWithCompanion(PurchaseBatchRecordsCompanion data) {
    return PurchaseBatchRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      category: data.category.present ? data.category.value : this.category,
      productUniqueKey: data.productUniqueKey.present
          ? data.productUniqueKey.value
          : this.productUniqueKey,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      quantityPurchased: data.quantityPurchased.present
          ? data.quantityPurchased.value
          : this.quantityPurchased,
      quantityRemaining: data.quantityRemaining.present
          ? data.quantityRemaining.value
          : this.quantityRemaining,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      supplierName: data.supplierName.present
          ? data.supplierName.value
          : this.supplierName,
      unit: data.unit.present ? data.unit.value : this.unit,
      batchNumber: data.batchNumber.present
          ? data.batchNumber.value
          : this.batchNumber,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      productionDate: data.productionDate.present
          ? data.productionDate.value
          : this.productionDate,
      warrantyMonths: data.warrantyMonths.present
          ? data.warrantyMonths.value
          : this.warrantyMonths,
      notes: data.notes.present ? data.notes.value : this.notes,
      isConsumed: data.isConsumed.present
          ? data.isConsumed.value
          : this.isConsumed,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseBatchRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('companyName: $companyName, ')
          ..write('modelName: $modelName, ')
          ..write('category: $category, ')
          ..write('productUniqueKey: $productUniqueKey, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('quantityPurchased: $quantityPurchased, ')
          ..write('quantityRemaining: $quantityRemaining, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('supplierId: $supplierId, ')
          ..write('supplierName: $supplierName, ')
          ..write('unit: $unit, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('productionDate: $productionDate, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('notes: $notes, ')
          ..write('isConsumed: $isConsumed, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    productId,
    productName,
    companyName,
    modelName,
    category,
    productUniqueKey,
    purchasePrice,
    sellingPrice,
    quantityPurchased,
    quantityRemaining,
    purchaseDate,
    supplierId,
    supplierName,
    unit,
    batchNumber,
    expiryDate,
    productionDate,
    warrantyMonths,
    notes,
    isConsumed,
    syncStatus,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseBatchRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.companyName == this.companyName &&
          other.modelName == this.modelName &&
          other.category == this.category &&
          other.productUniqueKey == this.productUniqueKey &&
          other.purchasePrice == this.purchasePrice &&
          other.sellingPrice == this.sellingPrice &&
          other.quantityPurchased == this.quantityPurchased &&
          other.quantityRemaining == this.quantityRemaining &&
          other.purchaseDate == this.purchaseDate &&
          other.supplierId == this.supplierId &&
          other.supplierName == this.supplierName &&
          other.unit == this.unit &&
          other.batchNumber == this.batchNumber &&
          other.expiryDate == this.expiryDate &&
          other.productionDate == this.productionDate &&
          other.warrantyMonths == this.warrantyMonths &&
          other.notes == this.notes &&
          other.isConsumed == this.isConsumed &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PurchaseBatchRecordsCompanion
    extends UpdateCompanion<PurchaseBatchRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String> companyName;
  final Value<String> modelName;
  final Value<String> category;
  final Value<String> productUniqueKey;
  final Value<double> purchasePrice;
  final Value<double> sellingPrice;
  final Value<int> quantityPurchased;
  final Value<int> quantityRemaining;
  final Value<DateTime> purchaseDate;
  final Value<String?> supplierId;
  final Value<String?> supplierName;
  final Value<String> unit;
  final Value<String?> batchNumber;
  final Value<DateTime?> expiryDate;
  final Value<DateTime?> productionDate;
  final Value<int?> warrantyMonths;
  final Value<String?> notes;
  final Value<bool> isConsumed;
  final Value<int> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PurchaseBatchRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.companyName = const Value.absent(),
    this.modelName = const Value.absent(),
    this.category = const Value.absent(),
    this.productUniqueKey = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.quantityPurchased = const Value.absent(),
    this.quantityRemaining = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.supplierName = const Value.absent(),
    this.unit = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.productionDate = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.notes = const Value.absent(),
    this.isConsumed = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PurchaseBatchRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String productId,
    this.productName = const Value.absent(),
    this.companyName = const Value.absent(),
    this.modelName = const Value.absent(),
    this.category = const Value.absent(),
    this.productUniqueKey = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.quantityPurchased = const Value.absent(),
    this.quantityRemaining = const Value.absent(),
    required DateTime purchaseDate,
    this.supplierId = const Value.absent(),
    this.supplierName = const Value.absent(),
    this.unit = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.productionDate = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.notes = const Value.absent(),
    this.isConsumed = const Value.absent(),
    required int syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : productId = Value(productId),
       purchaseDate = Value(purchaseDate),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PurchaseBatchRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? companyName,
    Expression<String>? modelName,
    Expression<String>? category,
    Expression<String>? productUniqueKey,
    Expression<double>? purchasePrice,
    Expression<double>? sellingPrice,
    Expression<int>? quantityPurchased,
    Expression<int>? quantityRemaining,
    Expression<DateTime>? purchaseDate,
    Expression<String>? supplierId,
    Expression<String>? supplierName,
    Expression<String>? unit,
    Expression<String>? batchNumber,
    Expression<DateTime>? expiryDate,
    Expression<DateTime>? productionDate,
    Expression<int>? warrantyMonths,
    Expression<String>? notes,
    Expression<bool>? isConsumed,
    Expression<int>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (companyName != null) 'company_name': companyName,
      if (modelName != null) 'model_name': modelName,
      if (category != null) 'category': category,
      if (productUniqueKey != null) 'product_unique_key': productUniqueKey,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (quantityPurchased != null) 'quantity_purchased': quantityPurchased,
      if (quantityRemaining != null) 'quantity_remaining': quantityRemaining,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (supplierId != null) 'supplier_id': supplierId,
      if (supplierName != null) 'supplier_name': supplierName,
      if (unit != null) 'unit': unit,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (productionDate != null) 'production_date': productionDate,
      if (warrantyMonths != null) 'warranty_months': warrantyMonths,
      if (notes != null) 'notes': notes,
      if (isConsumed != null) 'is_consumed': isConsumed,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PurchaseBatchRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? productId,
    Value<String>? productName,
    Value<String>? companyName,
    Value<String>? modelName,
    Value<String>? category,
    Value<String>? productUniqueKey,
    Value<double>? purchasePrice,
    Value<double>? sellingPrice,
    Value<int>? quantityPurchased,
    Value<int>? quantityRemaining,
    Value<DateTime>? purchaseDate,
    Value<String?>? supplierId,
    Value<String?>? supplierName,
    Value<String>? unit,
    Value<String?>? batchNumber,
    Value<DateTime?>? expiryDate,
    Value<DateTime?>? productionDate,
    Value<int?>? warrantyMonths,
    Value<String?>? notes,
    Value<bool>? isConsumed,
    Value<int>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PurchaseBatchRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      modelName: modelName ?? this.modelName,
      category: category ?? this.category,
      productUniqueKey: productUniqueKey ?? this.productUniqueKey,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantityPurchased: quantityPurchased ?? this.quantityPurchased,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      unit: unit ?? this.unit,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      productionDate: productionDate ?? this.productionDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      notes: notes ?? this.notes,
      isConsumed: isConsumed ?? this.isConsumed,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (productUniqueKey.present) {
      map['product_unique_key'] = Variable<String>(productUniqueKey.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<double>(sellingPrice.value);
    }
    if (quantityPurchased.present) {
      map['quantity_purchased'] = Variable<int>(quantityPurchased.value);
    }
    if (quantityRemaining.present) {
      map['quantity_remaining'] = Variable<int>(quantityRemaining.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (supplierName.present) {
      map['supplier_name'] = Variable<String>(supplierName.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (batchNumber.present) {
      map['batch_number'] = Variable<String>(batchNumber.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (productionDate.present) {
      map['production_date'] = Variable<DateTime>(productionDate.value);
    }
    if (warrantyMonths.present) {
      map['warranty_months'] = Variable<int>(warrantyMonths.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isConsumed.present) {
      map['is_consumed'] = Variable<bool>(isConsumed.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseBatchRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('companyName: $companyName, ')
          ..write('modelName: $modelName, ')
          ..write('category: $category, ')
          ..write('productUniqueKey: $productUniqueKey, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('quantityPurchased: $quantityPurchased, ')
          ..write('quantityRemaining: $quantityRemaining, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('supplierId: $supplierId, ')
          ..write('supplierName: $supplierName, ')
          ..write('unit: $unit, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('productionDate: $productionDate, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('notes: $notes, ')
          ..write('isConsumed: $isConsumed, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StockLedgerRecordsTable extends StockLedgerRecords
    with TableInfo<$StockLedgerRecordsTable, StockLedgerRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockLedgerRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _productUniqueKeyMeta = const VerificationMeta(
    'productUniqueKey',
  );
  @override
  late final GeneratedColumn<String> productUniqueKey = GeneratedColumn<String>(
    'product_unique_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _localBatchIdMeta = const VerificationMeta(
    'localBatchId',
  );
  @override
  late final GeneratedColumn<int> localBatchId = GeneratedColumn<int>(
    'local_batch_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ledgerTypeMeta = const VerificationMeta(
    'ledgerType',
  );
  @override
  late final GeneratedColumn<int> ledgerType = GeneratedColumn<int>(
    'ledger_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellingPriceMeta = const VerificationMeta(
    'sellingPrice',
  );
  @override
  late final GeneratedColumn<double> sellingPrice = GeneratedColumn<double>(
    'selling_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCostMeta = const VerificationMeta(
    'totalCost',
  );
  @override
  late final GeneratedColumn<double> totalCost = GeneratedColumn<double>(
    'total_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalRevenueMeta = const VerificationMeta(
    'totalRevenue',
  );
  @override
  late final GeneratedColumn<double> totalRevenue = GeneratedColumn<double>(
    'total_revenue',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _profitMeta = const VerificationMeta('profit');
  @override
  late final GeneratedColumn<double> profit = GeneratedColumn<double>(
    'profit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _balanceQuantityMeta = const VerificationMeta(
    'balanceQuantity',
  );
  @override
  late final GeneratedColumn<int> balanceQuantity = GeneratedColumn<int>(
    'balance_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _balanceValueMeta = const VerificationMeta(
    'balanceValue',
  );
  @override
  late final GeneratedColumn<double> balanceValue = GeneratedColumn<double>(
    'balance_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    productId,
    productName,
    companyName,
    modelName,
    productUniqueKey,
    batchId,
    localBatchId,
    ledgerType,
    referenceId,
    referenceType,
    quantity,
    costPrice,
    sellingPrice,
    totalCost,
    totalRevenue,
    profit,
    balanceQuantity,
    balanceValue,
    transactionDate,
    notes,
    syncStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockLedgerRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('product_unique_key')) {
      context.handle(
        _productUniqueKeyMeta,
        productUniqueKey.isAcceptableOrUnknown(
          data['product_unique_key']!,
          _productUniqueKeyMeta,
        ),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('local_batch_id')) {
      context.handle(
        _localBatchIdMeta,
        localBatchId.isAcceptableOrUnknown(
          data['local_batch_id']!,
          _localBatchIdMeta,
        ),
      );
    }
    if (data.containsKey('ledger_type')) {
      context.handle(
        _ledgerTypeMeta,
        ledgerType.isAcceptableOrUnknown(data['ledger_type']!, _ledgerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ledgerTypeMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('selling_price')) {
      context.handle(
        _sellingPriceMeta,
        sellingPrice.isAcceptableOrUnknown(
          data['selling_price']!,
          _sellingPriceMeta,
        ),
      );
    }
    if (data.containsKey('total_cost')) {
      context.handle(
        _totalCostMeta,
        totalCost.isAcceptableOrUnknown(data['total_cost']!, _totalCostMeta),
      );
    }
    if (data.containsKey('total_revenue')) {
      context.handle(
        _totalRevenueMeta,
        totalRevenue.isAcceptableOrUnknown(
          data['total_revenue']!,
          _totalRevenueMeta,
        ),
      );
    }
    if (data.containsKey('profit')) {
      context.handle(
        _profitMeta,
        profit.isAcceptableOrUnknown(data['profit']!, _profitMeta),
      );
    }
    if (data.containsKey('balance_quantity')) {
      context.handle(
        _balanceQuantityMeta,
        balanceQuantity.isAcceptableOrUnknown(
          data['balance_quantity']!,
          _balanceQuantityMeta,
        ),
      );
    }
    if (data.containsKey('balance_value')) {
      context.handle(
        _balanceValueMeta,
        balanceValue.isAcceptableOrUnknown(
          data['balance_value']!,
          _balanceValueMeta,
        ),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockLedgerRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockLedgerRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      )!,
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      )!,
      productUniqueKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_unique_key'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      localBatchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_batch_id'],
      ),
      ledgerType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ledger_type'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      )!,
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price'],
      )!,
      sellingPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}selling_price'],
      )!,
      totalCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_cost'],
      )!,
      totalRevenue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_revenue'],
      )!,
      profit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit'],
      )!,
      balanceQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_quantity'],
      )!,
      balanceValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance_value'],
      )!,
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StockLedgerRecordsTable createAlias(String alias) {
    return $StockLedgerRecordsTable(attachedDatabase, alias);
  }
}

class StockLedgerRecord extends DataClass
    implements Insertable<StockLedgerRecord> {
  final int id;
  final String? serverId;
  final String productId;
  final String productName;
  final String companyName;
  final String modelName;
  final String productUniqueKey;
  final String batchId;
  final int? localBatchId;
  final int ledgerType;
  final String referenceId;
  final String referenceType;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final double totalCost;
  final double totalRevenue;
  final double profit;
  final int balanceQuantity;
  final double balanceValue;
  final DateTime transactionDate;
  final String? notes;
  final int syncStatus;
  final DateTime createdAt;
  const StockLedgerRecord({
    required this.id,
    this.serverId,
    required this.productId,
    required this.productName,
    required this.companyName,
    required this.modelName,
    required this.productUniqueKey,
    required this.batchId,
    this.localBatchId,
    required this.ledgerType,
    required this.referenceId,
    required this.referenceType,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.totalCost,
    required this.totalRevenue,
    required this.profit,
    required this.balanceQuantity,
    required this.balanceValue,
    required this.transactionDate,
    this.notes,
    required this.syncStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['company_name'] = Variable<String>(companyName);
    map['model_name'] = Variable<String>(modelName);
    map['product_unique_key'] = Variable<String>(productUniqueKey);
    map['batch_id'] = Variable<String>(batchId);
    if (!nullToAbsent || localBatchId != null) {
      map['local_batch_id'] = Variable<int>(localBatchId);
    }
    map['ledger_type'] = Variable<int>(ledgerType);
    map['reference_id'] = Variable<String>(referenceId);
    map['reference_type'] = Variable<String>(referenceType);
    map['quantity'] = Variable<int>(quantity);
    map['cost_price'] = Variable<double>(costPrice);
    map['selling_price'] = Variable<double>(sellingPrice);
    map['total_cost'] = Variable<double>(totalCost);
    map['total_revenue'] = Variable<double>(totalRevenue);
    map['profit'] = Variable<double>(profit);
    map['balance_quantity'] = Variable<int>(balanceQuantity);
    map['balance_value'] = Variable<double>(balanceValue);
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StockLedgerRecordsCompanion toCompanion(bool nullToAbsent) {
    return StockLedgerRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      productId: Value(productId),
      productName: Value(productName),
      companyName: Value(companyName),
      modelName: Value(modelName),
      productUniqueKey: Value(productUniqueKey),
      batchId: Value(batchId),
      localBatchId: localBatchId == null && nullToAbsent
          ? const Value.absent()
          : Value(localBatchId),
      ledgerType: Value(ledgerType),
      referenceId: Value(referenceId),
      referenceType: Value(referenceType),
      quantity: Value(quantity),
      costPrice: Value(costPrice),
      sellingPrice: Value(sellingPrice),
      totalCost: Value(totalCost),
      totalRevenue: Value(totalRevenue),
      profit: Value(profit),
      balanceQuantity: Value(balanceQuantity),
      balanceValue: Value(balanceValue),
      transactionDate: Value(transactionDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory StockLedgerRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockLedgerRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      companyName: serializer.fromJson<String>(json['companyName']),
      modelName: serializer.fromJson<String>(json['modelName']),
      productUniqueKey: serializer.fromJson<String>(json['productUniqueKey']),
      batchId: serializer.fromJson<String>(json['batchId']),
      localBatchId: serializer.fromJson<int?>(json['localBatchId']),
      ledgerType: serializer.fromJson<int>(json['ledgerType']),
      referenceId: serializer.fromJson<String>(json['referenceId']),
      referenceType: serializer.fromJson<String>(json['referenceType']),
      quantity: serializer.fromJson<int>(json['quantity']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      sellingPrice: serializer.fromJson<double>(json['sellingPrice']),
      totalCost: serializer.fromJson<double>(json['totalCost']),
      totalRevenue: serializer.fromJson<double>(json['totalRevenue']),
      profit: serializer.fromJson<double>(json['profit']),
      balanceQuantity: serializer.fromJson<int>(json['balanceQuantity']),
      balanceValue: serializer.fromJson<double>(json['balanceValue']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'companyName': serializer.toJson<String>(companyName),
      'modelName': serializer.toJson<String>(modelName),
      'productUniqueKey': serializer.toJson<String>(productUniqueKey),
      'batchId': serializer.toJson<String>(batchId),
      'localBatchId': serializer.toJson<int?>(localBatchId),
      'ledgerType': serializer.toJson<int>(ledgerType),
      'referenceId': serializer.toJson<String>(referenceId),
      'referenceType': serializer.toJson<String>(referenceType),
      'quantity': serializer.toJson<int>(quantity),
      'costPrice': serializer.toJson<double>(costPrice),
      'sellingPrice': serializer.toJson<double>(sellingPrice),
      'totalCost': serializer.toJson<double>(totalCost),
      'totalRevenue': serializer.toJson<double>(totalRevenue),
      'profit': serializer.toJson<double>(profit),
      'balanceQuantity': serializer.toJson<int>(balanceQuantity),
      'balanceValue': serializer.toJson<double>(balanceValue),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StockLedgerRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? productId,
    String? productName,
    String? companyName,
    String? modelName,
    String? productUniqueKey,
    String? batchId,
    Value<int?> localBatchId = const Value.absent(),
    int? ledgerType,
    String? referenceId,
    String? referenceType,
    int? quantity,
    double? costPrice,
    double? sellingPrice,
    double? totalCost,
    double? totalRevenue,
    double? profit,
    int? balanceQuantity,
    double? balanceValue,
    DateTime? transactionDate,
    Value<String?> notes = const Value.absent(),
    int? syncStatus,
    DateTime? createdAt,
  }) => StockLedgerRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    companyName: companyName ?? this.companyName,
    modelName: modelName ?? this.modelName,
    productUniqueKey: productUniqueKey ?? this.productUniqueKey,
    batchId: batchId ?? this.batchId,
    localBatchId: localBatchId.present ? localBatchId.value : this.localBatchId,
    ledgerType: ledgerType ?? this.ledgerType,
    referenceId: referenceId ?? this.referenceId,
    referenceType: referenceType ?? this.referenceType,
    quantity: quantity ?? this.quantity,
    costPrice: costPrice ?? this.costPrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    totalCost: totalCost ?? this.totalCost,
    totalRevenue: totalRevenue ?? this.totalRevenue,
    profit: profit ?? this.profit,
    balanceQuantity: balanceQuantity ?? this.balanceQuantity,
    balanceValue: balanceValue ?? this.balanceValue,
    transactionDate: transactionDate ?? this.transactionDate,
    notes: notes.present ? notes.value : this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  StockLedgerRecord copyWithCompanion(StockLedgerRecordsCompanion data) {
    return StockLedgerRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      productUniqueKey: data.productUniqueKey.present
          ? data.productUniqueKey.value
          : this.productUniqueKey,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      localBatchId: data.localBatchId.present
          ? data.localBatchId.value
          : this.localBatchId,
      ledgerType: data.ledgerType.present
          ? data.ledgerType.value
          : this.ledgerType,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      totalCost: data.totalCost.present ? data.totalCost.value : this.totalCost,
      totalRevenue: data.totalRevenue.present
          ? data.totalRevenue.value
          : this.totalRevenue,
      profit: data.profit.present ? data.profit.value : this.profit,
      balanceQuantity: data.balanceQuantity.present
          ? data.balanceQuantity.value
          : this.balanceQuantity,
      balanceValue: data.balanceValue.present
          ? data.balanceValue.value
          : this.balanceValue,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockLedgerRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('companyName: $companyName, ')
          ..write('modelName: $modelName, ')
          ..write('productUniqueKey: $productUniqueKey, ')
          ..write('batchId: $batchId, ')
          ..write('localBatchId: $localBatchId, ')
          ..write('ledgerType: $ledgerType, ')
          ..write('referenceId: $referenceId, ')
          ..write('referenceType: $referenceType, ')
          ..write('quantity: $quantity, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('totalCost: $totalCost, ')
          ..write('totalRevenue: $totalRevenue, ')
          ..write('profit: $profit, ')
          ..write('balanceQuantity: $balanceQuantity, ')
          ..write('balanceValue: $balanceValue, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    productId,
    productName,
    companyName,
    modelName,
    productUniqueKey,
    batchId,
    localBatchId,
    ledgerType,
    referenceId,
    referenceType,
    quantity,
    costPrice,
    sellingPrice,
    totalCost,
    totalRevenue,
    profit,
    balanceQuantity,
    balanceValue,
    transactionDate,
    notes,
    syncStatus,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockLedgerRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.companyName == this.companyName &&
          other.modelName == this.modelName &&
          other.productUniqueKey == this.productUniqueKey &&
          other.batchId == this.batchId &&
          other.localBatchId == this.localBatchId &&
          other.ledgerType == this.ledgerType &&
          other.referenceId == this.referenceId &&
          other.referenceType == this.referenceType &&
          other.quantity == this.quantity &&
          other.costPrice == this.costPrice &&
          other.sellingPrice == this.sellingPrice &&
          other.totalCost == this.totalCost &&
          other.totalRevenue == this.totalRevenue &&
          other.profit == this.profit &&
          other.balanceQuantity == this.balanceQuantity &&
          other.balanceValue == this.balanceValue &&
          other.transactionDate == this.transactionDate &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class StockLedgerRecordsCompanion extends UpdateCompanion<StockLedgerRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String> companyName;
  final Value<String> modelName;
  final Value<String> productUniqueKey;
  final Value<String> batchId;
  final Value<int?> localBatchId;
  final Value<int> ledgerType;
  final Value<String> referenceId;
  final Value<String> referenceType;
  final Value<int> quantity;
  final Value<double> costPrice;
  final Value<double> sellingPrice;
  final Value<double> totalCost;
  final Value<double> totalRevenue;
  final Value<double> profit;
  final Value<int> balanceQuantity;
  final Value<double> balanceValue;
  final Value<DateTime> transactionDate;
  final Value<String?> notes;
  final Value<int> syncStatus;
  final Value<DateTime> createdAt;
  const StockLedgerRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.companyName = const Value.absent(),
    this.modelName = const Value.absent(),
    this.productUniqueKey = const Value.absent(),
    this.batchId = const Value.absent(),
    this.localBatchId = const Value.absent(),
    this.ledgerType = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.totalRevenue = const Value.absent(),
    this.profit = const Value.absent(),
    this.balanceQuantity = const Value.absent(),
    this.balanceValue = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StockLedgerRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String productId,
    this.productName = const Value.absent(),
    this.companyName = const Value.absent(),
    this.modelName = const Value.absent(),
    this.productUniqueKey = const Value.absent(),
    this.batchId = const Value.absent(),
    this.localBatchId = const Value.absent(),
    required int ledgerType,
    this.referenceId = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.totalRevenue = const Value.absent(),
    this.profit = const Value.absent(),
    this.balanceQuantity = const Value.absent(),
    this.balanceValue = const Value.absent(),
    required DateTime transactionDate,
    this.notes = const Value.absent(),
    required int syncStatus,
    required DateTime createdAt,
  }) : productId = Value(productId),
       ledgerType = Value(ledgerType),
       transactionDate = Value(transactionDate),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt);
  static Insertable<StockLedgerRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? companyName,
    Expression<String>? modelName,
    Expression<String>? productUniqueKey,
    Expression<String>? batchId,
    Expression<int>? localBatchId,
    Expression<int>? ledgerType,
    Expression<String>? referenceId,
    Expression<String>? referenceType,
    Expression<int>? quantity,
    Expression<double>? costPrice,
    Expression<double>? sellingPrice,
    Expression<double>? totalCost,
    Expression<double>? totalRevenue,
    Expression<double>? profit,
    Expression<int>? balanceQuantity,
    Expression<double>? balanceValue,
    Expression<DateTime>? transactionDate,
    Expression<String>? notes,
    Expression<int>? syncStatus,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (companyName != null) 'company_name': companyName,
      if (modelName != null) 'model_name': modelName,
      if (productUniqueKey != null) 'product_unique_key': productUniqueKey,
      if (batchId != null) 'batch_id': batchId,
      if (localBatchId != null) 'local_batch_id': localBatchId,
      if (ledgerType != null) 'ledger_type': ledgerType,
      if (referenceId != null) 'reference_id': referenceId,
      if (referenceType != null) 'reference_type': referenceType,
      if (quantity != null) 'quantity': quantity,
      if (costPrice != null) 'cost_price': costPrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (totalCost != null) 'total_cost': totalCost,
      if (totalRevenue != null) 'total_revenue': totalRevenue,
      if (profit != null) 'profit': profit,
      if (balanceQuantity != null) 'balance_quantity': balanceQuantity,
      if (balanceValue != null) 'balance_value': balanceValue,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StockLedgerRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? productId,
    Value<String>? productName,
    Value<String>? companyName,
    Value<String>? modelName,
    Value<String>? productUniqueKey,
    Value<String>? batchId,
    Value<int?>? localBatchId,
    Value<int>? ledgerType,
    Value<String>? referenceId,
    Value<String>? referenceType,
    Value<int>? quantity,
    Value<double>? costPrice,
    Value<double>? sellingPrice,
    Value<double>? totalCost,
    Value<double>? totalRevenue,
    Value<double>? profit,
    Value<int>? balanceQuantity,
    Value<double>? balanceValue,
    Value<DateTime>? transactionDate,
    Value<String?>? notes,
    Value<int>? syncStatus,
    Value<DateTime>? createdAt,
  }) {
    return StockLedgerRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      modelName: modelName ?? this.modelName,
      productUniqueKey: productUniqueKey ?? this.productUniqueKey,
      batchId: batchId ?? this.batchId,
      localBatchId: localBatchId ?? this.localBatchId,
      ledgerType: ledgerType ?? this.ledgerType,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      totalCost: totalCost ?? this.totalCost,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      profit: profit ?? this.profit,
      balanceQuantity: balanceQuantity ?? this.balanceQuantity,
      balanceValue: balanceValue ?? this.balanceValue,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (productUniqueKey.present) {
      map['product_unique_key'] = Variable<String>(productUniqueKey.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (localBatchId.present) {
      map['local_batch_id'] = Variable<int>(localBatchId.value);
    }
    if (ledgerType.present) {
      map['ledger_type'] = Variable<int>(ledgerType.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<double>(sellingPrice.value);
    }
    if (totalCost.present) {
      map['total_cost'] = Variable<double>(totalCost.value);
    }
    if (totalRevenue.present) {
      map['total_revenue'] = Variable<double>(totalRevenue.value);
    }
    if (profit.present) {
      map['profit'] = Variable<double>(profit.value);
    }
    if (balanceQuantity.present) {
      map['balance_quantity'] = Variable<int>(balanceQuantity.value);
    }
    if (balanceValue.present) {
      map['balance_value'] = Variable<double>(balanceValue.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockLedgerRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('companyName: $companyName, ')
          ..write('modelName: $modelName, ')
          ..write('productUniqueKey: $productUniqueKey, ')
          ..write('batchId: $batchId, ')
          ..write('localBatchId: $localBatchId, ')
          ..write('ledgerType: $ledgerType, ')
          ..write('referenceId: $referenceId, ')
          ..write('referenceType: $referenceType, ')
          ..write('quantity: $quantity, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('totalCost: $totalCost, ')
          ..write('totalRevenue: $totalRevenue, ')
          ..write('profit: $profit, ')
          ..write('balanceQuantity: $balanceQuantity, ')
          ..write('balanceValue: $balanceValue, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BillRecordsTable extends BillRecords
    with TableInfo<$BillRecordsTable, BillRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerContactMeta = const VerificationMeta(
    'customerContact',
  );
  @override
  late final GeneratedColumn<String> customerContact = GeneratedColumn<String>(
    'customer_contact',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _totalQuantityMeta = const VerificationMeta(
    'totalQuantity',
  );
  @override
  late final GeneratedColumn<int> totalQuantity = GeneratedColumn<int>(
    'total_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountPercentMeta = const VerificationMeta(
    'discountPercent',
  );
  @override
  late final GeneratedColumn<double> discountPercent = GeneratedColumn<double>(
    'discount_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _finalAmountMeta = const VerificationMeta(
    'finalAmount',
  );
  @override
  late final GeneratedColumn<double> finalAmount = GeneratedColumn<double>(
    'final_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _billDateMeta = const VerificationMeta(
    'billDate',
  );
  @override
  late final GeneratedColumn<DateTime> billDate = GeneratedColumn<DateTime>(
    'bill_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _returnStatusMeta = const VerificationMeta(
    'returnStatus',
  );
  @override
  late final GeneratedColumn<bool> returnStatus = GeneratedColumn<bool>(
    'return_status',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("return_status" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _returnDateMeta = const VerificationMeta(
    'returnDate',
  );
  @override
  late final GeneratedColumn<DateTime> returnDate = GeneratedColumn<DateTime>(
    'return_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<int> paymentStatus = GeneratedColumn<int>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAmountMeta = const VerificationMeta(
    'paidAmount',
  );
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
    'paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pendingAmountMeta = const VerificationMeta(
    'pendingAmount',
  );
  @override
  late final GeneratedColumn<double> pendingAmount = GeneratedColumn<double>(
    'pending_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isGstAppliedMeta = const VerificationMeta(
    'isGstApplied',
  );
  @override
  late final GeneratedColumn<bool> isGstApplied = GeneratedColumn<bool>(
    'is_gst_applied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_gst_applied" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTaxInclusiveMeta = const VerificationMeta(
    'isTaxInclusive',
  );
  @override
  late final GeneratedColumn<bool> isTaxInclusive = GeneratedColumn<bool>(
    'is_tax_inclusive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tax_inclusive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cgstPercentMeta = const VerificationMeta(
    'cgstPercent',
  );
  @override
  late final GeneratedColumn<double> cgstPercent = GeneratedColumn<double>(
    'cgst_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sgstPercentMeta = const VerificationMeta(
    'sgstPercent',
  );
  @override
  late final GeneratedColumn<double> sgstPercent = GeneratedColumn<double>(
    'sgst_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _igstPercentMeta = const VerificationMeta(
    'igstPercent',
  );
  @override
  late final GeneratedColumn<double> igstPercent = GeneratedColumn<double>(
    'igst_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _otherTaxPercentMeta = const VerificationMeta(
    'otherTaxPercent',
  );
  @override
  late final GeneratedColumn<double> otherTaxPercent = GeneratedColumn<double>(
    'other_tax_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _otherTaxNameMeta = const VerificationMeta(
    'otherTaxName',
  );
  @override
  late final GeneratedColumn<String> otherTaxName = GeneratedColumn<String>(
    'other_tax_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cgstAmountMeta = const VerificationMeta(
    'cgstAmount',
  );
  @override
  late final GeneratedColumn<double> cgstAmount = GeneratedColumn<double>(
    'cgst_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sgstAmountMeta = const VerificationMeta(
    'sgstAmount',
  );
  @override
  late final GeneratedColumn<double> sgstAmount = GeneratedColumn<double>(
    'sgst_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _igstAmountMeta = const VerificationMeta(
    'igstAmount',
  );
  @override
  late final GeneratedColumn<double> igstAmount = GeneratedColumn<double>(
    'igst_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _otherTaxAmountMeta = const VerificationMeta(
    'otherTaxAmount',
  );
  @override
  late final GeneratedColumn<double> otherTaxAmount = GeneratedColumn<double>(
    'other_tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalTaxAmountMeta = const VerificationMeta(
    'totalTaxAmount',
  );
  @override
  late final GeneratedColumn<double> totalTaxAmount = GeneratedColumn<double>(
    'total_tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customerGstinMeta = const VerificationMeta(
    'customerGstin',
  );
  @override
  late final GeneratedColumn<String> customerGstin = GeneratedColumn<String>(
    'customer_gstin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeOfSupplyMeta = const VerificationMeta(
    'placeOfSupply',
  );
  @override
  late final GeneratedColumn<String> placeOfSupply = GeneratedColumn<String>(
    'place_of_supply',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isInterstateMeta = const VerificationMeta(
    'isInterstate',
  );
  @override
  late final GeneratedColumn<bool> isInterstate = GeneratedColumn<bool>(
    'is_interstate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_interstate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _extraChargesJsonMeta = const VerificationMeta(
    'extraChargesJson',
  );
  @override
  late final GeneratedColumn<String> extraChargesJson = GeneratedColumn<String>(
    'extra_charges_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _paymentModeMeta = const VerificationMeta(
    'paymentMode',
  );
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
    'payment_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CASH'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    customerId,
    customerName,
    customerContact,
    itemsJson,
    totalQuantity,
    totalAmount,
    discountAmount,
    discountPercent,
    finalAmount,
    billDate,
    notes,
    returnStatus,
    returnDate,
    paymentStatus,
    paidAmount,
    pendingAmount,
    isGstApplied,
    isTaxInclusive,
    cgstPercent,
    sgstPercent,
    igstPercent,
    otherTaxPercent,
    otherTaxName,
    cgstAmount,
    sgstAmount,
    igstAmount,
    otherTaxAmount,
    totalTaxAmount,
    customerGstin,
    placeOfSupply,
    isInterstate,
    extraChargesJson,
    paymentMode,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_contact')) {
      context.handle(
        _customerContactMeta,
        customerContact.isAcceptableOrUnknown(
          data['customer_contact']!,
          _customerContactMeta,
        ),
      );
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    }
    if (data.containsKey('total_quantity')) {
      context.handle(
        _totalQuantityMeta,
        totalQuantity.isAcceptableOrUnknown(
          data['total_quantity']!,
          _totalQuantityMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('discount_percent')) {
      context.handle(
        _discountPercentMeta,
        discountPercent.isAcceptableOrUnknown(
          data['discount_percent']!,
          _discountPercentMeta,
        ),
      );
    }
    if (data.containsKey('final_amount')) {
      context.handle(
        _finalAmountMeta,
        finalAmount.isAcceptableOrUnknown(
          data['final_amount']!,
          _finalAmountMeta,
        ),
      );
    }
    if (data.containsKey('bill_date')) {
      context.handle(
        _billDateMeta,
        billDate.isAcceptableOrUnknown(data['bill_date']!, _billDateMeta),
      );
    } else if (isInserting) {
      context.missing(_billDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('return_status')) {
      context.handle(
        _returnStatusMeta,
        returnStatus.isAcceptableOrUnknown(
          data['return_status']!,
          _returnStatusMeta,
        ),
      );
    }
    if (data.containsKey('return_date')) {
      context.handle(
        _returnDateMeta,
        returnDate.isAcceptableOrUnknown(data['return_date']!, _returnDateMeta),
      );
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentStatusMeta);
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
        _paidAmountMeta,
        paidAmount.isAcceptableOrUnknown(data['paid_amount']!, _paidAmountMeta),
      );
    }
    if (data.containsKey('pending_amount')) {
      context.handle(
        _pendingAmountMeta,
        pendingAmount.isAcceptableOrUnknown(
          data['pending_amount']!,
          _pendingAmountMeta,
        ),
      );
    }
    if (data.containsKey('is_gst_applied')) {
      context.handle(
        _isGstAppliedMeta,
        isGstApplied.isAcceptableOrUnknown(
          data['is_gst_applied']!,
          _isGstAppliedMeta,
        ),
      );
    }
    if (data.containsKey('is_tax_inclusive')) {
      context.handle(
        _isTaxInclusiveMeta,
        isTaxInclusive.isAcceptableOrUnknown(
          data['is_tax_inclusive']!,
          _isTaxInclusiveMeta,
        ),
      );
    }
    if (data.containsKey('cgst_percent')) {
      context.handle(
        _cgstPercentMeta,
        cgstPercent.isAcceptableOrUnknown(
          data['cgst_percent']!,
          _cgstPercentMeta,
        ),
      );
    }
    if (data.containsKey('sgst_percent')) {
      context.handle(
        _sgstPercentMeta,
        sgstPercent.isAcceptableOrUnknown(
          data['sgst_percent']!,
          _sgstPercentMeta,
        ),
      );
    }
    if (data.containsKey('igst_percent')) {
      context.handle(
        _igstPercentMeta,
        igstPercent.isAcceptableOrUnknown(
          data['igst_percent']!,
          _igstPercentMeta,
        ),
      );
    }
    if (data.containsKey('other_tax_percent')) {
      context.handle(
        _otherTaxPercentMeta,
        otherTaxPercent.isAcceptableOrUnknown(
          data['other_tax_percent']!,
          _otherTaxPercentMeta,
        ),
      );
    }
    if (data.containsKey('other_tax_name')) {
      context.handle(
        _otherTaxNameMeta,
        otherTaxName.isAcceptableOrUnknown(
          data['other_tax_name']!,
          _otherTaxNameMeta,
        ),
      );
    }
    if (data.containsKey('cgst_amount')) {
      context.handle(
        _cgstAmountMeta,
        cgstAmount.isAcceptableOrUnknown(data['cgst_amount']!, _cgstAmountMeta),
      );
    }
    if (data.containsKey('sgst_amount')) {
      context.handle(
        _sgstAmountMeta,
        sgstAmount.isAcceptableOrUnknown(data['sgst_amount']!, _sgstAmountMeta),
      );
    }
    if (data.containsKey('igst_amount')) {
      context.handle(
        _igstAmountMeta,
        igstAmount.isAcceptableOrUnknown(data['igst_amount']!, _igstAmountMeta),
      );
    }
    if (data.containsKey('other_tax_amount')) {
      context.handle(
        _otherTaxAmountMeta,
        otherTaxAmount.isAcceptableOrUnknown(
          data['other_tax_amount']!,
          _otherTaxAmountMeta,
        ),
      );
    }
    if (data.containsKey('total_tax_amount')) {
      context.handle(
        _totalTaxAmountMeta,
        totalTaxAmount.isAcceptableOrUnknown(
          data['total_tax_amount']!,
          _totalTaxAmountMeta,
        ),
      );
    }
    if (data.containsKey('customer_gstin')) {
      context.handle(
        _customerGstinMeta,
        customerGstin.isAcceptableOrUnknown(
          data['customer_gstin']!,
          _customerGstinMeta,
        ),
      );
    }
    if (data.containsKey('place_of_supply')) {
      context.handle(
        _placeOfSupplyMeta,
        placeOfSupply.isAcceptableOrUnknown(
          data['place_of_supply']!,
          _placeOfSupplyMeta,
        ),
      );
    }
    if (data.containsKey('is_interstate')) {
      context.handle(
        _isInterstateMeta,
        isInterstate.isAcceptableOrUnknown(
          data['is_interstate']!,
          _isInterstateMeta,
        ),
      );
    }
    if (data.containsKey('extra_charges_json')) {
      context.handle(
        _extraChargesJsonMeta,
        extraChargesJson.isAcceptableOrUnknown(
          data['extra_charges_json']!,
          _extraChargesJsonMeta,
        ),
      );
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
        _paymentModeMeta,
        paymentMode.isAcceptableOrUnknown(
          data['payment_mode']!,
          _paymentModeMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      customerContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_contact'],
      ),
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      totalQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_quantity'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      )!,
      discountPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_percent'],
      )!,
      finalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}final_amount'],
      )!,
      billDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bill_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      returnStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}return_status'],
      )!,
      returnDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}return_date'],
      ),
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_status'],
      )!,
      paidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paid_amount'],
      )!,
      pendingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pending_amount'],
      )!,
      isGstApplied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_gst_applied'],
      )!,
      isTaxInclusive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tax_inclusive'],
      )!,
      cgstPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cgst_percent'],
      )!,
      sgstPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sgst_percent'],
      )!,
      igstPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}igst_percent'],
      )!,
      otherTaxPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}other_tax_percent'],
      )!,
      otherTaxName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_tax_name'],
      ),
      cgstAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cgst_amount'],
      )!,
      sgstAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sgst_amount'],
      )!,
      igstAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}igst_amount'],
      )!,
      otherTaxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}other_tax_amount'],
      )!,
      totalTaxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_tax_amount'],
      )!,
      customerGstin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_gstin'],
      ),
      placeOfSupply: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_of_supply'],
      ),
      isInterstate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_interstate'],
      )!,
      extraChargesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_charges_json'],
      )!,
      paymentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_mode'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BillRecordsTable createAlias(String alias) {
    return $BillRecordsTable(attachedDatabase, alias);
  }
}

class BillRecord extends DataClass implements Insertable<BillRecord> {
  final int id;
  final String? serverId;
  final String? customerId;
  final String? customerName;
  final String? customerContact;
  final String itemsJson;
  final int totalQuantity;
  final double totalAmount;
  final double discountAmount;
  final double discountPercent;
  final double finalAmount;
  final DateTime billDate;
  final String? notes;
  final bool returnStatus;
  final DateTime? returnDate;
  final int paymentStatus;
  final double paidAmount;
  final double pendingAmount;
  final bool isGstApplied;
  final bool isTaxInclusive;
  final double cgstPercent;
  final double sgstPercent;
  final double igstPercent;
  final double otherTaxPercent;
  final String? otherTaxName;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double otherTaxAmount;
  final double totalTaxAmount;
  final String? customerGstin;
  final String? placeOfSupply;
  final bool isInterstate;
  final String extraChargesJson;
  final String paymentMode;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BillRecord({
    required this.id,
    this.serverId,
    this.customerId,
    this.customerName,
    this.customerContact,
    required this.itemsJson,
    required this.totalQuantity,
    required this.totalAmount,
    required this.discountAmount,
    required this.discountPercent,
    required this.finalAmount,
    required this.billDate,
    this.notes,
    required this.returnStatus,
    this.returnDate,
    required this.paymentStatus,
    required this.paidAmount,
    required this.pendingAmount,
    required this.isGstApplied,
    required this.isTaxInclusive,
    required this.cgstPercent,
    required this.sgstPercent,
    required this.igstPercent,
    required this.otherTaxPercent,
    this.otherTaxName,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.otherTaxAmount,
    required this.totalTaxAmount,
    this.customerGstin,
    this.placeOfSupply,
    required this.isInterstate,
    required this.extraChargesJson,
    required this.paymentMode,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerContact != null) {
      map['customer_contact'] = Variable<String>(customerContact);
    }
    map['items_json'] = Variable<String>(itemsJson);
    map['total_quantity'] = Variable<int>(totalQuantity);
    map['total_amount'] = Variable<double>(totalAmount);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['discount_percent'] = Variable<double>(discountPercent);
    map['final_amount'] = Variable<double>(finalAmount);
    map['bill_date'] = Variable<DateTime>(billDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['return_status'] = Variable<bool>(returnStatus);
    if (!nullToAbsent || returnDate != null) {
      map['return_date'] = Variable<DateTime>(returnDate);
    }
    map['payment_status'] = Variable<int>(paymentStatus);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['pending_amount'] = Variable<double>(pendingAmount);
    map['is_gst_applied'] = Variable<bool>(isGstApplied);
    map['is_tax_inclusive'] = Variable<bool>(isTaxInclusive);
    map['cgst_percent'] = Variable<double>(cgstPercent);
    map['sgst_percent'] = Variable<double>(sgstPercent);
    map['igst_percent'] = Variable<double>(igstPercent);
    map['other_tax_percent'] = Variable<double>(otherTaxPercent);
    if (!nullToAbsent || otherTaxName != null) {
      map['other_tax_name'] = Variable<String>(otherTaxName);
    }
    map['cgst_amount'] = Variable<double>(cgstAmount);
    map['sgst_amount'] = Variable<double>(sgstAmount);
    map['igst_amount'] = Variable<double>(igstAmount);
    map['other_tax_amount'] = Variable<double>(otherTaxAmount);
    map['total_tax_amount'] = Variable<double>(totalTaxAmount);
    if (!nullToAbsent || customerGstin != null) {
      map['customer_gstin'] = Variable<String>(customerGstin);
    }
    if (!nullToAbsent || placeOfSupply != null) {
      map['place_of_supply'] = Variable<String>(placeOfSupply);
    }
    map['is_interstate'] = Variable<bool>(isInterstate);
    map['extra_charges_json'] = Variable<String>(extraChargesJson);
    map['payment_mode'] = Variable<String>(paymentMode);
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BillRecordsCompanion toCompanion(bool nullToAbsent) {
    return BillRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerContact: customerContact == null && nullToAbsent
          ? const Value.absent()
          : Value(customerContact),
      itemsJson: Value(itemsJson),
      totalQuantity: Value(totalQuantity),
      totalAmount: Value(totalAmount),
      discountAmount: Value(discountAmount),
      discountPercent: Value(discountPercent),
      finalAmount: Value(finalAmount),
      billDate: Value(billDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      returnStatus: Value(returnStatus),
      returnDate: returnDate == null && nullToAbsent
          ? const Value.absent()
          : Value(returnDate),
      paymentStatus: Value(paymentStatus),
      paidAmount: Value(paidAmount),
      pendingAmount: Value(pendingAmount),
      isGstApplied: Value(isGstApplied),
      isTaxInclusive: Value(isTaxInclusive),
      cgstPercent: Value(cgstPercent),
      sgstPercent: Value(sgstPercent),
      igstPercent: Value(igstPercent),
      otherTaxPercent: Value(otherTaxPercent),
      otherTaxName: otherTaxName == null && nullToAbsent
          ? const Value.absent()
          : Value(otherTaxName),
      cgstAmount: Value(cgstAmount),
      sgstAmount: Value(sgstAmount),
      igstAmount: Value(igstAmount),
      otherTaxAmount: Value(otherTaxAmount),
      totalTaxAmount: Value(totalTaxAmount),
      customerGstin: customerGstin == null && nullToAbsent
          ? const Value.absent()
          : Value(customerGstin),
      placeOfSupply: placeOfSupply == null && nullToAbsent
          ? const Value.absent()
          : Value(placeOfSupply),
      isInterstate: Value(isInterstate),
      extraChargesJson: Value(extraChargesJson),
      paymentMode: Value(paymentMode),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BillRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerContact: serializer.fromJson<String?>(json['customerContact']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      totalQuantity: serializer.fromJson<int>(json['totalQuantity']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      discountPercent: serializer.fromJson<double>(json['discountPercent']),
      finalAmount: serializer.fromJson<double>(json['finalAmount']),
      billDate: serializer.fromJson<DateTime>(json['billDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      returnStatus: serializer.fromJson<bool>(json['returnStatus']),
      returnDate: serializer.fromJson<DateTime?>(json['returnDate']),
      paymentStatus: serializer.fromJson<int>(json['paymentStatus']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      pendingAmount: serializer.fromJson<double>(json['pendingAmount']),
      isGstApplied: serializer.fromJson<bool>(json['isGstApplied']),
      isTaxInclusive: serializer.fromJson<bool>(json['isTaxInclusive']),
      cgstPercent: serializer.fromJson<double>(json['cgstPercent']),
      sgstPercent: serializer.fromJson<double>(json['sgstPercent']),
      igstPercent: serializer.fromJson<double>(json['igstPercent']),
      otherTaxPercent: serializer.fromJson<double>(json['otherTaxPercent']),
      otherTaxName: serializer.fromJson<String?>(json['otherTaxName']),
      cgstAmount: serializer.fromJson<double>(json['cgstAmount']),
      sgstAmount: serializer.fromJson<double>(json['sgstAmount']),
      igstAmount: serializer.fromJson<double>(json['igstAmount']),
      otherTaxAmount: serializer.fromJson<double>(json['otherTaxAmount']),
      totalTaxAmount: serializer.fromJson<double>(json['totalTaxAmount']),
      customerGstin: serializer.fromJson<String?>(json['customerGstin']),
      placeOfSupply: serializer.fromJson<String?>(json['placeOfSupply']),
      isInterstate: serializer.fromJson<bool>(json['isInterstate']),
      extraChargesJson: serializer.fromJson<String>(json['extraChargesJson']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'customerId': serializer.toJson<String?>(customerId),
      'customerName': serializer.toJson<String?>(customerName),
      'customerContact': serializer.toJson<String?>(customerContact),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'totalQuantity': serializer.toJson<int>(totalQuantity),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'discountPercent': serializer.toJson<double>(discountPercent),
      'finalAmount': serializer.toJson<double>(finalAmount),
      'billDate': serializer.toJson<DateTime>(billDate),
      'notes': serializer.toJson<String?>(notes),
      'returnStatus': serializer.toJson<bool>(returnStatus),
      'returnDate': serializer.toJson<DateTime?>(returnDate),
      'paymentStatus': serializer.toJson<int>(paymentStatus),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'pendingAmount': serializer.toJson<double>(pendingAmount),
      'isGstApplied': serializer.toJson<bool>(isGstApplied),
      'isTaxInclusive': serializer.toJson<bool>(isTaxInclusive),
      'cgstPercent': serializer.toJson<double>(cgstPercent),
      'sgstPercent': serializer.toJson<double>(sgstPercent),
      'igstPercent': serializer.toJson<double>(igstPercent),
      'otherTaxPercent': serializer.toJson<double>(otherTaxPercent),
      'otherTaxName': serializer.toJson<String?>(otherTaxName),
      'cgstAmount': serializer.toJson<double>(cgstAmount),
      'sgstAmount': serializer.toJson<double>(sgstAmount),
      'igstAmount': serializer.toJson<double>(igstAmount),
      'otherTaxAmount': serializer.toJson<double>(otherTaxAmount),
      'totalTaxAmount': serializer.toJson<double>(totalTaxAmount),
      'customerGstin': serializer.toJson<String?>(customerGstin),
      'placeOfSupply': serializer.toJson<String?>(placeOfSupply),
      'isInterstate': serializer.toJson<bool>(isInterstate),
      'extraChargesJson': serializer.toJson<String>(extraChargesJson),
      'paymentMode': serializer.toJson<String>(paymentMode),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BillRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    Value<String?> customerId = const Value.absent(),
    Value<String?> customerName = const Value.absent(),
    Value<String?> customerContact = const Value.absent(),
    String? itemsJson,
    int? totalQuantity,
    double? totalAmount,
    double? discountAmount,
    double? discountPercent,
    double? finalAmount,
    DateTime? billDate,
    Value<String?> notes = const Value.absent(),
    bool? returnStatus,
    Value<DateTime?> returnDate = const Value.absent(),
    int? paymentStatus,
    double? paidAmount,
    double? pendingAmount,
    bool? isGstApplied,
    bool? isTaxInclusive,
    double? cgstPercent,
    double? sgstPercent,
    double? igstPercent,
    double? otherTaxPercent,
    Value<String?> otherTaxName = const Value.absent(),
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? otherTaxAmount,
    double? totalTaxAmount,
    Value<String?> customerGstin = const Value.absent(),
    Value<String?> placeOfSupply = const Value.absent(),
    bool? isInterstate,
    String? extraChargesJson,
    String? paymentMode,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BillRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    customerId: customerId.present ? customerId.value : this.customerId,
    customerName: customerName.present ? customerName.value : this.customerName,
    customerContact: customerContact.present
        ? customerContact.value
        : this.customerContact,
    itemsJson: itemsJson ?? this.itemsJson,
    totalQuantity: totalQuantity ?? this.totalQuantity,
    totalAmount: totalAmount ?? this.totalAmount,
    discountAmount: discountAmount ?? this.discountAmount,
    discountPercent: discountPercent ?? this.discountPercent,
    finalAmount: finalAmount ?? this.finalAmount,
    billDate: billDate ?? this.billDate,
    notes: notes.present ? notes.value : this.notes,
    returnStatus: returnStatus ?? this.returnStatus,
    returnDate: returnDate.present ? returnDate.value : this.returnDate,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    paidAmount: paidAmount ?? this.paidAmount,
    pendingAmount: pendingAmount ?? this.pendingAmount,
    isGstApplied: isGstApplied ?? this.isGstApplied,
    isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
    cgstPercent: cgstPercent ?? this.cgstPercent,
    sgstPercent: sgstPercent ?? this.sgstPercent,
    igstPercent: igstPercent ?? this.igstPercent,
    otherTaxPercent: otherTaxPercent ?? this.otherTaxPercent,
    otherTaxName: otherTaxName.present ? otherTaxName.value : this.otherTaxName,
    cgstAmount: cgstAmount ?? this.cgstAmount,
    sgstAmount: sgstAmount ?? this.sgstAmount,
    igstAmount: igstAmount ?? this.igstAmount,
    otherTaxAmount: otherTaxAmount ?? this.otherTaxAmount,
    totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
    customerGstin: customerGstin.present
        ? customerGstin.value
        : this.customerGstin,
    placeOfSupply: placeOfSupply.present
        ? placeOfSupply.value
        : this.placeOfSupply,
    isInterstate: isInterstate ?? this.isInterstate,
    extraChargesJson: extraChargesJson ?? this.extraChargesJson,
    paymentMode: paymentMode ?? this.paymentMode,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BillRecord copyWithCompanion(BillRecordsCompanion data) {
    return BillRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerContact: data.customerContact.present
          ? data.customerContact.value
          : this.customerContact,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      totalQuantity: data.totalQuantity.present
          ? data.totalQuantity.value
          : this.totalQuantity,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      discountPercent: data.discountPercent.present
          ? data.discountPercent.value
          : this.discountPercent,
      finalAmount: data.finalAmount.present
          ? data.finalAmount.value
          : this.finalAmount,
      billDate: data.billDate.present ? data.billDate.value : this.billDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      returnStatus: data.returnStatus.present
          ? data.returnStatus.value
          : this.returnStatus,
      returnDate: data.returnDate.present
          ? data.returnDate.value
          : this.returnDate,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      paidAmount: data.paidAmount.present
          ? data.paidAmount.value
          : this.paidAmount,
      pendingAmount: data.pendingAmount.present
          ? data.pendingAmount.value
          : this.pendingAmount,
      isGstApplied: data.isGstApplied.present
          ? data.isGstApplied.value
          : this.isGstApplied,
      isTaxInclusive: data.isTaxInclusive.present
          ? data.isTaxInclusive.value
          : this.isTaxInclusive,
      cgstPercent: data.cgstPercent.present
          ? data.cgstPercent.value
          : this.cgstPercent,
      sgstPercent: data.sgstPercent.present
          ? data.sgstPercent.value
          : this.sgstPercent,
      igstPercent: data.igstPercent.present
          ? data.igstPercent.value
          : this.igstPercent,
      otherTaxPercent: data.otherTaxPercent.present
          ? data.otherTaxPercent.value
          : this.otherTaxPercent,
      otherTaxName: data.otherTaxName.present
          ? data.otherTaxName.value
          : this.otherTaxName,
      cgstAmount: data.cgstAmount.present
          ? data.cgstAmount.value
          : this.cgstAmount,
      sgstAmount: data.sgstAmount.present
          ? data.sgstAmount.value
          : this.sgstAmount,
      igstAmount: data.igstAmount.present
          ? data.igstAmount.value
          : this.igstAmount,
      otherTaxAmount: data.otherTaxAmount.present
          ? data.otherTaxAmount.value
          : this.otherTaxAmount,
      totalTaxAmount: data.totalTaxAmount.present
          ? data.totalTaxAmount.value
          : this.totalTaxAmount,
      customerGstin: data.customerGstin.present
          ? data.customerGstin.value
          : this.customerGstin,
      placeOfSupply: data.placeOfSupply.present
          ? data.placeOfSupply.value
          : this.placeOfSupply,
      isInterstate: data.isInterstate.present
          ? data.isInterstate.value
          : this.isInterstate,
      extraChargesJson: data.extraChargesJson.present
          ? data.extraChargesJson.value
          : this.extraChargesJson,
      paymentMode: data.paymentMode.present
          ? data.paymentMode.value
          : this.paymentMode,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerContact: $customerContact, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('totalQuantity: $totalQuantity, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('billDate: $billDate, ')
          ..write('notes: $notes, ')
          ..write('returnStatus: $returnStatus, ')
          ..write('returnDate: $returnDate, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('pendingAmount: $pendingAmount, ')
          ..write('isGstApplied: $isGstApplied, ')
          ..write('isTaxInclusive: $isTaxInclusive, ')
          ..write('cgstPercent: $cgstPercent, ')
          ..write('sgstPercent: $sgstPercent, ')
          ..write('igstPercent: $igstPercent, ')
          ..write('otherTaxPercent: $otherTaxPercent, ')
          ..write('otherTaxName: $otherTaxName, ')
          ..write('cgstAmount: $cgstAmount, ')
          ..write('sgstAmount: $sgstAmount, ')
          ..write('igstAmount: $igstAmount, ')
          ..write('otherTaxAmount: $otherTaxAmount, ')
          ..write('totalTaxAmount: $totalTaxAmount, ')
          ..write('customerGstin: $customerGstin, ')
          ..write('placeOfSupply: $placeOfSupply, ')
          ..write('isInterstate: $isInterstate, ')
          ..write('extraChargesJson: $extraChargesJson, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    customerId,
    customerName,
    customerContact,
    itemsJson,
    totalQuantity,
    totalAmount,
    discountAmount,
    discountPercent,
    finalAmount,
    billDate,
    notes,
    returnStatus,
    returnDate,
    paymentStatus,
    paidAmount,
    pendingAmount,
    isGstApplied,
    isTaxInclusive,
    cgstPercent,
    sgstPercent,
    igstPercent,
    otherTaxPercent,
    otherTaxName,
    cgstAmount,
    sgstAmount,
    igstAmount,
    otherTaxAmount,
    totalTaxAmount,
    customerGstin,
    placeOfSupply,
    isInterstate,
    extraChargesJson,
    paymentMode,
    syncStatus,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.customerContact == this.customerContact &&
          other.itemsJson == this.itemsJson &&
          other.totalQuantity == this.totalQuantity &&
          other.totalAmount == this.totalAmount &&
          other.discountAmount == this.discountAmount &&
          other.discountPercent == this.discountPercent &&
          other.finalAmount == this.finalAmount &&
          other.billDate == this.billDate &&
          other.notes == this.notes &&
          other.returnStatus == this.returnStatus &&
          other.returnDate == this.returnDate &&
          other.paymentStatus == this.paymentStatus &&
          other.paidAmount == this.paidAmount &&
          other.pendingAmount == this.pendingAmount &&
          other.isGstApplied == this.isGstApplied &&
          other.isTaxInclusive == this.isTaxInclusive &&
          other.cgstPercent == this.cgstPercent &&
          other.sgstPercent == this.sgstPercent &&
          other.igstPercent == this.igstPercent &&
          other.otherTaxPercent == this.otherTaxPercent &&
          other.otherTaxName == this.otherTaxName &&
          other.cgstAmount == this.cgstAmount &&
          other.sgstAmount == this.sgstAmount &&
          other.igstAmount == this.igstAmount &&
          other.otherTaxAmount == this.otherTaxAmount &&
          other.totalTaxAmount == this.totalTaxAmount &&
          other.customerGstin == this.customerGstin &&
          other.placeOfSupply == this.placeOfSupply &&
          other.isInterstate == this.isInterstate &&
          other.extraChargesJson == this.extraChargesJson &&
          other.paymentMode == this.paymentMode &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BillRecordsCompanion extends UpdateCompanion<BillRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String?> customerId;
  final Value<String?> customerName;
  final Value<String?> customerContact;
  final Value<String> itemsJson;
  final Value<int> totalQuantity;
  final Value<double> totalAmount;
  final Value<double> discountAmount;
  final Value<double> discountPercent;
  final Value<double> finalAmount;
  final Value<DateTime> billDate;
  final Value<String?> notes;
  final Value<bool> returnStatus;
  final Value<DateTime?> returnDate;
  final Value<int> paymentStatus;
  final Value<double> paidAmount;
  final Value<double> pendingAmount;
  final Value<bool> isGstApplied;
  final Value<bool> isTaxInclusive;
  final Value<double> cgstPercent;
  final Value<double> sgstPercent;
  final Value<double> igstPercent;
  final Value<double> otherTaxPercent;
  final Value<String?> otherTaxName;
  final Value<double> cgstAmount;
  final Value<double> sgstAmount;
  final Value<double> igstAmount;
  final Value<double> otherTaxAmount;
  final Value<double> totalTaxAmount;
  final Value<String?> customerGstin;
  final Value<String?> placeOfSupply;
  final Value<bool> isInterstate;
  final Value<String> extraChargesJson;
  final Value<String> paymentMode;
  final Value<int> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BillRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerContact = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.totalQuantity = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.discountPercent = const Value.absent(),
    this.finalAmount = const Value.absent(),
    this.billDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.returnStatus = const Value.absent(),
    this.returnDate = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.pendingAmount = const Value.absent(),
    this.isGstApplied = const Value.absent(),
    this.isTaxInclusive = const Value.absent(),
    this.cgstPercent = const Value.absent(),
    this.sgstPercent = const Value.absent(),
    this.igstPercent = const Value.absent(),
    this.otherTaxPercent = const Value.absent(),
    this.otherTaxName = const Value.absent(),
    this.cgstAmount = const Value.absent(),
    this.sgstAmount = const Value.absent(),
    this.igstAmount = const Value.absent(),
    this.otherTaxAmount = const Value.absent(),
    this.totalTaxAmount = const Value.absent(),
    this.customerGstin = const Value.absent(),
    this.placeOfSupply = const Value.absent(),
    this.isInterstate = const Value.absent(),
    this.extraChargesJson = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BillRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerContact = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.totalQuantity = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.discountPercent = const Value.absent(),
    this.finalAmount = const Value.absent(),
    required DateTime billDate,
    this.notes = const Value.absent(),
    this.returnStatus = const Value.absent(),
    this.returnDate = const Value.absent(),
    required int paymentStatus,
    this.paidAmount = const Value.absent(),
    this.pendingAmount = const Value.absent(),
    this.isGstApplied = const Value.absent(),
    this.isTaxInclusive = const Value.absent(),
    this.cgstPercent = const Value.absent(),
    this.sgstPercent = const Value.absent(),
    this.igstPercent = const Value.absent(),
    this.otherTaxPercent = const Value.absent(),
    this.otherTaxName = const Value.absent(),
    this.cgstAmount = const Value.absent(),
    this.sgstAmount = const Value.absent(),
    this.igstAmount = const Value.absent(),
    this.otherTaxAmount = const Value.absent(),
    this.totalTaxAmount = const Value.absent(),
    this.customerGstin = const Value.absent(),
    this.placeOfSupply = const Value.absent(),
    this.isInterstate = const Value.absent(),
    this.extraChargesJson = const Value.absent(),
    this.paymentMode = const Value.absent(),
    required int syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : billDate = Value(billDate),
       paymentStatus = Value(paymentStatus),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BillRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<String>? customerContact,
    Expression<String>? itemsJson,
    Expression<int>? totalQuantity,
    Expression<double>? totalAmount,
    Expression<double>? discountAmount,
    Expression<double>? discountPercent,
    Expression<double>? finalAmount,
    Expression<DateTime>? billDate,
    Expression<String>? notes,
    Expression<bool>? returnStatus,
    Expression<DateTime>? returnDate,
    Expression<int>? paymentStatus,
    Expression<double>? paidAmount,
    Expression<double>? pendingAmount,
    Expression<bool>? isGstApplied,
    Expression<bool>? isTaxInclusive,
    Expression<double>? cgstPercent,
    Expression<double>? sgstPercent,
    Expression<double>? igstPercent,
    Expression<double>? otherTaxPercent,
    Expression<String>? otherTaxName,
    Expression<double>? cgstAmount,
    Expression<double>? sgstAmount,
    Expression<double>? igstAmount,
    Expression<double>? otherTaxAmount,
    Expression<double>? totalTaxAmount,
    Expression<String>? customerGstin,
    Expression<String>? placeOfSupply,
    Expression<bool>? isInterstate,
    Expression<String>? extraChargesJson,
    Expression<String>? paymentMode,
    Expression<int>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerContact != null) 'customer_contact': customerContact,
      if (itemsJson != null) 'items_json': itemsJson,
      if (totalQuantity != null) 'total_quantity': totalQuantity,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (finalAmount != null) 'final_amount': finalAmount,
      if (billDate != null) 'bill_date': billDate,
      if (notes != null) 'notes': notes,
      if (returnStatus != null) 'return_status': returnStatus,
      if (returnDate != null) 'return_date': returnDate,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (pendingAmount != null) 'pending_amount': pendingAmount,
      if (isGstApplied != null) 'is_gst_applied': isGstApplied,
      if (isTaxInclusive != null) 'is_tax_inclusive': isTaxInclusive,
      if (cgstPercent != null) 'cgst_percent': cgstPercent,
      if (sgstPercent != null) 'sgst_percent': sgstPercent,
      if (igstPercent != null) 'igst_percent': igstPercent,
      if (otherTaxPercent != null) 'other_tax_percent': otherTaxPercent,
      if (otherTaxName != null) 'other_tax_name': otherTaxName,
      if (cgstAmount != null) 'cgst_amount': cgstAmount,
      if (sgstAmount != null) 'sgst_amount': sgstAmount,
      if (igstAmount != null) 'igst_amount': igstAmount,
      if (otherTaxAmount != null) 'other_tax_amount': otherTaxAmount,
      if (totalTaxAmount != null) 'total_tax_amount': totalTaxAmount,
      if (customerGstin != null) 'customer_gstin': customerGstin,
      if (placeOfSupply != null) 'place_of_supply': placeOfSupply,
      if (isInterstate != null) 'is_interstate': isInterstate,
      if (extraChargesJson != null) 'extra_charges_json': extraChargesJson,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BillRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String?>? customerId,
    Value<String?>? customerName,
    Value<String?>? customerContact,
    Value<String>? itemsJson,
    Value<int>? totalQuantity,
    Value<double>? totalAmount,
    Value<double>? discountAmount,
    Value<double>? discountPercent,
    Value<double>? finalAmount,
    Value<DateTime>? billDate,
    Value<String?>? notes,
    Value<bool>? returnStatus,
    Value<DateTime?>? returnDate,
    Value<int>? paymentStatus,
    Value<double>? paidAmount,
    Value<double>? pendingAmount,
    Value<bool>? isGstApplied,
    Value<bool>? isTaxInclusive,
    Value<double>? cgstPercent,
    Value<double>? sgstPercent,
    Value<double>? igstPercent,
    Value<double>? otherTaxPercent,
    Value<String?>? otherTaxName,
    Value<double>? cgstAmount,
    Value<double>? sgstAmount,
    Value<double>? igstAmount,
    Value<double>? otherTaxAmount,
    Value<double>? totalTaxAmount,
    Value<String?>? customerGstin,
    Value<String?>? placeOfSupply,
    Value<bool>? isInterstate,
    Value<String>? extraChargesJson,
    Value<String>? paymentMode,
    Value<int>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BillRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      itemsJson: itemsJson ?? this.itemsJson,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      finalAmount: finalAmount ?? this.finalAmount,
      billDate: billDate ?? this.billDate,
      notes: notes ?? this.notes,
      returnStatus: returnStatus ?? this.returnStatus,
      returnDate: returnDate ?? this.returnDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      isGstApplied: isGstApplied ?? this.isGstApplied,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      igstPercent: igstPercent ?? this.igstPercent,
      otherTaxPercent: otherTaxPercent ?? this.otherTaxPercent,
      otherTaxName: otherTaxName ?? this.otherTaxName,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      otherTaxAmount: otherTaxAmount ?? this.otherTaxAmount,
      totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
      customerGstin: customerGstin ?? this.customerGstin,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
      isInterstate: isInterstate ?? this.isInterstate,
      extraChargesJson: extraChargesJson ?? this.extraChargesJson,
      paymentMode: paymentMode ?? this.paymentMode,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerContact.present) {
      map['customer_contact'] = Variable<String>(customerContact.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (totalQuantity.present) {
      map['total_quantity'] = Variable<int>(totalQuantity.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (discountPercent.present) {
      map['discount_percent'] = Variable<double>(discountPercent.value);
    }
    if (finalAmount.present) {
      map['final_amount'] = Variable<double>(finalAmount.value);
    }
    if (billDate.present) {
      map['bill_date'] = Variable<DateTime>(billDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (returnStatus.present) {
      map['return_status'] = Variable<bool>(returnStatus.value);
    }
    if (returnDate.present) {
      map['return_date'] = Variable<DateTime>(returnDate.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<int>(paymentStatus.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (pendingAmount.present) {
      map['pending_amount'] = Variable<double>(pendingAmount.value);
    }
    if (isGstApplied.present) {
      map['is_gst_applied'] = Variable<bool>(isGstApplied.value);
    }
    if (isTaxInclusive.present) {
      map['is_tax_inclusive'] = Variable<bool>(isTaxInclusive.value);
    }
    if (cgstPercent.present) {
      map['cgst_percent'] = Variable<double>(cgstPercent.value);
    }
    if (sgstPercent.present) {
      map['sgst_percent'] = Variable<double>(sgstPercent.value);
    }
    if (igstPercent.present) {
      map['igst_percent'] = Variable<double>(igstPercent.value);
    }
    if (otherTaxPercent.present) {
      map['other_tax_percent'] = Variable<double>(otherTaxPercent.value);
    }
    if (otherTaxName.present) {
      map['other_tax_name'] = Variable<String>(otherTaxName.value);
    }
    if (cgstAmount.present) {
      map['cgst_amount'] = Variable<double>(cgstAmount.value);
    }
    if (sgstAmount.present) {
      map['sgst_amount'] = Variable<double>(sgstAmount.value);
    }
    if (igstAmount.present) {
      map['igst_amount'] = Variable<double>(igstAmount.value);
    }
    if (otherTaxAmount.present) {
      map['other_tax_amount'] = Variable<double>(otherTaxAmount.value);
    }
    if (totalTaxAmount.present) {
      map['total_tax_amount'] = Variable<double>(totalTaxAmount.value);
    }
    if (customerGstin.present) {
      map['customer_gstin'] = Variable<String>(customerGstin.value);
    }
    if (placeOfSupply.present) {
      map['place_of_supply'] = Variable<String>(placeOfSupply.value);
    }
    if (isInterstate.present) {
      map['is_interstate'] = Variable<bool>(isInterstate.value);
    }
    if (extraChargesJson.present) {
      map['extra_charges_json'] = Variable<String>(extraChargesJson.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerContact: $customerContact, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('totalQuantity: $totalQuantity, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('billDate: $billDate, ')
          ..write('notes: $notes, ')
          ..write('returnStatus: $returnStatus, ')
          ..write('returnDate: $returnDate, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('pendingAmount: $pendingAmount, ')
          ..write('isGstApplied: $isGstApplied, ')
          ..write('isTaxInclusive: $isTaxInclusive, ')
          ..write('cgstPercent: $cgstPercent, ')
          ..write('sgstPercent: $sgstPercent, ')
          ..write('igstPercent: $igstPercent, ')
          ..write('otherTaxPercent: $otherTaxPercent, ')
          ..write('otherTaxName: $otherTaxName, ')
          ..write('cgstAmount: $cgstAmount, ')
          ..write('sgstAmount: $sgstAmount, ')
          ..write('igstAmount: $igstAmount, ')
          ..write('otherTaxAmount: $otherTaxAmount, ')
          ..write('totalTaxAmount: $totalTaxAmount, ')
          ..write('customerGstin: $customerGstin, ')
          ..write('placeOfSupply: $placeOfSupply, ')
          ..write('isInterstate: $isInterstate, ')
          ..write('extraChargesJson: $extraChargesJson, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EventOrderRecordsTable extends EventOrderRecords
    with TableInfo<$EventOrderRecordsTable, EventOrderRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventOrderRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderTypeMeta = const VerificationMeta(
    'orderType',
  );
  @override
  late final GeneratedColumn<int> orderType = GeneratedColumn<int>(
    'order_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customerContactMeta = const VerificationMeta(
    'customerContact',
  );
  @override
  late final GeneratedColumn<String> customerContact = GeneratedColumn<String>(
    'customer_contact',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customerAddressMeta = const VerificationMeta(
    'customerAddress',
  );
  @override
  late final GeneratedColumn<String> customerAddress = GeneratedColumn<String>(
    'customer_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderNameMeta = const VerificationMeta(
    'orderName',
  );
  @override
  late final GeneratedColumn<String> orderName = GeneratedColumn<String>(
    'order_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventDateMeta = const VerificationMeta(
    'eventDate',
  );
  @override
  late final GeneratedColumn<DateTime> eventDate = GeneratedColumn<DateTime>(
    'event_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventLocationMeta = const VerificationMeta(
    'eventLocation',
  );
  @override
  late final GeneratedColumn<String> eventLocation = GeneratedColumn<String>(
    'event_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subEventsJsonMeta = const VerificationMeta(
    'subEventsJson',
  );
  @override
  late final GeneratedColumn<String> subEventsJson = GeneratedColumn<String>(
    'sub_events_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _eventChargesMeta = const VerificationMeta(
    'eventCharges',
  );
  @override
  late final GeneratedColumn<double> eventCharges = GeneratedColumn<double>(
    'event_charges',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _advanceAmountMeta = const VerificationMeta(
    'advanceAmount',
  );
  @override
  late final GeneratedColumn<double> advanceAmount = GeneratedColumn<double>(
    'advance_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remainingAmountMeta = const VerificationMeta(
    'remainingAmount',
  );
  @override
  late final GeneratedColumn<double> remainingAmount = GeneratedColumn<double>(
    'remaining_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _convertedBillIdMeta = const VerificationMeta(
    'convertedBillId',
  );
  @override
  late final GeneratedColumn<String> convertedBillId = GeneratedColumn<String>(
    'converted_bill_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customDataJsonMeta = const VerificationMeta(
    'customDataJson',
  );
  @override
  late final GeneratedColumn<String> customDataJson = GeneratedColumn<String>(
    'custom_data_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    orderType,
    customerId,
    customerName,
    customerContact,
    customerAddress,
    orderName,
    description,
    eventDate,
    eventLocation,
    subEventsJson,
    itemsJson,
    eventCharges,
    totalAmount,
    advanceAmount,
    remainingAmount,
    notes,
    status,
    convertedBillId,
    customDataJson,
    createdAt,
    updatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventOrderRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('order_type')) {
      context.handle(
        _orderTypeMeta,
        orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_contact')) {
      context.handle(
        _customerContactMeta,
        customerContact.isAcceptableOrUnknown(
          data['customer_contact']!,
          _customerContactMeta,
        ),
      );
    }
    if (data.containsKey('customer_address')) {
      context.handle(
        _customerAddressMeta,
        customerAddress.isAcceptableOrUnknown(
          data['customer_address']!,
          _customerAddressMeta,
        ),
      );
    }
    if (data.containsKey('order_name')) {
      context.handle(
        _orderNameMeta,
        orderName.isAcceptableOrUnknown(data['order_name']!, _orderNameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('event_date')) {
      context.handle(
        _eventDateMeta,
        eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta),
      );
    } else if (isInserting) {
      context.missing(_eventDateMeta);
    }
    if (data.containsKey('event_location')) {
      context.handle(
        _eventLocationMeta,
        eventLocation.isAcceptableOrUnknown(
          data['event_location']!,
          _eventLocationMeta,
        ),
      );
    }
    if (data.containsKey('sub_events_json')) {
      context.handle(
        _subEventsJsonMeta,
        subEventsJson.isAcceptableOrUnknown(
          data['sub_events_json']!,
          _subEventsJsonMeta,
        ),
      );
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    }
    if (data.containsKey('event_charges')) {
      context.handle(
        _eventChargesMeta,
        eventCharges.isAcceptableOrUnknown(
          data['event_charges']!,
          _eventChargesMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('advance_amount')) {
      context.handle(
        _advanceAmountMeta,
        advanceAmount.isAcceptableOrUnknown(
          data['advance_amount']!,
          _advanceAmountMeta,
        ),
      );
    }
    if (data.containsKey('remaining_amount')) {
      context.handle(
        _remainingAmountMeta,
        remainingAmount.isAcceptableOrUnknown(
          data['remaining_amount']!,
          _remainingAmountMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('converted_bill_id')) {
      context.handle(
        _convertedBillIdMeta,
        convertedBillId.isAcceptableOrUnknown(
          data['converted_bill_id']!,
          _convertedBillIdMeta,
        ),
      );
    }
    if (data.containsKey('custom_data_json')) {
      context.handle(
        _customDataJsonMeta,
        customDataJson.isAcceptableOrUnknown(
          data['custom_data_json']!,
          _customDataJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventOrderRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventOrderRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      orderType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_type'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      customerContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_contact'],
      )!,
      customerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_address'],
      ),
      orderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      eventDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}event_date'],
      )!,
      eventLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_location'],
      ),
      subEventsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_events_json'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      eventCharges: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}event_charges'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      advanceAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}advance_amount'],
      )!,
      remainingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_amount'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      convertedBillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}converted_bill_id'],
      ),
      customDataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_data_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $EventOrderRecordsTable createAlias(String alias) {
    return $EventOrderRecordsTable(attachedDatabase, alias);
  }
}

class EventOrderRecord extends DataClass
    implements Insertable<EventOrderRecord> {
  final int id;
  final String? serverId;
  final int orderType;
  final String? customerId;
  final String customerName;
  final String customerContact;
  final String? customerAddress;
  final String orderName;
  final String? description;
  final DateTime eventDate;
  final String? eventLocation;
  final String subEventsJson;
  final String itemsJson;
  final double eventCharges;
  final double totalAmount;
  final double advanceAmount;
  final double remainingAmount;
  final String? notes;
  final int status;
  final String? convertedBillId;
  final String? customDataJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus;
  const EventOrderRecord({
    required this.id,
    this.serverId,
    required this.orderType,
    this.customerId,
    required this.customerName,
    required this.customerContact,
    this.customerAddress,
    required this.orderName,
    this.description,
    required this.eventDate,
    this.eventLocation,
    required this.subEventsJson,
    required this.itemsJson,
    required this.eventCharges,
    required this.totalAmount,
    required this.advanceAmount,
    required this.remainingAmount,
    this.notes,
    required this.status,
    this.convertedBillId,
    this.customDataJson,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['order_type'] = Variable<int>(orderType);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['customer_name'] = Variable<String>(customerName);
    map['customer_contact'] = Variable<String>(customerContact);
    if (!nullToAbsent || customerAddress != null) {
      map['customer_address'] = Variable<String>(customerAddress);
    }
    map['order_name'] = Variable<String>(orderName);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['event_date'] = Variable<DateTime>(eventDate);
    if (!nullToAbsent || eventLocation != null) {
      map['event_location'] = Variable<String>(eventLocation);
    }
    map['sub_events_json'] = Variable<String>(subEventsJson);
    map['items_json'] = Variable<String>(itemsJson);
    map['event_charges'] = Variable<double>(eventCharges);
    map['total_amount'] = Variable<double>(totalAmount);
    map['advance_amount'] = Variable<double>(advanceAmount);
    map['remaining_amount'] = Variable<double>(remainingAmount);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || convertedBillId != null) {
      map['converted_bill_id'] = Variable<String>(convertedBillId);
    }
    if (!nullToAbsent || customDataJson != null) {
      map['custom_data_json'] = Variable<String>(customDataJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  EventOrderRecordsCompanion toCompanion(bool nullToAbsent) {
    return EventOrderRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      orderType: Value(orderType),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: Value(customerName),
      customerContact: Value(customerContact),
      customerAddress: customerAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(customerAddress),
      orderName: Value(orderName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      eventDate: Value(eventDate),
      eventLocation: eventLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(eventLocation),
      subEventsJson: Value(subEventsJson),
      itemsJson: Value(itemsJson),
      eventCharges: Value(eventCharges),
      totalAmount: Value(totalAmount),
      advanceAmount: Value(advanceAmount),
      remainingAmount: Value(remainingAmount),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      convertedBillId: convertedBillId == null && nullToAbsent
          ? const Value.absent()
          : Value(convertedBillId),
      customDataJson: customDataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(customDataJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory EventOrderRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventOrderRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      orderType: serializer.fromJson<int>(json['orderType']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerContact: serializer.fromJson<String>(json['customerContact']),
      customerAddress: serializer.fromJson<String?>(json['customerAddress']),
      orderName: serializer.fromJson<String>(json['orderName']),
      description: serializer.fromJson<String?>(json['description']),
      eventDate: serializer.fromJson<DateTime>(json['eventDate']),
      eventLocation: serializer.fromJson<String?>(json['eventLocation']),
      subEventsJson: serializer.fromJson<String>(json['subEventsJson']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      eventCharges: serializer.fromJson<double>(json['eventCharges']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      advanceAmount: serializer.fromJson<double>(json['advanceAmount']),
      remainingAmount: serializer.fromJson<double>(json['remainingAmount']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<int>(json['status']),
      convertedBillId: serializer.fromJson<String?>(json['convertedBillId']),
      customDataJson: serializer.fromJson<String?>(json['customDataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'orderType': serializer.toJson<int>(orderType),
      'customerId': serializer.toJson<String?>(customerId),
      'customerName': serializer.toJson<String>(customerName),
      'customerContact': serializer.toJson<String>(customerContact),
      'customerAddress': serializer.toJson<String?>(customerAddress),
      'orderName': serializer.toJson<String>(orderName),
      'description': serializer.toJson<String?>(description),
      'eventDate': serializer.toJson<DateTime>(eventDate),
      'eventLocation': serializer.toJson<String?>(eventLocation),
      'subEventsJson': serializer.toJson<String>(subEventsJson),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'eventCharges': serializer.toJson<double>(eventCharges),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'advanceAmount': serializer.toJson<double>(advanceAmount),
      'remainingAmount': serializer.toJson<double>(remainingAmount),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<int>(status),
      'convertedBillId': serializer.toJson<String?>(convertedBillId),
      'customDataJson': serializer.toJson<String?>(customDataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  EventOrderRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    int? orderType,
    Value<String?> customerId = const Value.absent(),
    String? customerName,
    String? customerContact,
    Value<String?> customerAddress = const Value.absent(),
    String? orderName,
    Value<String?> description = const Value.absent(),
    DateTime? eventDate,
    Value<String?> eventLocation = const Value.absent(),
    String? subEventsJson,
    String? itemsJson,
    double? eventCharges,
    double? totalAmount,
    double? advanceAmount,
    double? remainingAmount,
    Value<String?> notes = const Value.absent(),
    int? status,
    Value<String?> convertedBillId = const Value.absent(),
    Value<String?> customDataJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) => EventOrderRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    orderType: orderType ?? this.orderType,
    customerId: customerId.present ? customerId.value : this.customerId,
    customerName: customerName ?? this.customerName,
    customerContact: customerContact ?? this.customerContact,
    customerAddress: customerAddress.present
        ? customerAddress.value
        : this.customerAddress,
    orderName: orderName ?? this.orderName,
    description: description.present ? description.value : this.description,
    eventDate: eventDate ?? this.eventDate,
    eventLocation: eventLocation.present
        ? eventLocation.value
        : this.eventLocation,
    subEventsJson: subEventsJson ?? this.subEventsJson,
    itemsJson: itemsJson ?? this.itemsJson,
    eventCharges: eventCharges ?? this.eventCharges,
    totalAmount: totalAmount ?? this.totalAmount,
    advanceAmount: advanceAmount ?? this.advanceAmount,
    remainingAmount: remainingAmount ?? this.remainingAmount,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    convertedBillId: convertedBillId.present
        ? convertedBillId.value
        : this.convertedBillId,
    customDataJson: customDataJson.present
        ? customDataJson.value
        : this.customDataJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  EventOrderRecord copyWithCompanion(EventOrderRecordsCompanion data) {
    return EventOrderRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerContact: data.customerContact.present
          ? data.customerContact.value
          : this.customerContact,
      customerAddress: data.customerAddress.present
          ? data.customerAddress.value
          : this.customerAddress,
      orderName: data.orderName.present ? data.orderName.value : this.orderName,
      description: data.description.present
          ? data.description.value
          : this.description,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      eventLocation: data.eventLocation.present
          ? data.eventLocation.value
          : this.eventLocation,
      subEventsJson: data.subEventsJson.present
          ? data.subEventsJson.value
          : this.subEventsJson,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      eventCharges: data.eventCharges.present
          ? data.eventCharges.value
          : this.eventCharges,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      advanceAmount: data.advanceAmount.present
          ? data.advanceAmount.value
          : this.advanceAmount,
      remainingAmount: data.remainingAmount.present
          ? data.remainingAmount.value
          : this.remainingAmount,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      convertedBillId: data.convertedBillId.present
          ? data.convertedBillId.value
          : this.convertedBillId,
      customDataJson: data.customDataJson.present
          ? data.customDataJson.value
          : this.customDataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventOrderRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('orderType: $orderType, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerContact: $customerContact, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('orderName: $orderName, ')
          ..write('description: $description, ')
          ..write('eventDate: $eventDate, ')
          ..write('eventLocation: $eventLocation, ')
          ..write('subEventsJson: $subEventsJson, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('eventCharges: $eventCharges, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('advanceAmount: $advanceAmount, ')
          ..write('remainingAmount: $remainingAmount, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('convertedBillId: $convertedBillId, ')
          ..write('customDataJson: $customDataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    orderType,
    customerId,
    customerName,
    customerContact,
    customerAddress,
    orderName,
    description,
    eventDate,
    eventLocation,
    subEventsJson,
    itemsJson,
    eventCharges,
    totalAmount,
    advanceAmount,
    remainingAmount,
    notes,
    status,
    convertedBillId,
    customDataJson,
    createdAt,
    updatedAt,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventOrderRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.orderType == this.orderType &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.customerContact == this.customerContact &&
          other.customerAddress == this.customerAddress &&
          other.orderName == this.orderName &&
          other.description == this.description &&
          other.eventDate == this.eventDate &&
          other.eventLocation == this.eventLocation &&
          other.subEventsJson == this.subEventsJson &&
          other.itemsJson == this.itemsJson &&
          other.eventCharges == this.eventCharges &&
          other.totalAmount == this.totalAmount &&
          other.advanceAmount == this.advanceAmount &&
          other.remainingAmount == this.remainingAmount &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.convertedBillId == this.convertedBillId &&
          other.customDataJson == this.customDataJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class EventOrderRecordsCompanion extends UpdateCompanion<EventOrderRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<int> orderType;
  final Value<String?> customerId;
  final Value<String> customerName;
  final Value<String> customerContact;
  final Value<String?> customerAddress;
  final Value<String> orderName;
  final Value<String?> description;
  final Value<DateTime> eventDate;
  final Value<String?> eventLocation;
  final Value<String> subEventsJson;
  final Value<String> itemsJson;
  final Value<double> eventCharges;
  final Value<double> totalAmount;
  final Value<double> advanceAmount;
  final Value<double> remainingAmount;
  final Value<String?> notes;
  final Value<int> status;
  final Value<String?> convertedBillId;
  final Value<String?> customDataJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> syncStatus;
  const EventOrderRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.orderType = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerContact = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.orderName = const Value.absent(),
    this.description = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.eventLocation = const Value.absent(),
    this.subEventsJson = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.eventCharges = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.advanceAmount = const Value.absent(),
    this.remainingAmount = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.convertedBillId = const Value.absent(),
    this.customDataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  EventOrderRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.orderType = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerContact = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.orderName = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime eventDate,
    this.eventLocation = const Value.absent(),
    this.subEventsJson = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.eventCharges = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.advanceAmount = const Value.absent(),
    this.remainingAmount = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.convertedBillId = const Value.absent(),
    this.customDataJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required int syncStatus,
  }) : eventDate = Value(eventDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<EventOrderRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<int>? orderType,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<String>? customerContact,
    Expression<String>? customerAddress,
    Expression<String>? orderName,
    Expression<String>? description,
    Expression<DateTime>? eventDate,
    Expression<String>? eventLocation,
    Expression<String>? subEventsJson,
    Expression<String>? itemsJson,
    Expression<double>? eventCharges,
    Expression<double>? totalAmount,
    Expression<double>? advanceAmount,
    Expression<double>? remainingAmount,
    Expression<String>? notes,
    Expression<int>? status,
    Expression<String>? convertedBillId,
    Expression<String>? customDataJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (orderType != null) 'order_type': orderType,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerContact != null) 'customer_contact': customerContact,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (orderName != null) 'order_name': orderName,
      if (description != null) 'description': description,
      if (eventDate != null) 'event_date': eventDate,
      if (eventLocation != null) 'event_location': eventLocation,
      if (subEventsJson != null) 'sub_events_json': subEventsJson,
      if (itemsJson != null) 'items_json': itemsJson,
      if (eventCharges != null) 'event_charges': eventCharges,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (advanceAmount != null) 'advance_amount': advanceAmount,
      if (remainingAmount != null) 'remaining_amount': remainingAmount,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (convertedBillId != null) 'converted_bill_id': convertedBillId,
      if (customDataJson != null) 'custom_data_json': customDataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  EventOrderRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<int>? orderType,
    Value<String?>? customerId,
    Value<String>? customerName,
    Value<String>? customerContact,
    Value<String?>? customerAddress,
    Value<String>? orderName,
    Value<String?>? description,
    Value<DateTime>? eventDate,
    Value<String?>? eventLocation,
    Value<String>? subEventsJson,
    Value<String>? itemsJson,
    Value<double>? eventCharges,
    Value<double>? totalAmount,
    Value<double>? advanceAmount,
    Value<double>? remainingAmount,
    Value<String?>? notes,
    Value<int>? status,
    Value<String?>? convertedBillId,
    Value<String?>? customDataJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? syncStatus,
  }) {
    return EventOrderRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      orderType: orderType ?? this.orderType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      customerAddress: customerAddress ?? this.customerAddress,
      orderName: orderName ?? this.orderName,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      subEventsJson: subEventsJson ?? this.subEventsJson,
      itemsJson: itemsJson ?? this.itemsJson,
      eventCharges: eventCharges ?? this.eventCharges,
      totalAmount: totalAmount ?? this.totalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      convertedBillId: convertedBillId ?? this.convertedBillId,
      customDataJson: customDataJson ?? this.customDataJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<int>(orderType.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerContact.present) {
      map['customer_contact'] = Variable<String>(customerContact.value);
    }
    if (customerAddress.present) {
      map['customer_address'] = Variable<String>(customerAddress.value);
    }
    if (orderName.present) {
      map['order_name'] = Variable<String>(orderName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<DateTime>(eventDate.value);
    }
    if (eventLocation.present) {
      map['event_location'] = Variable<String>(eventLocation.value);
    }
    if (subEventsJson.present) {
      map['sub_events_json'] = Variable<String>(subEventsJson.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (eventCharges.present) {
      map['event_charges'] = Variable<double>(eventCharges.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (advanceAmount.present) {
      map['advance_amount'] = Variable<double>(advanceAmount.value);
    }
    if (remainingAmount.present) {
      map['remaining_amount'] = Variable<double>(remainingAmount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (convertedBillId.present) {
      map['converted_bill_id'] = Variable<String>(convertedBillId.value);
    }
    if (customDataJson.present) {
      map['custom_data_json'] = Variable<String>(customDataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventOrderRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('orderType: $orderType, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerContact: $customerContact, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('orderName: $orderName, ')
          ..write('description: $description, ')
          ..write('eventDate: $eventDate, ')
          ..write('eventLocation: $eventLocation, ')
          ..write('subEventsJson: $subEventsJson, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('eventCharges: $eventCharges, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('advanceAmount: $advanceAmount, ')
          ..write('remainingAmount: $remainingAmount, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('convertedBillId: $convertedBillId, ')
          ..write('customDataJson: $customDataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $QuotationRecordsTable extends QuotationRecords
    with TableInfo<$QuotationRecordsTable, QuotationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuotationRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotationNumberMeta = const VerificationMeta(
    'quotationNumber',
  );
  @override
  late final GeneratedColumn<String> quotationNumber = GeneratedColumn<String>(
    'quotation_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quotationTypeMeta = const VerificationMeta(
    'quotationType',
  );
  @override
  late final GeneratedColumn<int> quotationType = GeneratedColumn<int>(
    'quotation_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customerContactMeta = const VerificationMeta(
    'customerContact',
  );
  @override
  late final GeneratedColumn<String> customerContact = GeneratedColumn<String>(
    'customer_contact',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customerAddressMeta = const VerificationMeta(
    'customerAddress',
  );
  @override
  late final GeneratedColumn<String> customerAddress = GeneratedColumn<String>(
    'customer_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceDateMeta = const VerificationMeta(
    'referenceDate',
  );
  @override
  late final GeneratedColumn<DateTime> referenceDate =
      GeneratedColumn<DateTime>(
        'reference_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _eventLocationMeta = const VerificationMeta(
    'eventLocation',
  );
  @override
  late final GeneratedColumn<String> eventLocation = GeneratedColumn<String>(
    'event_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validUntilMeta = const VerificationMeta(
    'validUntil',
  );
  @override
  late final GeneratedColumn<DateTime> validUntil = GeneratedColumn<DateTime>(
    'valid_until',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subEventsJsonMeta = const VerificationMeta(
    'subEventsJson',
  );
  @override
  late final GeneratedColumn<String> subEventsJson = GeneratedColumn<String>(
    'sub_events_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _eventChargesMeta = const VerificationMeta(
    'eventCharges',
  );
  @override
  late final GeneratedColumn<double> eventCharges = GeneratedColumn<double>(
    'event_charges',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountPercentMeta = const VerificationMeta(
    'discountPercent',
  );
  @override
  late final GeneratedColumn<double> discountPercent = GeneratedColumn<double>(
    'discount_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _convertedBillIdMeta = const VerificationMeta(
    'convertedBillId',
  );
  @override
  late final GeneratedColumn<String> convertedBillId = GeneratedColumn<String>(
    'converted_bill_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _convertedEventOrderIdMeta =
      const VerificationMeta('convertedEventOrderId');
  @override
  late final GeneratedColumn<String> convertedEventOrderId =
      GeneratedColumn<String>(
        'converted_event_order_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customDataJsonMeta = const VerificationMeta(
    'customDataJson',
  );
  @override
  late final GeneratedColumn<String> customDataJson = GeneratedColumn<String>(
    'custom_data_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    quotationNumber,
    quotationType,
    customerId,
    customerName,
    customerContact,
    customerAddress,
    title,
    description,
    referenceDate,
    eventLocation,
    validUntil,
    subEventsJson,
    itemsJson,
    eventCharges,
    discountPercent,
    discountAmount,
    totalAmount,
    notes,
    status,
    convertedBillId,
    convertedEventOrderId,
    customDataJson,
    createdAt,
    updatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuotationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('quotation_number')) {
      context.handle(
        _quotationNumberMeta,
        quotationNumber.isAcceptableOrUnknown(
          data['quotation_number']!,
          _quotationNumberMeta,
        ),
      );
    }
    if (data.containsKey('quotation_type')) {
      context.handle(
        _quotationTypeMeta,
        quotationType.isAcceptableOrUnknown(
          data['quotation_type']!,
          _quotationTypeMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_contact')) {
      context.handle(
        _customerContactMeta,
        customerContact.isAcceptableOrUnknown(
          data['customer_contact']!,
          _customerContactMeta,
        ),
      );
    }
    if (data.containsKey('customer_address')) {
      context.handle(
        _customerAddressMeta,
        customerAddress.isAcceptableOrUnknown(
          data['customer_address']!,
          _customerAddressMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('reference_date')) {
      context.handle(
        _referenceDateMeta,
        referenceDate.isAcceptableOrUnknown(
          data['reference_date']!,
          _referenceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceDateMeta);
    }
    if (data.containsKey('event_location')) {
      context.handle(
        _eventLocationMeta,
        eventLocation.isAcceptableOrUnknown(
          data['event_location']!,
          _eventLocationMeta,
        ),
      );
    }
    if (data.containsKey('valid_until')) {
      context.handle(
        _validUntilMeta,
        validUntil.isAcceptableOrUnknown(data['valid_until']!, _validUntilMeta),
      );
    } else if (isInserting) {
      context.missing(_validUntilMeta);
    }
    if (data.containsKey('sub_events_json')) {
      context.handle(
        _subEventsJsonMeta,
        subEventsJson.isAcceptableOrUnknown(
          data['sub_events_json']!,
          _subEventsJsonMeta,
        ),
      );
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    }
    if (data.containsKey('event_charges')) {
      context.handle(
        _eventChargesMeta,
        eventCharges.isAcceptableOrUnknown(
          data['event_charges']!,
          _eventChargesMeta,
        ),
      );
    }
    if (data.containsKey('discount_percent')) {
      context.handle(
        _discountPercentMeta,
        discountPercent.isAcceptableOrUnknown(
          data['discount_percent']!,
          _discountPercentMeta,
        ),
      );
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('converted_bill_id')) {
      context.handle(
        _convertedBillIdMeta,
        convertedBillId.isAcceptableOrUnknown(
          data['converted_bill_id']!,
          _convertedBillIdMeta,
        ),
      );
    }
    if (data.containsKey('converted_event_order_id')) {
      context.handle(
        _convertedEventOrderIdMeta,
        convertedEventOrderId.isAcceptableOrUnknown(
          data['converted_event_order_id']!,
          _convertedEventOrderIdMeta,
        ),
      );
    }
    if (data.containsKey('custom_data_json')) {
      context.handle(
        _customDataJsonMeta,
        customDataJson.isAcceptableOrUnknown(
          data['custom_data_json']!,
          _customDataJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuotationRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuotationRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      quotationNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quotation_number'],
      )!,
      quotationType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quotation_type'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      customerContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_contact'],
      )!,
      customerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_address'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      referenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reference_date'],
      )!,
      eventLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_location'],
      ),
      validUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_until'],
      )!,
      subEventsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_events_json'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      eventCharges: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}event_charges'],
      )!,
      discountPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_percent'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      convertedBillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}converted_bill_id'],
      ),
      convertedEventOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}converted_event_order_id'],
      ),
      customDataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_data_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $QuotationRecordsTable createAlias(String alias) {
    return $QuotationRecordsTable(attachedDatabase, alias);
  }
}

class QuotationRecord extends DataClass implements Insertable<QuotationRecord> {
  final int id;
  final String? serverId;
  final String quotationNumber;
  final int quotationType;
  final String? customerId;
  final String customerName;
  final String customerContact;
  final String? customerAddress;
  final String title;
  final String? description;
  final DateTime referenceDate;
  final String? eventLocation;
  final DateTime validUntil;
  final String subEventsJson;
  final String itemsJson;
  final double eventCharges;
  final double discountPercent;
  final double discountAmount;
  final double totalAmount;
  final String? notes;
  final int status;
  final String? convertedBillId;
  final String? convertedEventOrderId;
  final String? customDataJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus;
  const QuotationRecord({
    required this.id,
    this.serverId,
    required this.quotationNumber,
    required this.quotationType,
    this.customerId,
    required this.customerName,
    required this.customerContact,
    this.customerAddress,
    required this.title,
    this.description,
    required this.referenceDate,
    this.eventLocation,
    required this.validUntil,
    required this.subEventsJson,
    required this.itemsJson,
    required this.eventCharges,
    required this.discountPercent,
    required this.discountAmount,
    required this.totalAmount,
    this.notes,
    required this.status,
    this.convertedBillId,
    this.convertedEventOrderId,
    this.customDataJson,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['quotation_number'] = Variable<String>(quotationNumber);
    map['quotation_type'] = Variable<int>(quotationType);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['customer_name'] = Variable<String>(customerName);
    map['customer_contact'] = Variable<String>(customerContact);
    if (!nullToAbsent || customerAddress != null) {
      map['customer_address'] = Variable<String>(customerAddress);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['reference_date'] = Variable<DateTime>(referenceDate);
    if (!nullToAbsent || eventLocation != null) {
      map['event_location'] = Variable<String>(eventLocation);
    }
    map['valid_until'] = Variable<DateTime>(validUntil);
    map['sub_events_json'] = Variable<String>(subEventsJson);
    map['items_json'] = Variable<String>(itemsJson);
    map['event_charges'] = Variable<double>(eventCharges);
    map['discount_percent'] = Variable<double>(discountPercent);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || convertedBillId != null) {
      map['converted_bill_id'] = Variable<String>(convertedBillId);
    }
    if (!nullToAbsent || convertedEventOrderId != null) {
      map['converted_event_order_id'] = Variable<String>(convertedEventOrderId);
    }
    if (!nullToAbsent || customDataJson != null) {
      map['custom_data_json'] = Variable<String>(customDataJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  QuotationRecordsCompanion toCompanion(bool nullToAbsent) {
    return QuotationRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      quotationNumber: Value(quotationNumber),
      quotationType: Value(quotationType),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: Value(customerName),
      customerContact: Value(customerContact),
      customerAddress: customerAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(customerAddress),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      referenceDate: Value(referenceDate),
      eventLocation: eventLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(eventLocation),
      validUntil: Value(validUntil),
      subEventsJson: Value(subEventsJson),
      itemsJson: Value(itemsJson),
      eventCharges: Value(eventCharges),
      discountPercent: Value(discountPercent),
      discountAmount: Value(discountAmount),
      totalAmount: Value(totalAmount),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      convertedBillId: convertedBillId == null && nullToAbsent
          ? const Value.absent()
          : Value(convertedBillId),
      convertedEventOrderId: convertedEventOrderId == null && nullToAbsent
          ? const Value.absent()
          : Value(convertedEventOrderId),
      customDataJson: customDataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(customDataJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory QuotationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuotationRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      quotationNumber: serializer.fromJson<String>(json['quotationNumber']),
      quotationType: serializer.fromJson<int>(json['quotationType']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerContact: serializer.fromJson<String>(json['customerContact']),
      customerAddress: serializer.fromJson<String?>(json['customerAddress']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      referenceDate: serializer.fromJson<DateTime>(json['referenceDate']),
      eventLocation: serializer.fromJson<String?>(json['eventLocation']),
      validUntil: serializer.fromJson<DateTime>(json['validUntil']),
      subEventsJson: serializer.fromJson<String>(json['subEventsJson']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      eventCharges: serializer.fromJson<double>(json['eventCharges']),
      discountPercent: serializer.fromJson<double>(json['discountPercent']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<int>(json['status']),
      convertedBillId: serializer.fromJson<String?>(json['convertedBillId']),
      convertedEventOrderId: serializer.fromJson<String?>(
        json['convertedEventOrderId'],
      ),
      customDataJson: serializer.fromJson<String?>(json['customDataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'quotationNumber': serializer.toJson<String>(quotationNumber),
      'quotationType': serializer.toJson<int>(quotationType),
      'customerId': serializer.toJson<String?>(customerId),
      'customerName': serializer.toJson<String>(customerName),
      'customerContact': serializer.toJson<String>(customerContact),
      'customerAddress': serializer.toJson<String?>(customerAddress),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'referenceDate': serializer.toJson<DateTime>(referenceDate),
      'eventLocation': serializer.toJson<String?>(eventLocation),
      'validUntil': serializer.toJson<DateTime>(validUntil),
      'subEventsJson': serializer.toJson<String>(subEventsJson),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'eventCharges': serializer.toJson<double>(eventCharges),
      'discountPercent': serializer.toJson<double>(discountPercent),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<int>(status),
      'convertedBillId': serializer.toJson<String?>(convertedBillId),
      'convertedEventOrderId': serializer.toJson<String?>(
        convertedEventOrderId,
      ),
      'customDataJson': serializer.toJson<String?>(customDataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  QuotationRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? quotationNumber,
    int? quotationType,
    Value<String?> customerId = const Value.absent(),
    String? customerName,
    String? customerContact,
    Value<String?> customerAddress = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    DateTime? referenceDate,
    Value<String?> eventLocation = const Value.absent(),
    DateTime? validUntil,
    String? subEventsJson,
    String? itemsJson,
    double? eventCharges,
    double? discountPercent,
    double? discountAmount,
    double? totalAmount,
    Value<String?> notes = const Value.absent(),
    int? status,
    Value<String?> convertedBillId = const Value.absent(),
    Value<String?> convertedEventOrderId = const Value.absent(),
    Value<String?> customDataJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) => QuotationRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    quotationNumber: quotationNumber ?? this.quotationNumber,
    quotationType: quotationType ?? this.quotationType,
    customerId: customerId.present ? customerId.value : this.customerId,
    customerName: customerName ?? this.customerName,
    customerContact: customerContact ?? this.customerContact,
    customerAddress: customerAddress.present
        ? customerAddress.value
        : this.customerAddress,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    referenceDate: referenceDate ?? this.referenceDate,
    eventLocation: eventLocation.present
        ? eventLocation.value
        : this.eventLocation,
    validUntil: validUntil ?? this.validUntil,
    subEventsJson: subEventsJson ?? this.subEventsJson,
    itemsJson: itemsJson ?? this.itemsJson,
    eventCharges: eventCharges ?? this.eventCharges,
    discountPercent: discountPercent ?? this.discountPercent,
    discountAmount: discountAmount ?? this.discountAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    convertedBillId: convertedBillId.present
        ? convertedBillId.value
        : this.convertedBillId,
    convertedEventOrderId: convertedEventOrderId.present
        ? convertedEventOrderId.value
        : this.convertedEventOrderId,
    customDataJson: customDataJson.present
        ? customDataJson.value
        : this.customDataJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  QuotationRecord copyWithCompanion(QuotationRecordsCompanion data) {
    return QuotationRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      quotationNumber: data.quotationNumber.present
          ? data.quotationNumber.value
          : this.quotationNumber,
      quotationType: data.quotationType.present
          ? data.quotationType.value
          : this.quotationType,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerContact: data.customerContact.present
          ? data.customerContact.value
          : this.customerContact,
      customerAddress: data.customerAddress.present
          ? data.customerAddress.value
          : this.customerAddress,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      referenceDate: data.referenceDate.present
          ? data.referenceDate.value
          : this.referenceDate,
      eventLocation: data.eventLocation.present
          ? data.eventLocation.value
          : this.eventLocation,
      validUntil: data.validUntil.present
          ? data.validUntil.value
          : this.validUntil,
      subEventsJson: data.subEventsJson.present
          ? data.subEventsJson.value
          : this.subEventsJson,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      eventCharges: data.eventCharges.present
          ? data.eventCharges.value
          : this.eventCharges,
      discountPercent: data.discountPercent.present
          ? data.discountPercent.value
          : this.discountPercent,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      convertedBillId: data.convertedBillId.present
          ? data.convertedBillId.value
          : this.convertedBillId,
      convertedEventOrderId: data.convertedEventOrderId.present
          ? data.convertedEventOrderId.value
          : this.convertedEventOrderId,
      customDataJson: data.customDataJson.present
          ? data.customDataJson.value
          : this.customDataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuotationRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('quotationNumber: $quotationNumber, ')
          ..write('quotationType: $quotationType, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerContact: $customerContact, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('referenceDate: $referenceDate, ')
          ..write('eventLocation: $eventLocation, ')
          ..write('validUntil: $validUntil, ')
          ..write('subEventsJson: $subEventsJson, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('eventCharges: $eventCharges, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('convertedBillId: $convertedBillId, ')
          ..write('convertedEventOrderId: $convertedEventOrderId, ')
          ..write('customDataJson: $customDataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    quotationNumber,
    quotationType,
    customerId,
    customerName,
    customerContact,
    customerAddress,
    title,
    description,
    referenceDate,
    eventLocation,
    validUntil,
    subEventsJson,
    itemsJson,
    eventCharges,
    discountPercent,
    discountAmount,
    totalAmount,
    notes,
    status,
    convertedBillId,
    convertedEventOrderId,
    customDataJson,
    createdAt,
    updatedAt,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuotationRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.quotationNumber == this.quotationNumber &&
          other.quotationType == this.quotationType &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.customerContact == this.customerContact &&
          other.customerAddress == this.customerAddress &&
          other.title == this.title &&
          other.description == this.description &&
          other.referenceDate == this.referenceDate &&
          other.eventLocation == this.eventLocation &&
          other.validUntil == this.validUntil &&
          other.subEventsJson == this.subEventsJson &&
          other.itemsJson == this.itemsJson &&
          other.eventCharges == this.eventCharges &&
          other.discountPercent == this.discountPercent &&
          other.discountAmount == this.discountAmount &&
          other.totalAmount == this.totalAmount &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.convertedBillId == this.convertedBillId &&
          other.convertedEventOrderId == this.convertedEventOrderId &&
          other.customDataJson == this.customDataJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class QuotationRecordsCompanion extends UpdateCompanion<QuotationRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> quotationNumber;
  final Value<int> quotationType;
  final Value<String?> customerId;
  final Value<String> customerName;
  final Value<String> customerContact;
  final Value<String?> customerAddress;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> referenceDate;
  final Value<String?> eventLocation;
  final Value<DateTime> validUntil;
  final Value<String> subEventsJson;
  final Value<String> itemsJson;
  final Value<double> eventCharges;
  final Value<double> discountPercent;
  final Value<double> discountAmount;
  final Value<double> totalAmount;
  final Value<String?> notes;
  final Value<int> status;
  final Value<String?> convertedBillId;
  final Value<String?> convertedEventOrderId;
  final Value<String?> customDataJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> syncStatus;
  const QuotationRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.quotationNumber = const Value.absent(),
    this.quotationType = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerContact = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.referenceDate = const Value.absent(),
    this.eventLocation = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.subEventsJson = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.eventCharges = const Value.absent(),
    this.discountPercent = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.convertedBillId = const Value.absent(),
    this.convertedEventOrderId = const Value.absent(),
    this.customDataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  QuotationRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.quotationNumber = const Value.absent(),
    this.quotationType = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerContact = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime referenceDate,
    this.eventLocation = const Value.absent(),
    required DateTime validUntil,
    this.subEventsJson = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.eventCharges = const Value.absent(),
    this.discountPercent = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.convertedBillId = const Value.absent(),
    this.convertedEventOrderId = const Value.absent(),
    this.customDataJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required int syncStatus,
  }) : referenceDate = Value(referenceDate),
       validUntil = Value(validUntil),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<QuotationRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? quotationNumber,
    Expression<int>? quotationType,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<String>? customerContact,
    Expression<String>? customerAddress,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? referenceDate,
    Expression<String>? eventLocation,
    Expression<DateTime>? validUntil,
    Expression<String>? subEventsJson,
    Expression<String>? itemsJson,
    Expression<double>? eventCharges,
    Expression<double>? discountPercent,
    Expression<double>? discountAmount,
    Expression<double>? totalAmount,
    Expression<String>? notes,
    Expression<int>? status,
    Expression<String>? convertedBillId,
    Expression<String>? convertedEventOrderId,
    Expression<String>? customDataJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (quotationNumber != null) 'quotation_number': quotationNumber,
      if (quotationType != null) 'quotation_type': quotationType,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerContact != null) 'customer_contact': customerContact,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (referenceDate != null) 'reference_date': referenceDate,
      if (eventLocation != null) 'event_location': eventLocation,
      if (validUntil != null) 'valid_until': validUntil,
      if (subEventsJson != null) 'sub_events_json': subEventsJson,
      if (itemsJson != null) 'items_json': itemsJson,
      if (eventCharges != null) 'event_charges': eventCharges,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (convertedBillId != null) 'converted_bill_id': convertedBillId,
      if (convertedEventOrderId != null)
        'converted_event_order_id': convertedEventOrderId,
      if (customDataJson != null) 'custom_data_json': customDataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  QuotationRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? quotationNumber,
    Value<int>? quotationType,
    Value<String?>? customerId,
    Value<String>? customerName,
    Value<String>? customerContact,
    Value<String?>? customerAddress,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime>? referenceDate,
    Value<String?>? eventLocation,
    Value<DateTime>? validUntil,
    Value<String>? subEventsJson,
    Value<String>? itemsJson,
    Value<double>? eventCharges,
    Value<double>? discountPercent,
    Value<double>? discountAmount,
    Value<double>? totalAmount,
    Value<String?>? notes,
    Value<int>? status,
    Value<String?>? convertedBillId,
    Value<String?>? convertedEventOrderId,
    Value<String?>? customDataJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? syncStatus,
  }) {
    return QuotationRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      quotationType: quotationType ?? this.quotationType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      customerAddress: customerAddress ?? this.customerAddress,
      title: title ?? this.title,
      description: description ?? this.description,
      referenceDate: referenceDate ?? this.referenceDate,
      eventLocation: eventLocation ?? this.eventLocation,
      validUntil: validUntil ?? this.validUntil,
      subEventsJson: subEventsJson ?? this.subEventsJson,
      itemsJson: itemsJson ?? this.itemsJson,
      eventCharges: eventCharges ?? this.eventCharges,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      convertedBillId: convertedBillId ?? this.convertedBillId,
      convertedEventOrderId:
          convertedEventOrderId ?? this.convertedEventOrderId,
      customDataJson: customDataJson ?? this.customDataJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (quotationNumber.present) {
      map['quotation_number'] = Variable<String>(quotationNumber.value);
    }
    if (quotationType.present) {
      map['quotation_type'] = Variable<int>(quotationType.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerContact.present) {
      map['customer_contact'] = Variable<String>(customerContact.value);
    }
    if (customerAddress.present) {
      map['customer_address'] = Variable<String>(customerAddress.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (referenceDate.present) {
      map['reference_date'] = Variable<DateTime>(referenceDate.value);
    }
    if (eventLocation.present) {
      map['event_location'] = Variable<String>(eventLocation.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<DateTime>(validUntil.value);
    }
    if (subEventsJson.present) {
      map['sub_events_json'] = Variable<String>(subEventsJson.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (eventCharges.present) {
      map['event_charges'] = Variable<double>(eventCharges.value);
    }
    if (discountPercent.present) {
      map['discount_percent'] = Variable<double>(discountPercent.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (convertedBillId.present) {
      map['converted_bill_id'] = Variable<String>(convertedBillId.value);
    }
    if (convertedEventOrderId.present) {
      map['converted_event_order_id'] = Variable<String>(
        convertedEventOrderId.value,
      );
    }
    if (customDataJson.present) {
      map['custom_data_json'] = Variable<String>(customDataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuotationRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('quotationNumber: $quotationNumber, ')
          ..write('quotationType: $quotationType, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerContact: $customerContact, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('referenceDate: $referenceDate, ')
          ..write('eventLocation: $eventLocation, ')
          ..write('validUntil: $validUntil, ')
          ..write('subEventsJson: $subEventsJson, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('eventCharges: $eventCharges, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('convertedBillId: $convertedBillId, ')
          ..write('convertedEventOrderId: $convertedEventOrderId, ')
          ..write('customDataJson: $customDataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $ExpenseRecordsTable extends ExpenseRecords
    with TableInfo<$ExpenseRecordsTable, ExpenseRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<int> category = GeneratedColumn<int>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorNameMeta = const VerificationMeta(
    'vendorName',
  );
  @override
  late final GeneratedColumn<String> vendorName = GeneratedColumn<String>(
    'vendor_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptNumberMeta = const VerificationMeta(
    'receiptNumber',
  );
  @override
  late final GeneratedColumn<String> receiptNumber = GeneratedColumn<String>(
    'receipt_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _expenseDateMeta = const VerificationMeta(
    'expenseDate',
  );
  @override
  late final GeneratedColumn<DateTime> expenseDate = GeneratedColumn<DateTime>(
    'expense_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    title,
    description,
    category,
    amount,
    paymentMethod,
    vendorName,
    receiptNumber,
    isRecurring,
    expenseDate,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('vendor_name')) {
      context.handle(
        _vendorNameMeta,
        vendorName.isAcceptableOrUnknown(data['vendor_name']!, _vendorNameMeta),
      );
    }
    if (data.containsKey('receipt_number')) {
      context.handle(
        _receiptNumberMeta,
        receiptNumber.isAcceptableOrUnknown(
          data['receipt_number']!,
          _receiptNumberMeta,
        ),
      );
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('expense_date')) {
      context.handle(
        _expenseDateMeta,
        expenseDate.isAcceptableOrUnknown(
          data['expense_date']!,
          _expenseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expenseDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      vendorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_name'],
      ),
      receiptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_number'],
      ),
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      expenseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expense_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExpenseRecordsTable createAlias(String alias) {
    return $ExpenseRecordsTable(attachedDatabase, alias);
  }
}

class ExpenseRecord extends DataClass implements Insertable<ExpenseRecord> {
  final int id;
  final String? serverId;
  final String title;
  final String? description;
  final int category;
  final double amount;
  final String? paymentMethod;
  final String? vendorName;
  final String? receiptNumber;
  final bool isRecurring;
  final DateTime expenseDate;
  final String? notes;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExpenseRecord({
    required this.id,
    this.serverId,
    required this.title,
    this.description,
    required this.category,
    required this.amount,
    this.paymentMethod,
    this.vendorName,
    this.receiptNumber,
    required this.isRecurring,
    required this.expenseDate,
    this.notes,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category'] = Variable<int>(category);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || vendorName != null) {
      map['vendor_name'] = Variable<String>(vendorName);
    }
    if (!nullToAbsent || receiptNumber != null) {
      map['receipt_number'] = Variable<String>(receiptNumber);
    }
    map['is_recurring'] = Variable<bool>(isRecurring);
    map['expense_date'] = Variable<DateTime>(expenseDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExpenseRecordsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: Value(category),
      amount: Value(amount),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      vendorName: vendorName == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorName),
      receiptNumber: receiptNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptNumber),
      isRecurring: Value(isRecurring),
      expenseDate: Value(expenseDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExpenseRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<int>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      vendorName: serializer.fromJson<String?>(json['vendorName']),
      receiptNumber: serializer.fromJson<String?>(json['receiptNumber']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      expenseDate: serializer.fromJson<DateTime>(json['expenseDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<int>(category),
      'amount': serializer.toJson<double>(amount),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'vendorName': serializer.toJson<String?>(vendorName),
      'receiptNumber': serializer.toJson<String?>(receiptNumber),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'expenseDate': serializer.toJson<DateTime>(expenseDate),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExpenseRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    int? category,
    double? amount,
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> vendorName = const Value.absent(),
    Value<String?> receiptNumber = const Value.absent(),
    bool? isRecurring,
    DateTime? expenseDate,
    Value<String?> notes = const Value.absent(),
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExpenseRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    vendorName: vendorName.present ? vendorName.value : this.vendorName,
    receiptNumber: receiptNumber.present
        ? receiptNumber.value
        : this.receiptNumber,
    isRecurring: isRecurring ?? this.isRecurring,
    expenseDate: expenseDate ?? this.expenseDate,
    notes: notes.present ? notes.value : this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExpenseRecord copyWithCompanion(ExpenseRecordsCompanion data) {
    return ExpenseRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      vendorName: data.vendorName.present
          ? data.vendorName.value
          : this.vendorName,
      receiptNumber: data.receiptNumber.present
          ? data.receiptNumber.value
          : this.receiptNumber,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      expenseDate: data.expenseDate.present
          ? data.expenseDate.value
          : this.expenseDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('vendorName: $vendorName, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    title,
    description,
    category,
    amount,
    paymentMethod,
    vendorName,
    receiptNumber,
    isRecurring,
    expenseDate,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.paymentMethod == this.paymentMethod &&
          other.vendorName == this.vendorName &&
          other.receiptNumber == this.receiptNumber &&
          other.isRecurring == this.isRecurring &&
          other.expenseDate == this.expenseDate &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExpenseRecordsCompanion extends UpdateCompanion<ExpenseRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> category;
  final Value<double> amount;
  final Value<String?> paymentMethod;
  final Value<String?> vendorName;
  final Value<String?> receiptNumber;
  final Value<bool> isRecurring;
  final Value<DateTime> expenseDate;
  final Value<String?> notes;
  final Value<int> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ExpenseRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.vendorName = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.expenseDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ExpenseRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required int category,
    this.amount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.vendorName = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.isRecurring = const Value.absent(),
    required DateTime expenseDate,
    this.notes = const Value.absent(),
    required int syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : title = Value(title),
       category = Value(category),
       expenseDate = Value(expenseDate),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExpenseRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? category,
    Expression<double>? amount,
    Expression<String>? paymentMethod,
    Expression<String>? vendorName,
    Expression<String>? receiptNumber,
    Expression<bool>? isRecurring,
    Expression<DateTime>? expenseDate,
    Expression<String>? notes,
    Expression<int>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (vendorName != null) 'vendor_name': vendorName,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (expenseDate != null) 'expense_date': expenseDate,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ExpenseRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? category,
    Value<double>? amount,
    Value<String?>? paymentMethod,
    Value<String?>? vendorName,
    Value<String?>? receiptNumber,
    Value<bool>? isRecurring,
    Value<DateTime>? expenseDate,
    Value<String?>? notes,
    Value<int>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ExpenseRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      vendorName: vendorName ?? this.vendorName,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      isRecurring: isRecurring ?? this.isRecurring,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (vendorName.present) {
      map['vendor_name'] = Variable<String>(vendorName.value);
    }
    if (receiptNumber.present) {
      map['receipt_number'] = Variable<String>(receiptNumber.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (expenseDate.present) {
      map['expense_date'] = Variable<DateTime>(expenseDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('vendorName: $vendorName, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ShopImageRecordsTable extends ShopImageRecords
    with TableInfo<$ShopImageRecordsTable, ShopImageRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopImageRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _shopLogoBase64Meta = const VerificationMeta(
    'shopLogoBase64',
  );
  @override
  late final GeneratedColumn<String> shopLogoBase64 = GeneratedColumn<String>(
    'shop_logo_base64',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signatureBase64Meta = const VerificationMeta(
    'signatureBase64',
  );
  @override
  late final GeneratedColumn<String> signatureBase64 = GeneratedColumn<String>(
    'signature_base64',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qrCodeBase64Meta = const VerificationMeta(
    'qrCodeBase64',
  );
  @override
  late final GeneratedColumn<String> qrCodeBase64 = GeneratedColumn<String>(
    'qr_code_base64',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    shopLogoBase64,
    signatureBase64,
    qrCodeBase64,
    lastSyncedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shop_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShopImageRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('shop_logo_base64')) {
      context.handle(
        _shopLogoBase64Meta,
        shopLogoBase64.isAcceptableOrUnknown(
          data['shop_logo_base64']!,
          _shopLogoBase64Meta,
        ),
      );
    }
    if (data.containsKey('signature_base64')) {
      context.handle(
        _signatureBase64Meta,
        signatureBase64.isAcceptableOrUnknown(
          data['signature_base64']!,
          _signatureBase64Meta,
        ),
      );
    }
    if (data.containsKey('qr_code_base64')) {
      context.handle(
        _qrCodeBase64Meta,
        qrCodeBase64.isAcceptableOrUnknown(
          data['qr_code_base64']!,
          _qrCodeBase64Meta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShopImageRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShopImageRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      shopLogoBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_logo_base64'],
      ),
      signatureBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_base64'],
      ),
      qrCodeBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qr_code_base64'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ShopImageRecordsTable createAlias(String alias) {
    return $ShopImageRecordsTable(attachedDatabase, alias);
  }
}

class ShopImageRecord extends DataClass implements Insertable<ShopImageRecord> {
  final int id;
  final String userId;
  final String? shopLogoBase64;
  final String? signatureBase64;
  final String? qrCodeBase64;
  final DateTime? lastSyncedAt;
  final DateTime updatedAt;
  const ShopImageRecord({
    required this.id,
    required this.userId,
    this.shopLogoBase64,
    this.signatureBase64,
    this.qrCodeBase64,
    this.lastSyncedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || shopLogoBase64 != null) {
      map['shop_logo_base64'] = Variable<String>(shopLogoBase64);
    }
    if (!nullToAbsent || signatureBase64 != null) {
      map['signature_base64'] = Variable<String>(signatureBase64);
    }
    if (!nullToAbsent || qrCodeBase64 != null) {
      map['qr_code_base64'] = Variable<String>(qrCodeBase64);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ShopImageRecordsCompanion toCompanion(bool nullToAbsent) {
    return ShopImageRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      shopLogoBase64: shopLogoBase64 == null && nullToAbsent
          ? const Value.absent()
          : Value(shopLogoBase64),
      signatureBase64: signatureBase64 == null && nullToAbsent
          ? const Value.absent()
          : Value(signatureBase64),
      qrCodeBase64: qrCodeBase64 == null && nullToAbsent
          ? const Value.absent()
          : Value(qrCodeBase64),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ShopImageRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShopImageRecord(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      shopLogoBase64: serializer.fromJson<String?>(json['shopLogoBase64']),
      signatureBase64: serializer.fromJson<String?>(json['signatureBase64']),
      qrCodeBase64: serializer.fromJson<String?>(json['qrCodeBase64']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'shopLogoBase64': serializer.toJson<String?>(shopLogoBase64),
      'signatureBase64': serializer.toJson<String?>(signatureBase64),
      'qrCodeBase64': serializer.toJson<String?>(qrCodeBase64),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ShopImageRecord copyWith({
    int? id,
    String? userId,
    Value<String?> shopLogoBase64 = const Value.absent(),
    Value<String?> signatureBase64 = const Value.absent(),
    Value<String?> qrCodeBase64 = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => ShopImageRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    shopLogoBase64: shopLogoBase64.present
        ? shopLogoBase64.value
        : this.shopLogoBase64,
    signatureBase64: signatureBase64.present
        ? signatureBase64.value
        : this.signatureBase64,
    qrCodeBase64: qrCodeBase64.present ? qrCodeBase64.value : this.qrCodeBase64,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ShopImageRecord copyWithCompanion(ShopImageRecordsCompanion data) {
    return ShopImageRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      shopLogoBase64: data.shopLogoBase64.present
          ? data.shopLogoBase64.value
          : this.shopLogoBase64,
      signatureBase64: data.signatureBase64.present
          ? data.signatureBase64.value
          : this.signatureBase64,
      qrCodeBase64: data.qrCodeBase64.present
          ? data.qrCodeBase64.value
          : this.qrCodeBase64,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShopImageRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('shopLogoBase64: $shopLogoBase64, ')
          ..write('signatureBase64: $signatureBase64, ')
          ..write('qrCodeBase64: $qrCodeBase64, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    shopLogoBase64,
    signatureBase64,
    qrCodeBase64,
    lastSyncedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShopImageRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.shopLogoBase64 == this.shopLogoBase64 &&
          other.signatureBase64 == this.signatureBase64 &&
          other.qrCodeBase64 == this.qrCodeBase64 &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.updatedAt == this.updatedAt);
}

class ShopImageRecordsCompanion extends UpdateCompanion<ShopImageRecord> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String?> shopLogoBase64;
  final Value<String?> signatureBase64;
  final Value<String?> qrCodeBase64;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> updatedAt;
  const ShopImageRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.shopLogoBase64 = const Value.absent(),
    this.signatureBase64 = const Value.absent(),
    this.qrCodeBase64 = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ShopImageRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    this.shopLogoBase64 = const Value.absent(),
    this.signatureBase64 = const Value.absent(),
    this.qrCodeBase64 = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required DateTime updatedAt,
  }) : userId = Value(userId),
       updatedAt = Value(updatedAt);
  static Insertable<ShopImageRecord> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? shopLogoBase64,
    Expression<String>? signatureBase64,
    Expression<String>? qrCodeBase64,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (shopLogoBase64 != null) 'shop_logo_base64': shopLogoBase64,
      if (signatureBase64 != null) 'signature_base64': signatureBase64,
      if (qrCodeBase64 != null) 'qr_code_base64': qrCodeBase64,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ShopImageRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String?>? shopLogoBase64,
    Value<String?>? signatureBase64,
    Value<String?>? qrCodeBase64,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime>? updatedAt,
  }) {
    return ShopImageRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shopLogoBase64: shopLogoBase64 ?? this.shopLogoBase64,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      qrCodeBase64: qrCodeBase64 ?? this.qrCodeBase64,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (shopLogoBase64.present) {
      map['shop_logo_base64'] = Variable<String>(shopLogoBase64.value);
    }
    if (signatureBase64.present) {
      map['signature_base64'] = Variable<String>(signatureBase64.value);
    }
    if (qrCodeBase64.present) {
      map['qr_code_base64'] = Variable<String>(qrCodeBase64.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopImageRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('shopLogoBase64: $shopLogoBase64, ')
          ..write('signatureBase64: $signatureBase64, ')
          ..write('qrCodeBase64: $qrCodeBase64, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CustomerTransactionRecordsTable extends CustomerTransactionRecords
    with
        TableInfo<$CustomerTransactionRecordsTable, CustomerTransactionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerTransactionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<int> transactionType = GeneratedColumn<int>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _balanceAfterMeta = const VerificationMeta(
    'balanceAfter',
  );
  @override
  late final GeneratedColumn<double> balanceAfter = GeneratedColumn<double>(
    'balance_after',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    customerId,
    customerName,
    transactionType,
    amount,
    balanceAfter,
    referenceId,
    referenceType,
    description,
    paymentMethod,
    transactionDate,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerTransactionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('balance_after')) {
      context.handle(
        _balanceAfterMeta,
        balanceAfter.isAcceptableOrUnknown(
          data['balance_after']!,
          _balanceAfterMeta,
        ),
      );
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerTransactionRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerTransactionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      balanceAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance_after'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      ),
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomerTransactionRecordsTable createAlias(String alias) {
    return $CustomerTransactionRecordsTable(attachedDatabase, alias);
  }
}

class CustomerTransactionRecord extends DataClass
    implements Insertable<CustomerTransactionRecord> {
  final int id;
  final String? serverId;
  final String customerId;
  final String customerName;
  final int transactionType;
  final double amount;
  final double balanceAfter;
  final String? referenceId;
  final String? referenceType;
  final String? description;
  final String? paymentMethod;
  final DateTime transactionDate;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CustomerTransactionRecord({
    required this.id,
    this.serverId,
    required this.customerId,
    required this.customerName,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    this.referenceId,
    this.referenceType,
    this.description,
    this.paymentMethod,
    required this.transactionDate,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['customer_id'] = Variable<String>(customerId);
    map['customer_name'] = Variable<String>(customerName);
    map['transaction_type'] = Variable<int>(transactionType);
    map['amount'] = Variable<double>(amount);
    map['balance_after'] = Variable<double>(balanceAfter);
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    if (!nullToAbsent || referenceType != null) {
      map['reference_type'] = Variable<String>(referenceType);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomerTransactionRecordsCompanion toCompanion(bool nullToAbsent) {
    return CustomerTransactionRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      customerId: Value(customerId),
      customerName: Value(customerName),
      transactionType: Value(transactionType),
      amount: Value(amount),
      balanceAfter: Value(balanceAfter),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      referenceType: referenceType == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      transactionDate: Value(transactionDate),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomerTransactionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerTransactionRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      transactionType: serializer.fromJson<int>(json['transactionType']),
      amount: serializer.fromJson<double>(json['amount']),
      balanceAfter: serializer.fromJson<double>(json['balanceAfter']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      referenceType: serializer.fromJson<String?>(json['referenceType']),
      description: serializer.fromJson<String?>(json['description']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'customerId': serializer.toJson<String>(customerId),
      'customerName': serializer.toJson<String>(customerName),
      'transactionType': serializer.toJson<int>(transactionType),
      'amount': serializer.toJson<double>(amount),
      'balanceAfter': serializer.toJson<double>(balanceAfter),
      'referenceId': serializer.toJson<String?>(referenceId),
      'referenceType': serializer.toJson<String?>(referenceType),
      'description': serializer.toJson<String?>(description),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomerTransactionRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? customerId,
    String? customerName,
    int? transactionType,
    double? amount,
    double? balanceAfter,
    Value<String?> referenceId = const Value.absent(),
    Value<String?> referenceType = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    DateTime? transactionDate,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CustomerTransactionRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    transactionType: transactionType ?? this.transactionType,
    amount: amount ?? this.amount,
    balanceAfter: balanceAfter ?? this.balanceAfter,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    referenceType: referenceType.present
        ? referenceType.value
        : this.referenceType,
    description: description.present ? description.value : this.description,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    transactionDate: transactionDate ?? this.transactionDate,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomerTransactionRecord copyWithCompanion(
    CustomerTransactionRecordsCompanion data,
  ) {
    return CustomerTransactionRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      amount: data.amount.present ? data.amount.value : this.amount,
      balanceAfter: data.balanceAfter.present
          ? data.balanceAfter.value
          : this.balanceAfter,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      description: data.description.present
          ? data.description.value
          : this.description,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerTransactionRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('transactionType: $transactionType, ')
          ..write('amount: $amount, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('referenceId: $referenceId, ')
          ..write('referenceType: $referenceType, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    customerId,
    customerName,
    transactionType,
    amount,
    balanceAfter,
    referenceId,
    referenceType,
    description,
    paymentMethod,
    transactionDate,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerTransactionRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.transactionType == this.transactionType &&
          other.amount == this.amount &&
          other.balanceAfter == this.balanceAfter &&
          other.referenceId == this.referenceId &&
          other.referenceType == this.referenceType &&
          other.description == this.description &&
          other.paymentMethod == this.paymentMethod &&
          other.transactionDate == this.transactionDate &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomerTransactionRecordsCompanion
    extends UpdateCompanion<CustomerTransactionRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> customerId;
  final Value<String> customerName;
  final Value<int> transactionType;
  final Value<double> amount;
  final Value<double> balanceAfter;
  final Value<String?> referenceId;
  final Value<String?> referenceType;
  final Value<String?> description;
  final Value<String?> paymentMethod;
  final Value<DateTime> transactionDate;
  final Value<int> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CustomerTransactionRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.amount = const Value.absent(),
    this.balanceAfter = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CustomerTransactionRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String customerId,
    this.customerName = const Value.absent(),
    required int transactionType,
    this.amount = const Value.absent(),
    this.balanceAfter = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    required DateTime transactionDate,
    required int syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : customerId = Value(customerId),
       transactionType = Value(transactionType),
       transactionDate = Value(transactionDate),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomerTransactionRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<int>? transactionType,
    Expression<double>? amount,
    Expression<double>? balanceAfter,
    Expression<String>? referenceId,
    Expression<String>? referenceType,
    Expression<String>? description,
    Expression<String>? paymentMethod,
    Expression<DateTime>? transactionDate,
    Expression<int>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (transactionType != null) 'transaction_type': transactionType,
      if (amount != null) 'amount': amount,
      if (balanceAfter != null) 'balance_after': balanceAfter,
      if (referenceId != null) 'reference_id': referenceId,
      if (referenceType != null) 'reference_type': referenceType,
      if (description != null) 'description': description,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CustomerTransactionRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? customerId,
    Value<String>? customerName,
    Value<int>? transactionType,
    Value<double>? amount,
    Value<double>? balanceAfter,
    Value<String?>? referenceId,
    Value<String?>? referenceType,
    Value<String?>? description,
    Value<String?>? paymentMethod,
    Value<DateTime>? transactionDate,
    Value<int>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CustomerTransactionRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<int>(transactionType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (balanceAfter.present) {
      map['balance_after'] = Variable<double>(balanceAfter.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerTransactionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('transactionType: $transactionType, ')
          ..write('amount: $amount, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('referenceId: $referenceId, ')
          ..write('referenceType: $referenceType, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EmployeeRecordsTable extends EmployeeRecords
    with TableInfo<$EmployeeRecordsTable, EmployeeRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeeRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterLabelMeta = const VerificationMeta(
    'counterLabel',
  );
  @override
  late final GeneratedColumn<String> counterLabel = GeneratedColumn<String>(
    'counter_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokenNumberMeta = const VerificationMeta(
    'tokenNumber',
  );
  @override
  late final GeneratedColumn<int> tokenNumber = GeneratedColumn<int>(
    'token_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _counterAccessMeta = const VerificationMeta(
    'counterAccess',
  );
  @override
  late final GeneratedColumn<bool> counterAccess = GeneratedColumn<bool>(
    'counter_access',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counter_access" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<double> points = GeneratedColumn<double>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<DateTime> dateOfBirth = GeneratedColumn<DateTime>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinCodeMeta = const VerificationMeta(
    'pinCode',
  );
  @override
  late final GeneratedColumn<String> pinCode = GeneratedColumn<String>(
    'pin_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _govIdNumberMeta = const VerificationMeta(
    'govIdNumber',
  );
  @override
  late final GeneratedColumn<String> govIdNumber = GeneratedColumn<String>(
    'gov_id_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _govIdTypeMeta = const VerificationMeta(
    'govIdType',
  );
  @override
  late final GeneratedColumn<String> govIdType = GeneratedColumn<String>(
    'gov_id_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salaryMeta = const VerificationMeta('salary');
  @override
  late final GeneratedColumn<double> salary = GeneratedColumn<double>(
    'salary',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateOfJoiningMeta = const VerificationMeta(
    'dateOfJoining',
  );
  @override
  late final GeneratedColumn<DateTime> dateOfJoining =
      GeneratedColumn<DateTime>(
        'date_of_joining',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _allowedModulesJsonMeta =
      const VerificationMeta('allowedModulesJson');
  @override
  late final GeneratedColumn<String> allowedModulesJson =
      GeneratedColumn<String>(
        'allowed_modules_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    email,
    displayName,
    phone,
    counterLabel,
    tokenNumber,
    counterAccess,
    points,
    dateOfBirth,
    address,
    pinCode,
    govIdNumber,
    govIdType,
    salary,
    dateOfJoining,
    allowedModulesJson,
    active,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmployeeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('counter_label')) {
      context.handle(
        _counterLabelMeta,
        counterLabel.isAcceptableOrUnknown(
          data['counter_label']!,
          _counterLabelMeta,
        ),
      );
    }
    if (data.containsKey('token_number')) {
      context.handle(
        _tokenNumberMeta,
        tokenNumber.isAcceptableOrUnknown(
          data['token_number']!,
          _tokenNumberMeta,
        ),
      );
    }
    if (data.containsKey('counter_access')) {
      context.handle(
        _counterAccessMeta,
        counterAccess.isAcceptableOrUnknown(
          data['counter_access']!,
          _counterAccessMeta,
        ),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('pin_code')) {
      context.handle(
        _pinCodeMeta,
        pinCode.isAcceptableOrUnknown(data['pin_code']!, _pinCodeMeta),
      );
    }
    if (data.containsKey('gov_id_number')) {
      context.handle(
        _govIdNumberMeta,
        govIdNumber.isAcceptableOrUnknown(
          data['gov_id_number']!,
          _govIdNumberMeta,
        ),
      );
    }
    if (data.containsKey('gov_id_type')) {
      context.handle(
        _govIdTypeMeta,
        govIdType.isAcceptableOrUnknown(data['gov_id_type']!, _govIdTypeMeta),
      );
    }
    if (data.containsKey('salary')) {
      context.handle(
        _salaryMeta,
        salary.isAcceptableOrUnknown(data['salary']!, _salaryMeta),
      );
    }
    if (data.containsKey('date_of_joining')) {
      context.handle(
        _dateOfJoiningMeta,
        dateOfJoining.isAcceptableOrUnknown(
          data['date_of_joining']!,
          _dateOfJoiningMeta,
        ),
      );
    }
    if (data.containsKey('allowed_modules_json')) {
      context.handle(
        _allowedModulesJsonMeta,
        allowedModulesJson.isAcceptableOrUnknown(
          data['allowed_modules_json']!,
          _allowedModulesJsonMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmployeeRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeeRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      counterLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_label'],
      ),
      tokenNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}token_number'],
      )!,
      counterAccess: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counter_access'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}points'],
      )!,
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_of_birth'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      pinCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_code'],
      ),
      govIdNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gov_id_number'],
      ),
      govIdType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gov_id_type'],
      ),
      salary: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}salary'],
      ),
      dateOfJoining: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_of_joining'],
      ),
      allowedModulesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allowed_modules_json'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EmployeeRecordsTable createAlias(String alias) {
    return $EmployeeRecordsTable(attachedDatabase, alias);
  }
}

class EmployeeRecord extends DataClass implements Insertable<EmployeeRecord> {
  final int id;
  final String? serverId;
  final String email;
  final String displayName;
  final String? phone;
  final String? counterLabel;
  final int tokenNumber;
  final bool counterAccess;
  final double points;
  final DateTime? dateOfBirth;
  final String? address;
  final String? pinCode;
  final String? govIdNumber;
  final String? govIdType;
  final double? salary;
  final DateTime? dateOfJoining;
  final String allowedModulesJson;
  final bool active;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EmployeeRecord({
    required this.id,
    this.serverId,
    required this.email,
    required this.displayName,
    this.phone,
    this.counterLabel,
    required this.tokenNumber,
    required this.counterAccess,
    required this.points,
    this.dateOfBirth,
    this.address,
    this.pinCode,
    this.govIdNumber,
    this.govIdType,
    this.salary,
    this.dateOfJoining,
    required this.allowedModulesJson,
    required this.active,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || counterLabel != null) {
      map['counter_label'] = Variable<String>(counterLabel);
    }
    map['token_number'] = Variable<int>(tokenNumber);
    map['counter_access'] = Variable<bool>(counterAccess);
    map['points'] = Variable<double>(points);
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || pinCode != null) {
      map['pin_code'] = Variable<String>(pinCode);
    }
    if (!nullToAbsent || govIdNumber != null) {
      map['gov_id_number'] = Variable<String>(govIdNumber);
    }
    if (!nullToAbsent || govIdType != null) {
      map['gov_id_type'] = Variable<String>(govIdType);
    }
    if (!nullToAbsent || salary != null) {
      map['salary'] = Variable<double>(salary);
    }
    if (!nullToAbsent || dateOfJoining != null) {
      map['date_of_joining'] = Variable<DateTime>(dateOfJoining);
    }
    map['allowed_modules_json'] = Variable<String>(allowedModulesJson);
    map['active'] = Variable<bool>(active);
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EmployeeRecordsCompanion toCompanion(bool nullToAbsent) {
    return EmployeeRecordsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      email: Value(email),
      displayName: Value(displayName),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      counterLabel: counterLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(counterLabel),
      tokenNumber: Value(tokenNumber),
      counterAccess: Value(counterAccess),
      points: Value(points),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      pinCode: pinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(pinCode),
      govIdNumber: govIdNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(govIdNumber),
      govIdType: govIdType == null && nullToAbsent
          ? const Value.absent()
          : Value(govIdType),
      salary: salary == null && nullToAbsent
          ? const Value.absent()
          : Value(salary),
      dateOfJoining: dateOfJoining == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfJoining),
      allowedModulesJson: Value(allowedModulesJson),
      active: Value(active),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EmployeeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeeRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      phone: serializer.fromJson<String?>(json['phone']),
      counterLabel: serializer.fromJson<String?>(json['counterLabel']),
      tokenNumber: serializer.fromJson<int>(json['tokenNumber']),
      counterAccess: serializer.fromJson<bool>(json['counterAccess']),
      points: serializer.fromJson<double>(json['points']),
      dateOfBirth: serializer.fromJson<DateTime?>(json['dateOfBirth']),
      address: serializer.fromJson<String?>(json['address']),
      pinCode: serializer.fromJson<String?>(json['pinCode']),
      govIdNumber: serializer.fromJson<String?>(json['govIdNumber']),
      govIdType: serializer.fromJson<String?>(json['govIdType']),
      salary: serializer.fromJson<double?>(json['salary']),
      dateOfJoining: serializer.fromJson<DateTime?>(json['dateOfJoining']),
      allowedModulesJson: serializer.fromJson<String>(
        json['allowedModulesJson'],
      ),
      active: serializer.fromJson<bool>(json['active']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String>(displayName),
      'phone': serializer.toJson<String?>(phone),
      'counterLabel': serializer.toJson<String?>(counterLabel),
      'tokenNumber': serializer.toJson<int>(tokenNumber),
      'counterAccess': serializer.toJson<bool>(counterAccess),
      'points': serializer.toJson<double>(points),
      'dateOfBirth': serializer.toJson<DateTime?>(dateOfBirth),
      'address': serializer.toJson<String?>(address),
      'pinCode': serializer.toJson<String?>(pinCode),
      'govIdNumber': serializer.toJson<String?>(govIdNumber),
      'govIdType': serializer.toJson<String?>(govIdType),
      'salary': serializer.toJson<double?>(salary),
      'dateOfJoining': serializer.toJson<DateTime?>(dateOfJoining),
      'allowedModulesJson': serializer.toJson<String>(allowedModulesJson),
      'active': serializer.toJson<bool>(active),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EmployeeRecord copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? email,
    String? displayName,
    Value<String?> phone = const Value.absent(),
    Value<String?> counterLabel = const Value.absent(),
    int? tokenNumber,
    bool? counterAccess,
    double? points,
    Value<DateTime?> dateOfBirth = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> pinCode = const Value.absent(),
    Value<String?> govIdNumber = const Value.absent(),
    Value<String?> govIdType = const Value.absent(),
    Value<double?> salary = const Value.absent(),
    Value<DateTime?> dateOfJoining = const Value.absent(),
    String? allowedModulesJson,
    bool? active,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EmployeeRecord(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    phone: phone.present ? phone.value : this.phone,
    counterLabel: counterLabel.present ? counterLabel.value : this.counterLabel,
    tokenNumber: tokenNumber ?? this.tokenNumber,
    counterAccess: counterAccess ?? this.counterAccess,
    points: points ?? this.points,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    address: address.present ? address.value : this.address,
    pinCode: pinCode.present ? pinCode.value : this.pinCode,
    govIdNumber: govIdNumber.present ? govIdNumber.value : this.govIdNumber,
    govIdType: govIdType.present ? govIdType.value : this.govIdType,
    salary: salary.present ? salary.value : this.salary,
    dateOfJoining: dateOfJoining.present
        ? dateOfJoining.value
        : this.dateOfJoining,
    allowedModulesJson: allowedModulesJson ?? this.allowedModulesJson,
    active: active ?? this.active,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EmployeeRecord copyWithCompanion(EmployeeRecordsCompanion data) {
    return EmployeeRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      phone: data.phone.present ? data.phone.value : this.phone,
      counterLabel: data.counterLabel.present
          ? data.counterLabel.value
          : this.counterLabel,
      tokenNumber: data.tokenNumber.present
          ? data.tokenNumber.value
          : this.tokenNumber,
      counterAccess: data.counterAccess.present
          ? data.counterAccess.value
          : this.counterAccess,
      points: data.points.present ? data.points.value : this.points,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      address: data.address.present ? data.address.value : this.address,
      pinCode: data.pinCode.present ? data.pinCode.value : this.pinCode,
      govIdNumber: data.govIdNumber.present
          ? data.govIdNumber.value
          : this.govIdNumber,
      govIdType: data.govIdType.present ? data.govIdType.value : this.govIdType,
      salary: data.salary.present ? data.salary.value : this.salary,
      dateOfJoining: data.dateOfJoining.present
          ? data.dateOfJoining.value
          : this.dateOfJoining,
      allowedModulesJson: data.allowedModulesJson.present
          ? data.allowedModulesJson.value
          : this.allowedModulesJson,
      active: data.active.present ? data.active.value : this.active,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('phone: $phone, ')
          ..write('counterLabel: $counterLabel, ')
          ..write('tokenNumber: $tokenNumber, ')
          ..write('counterAccess: $counterAccess, ')
          ..write('points: $points, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('address: $address, ')
          ..write('pinCode: $pinCode, ')
          ..write('govIdNumber: $govIdNumber, ')
          ..write('govIdType: $govIdType, ')
          ..write('salary: $salary, ')
          ..write('dateOfJoining: $dateOfJoining, ')
          ..write('allowedModulesJson: $allowedModulesJson, ')
          ..write('active: $active, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    email,
    displayName,
    phone,
    counterLabel,
    tokenNumber,
    counterAccess,
    points,
    dateOfBirth,
    address,
    pinCode,
    govIdNumber,
    govIdType,
    salary,
    dateOfJoining,
    allowedModulesJson,
    active,
    syncStatus,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeeRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.phone == this.phone &&
          other.counterLabel == this.counterLabel &&
          other.tokenNumber == this.tokenNumber &&
          other.counterAccess == this.counterAccess &&
          other.points == this.points &&
          other.dateOfBirth == this.dateOfBirth &&
          other.address == this.address &&
          other.pinCode == this.pinCode &&
          other.govIdNumber == this.govIdNumber &&
          other.govIdType == this.govIdType &&
          other.salary == this.salary &&
          other.dateOfJoining == this.dateOfJoining &&
          other.allowedModulesJson == this.allowedModulesJson &&
          other.active == this.active &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EmployeeRecordsCompanion extends UpdateCompanion<EmployeeRecord> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> email;
  final Value<String> displayName;
  final Value<String?> phone;
  final Value<String?> counterLabel;
  final Value<int> tokenNumber;
  final Value<bool> counterAccess;
  final Value<double> points;
  final Value<DateTime?> dateOfBirth;
  final Value<String?> address;
  final Value<String?> pinCode;
  final Value<String?> govIdNumber;
  final Value<String?> govIdType;
  final Value<double?> salary;
  final Value<DateTime?> dateOfJoining;
  final Value<String> allowedModulesJson;
  final Value<bool> active;
  final Value<int> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EmployeeRecordsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.phone = const Value.absent(),
    this.counterLabel = const Value.absent(),
    this.tokenNumber = const Value.absent(),
    this.counterAccess = const Value.absent(),
    this.points = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.address = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.govIdNumber = const Value.absent(),
    this.govIdType = const Value.absent(),
    this.salary = const Value.absent(),
    this.dateOfJoining = const Value.absent(),
    this.allowedModulesJson = const Value.absent(),
    this.active = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EmployeeRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String email,
    required String displayName,
    this.phone = const Value.absent(),
    this.counterLabel = const Value.absent(),
    this.tokenNumber = const Value.absent(),
    this.counterAccess = const Value.absent(),
    this.points = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.address = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.govIdNumber = const Value.absent(),
    this.govIdType = const Value.absent(),
    this.salary = const Value.absent(),
    this.dateOfJoining = const Value.absent(),
    this.allowedModulesJson = const Value.absent(),
    this.active = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : email = Value(email),
       displayName = Value(displayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EmployeeRecord> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? phone,
    Expression<String>? counterLabel,
    Expression<int>? tokenNumber,
    Expression<bool>? counterAccess,
    Expression<double>? points,
    Expression<DateTime>? dateOfBirth,
    Expression<String>? address,
    Expression<String>? pinCode,
    Expression<String>? govIdNumber,
    Expression<String>? govIdType,
    Expression<double>? salary,
    Expression<DateTime>? dateOfJoining,
    Expression<String>? allowedModulesJson,
    Expression<bool>? active,
    Expression<int>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (phone != null) 'phone': phone,
      if (counterLabel != null) 'counter_label': counterLabel,
      if (tokenNumber != null) 'token_number': tokenNumber,
      if (counterAccess != null) 'counter_access': counterAccess,
      if (points != null) 'points': points,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (address != null) 'address': address,
      if (pinCode != null) 'pin_code': pinCode,
      if (govIdNumber != null) 'gov_id_number': govIdNumber,
      if (govIdType != null) 'gov_id_type': govIdType,
      if (salary != null) 'salary': salary,
      if (dateOfJoining != null) 'date_of_joining': dateOfJoining,
      if (allowedModulesJson != null)
        'allowed_modules_json': allowedModulesJson,
      if (active != null) 'active': active,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EmployeeRecordsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? email,
    Value<String>? displayName,
    Value<String?>? phone,
    Value<String?>? counterLabel,
    Value<int>? tokenNumber,
    Value<bool>? counterAccess,
    Value<double>? points,
    Value<DateTime?>? dateOfBirth,
    Value<String?>? address,
    Value<String?>? pinCode,
    Value<String?>? govIdNumber,
    Value<String?>? govIdType,
    Value<double?>? salary,
    Value<DateTime?>? dateOfJoining,
    Value<String>? allowedModulesJson,
    Value<bool>? active,
    Value<int>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return EmployeeRecordsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      counterLabel: counterLabel ?? this.counterLabel,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      counterAccess: counterAccess ?? this.counterAccess,
      points: points ?? this.points,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      pinCode: pinCode ?? this.pinCode,
      govIdNumber: govIdNumber ?? this.govIdNumber,
      govIdType: govIdType ?? this.govIdType,
      salary: salary ?? this.salary,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      allowedModulesJson: allowedModulesJson ?? this.allowedModulesJson,
      active: active ?? this.active,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (counterLabel.present) {
      map['counter_label'] = Variable<String>(counterLabel.value);
    }
    if (tokenNumber.present) {
      map['token_number'] = Variable<int>(tokenNumber.value);
    }
    if (counterAccess.present) {
      map['counter_access'] = Variable<bool>(counterAccess.value);
    }
    if (points.present) {
      map['points'] = Variable<double>(points.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (pinCode.present) {
      map['pin_code'] = Variable<String>(pinCode.value);
    }
    if (govIdNumber.present) {
      map['gov_id_number'] = Variable<String>(govIdNumber.value);
    }
    if (govIdType.present) {
      map['gov_id_type'] = Variable<String>(govIdType.value);
    }
    if (salary.present) {
      map['salary'] = Variable<double>(salary.value);
    }
    if (dateOfJoining.present) {
      map['date_of_joining'] = Variable<DateTime>(dateOfJoining.value);
    }
    if (allowedModulesJson.present) {
      map['allowed_modules_json'] = Variable<String>(allowedModulesJson.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('phone: $phone, ')
          ..write('counterLabel: $counterLabel, ')
          ..write('tokenNumber: $tokenNumber, ')
          ..write('counterAccess: $counterAccess, ')
          ..write('points: $points, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('address: $address, ')
          ..write('pinCode: $pinCode, ')
          ..write('govIdNumber: $govIdNumber, ')
          ..write('govIdType: $govIdType, ')
          ..write('salary: $salary, ')
          ..write('dateOfJoining: $dateOfJoining, ')
          ..write('allowedModulesJson: $allowedModulesJson, ')
          ..write('active: $active, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CompanyRecordsTable companyRecords = $CompanyRecordsTable(this);
  late final $CustomerRecordsTable customerRecords = $CustomerRecordsTable(
    this,
  );
  late final $SupplierRecordsTable supplierRecords = $SupplierRecordsTable(
    this,
  );
  late final $ProductRecordsTable productRecords = $ProductRecordsTable(this);
  late final $PurchaseRecordsTable purchaseRecords = $PurchaseRecordsTable(
    this,
  );
  late final $PurchaseBatchRecordsTable purchaseBatchRecords =
      $PurchaseBatchRecordsTable(this);
  late final $StockLedgerRecordsTable stockLedgerRecords =
      $StockLedgerRecordsTable(this);
  late final $BillRecordsTable billRecords = $BillRecordsTable(this);
  late final $EventOrderRecordsTable eventOrderRecords =
      $EventOrderRecordsTable(this);
  late final $QuotationRecordsTable quotationRecords = $QuotationRecordsTable(
    this,
  );
  late final $ExpenseRecordsTable expenseRecords = $ExpenseRecordsTable(this);
  late final $ShopImageRecordsTable shopImageRecords = $ShopImageRecordsTable(
    this,
  );
  late final $CustomerTransactionRecordsTable customerTransactionRecords =
      $CustomerTransactionRecordsTable(this);
  late final $EmployeeRecordsTable employeeRecords = $EmployeeRecordsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    companyRecords,
    customerRecords,
    supplierRecords,
    productRecords,
    purchaseRecords,
    purchaseBatchRecords,
    stockLedgerRecords,
    billRecords,
    eventOrderRecords,
    quotationRecords,
    expenseRecords,
    shopImageRecords,
    customerTransactionRecords,
    employeeRecords,
  ];
}

typedef $$CompanyRecordsTableCreateCompanionBuilder =
    CompanyRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String companyName,
      Value<String> companyCode,
      Value<String> gstCode,
      Value<String> contact,
      Value<String> address,
      Value<bool> isActive,
      required int syncStatus,
      required DateTime updatedAt,
      required DateTime createdAt,
    });
typedef $$CompanyRecordsTableUpdateCompanionBuilder =
    CompanyRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> companyName,
      Value<String> companyCode,
      Value<String> gstCode,
      Value<String> contact,
      Value<String> address,
      Value<bool> isActive,
      Value<int> syncStatus,
      Value<DateTime> updatedAt,
      Value<DateTime> createdAt,
    });

class $$CompanyRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CompanyRecordsTable> {
  $$CompanyRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyCode => $composableBuilder(
    column: $table.companyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gstCode => $composableBuilder(
    column: $table.gstCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contact => $composableBuilder(
    column: $table.contact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompanyRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompanyRecordsTable> {
  $$CompanyRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyCode => $composableBuilder(
    column: $table.companyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gstCode => $composableBuilder(
    column: $table.gstCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contact => $composableBuilder(
    column: $table.contact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompanyRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompanyRecordsTable> {
  $$CompanyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyCode => $composableBuilder(
    column: $table.companyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gstCode =>
      $composableBuilder(column: $table.gstCode, builder: (column) => column);

  GeneratedColumn<String> get contact =>
      $composableBuilder(column: $table.contact, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CompanyRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompanyRecordsTable,
          CompanyRecord,
          $$CompanyRecordsTableFilterComposer,
          $$CompanyRecordsTableOrderingComposer,
          $$CompanyRecordsTableAnnotationComposer,
          $$CompanyRecordsTableCreateCompanionBuilder,
          $$CompanyRecordsTableUpdateCompanionBuilder,
          (
            CompanyRecord,
            BaseReferences<_$AppDatabase, $CompanyRecordsTable, CompanyRecord>,
          ),
          CompanyRecord,
          PrefetchHooks Function()
        > {
  $$CompanyRecordsTableTableManager(
    _$AppDatabase db,
    $CompanyRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompanyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompanyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompanyRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> companyName = const Value.absent(),
                Value<String> companyCode = const Value.absent(),
                Value<String> gstCode = const Value.absent(),
                Value<String> contact = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CompanyRecordsCompanion(
                id: id,
                serverId: serverId,
                companyName: companyName,
                companyCode: companyCode,
                gstCode: gstCode,
                contact: contact,
                address: address,
                isActive: isActive,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String companyName,
                Value<String> companyCode = const Value.absent(),
                Value<String> gstCode = const Value.absent(),
                Value<String> contact = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int syncStatus,
                required DateTime updatedAt,
                required DateTime createdAt,
              }) => CompanyRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                companyName: companyName,
                companyCode: companyCode,
                gstCode: gstCode,
                contact: contact,
                address: address,
                isActive: isActive,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompanyRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompanyRecordsTable,
      CompanyRecord,
      $$CompanyRecordsTableFilterComposer,
      $$CompanyRecordsTableOrderingComposer,
      $$CompanyRecordsTableAnnotationComposer,
      $$CompanyRecordsTableCreateCompanionBuilder,
      $$CompanyRecordsTableUpdateCompanionBuilder,
      (
        CompanyRecord,
        BaseReferences<_$AppDatabase, $CompanyRecordsTable, CompanyRecord>,
      ),
      CompanyRecord,
      PrefetchHooks Function()
    >;
typedef $$CustomerRecordsTableCreateCompanionBuilder =
    CustomerRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String name,
      required String mobile,
      Value<String?> address,
      Value<String?> email,
      Value<String?> gstin,
      Value<double> currentPendingAmount,
      Value<double> totalPurchases,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      required DateTime updatedAt,
      required DateTime createdAt,
    });
typedef $$CustomerRecordsTableUpdateCompanionBuilder =
    CustomerRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> name,
      Value<String> mobile,
      Value<String?> address,
      Value<String?> email,
      Value<String?> gstin,
      Value<double> currentPendingAmount,
      Value<double> totalPurchases,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime> updatedAt,
      Value<DateTime> createdAt,
    });

class $$CustomerRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerRecordsTable> {
  $$CustomerRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentPendingAmount => $composableBuilder(
    column: $table.currentPendingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPurchases => $composableBuilder(
    column: $table.totalPurchases,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomerRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerRecordsTable> {
  $$CustomerRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentPendingAmount => $composableBuilder(
    column: $table.currentPendingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPurchases => $composableBuilder(
    column: $table.totalPurchases,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomerRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerRecordsTable> {
  $$CustomerRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get gstin =>
      $composableBuilder(column: $table.gstin, builder: (column) => column);

  GeneratedColumn<double> get currentPendingAmount => $composableBuilder(
    column: $table.currentPendingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPurchases => $composableBuilder(
    column: $table.totalPurchases,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomerRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerRecordsTable,
          CustomerRecord,
          $$CustomerRecordsTableFilterComposer,
          $$CustomerRecordsTableOrderingComposer,
          $$CustomerRecordsTableAnnotationComposer,
          $$CustomerRecordsTableCreateCompanionBuilder,
          $$CustomerRecordsTableUpdateCompanionBuilder,
          (
            CustomerRecord,
            BaseReferences<
              _$AppDatabase,
              $CustomerRecordsTable,
              CustomerRecord
            >,
          ),
          CustomerRecord,
          PrefetchHooks Function()
        > {
  $$CustomerRecordsTableTableManager(
    _$AppDatabase db,
    $CustomerRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomerRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomerRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> mobile = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> gstin = const Value.absent(),
                Value<double> currentPendingAmount = const Value.absent(),
                Value<double> totalPurchases = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CustomerRecordsCompanion(
                id: id,
                serverId: serverId,
                name: name,
                mobile: mobile,
                address: address,
                email: email,
                gstin: gstin,
                currentPendingAmount: currentPendingAmount,
                totalPurchases: totalPurchases,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String name,
                required String mobile,
                Value<String?> address = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> gstin = const Value.absent(),
                Value<double> currentPendingAmount = const Value.absent(),
                Value<double> totalPurchases = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime updatedAt,
                required DateTime createdAt,
              }) => CustomerRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                mobile: mobile,
                address: address,
                email: email,
                gstin: gstin,
                currentPendingAmount: currentPendingAmount,
                totalPurchases: totalPurchases,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomerRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerRecordsTable,
      CustomerRecord,
      $$CustomerRecordsTableFilterComposer,
      $$CustomerRecordsTableOrderingComposer,
      $$CustomerRecordsTableAnnotationComposer,
      $$CustomerRecordsTableCreateCompanionBuilder,
      $$CustomerRecordsTableUpdateCompanionBuilder,
      (
        CustomerRecord,
        BaseReferences<_$AppDatabase, $CustomerRecordsTable, CustomerRecord>,
      ),
      CustomerRecord,
      PrefetchHooks Function()
    >;
typedef $$SupplierRecordsTableCreateCompanionBuilder =
    SupplierRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String firstName,
      Value<String> middleName,
      Value<String> lastName,
      Value<String> supplierCode,
      required String contact,
      Value<String> address,
      Value<bool> isActive,
      required int syncStatus,
      required DateTime updatedAt,
      required DateTime createdAt,
    });
typedef $$SupplierRecordsTableUpdateCompanionBuilder =
    SupplierRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> firstName,
      Value<String> middleName,
      Value<String> lastName,
      Value<String> supplierCode,
      Value<String> contact,
      Value<String> address,
      Value<bool> isActive,
      Value<int> syncStatus,
      Value<DateTime> updatedAt,
      Value<DateTime> createdAt,
    });

class $$SupplierRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SupplierRecordsTable> {
  $$SupplierRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierCode => $composableBuilder(
    column: $table.supplierCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contact => $composableBuilder(
    column: $table.contact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SupplierRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SupplierRecordsTable> {
  $$SupplierRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierCode => $composableBuilder(
    column: $table.supplierCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contact => $composableBuilder(
    column: $table.contact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SupplierRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SupplierRecordsTable> {
  $$SupplierRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get supplierCode => $composableBuilder(
    column: $table.supplierCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contact =>
      $composableBuilder(column: $table.contact, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SupplierRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SupplierRecordsTable,
          SupplierRecord,
          $$SupplierRecordsTableFilterComposer,
          $$SupplierRecordsTableOrderingComposer,
          $$SupplierRecordsTableAnnotationComposer,
          $$SupplierRecordsTableCreateCompanionBuilder,
          $$SupplierRecordsTableUpdateCompanionBuilder,
          (
            SupplierRecord,
            BaseReferences<
              _$AppDatabase,
              $SupplierRecordsTable,
              SupplierRecord
            >,
          ),
          SupplierRecord,
          PrefetchHooks Function()
        > {
  $$SupplierRecordsTableTableManager(
    _$AppDatabase db,
    $SupplierRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SupplierRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SupplierRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SupplierRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> middleName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> supplierCode = const Value.absent(),
                Value<String> contact = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SupplierRecordsCompanion(
                id: id,
                serverId: serverId,
                firstName: firstName,
                middleName: middleName,
                lastName: lastName,
                supplierCode: supplierCode,
                contact: contact,
                address: address,
                isActive: isActive,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String firstName,
                Value<String> middleName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> supplierCode = const Value.absent(),
                required String contact,
                Value<String> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int syncStatus,
                required DateTime updatedAt,
                required DateTime createdAt,
              }) => SupplierRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                firstName: firstName,
                middleName: middleName,
                lastName: lastName,
                supplierCode: supplierCode,
                contact: contact,
                address: address,
                isActive: isActive,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SupplierRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SupplierRecordsTable,
      SupplierRecord,
      $$SupplierRecordsTableFilterComposer,
      $$SupplierRecordsTableOrderingComposer,
      $$SupplierRecordsTableAnnotationComposer,
      $$SupplierRecordsTableCreateCompanionBuilder,
      $$SupplierRecordsTableUpdateCompanionBuilder,
      (
        SupplierRecord,
        BaseReferences<_$AppDatabase, $SupplierRecordsTable, SupplierRecord>,
      ),
      SupplierRecord,
      PrefetchHooks Function()
    >;
typedef $$ProductRecordsTableCreateCompanionBuilder =
    ProductRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> indexNo,
      required String name,
      Value<String> companyName,
      Value<String> category,
      Value<String?> barcode,
      Value<double> purchasePrice,
      Value<double> salesPrice,
      Value<int> currentStock,
      Value<String?> unit,
      Value<bool> isActive,
      required int syncStatus,
      required DateTime updatedAt,
      required DateTime createdAt,
      Value<int?> minStockLevel,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> defaultSupplierId,
      Value<String?> defaultSupplierName,
      Value<double> cgstPercent,
      Value<double> sgstPercent,
      Value<String?> hsnCode,
      Value<String?> customFieldsJson,
      Value<String?> size,
      Value<String?> color,
      Value<double?> mrp,
      Value<String?> composition,
      Value<String?> drugSchedule,
      Value<String?> packUnit,
      Value<int> unitsPerPack,
    });
typedef $$ProductRecordsTableUpdateCompanionBuilder =
    ProductRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> indexNo,
      Value<String> name,
      Value<String> companyName,
      Value<String> category,
      Value<String?> barcode,
      Value<double> purchasePrice,
      Value<double> salesPrice,
      Value<int> currentStock,
      Value<String?> unit,
      Value<bool> isActive,
      Value<int> syncStatus,
      Value<DateTime> updatedAt,
      Value<DateTime> createdAt,
      Value<int?> minStockLevel,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> defaultSupplierId,
      Value<String?> defaultSupplierName,
      Value<double> cgstPercent,
      Value<double> sgstPercent,
      Value<String?> hsnCode,
      Value<String?> customFieldsJson,
      Value<String?> size,
      Value<String?> color,
      Value<double?> mrp,
      Value<String?> composition,
      Value<String?> drugSchedule,
      Value<String?> packUnit,
      Value<int> unitsPerPack,
    });

class $$ProductRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductRecordsTable> {
  $$ProductRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indexNo => $composableBuilder(
    column: $table.indexNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salesPrice => $composableBuilder(
    column: $table.salesPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minStockLevel => $composableBuilder(
    column: $table.minStockLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultSupplierId => $composableBuilder(
    column: $table.defaultSupplierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultSupplierName => $composableBuilder(
    column: $table.defaultSupplierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cgstPercent => $composableBuilder(
    column: $table.cgstPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sgstPercent => $composableBuilder(
    column: $table.sgstPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hsnCode => $composableBuilder(
    column: $table.hsnCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customFieldsJson => $composableBuilder(
    column: $table.customFieldsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mrp => $composableBuilder(
    column: $table.mrp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get composition => $composableBuilder(
    column: $table.composition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get drugSchedule => $composableBuilder(
    column: $table.drugSchedule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packUnit => $composableBuilder(
    column: $table.packUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitsPerPack => $composableBuilder(
    column: $table.unitsPerPack,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductRecordsTable> {
  $$ProductRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexNo => $composableBuilder(
    column: $table.indexNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salesPrice => $composableBuilder(
    column: $table.salesPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minStockLevel => $composableBuilder(
    column: $table.minStockLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultSupplierId => $composableBuilder(
    column: $table.defaultSupplierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultSupplierName => $composableBuilder(
    column: $table.defaultSupplierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cgstPercent => $composableBuilder(
    column: $table.cgstPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sgstPercent => $composableBuilder(
    column: $table.sgstPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hsnCode => $composableBuilder(
    column: $table.hsnCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customFieldsJson => $composableBuilder(
    column: $table.customFieldsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mrp => $composableBuilder(
    column: $table.mrp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get composition => $composableBuilder(
    column: $table.composition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get drugSchedule => $composableBuilder(
    column: $table.drugSchedule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packUnit => $composableBuilder(
    column: $table.packUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitsPerPack => $composableBuilder(
    column: $table.unitsPerPack,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductRecordsTable> {
  $$ProductRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get indexNo =>
      $composableBuilder(column: $table.indexNo, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get salesPrice => $composableBuilder(
    column: $table.salesPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get minStockLevel => $composableBuilder(
    column: $table.minStockLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get defaultSupplierId => $composableBuilder(
    column: $table.defaultSupplierId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultSupplierName => $composableBuilder(
    column: $table.defaultSupplierName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cgstPercent => $composableBuilder(
    column: $table.cgstPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sgstPercent => $composableBuilder(
    column: $table.sgstPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hsnCode =>
      $composableBuilder(column: $table.hsnCode, builder: (column) => column);

  GeneratedColumn<String> get customFieldsJson => $composableBuilder(
    column: $table.customFieldsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get mrp =>
      $composableBuilder(column: $table.mrp, builder: (column) => column);

  GeneratedColumn<String> get composition => $composableBuilder(
    column: $table.composition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get drugSchedule => $composableBuilder(
    column: $table.drugSchedule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get packUnit =>
      $composableBuilder(column: $table.packUnit, builder: (column) => column);

  GeneratedColumn<int> get unitsPerPack => $composableBuilder(
    column: $table.unitsPerPack,
    builder: (column) => column,
  );
}

class $$ProductRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductRecordsTable,
          ProductRecord,
          $$ProductRecordsTableFilterComposer,
          $$ProductRecordsTableOrderingComposer,
          $$ProductRecordsTableAnnotationComposer,
          $$ProductRecordsTableCreateCompanionBuilder,
          $$ProductRecordsTableUpdateCompanionBuilder,
          (
            ProductRecord,
            BaseReferences<_$AppDatabase, $ProductRecordsTable, ProductRecord>,
          ),
          ProductRecord,
          PrefetchHooks Function()
        > {
  $$ProductRecordsTableTableManager(
    _$AppDatabase db,
    $ProductRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> indexNo = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> companyName = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<double> purchasePrice = const Value.absent(),
                Value<double> salesPrice = const Value.absent(),
                Value<int> currentStock = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> minStockLevel = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> defaultSupplierId = const Value.absent(),
                Value<String?> defaultSupplierName = const Value.absent(),
                Value<double> cgstPercent = const Value.absent(),
                Value<double> sgstPercent = const Value.absent(),
                Value<String?> hsnCode = const Value.absent(),
                Value<String?> customFieldsJson = const Value.absent(),
                Value<String?> size = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<double?> mrp = const Value.absent(),
                Value<String?> composition = const Value.absent(),
                Value<String?> drugSchedule = const Value.absent(),
                Value<String?> packUnit = const Value.absent(),
                Value<int> unitsPerPack = const Value.absent(),
              }) => ProductRecordsCompanion(
                id: id,
                serverId: serverId,
                indexNo: indexNo,
                name: name,
                companyName: companyName,
                category: category,
                barcode: barcode,
                purchasePrice: purchasePrice,
                salesPrice: salesPrice,
                currentStock: currentStock,
                unit: unit,
                isActive: isActive,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                createdAt: createdAt,
                minStockLevel: minStockLevel,
                description: description,
                imageUrl: imageUrl,
                defaultSupplierId: defaultSupplierId,
                defaultSupplierName: defaultSupplierName,
                cgstPercent: cgstPercent,
                sgstPercent: sgstPercent,
                hsnCode: hsnCode,
                customFieldsJson: customFieldsJson,
                size: size,
                color: color,
                mrp: mrp,
                composition: composition,
                drugSchedule: drugSchedule,
                packUnit: packUnit,
                unitsPerPack: unitsPerPack,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> indexNo = const Value.absent(),
                required String name,
                Value<String> companyName = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<double> purchasePrice = const Value.absent(),
                Value<double> salesPrice = const Value.absent(),
                Value<int> currentStock = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int syncStatus,
                required DateTime updatedAt,
                required DateTime createdAt,
                Value<int?> minStockLevel = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> defaultSupplierId = const Value.absent(),
                Value<String?> defaultSupplierName = const Value.absent(),
                Value<double> cgstPercent = const Value.absent(),
                Value<double> sgstPercent = const Value.absent(),
                Value<String?> hsnCode = const Value.absent(),
                Value<String?> customFieldsJson = const Value.absent(),
                Value<String?> size = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<double?> mrp = const Value.absent(),
                Value<String?> composition = const Value.absent(),
                Value<String?> drugSchedule = const Value.absent(),
                Value<String?> packUnit = const Value.absent(),
                Value<int> unitsPerPack = const Value.absent(),
              }) => ProductRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                indexNo: indexNo,
                name: name,
                companyName: companyName,
                category: category,
                barcode: barcode,
                purchasePrice: purchasePrice,
                salesPrice: salesPrice,
                currentStock: currentStock,
                unit: unit,
                isActive: isActive,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                createdAt: createdAt,
                minStockLevel: minStockLevel,
                description: description,
                imageUrl: imageUrl,
                defaultSupplierId: defaultSupplierId,
                defaultSupplierName: defaultSupplierName,
                cgstPercent: cgstPercent,
                sgstPercent: sgstPercent,
                hsnCode: hsnCode,
                customFieldsJson: customFieldsJson,
                size: size,
                color: color,
                mrp: mrp,
                composition: composition,
                drugSchedule: drugSchedule,
                packUnit: packUnit,
                unitsPerPack: unitsPerPack,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductRecordsTable,
      ProductRecord,
      $$ProductRecordsTableFilterComposer,
      $$ProductRecordsTableOrderingComposer,
      $$ProductRecordsTableAnnotationComposer,
      $$ProductRecordsTableCreateCompanionBuilder,
      $$ProductRecordsTableUpdateCompanionBuilder,
      (
        ProductRecord,
        BaseReferences<_$AppDatabase, $ProductRecordsTable, ProductRecord>,
      ),
      ProductRecord,
      PrefetchHooks Function()
    >;
typedef $$PurchaseRecordsTableCreateCompanionBuilder =
    PurchaseRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String productId,
      Value<String> productName,
      Value<String?> supplierId,
      Value<String?> supplierName,
      Value<String?> companyId,
      Value<String?> companyName,
      Value<int> quantity,
      Value<String> unit,
      Value<double> purchasePrice,
      Value<double> salesPrice,
      Value<double> totalAmount,
      Value<DateTime?> productionDate,
      Value<DateTime?> expiryDate,
      Value<int?> warrantyMonths,
      Value<String?> notes,
      required int syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$PurchaseRecordsTableUpdateCompanionBuilder =
    PurchaseRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> productId,
      Value<String> productName,
      Value<String?> supplierId,
      Value<String?> supplierName,
      Value<String?> companyId,
      Value<String?> companyName,
      Value<int> quantity,
      Value<String> unit,
      Value<double> purchasePrice,
      Value<double> salesPrice,
      Value<double> totalAmount,
      Value<DateTime?> productionDate,
      Value<DateTime?> expiryDate,
      Value<int?> warrantyMonths,
      Value<String?> notes,
      Value<int> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PurchaseRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseRecordsTable> {
  $$PurchaseRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salesPrice => $composableBuilder(
    column: $table.salesPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get productionDate => $composableBuilder(
    column: $table.productionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchaseRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseRecordsTable> {
  $$PurchaseRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salesPrice => $composableBuilder(
    column: $table.salesPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get productionDate => $composableBuilder(
    column: $table.productionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchaseRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseRecordsTable> {
  $$PurchaseRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get salesPrice => $composableBuilder(
    column: $table.salesPrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get productionDate => $composableBuilder(
    column: $table.productionDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PurchaseRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseRecordsTable,
          PurchaseRecord,
          $$PurchaseRecordsTableFilterComposer,
          $$PurchaseRecordsTableOrderingComposer,
          $$PurchaseRecordsTableAnnotationComposer,
          $$PurchaseRecordsTableCreateCompanionBuilder,
          $$PurchaseRecordsTableUpdateCompanionBuilder,
          (
            PurchaseRecord,
            BaseReferences<
              _$AppDatabase,
              $PurchaseRecordsTable,
              PurchaseRecord
            >,
          ),
          PurchaseRecord,
          PrefetchHooks Function()
        > {
  $$PurchaseRecordsTableTableManager(
    _$AppDatabase db,
    $PurchaseRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchaseRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> supplierName = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> purchasePrice = const Value.absent(),
                Value<double> salesPrice = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<DateTime?> productionDate = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<int?> warrantyMonths = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PurchaseRecordsCompanion(
                id: id,
                serverId: serverId,
                productId: productId,
                productName: productName,
                supplierId: supplierId,
                supplierName: supplierName,
                companyId: companyId,
                companyName: companyName,
                quantity: quantity,
                unit: unit,
                purchasePrice: purchasePrice,
                salesPrice: salesPrice,
                totalAmount: totalAmount,
                productionDate: productionDate,
                expiryDate: expiryDate,
                warrantyMonths: warrantyMonths,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String productId,
                Value<String> productName = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> supplierName = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> purchasePrice = const Value.absent(),
                Value<double> salesPrice = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<DateTime?> productionDate = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<int?> warrantyMonths = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => PurchaseRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                productId: productId,
                productName: productName,
                supplierId: supplierId,
                supplierName: supplierName,
                companyId: companyId,
                companyName: companyName,
                quantity: quantity,
                unit: unit,
                purchasePrice: purchasePrice,
                salesPrice: salesPrice,
                totalAmount: totalAmount,
                productionDate: productionDate,
                expiryDate: expiryDate,
                warrantyMonths: warrantyMonths,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchaseRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseRecordsTable,
      PurchaseRecord,
      $$PurchaseRecordsTableFilterComposer,
      $$PurchaseRecordsTableOrderingComposer,
      $$PurchaseRecordsTableAnnotationComposer,
      $$PurchaseRecordsTableCreateCompanionBuilder,
      $$PurchaseRecordsTableUpdateCompanionBuilder,
      (
        PurchaseRecord,
        BaseReferences<_$AppDatabase, $PurchaseRecordsTable, PurchaseRecord>,
      ),
      PurchaseRecord,
      PrefetchHooks Function()
    >;
typedef $$PurchaseBatchRecordsTableCreateCompanionBuilder =
    PurchaseBatchRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String productId,
      Value<String> productName,
      Value<String> companyName,
      Value<String> modelName,
      Value<String> category,
      Value<String> productUniqueKey,
      Value<double> purchasePrice,
      Value<double> sellingPrice,
      Value<int> quantityPurchased,
      Value<int> quantityRemaining,
      required DateTime purchaseDate,
      Value<String?> supplierId,
      Value<String?> supplierName,
      Value<String> unit,
      Value<String?> batchNumber,
      Value<DateTime?> expiryDate,
      Value<DateTime?> productionDate,
      Value<int?> warrantyMonths,
      Value<String?> notes,
      Value<bool> isConsumed,
      required int syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$PurchaseBatchRecordsTableUpdateCompanionBuilder =
    PurchaseBatchRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> productId,
      Value<String> productName,
      Value<String> companyName,
      Value<String> modelName,
      Value<String> category,
      Value<String> productUniqueKey,
      Value<double> purchasePrice,
      Value<double> sellingPrice,
      Value<int> quantityPurchased,
      Value<int> quantityRemaining,
      Value<DateTime> purchaseDate,
      Value<String?> supplierId,
      Value<String?> supplierName,
      Value<String> unit,
      Value<String?> batchNumber,
      Value<DateTime?> expiryDate,
      Value<DateTime?> productionDate,
      Value<int?> warrantyMonths,
      Value<String?> notes,
      Value<bool> isConsumed,
      Value<int> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PurchaseBatchRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseBatchRecordsTable> {
  $$PurchaseBatchRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productUniqueKey => $composableBuilder(
    column: $table.productUniqueKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityPurchased => $composableBuilder(
    column: $table.quantityPurchased,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityRemaining => $composableBuilder(
    column: $table.quantityRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchNumber => $composableBuilder(
    column: $table.batchNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get productionDate => $composableBuilder(
    column: $table.productionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConsumed => $composableBuilder(
    column: $table.isConsumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchaseBatchRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseBatchRecordsTable> {
  $$PurchaseBatchRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productUniqueKey => $composableBuilder(
    column: $table.productUniqueKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityPurchased => $composableBuilder(
    column: $table.quantityPurchased,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityRemaining => $composableBuilder(
    column: $table.quantityRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchNumber => $composableBuilder(
    column: $table.batchNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get productionDate => $composableBuilder(
    column: $table.productionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConsumed => $composableBuilder(
    column: $table.isConsumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchaseBatchRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseBatchRecordsTable> {
  $$PurchaseBatchRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get productUniqueKey => $composableBuilder(
    column: $table.productUniqueKey,
    builder: (column) => column,
  );

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityPurchased => $composableBuilder(
    column: $table.quantityPurchased,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityRemaining => $composableBuilder(
    column: $table.quantityRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get batchNumber => $composableBuilder(
    column: $table.batchNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get productionDate => $composableBuilder(
    column: $table.productionDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isConsumed => $composableBuilder(
    column: $table.isConsumed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PurchaseBatchRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseBatchRecordsTable,
          PurchaseBatchRecord,
          $$PurchaseBatchRecordsTableFilterComposer,
          $$PurchaseBatchRecordsTableOrderingComposer,
          $$PurchaseBatchRecordsTableAnnotationComposer,
          $$PurchaseBatchRecordsTableCreateCompanionBuilder,
          $$PurchaseBatchRecordsTableUpdateCompanionBuilder,
          (
            PurchaseBatchRecord,
            BaseReferences<
              _$AppDatabase,
              $PurchaseBatchRecordsTable,
              PurchaseBatchRecord
            >,
          ),
          PurchaseBatchRecord,
          PrefetchHooks Function()
        > {
  $$PurchaseBatchRecordsTableTableManager(
    _$AppDatabase db,
    $PurchaseBatchRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseBatchRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseBatchRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PurchaseBatchRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> companyName = const Value.absent(),
                Value<String> modelName = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> productUniqueKey = const Value.absent(),
                Value<double> purchasePrice = const Value.absent(),
                Value<double> sellingPrice = const Value.absent(),
                Value<int> quantityPurchased = const Value.absent(),
                Value<int> quantityRemaining = const Value.absent(),
                Value<DateTime> purchaseDate = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> supplierName = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> batchNumber = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<DateTime?> productionDate = const Value.absent(),
                Value<int?> warrantyMonths = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isConsumed = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PurchaseBatchRecordsCompanion(
                id: id,
                serverId: serverId,
                productId: productId,
                productName: productName,
                companyName: companyName,
                modelName: modelName,
                category: category,
                productUniqueKey: productUniqueKey,
                purchasePrice: purchasePrice,
                sellingPrice: sellingPrice,
                quantityPurchased: quantityPurchased,
                quantityRemaining: quantityRemaining,
                purchaseDate: purchaseDate,
                supplierId: supplierId,
                supplierName: supplierName,
                unit: unit,
                batchNumber: batchNumber,
                expiryDate: expiryDate,
                productionDate: productionDate,
                warrantyMonths: warrantyMonths,
                notes: notes,
                isConsumed: isConsumed,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String productId,
                Value<String> productName = const Value.absent(),
                Value<String> companyName = const Value.absent(),
                Value<String> modelName = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> productUniqueKey = const Value.absent(),
                Value<double> purchasePrice = const Value.absent(),
                Value<double> sellingPrice = const Value.absent(),
                Value<int> quantityPurchased = const Value.absent(),
                Value<int> quantityRemaining = const Value.absent(),
                required DateTime purchaseDate,
                Value<String?> supplierId = const Value.absent(),
                Value<String?> supplierName = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> batchNumber = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<DateTime?> productionDate = const Value.absent(),
                Value<int?> warrantyMonths = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isConsumed = const Value.absent(),
                required int syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => PurchaseBatchRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                productId: productId,
                productName: productName,
                companyName: companyName,
                modelName: modelName,
                category: category,
                productUniqueKey: productUniqueKey,
                purchasePrice: purchasePrice,
                sellingPrice: sellingPrice,
                quantityPurchased: quantityPurchased,
                quantityRemaining: quantityRemaining,
                purchaseDate: purchaseDate,
                supplierId: supplierId,
                supplierName: supplierName,
                unit: unit,
                batchNumber: batchNumber,
                expiryDate: expiryDate,
                productionDate: productionDate,
                warrantyMonths: warrantyMonths,
                notes: notes,
                isConsumed: isConsumed,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchaseBatchRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseBatchRecordsTable,
      PurchaseBatchRecord,
      $$PurchaseBatchRecordsTableFilterComposer,
      $$PurchaseBatchRecordsTableOrderingComposer,
      $$PurchaseBatchRecordsTableAnnotationComposer,
      $$PurchaseBatchRecordsTableCreateCompanionBuilder,
      $$PurchaseBatchRecordsTableUpdateCompanionBuilder,
      (
        PurchaseBatchRecord,
        BaseReferences<
          _$AppDatabase,
          $PurchaseBatchRecordsTable,
          PurchaseBatchRecord
        >,
      ),
      PurchaseBatchRecord,
      PrefetchHooks Function()
    >;
typedef $$StockLedgerRecordsTableCreateCompanionBuilder =
    StockLedgerRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String productId,
      Value<String> productName,
      Value<String> companyName,
      Value<String> modelName,
      Value<String> productUniqueKey,
      Value<String> batchId,
      Value<int?> localBatchId,
      required int ledgerType,
      Value<String> referenceId,
      Value<String> referenceType,
      Value<int> quantity,
      Value<double> costPrice,
      Value<double> sellingPrice,
      Value<double> totalCost,
      Value<double> totalRevenue,
      Value<double> profit,
      Value<int> balanceQuantity,
      Value<double> balanceValue,
      required DateTime transactionDate,
      Value<String?> notes,
      required int syncStatus,
      required DateTime createdAt,
    });
typedef $$StockLedgerRecordsTableUpdateCompanionBuilder =
    StockLedgerRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> productId,
      Value<String> productName,
      Value<String> companyName,
      Value<String> modelName,
      Value<String> productUniqueKey,
      Value<String> batchId,
      Value<int?> localBatchId,
      Value<int> ledgerType,
      Value<String> referenceId,
      Value<String> referenceType,
      Value<int> quantity,
      Value<double> costPrice,
      Value<double> sellingPrice,
      Value<double> totalCost,
      Value<double> totalRevenue,
      Value<double> profit,
      Value<int> balanceQuantity,
      Value<double> balanceValue,
      Value<DateTime> transactionDate,
      Value<String?> notes,
      Value<int> syncStatus,
      Value<DateTime> createdAt,
    });

class $$StockLedgerRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $StockLedgerRecordsTable> {
  $$StockLedgerRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productUniqueKey => $composableBuilder(
    column: $table.productUniqueKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localBatchId => $composableBuilder(
    column: $table.localBatchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalRevenue => $composableBuilder(
    column: $table.totalRevenue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profit => $composableBuilder(
    column: $table.profit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceQuantity => $composableBuilder(
    column: $table.balanceQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balanceValue => $composableBuilder(
    column: $table.balanceValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockLedgerRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockLedgerRecordsTable> {
  $$StockLedgerRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productUniqueKey => $composableBuilder(
    column: $table.productUniqueKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localBatchId => $composableBuilder(
    column: $table.localBatchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalRevenue => $composableBuilder(
    column: $table.totalRevenue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profit => $composableBuilder(
    column: $table.profit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceQuantity => $composableBuilder(
    column: $table.balanceQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balanceValue => $composableBuilder(
    column: $table.balanceValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockLedgerRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockLedgerRecordsTable> {
  $$StockLedgerRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get productUniqueKey => $composableBuilder(
    column: $table.productUniqueKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<int> get localBatchId => $composableBuilder(
    column: $table.localBatchId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalCost =>
      $composableBuilder(column: $table.totalCost, builder: (column) => column);

  GeneratedColumn<double> get totalRevenue => $composableBuilder(
    column: $table.totalRevenue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profit =>
      $composableBuilder(column: $table.profit, builder: (column) => column);

  GeneratedColumn<int> get balanceQuantity => $composableBuilder(
    column: $table.balanceQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get balanceValue => $composableBuilder(
    column: $table.balanceValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StockLedgerRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockLedgerRecordsTable,
          StockLedgerRecord,
          $$StockLedgerRecordsTableFilterComposer,
          $$StockLedgerRecordsTableOrderingComposer,
          $$StockLedgerRecordsTableAnnotationComposer,
          $$StockLedgerRecordsTableCreateCompanionBuilder,
          $$StockLedgerRecordsTableUpdateCompanionBuilder,
          (
            StockLedgerRecord,
            BaseReferences<
              _$AppDatabase,
              $StockLedgerRecordsTable,
              StockLedgerRecord
            >,
          ),
          StockLedgerRecord,
          PrefetchHooks Function()
        > {
  $$StockLedgerRecordsTableTableManager(
    _$AppDatabase db,
    $StockLedgerRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockLedgerRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockLedgerRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockLedgerRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> companyName = const Value.absent(),
                Value<String> modelName = const Value.absent(),
                Value<String> productUniqueKey = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<int?> localBatchId = const Value.absent(),
                Value<int> ledgerType = const Value.absent(),
                Value<String> referenceId = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> costPrice = const Value.absent(),
                Value<double> sellingPrice = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                Value<double> totalRevenue = const Value.absent(),
                Value<double> profit = const Value.absent(),
                Value<int> balanceQuantity = const Value.absent(),
                Value<double> balanceValue = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StockLedgerRecordsCompanion(
                id: id,
                serverId: serverId,
                productId: productId,
                productName: productName,
                companyName: companyName,
                modelName: modelName,
                productUniqueKey: productUniqueKey,
                batchId: batchId,
                localBatchId: localBatchId,
                ledgerType: ledgerType,
                referenceId: referenceId,
                referenceType: referenceType,
                quantity: quantity,
                costPrice: costPrice,
                sellingPrice: sellingPrice,
                totalCost: totalCost,
                totalRevenue: totalRevenue,
                profit: profit,
                balanceQuantity: balanceQuantity,
                balanceValue: balanceValue,
                transactionDate: transactionDate,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String productId,
                Value<String> productName = const Value.absent(),
                Value<String> companyName = const Value.absent(),
                Value<String> modelName = const Value.absent(),
                Value<String> productUniqueKey = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<int?> localBatchId = const Value.absent(),
                required int ledgerType,
                Value<String> referenceId = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> costPrice = const Value.absent(),
                Value<double> sellingPrice = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                Value<double> totalRevenue = const Value.absent(),
                Value<double> profit = const Value.absent(),
                Value<int> balanceQuantity = const Value.absent(),
                Value<double> balanceValue = const Value.absent(),
                required DateTime transactionDate,
                Value<String?> notes = const Value.absent(),
                required int syncStatus,
                required DateTime createdAt,
              }) => StockLedgerRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                productId: productId,
                productName: productName,
                companyName: companyName,
                modelName: modelName,
                productUniqueKey: productUniqueKey,
                batchId: batchId,
                localBatchId: localBatchId,
                ledgerType: ledgerType,
                referenceId: referenceId,
                referenceType: referenceType,
                quantity: quantity,
                costPrice: costPrice,
                sellingPrice: sellingPrice,
                totalCost: totalCost,
                totalRevenue: totalRevenue,
                profit: profit,
                balanceQuantity: balanceQuantity,
                balanceValue: balanceValue,
                transactionDate: transactionDate,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockLedgerRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockLedgerRecordsTable,
      StockLedgerRecord,
      $$StockLedgerRecordsTableFilterComposer,
      $$StockLedgerRecordsTableOrderingComposer,
      $$StockLedgerRecordsTableAnnotationComposer,
      $$StockLedgerRecordsTableCreateCompanionBuilder,
      $$StockLedgerRecordsTableUpdateCompanionBuilder,
      (
        StockLedgerRecord,
        BaseReferences<
          _$AppDatabase,
          $StockLedgerRecordsTable,
          StockLedgerRecord
        >,
      ),
      StockLedgerRecord,
      PrefetchHooks Function()
    >;
typedef $$BillRecordsTableCreateCompanionBuilder =
    BillRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String?> customerId,
      Value<String?> customerName,
      Value<String?> customerContact,
      Value<String> itemsJson,
      Value<int> totalQuantity,
      Value<double> totalAmount,
      Value<double> discountAmount,
      Value<double> discountPercent,
      Value<double> finalAmount,
      required DateTime billDate,
      Value<String?> notes,
      Value<bool> returnStatus,
      Value<DateTime?> returnDate,
      required int paymentStatus,
      Value<double> paidAmount,
      Value<double> pendingAmount,
      Value<bool> isGstApplied,
      Value<bool> isTaxInclusive,
      Value<double> cgstPercent,
      Value<double> sgstPercent,
      Value<double> igstPercent,
      Value<double> otherTaxPercent,
      Value<String?> otherTaxName,
      Value<double> cgstAmount,
      Value<double> sgstAmount,
      Value<double> igstAmount,
      Value<double> otherTaxAmount,
      Value<double> totalTaxAmount,
      Value<String?> customerGstin,
      Value<String?> placeOfSupply,
      Value<bool> isInterstate,
      Value<String> extraChargesJson,
      Value<String> paymentMode,
      required int syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$BillRecordsTableUpdateCompanionBuilder =
    BillRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String?> customerId,
      Value<String?> customerName,
      Value<String?> customerContact,
      Value<String> itemsJson,
      Value<int> totalQuantity,
      Value<double> totalAmount,
      Value<double> discountAmount,
      Value<double> discountPercent,
      Value<double> finalAmount,
      Value<DateTime> billDate,
      Value<String?> notes,
      Value<bool> returnStatus,
      Value<DateTime?> returnDate,
      Value<int> paymentStatus,
      Value<double> paidAmount,
      Value<double> pendingAmount,
      Value<bool> isGstApplied,
      Value<bool> isTaxInclusive,
      Value<double> cgstPercent,
      Value<double> sgstPercent,
      Value<double> igstPercent,
      Value<double> otherTaxPercent,
      Value<String?> otherTaxName,
      Value<double> cgstAmount,
      Value<double> sgstAmount,
      Value<double> igstAmount,
      Value<double> otherTaxAmount,
      Value<double> totalTaxAmount,
      Value<String?> customerGstin,
      Value<String?> placeOfSupply,
      Value<bool> isInterstate,
      Value<String> extraChargesJson,
      Value<String> paymentMode,
      Value<int> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$BillRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $BillRecordsTable> {
  $$BillRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerContact => $composableBuilder(
    column: $table.customerContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuantity => $composableBuilder(
    column: $table.totalQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountPercent => $composableBuilder(
    column: $table.discountPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get finalAmount => $composableBuilder(
    column: $table.finalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get billDate => $composableBuilder(
    column: $table.billDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get returnStatus => $composableBuilder(
    column: $table.returnStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get returnDate => $composableBuilder(
    column: $table.returnDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pendingAmount => $composableBuilder(
    column: $table.pendingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGstApplied => $composableBuilder(
    column: $table.isGstApplied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTaxInclusive => $composableBuilder(
    column: $table.isTaxInclusive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cgstPercent => $composableBuilder(
    column: $table.cgstPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sgstPercent => $composableBuilder(
    column: $table.sgstPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get igstPercent => $composableBuilder(
    column: $table.igstPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get otherTaxPercent => $composableBuilder(
    column: $table.otherTaxPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherTaxName => $composableBuilder(
    column: $table.otherTaxName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cgstAmount => $composableBuilder(
    column: $table.cgstAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sgstAmount => $composableBuilder(
    column: $table.sgstAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get igstAmount => $composableBuilder(
    column: $table.igstAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get otherTaxAmount => $composableBuilder(
    column: $table.otherTaxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalTaxAmount => $composableBuilder(
    column: $table.totalTaxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerGstin => $composableBuilder(
    column: $table.customerGstin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeOfSupply => $composableBuilder(
    column: $table.placeOfSupply,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInterstate => $composableBuilder(
    column: $table.isInterstate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraChargesJson => $composableBuilder(
    column: $table.extraChargesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BillRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillRecordsTable> {
  $$BillRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerContact => $composableBuilder(
    column: $table.customerContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuantity => $composableBuilder(
    column: $table.totalQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountPercent => $composableBuilder(
    column: $table.discountPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get finalAmount => $composableBuilder(
    column: $table.finalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get billDate => $composableBuilder(
    column: $table.billDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get returnStatus => $composableBuilder(
    column: $table.returnStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get returnDate => $composableBuilder(
    column: $table.returnDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pendingAmount => $composableBuilder(
    column: $table.pendingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGstApplied => $composableBuilder(
    column: $table.isGstApplied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTaxInclusive => $composableBuilder(
    column: $table.isTaxInclusive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cgstPercent => $composableBuilder(
    column: $table.cgstPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sgstPercent => $composableBuilder(
    column: $table.sgstPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get igstPercent => $composableBuilder(
    column: $table.igstPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get otherTaxPercent => $composableBuilder(
    column: $table.otherTaxPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherTaxName => $composableBuilder(
    column: $table.otherTaxName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cgstAmount => $composableBuilder(
    column: $table.cgstAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sgstAmount => $composableBuilder(
    column: $table.sgstAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get igstAmount => $composableBuilder(
    column: $table.igstAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get otherTaxAmount => $composableBuilder(
    column: $table.otherTaxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalTaxAmount => $composableBuilder(
    column: $table.totalTaxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerGstin => $composableBuilder(
    column: $table.customerGstin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeOfSupply => $composableBuilder(
    column: $table.placeOfSupply,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInterstate => $composableBuilder(
    column: $table.isInterstate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraChargesJson => $composableBuilder(
    column: $table.extraChargesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BillRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillRecordsTable> {
  $$BillRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerContact => $composableBuilder(
    column: $table.customerContact,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<int> get totalQuantity => $composableBuilder(
    column: $table.totalQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountPercent => $composableBuilder(
    column: $table.discountPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get finalAmount => $composableBuilder(
    column: $table.finalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get billDate =>
      $composableBuilder(column: $table.billDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get returnStatus => $composableBuilder(
    column: $table.returnStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get returnDate => $composableBuilder(
    column: $table.returnDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pendingAmount => $composableBuilder(
    column: $table.pendingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGstApplied => $composableBuilder(
    column: $table.isGstApplied,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTaxInclusive => $composableBuilder(
    column: $table.isTaxInclusive,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cgstPercent => $composableBuilder(
    column: $table.cgstPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sgstPercent => $composableBuilder(
    column: $table.sgstPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get igstPercent => $composableBuilder(
    column: $table.igstPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get otherTaxPercent => $composableBuilder(
    column: $table.otherTaxPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get otherTaxName => $composableBuilder(
    column: $table.otherTaxName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cgstAmount => $composableBuilder(
    column: $table.cgstAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sgstAmount => $composableBuilder(
    column: $table.sgstAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get igstAmount => $composableBuilder(
    column: $table.igstAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get otherTaxAmount => $composableBuilder(
    column: $table.otherTaxAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalTaxAmount => $composableBuilder(
    column: $table.totalTaxAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerGstin => $composableBuilder(
    column: $table.customerGstin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get placeOfSupply => $composableBuilder(
    column: $table.placeOfSupply,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isInterstate => $composableBuilder(
    column: $table.isInterstate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extraChargesJson => $composableBuilder(
    column: $table.extraChargesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BillRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillRecordsTable,
          BillRecord,
          $$BillRecordsTableFilterComposer,
          $$BillRecordsTableOrderingComposer,
          $$BillRecordsTableAnnotationComposer,
          $$BillRecordsTableCreateCompanionBuilder,
          $$BillRecordsTableUpdateCompanionBuilder,
          (
            BillRecord,
            BaseReferences<_$AppDatabase, $BillRecordsTable, BillRecord>,
          ),
          BillRecord,
          PrefetchHooks Function()
        > {
  $$BillRecordsTableTableManager(_$AppDatabase db, $BillRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerContact = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<int> totalQuantity = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> discountPercent = const Value.absent(),
                Value<double> finalAmount = const Value.absent(),
                Value<DateTime> billDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> returnStatus = const Value.absent(),
                Value<DateTime?> returnDate = const Value.absent(),
                Value<int> paymentStatus = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<double> pendingAmount = const Value.absent(),
                Value<bool> isGstApplied = const Value.absent(),
                Value<bool> isTaxInclusive = const Value.absent(),
                Value<double> cgstPercent = const Value.absent(),
                Value<double> sgstPercent = const Value.absent(),
                Value<double> igstPercent = const Value.absent(),
                Value<double> otherTaxPercent = const Value.absent(),
                Value<String?> otherTaxName = const Value.absent(),
                Value<double> cgstAmount = const Value.absent(),
                Value<double> sgstAmount = const Value.absent(),
                Value<double> igstAmount = const Value.absent(),
                Value<double> otherTaxAmount = const Value.absent(),
                Value<double> totalTaxAmount = const Value.absent(),
                Value<String?> customerGstin = const Value.absent(),
                Value<String?> placeOfSupply = const Value.absent(),
                Value<bool> isInterstate = const Value.absent(),
                Value<String> extraChargesJson = const Value.absent(),
                Value<String> paymentMode = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BillRecordsCompanion(
                id: id,
                serverId: serverId,
                customerId: customerId,
                customerName: customerName,
                customerContact: customerContact,
                itemsJson: itemsJson,
                totalQuantity: totalQuantity,
                totalAmount: totalAmount,
                discountAmount: discountAmount,
                discountPercent: discountPercent,
                finalAmount: finalAmount,
                billDate: billDate,
                notes: notes,
                returnStatus: returnStatus,
                returnDate: returnDate,
                paymentStatus: paymentStatus,
                paidAmount: paidAmount,
                pendingAmount: pendingAmount,
                isGstApplied: isGstApplied,
                isTaxInclusive: isTaxInclusive,
                cgstPercent: cgstPercent,
                sgstPercent: sgstPercent,
                igstPercent: igstPercent,
                otherTaxPercent: otherTaxPercent,
                otherTaxName: otherTaxName,
                cgstAmount: cgstAmount,
                sgstAmount: sgstAmount,
                igstAmount: igstAmount,
                otherTaxAmount: otherTaxAmount,
                totalTaxAmount: totalTaxAmount,
                customerGstin: customerGstin,
                placeOfSupply: placeOfSupply,
                isInterstate: isInterstate,
                extraChargesJson: extraChargesJson,
                paymentMode: paymentMode,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerContact = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<int> totalQuantity = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> discountPercent = const Value.absent(),
                Value<double> finalAmount = const Value.absent(),
                required DateTime billDate,
                Value<String?> notes = const Value.absent(),
                Value<bool> returnStatus = const Value.absent(),
                Value<DateTime?> returnDate = const Value.absent(),
                required int paymentStatus,
                Value<double> paidAmount = const Value.absent(),
                Value<double> pendingAmount = const Value.absent(),
                Value<bool> isGstApplied = const Value.absent(),
                Value<bool> isTaxInclusive = const Value.absent(),
                Value<double> cgstPercent = const Value.absent(),
                Value<double> sgstPercent = const Value.absent(),
                Value<double> igstPercent = const Value.absent(),
                Value<double> otherTaxPercent = const Value.absent(),
                Value<String?> otherTaxName = const Value.absent(),
                Value<double> cgstAmount = const Value.absent(),
                Value<double> sgstAmount = const Value.absent(),
                Value<double> igstAmount = const Value.absent(),
                Value<double> otherTaxAmount = const Value.absent(),
                Value<double> totalTaxAmount = const Value.absent(),
                Value<String?> customerGstin = const Value.absent(),
                Value<String?> placeOfSupply = const Value.absent(),
                Value<bool> isInterstate = const Value.absent(),
                Value<String> extraChargesJson = const Value.absent(),
                Value<String> paymentMode = const Value.absent(),
                required int syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => BillRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                customerId: customerId,
                customerName: customerName,
                customerContact: customerContact,
                itemsJson: itemsJson,
                totalQuantity: totalQuantity,
                totalAmount: totalAmount,
                discountAmount: discountAmount,
                discountPercent: discountPercent,
                finalAmount: finalAmount,
                billDate: billDate,
                notes: notes,
                returnStatus: returnStatus,
                returnDate: returnDate,
                paymentStatus: paymentStatus,
                paidAmount: paidAmount,
                pendingAmount: pendingAmount,
                isGstApplied: isGstApplied,
                isTaxInclusive: isTaxInclusive,
                cgstPercent: cgstPercent,
                sgstPercent: sgstPercent,
                igstPercent: igstPercent,
                otherTaxPercent: otherTaxPercent,
                otherTaxName: otherTaxName,
                cgstAmount: cgstAmount,
                sgstAmount: sgstAmount,
                igstAmount: igstAmount,
                otherTaxAmount: otherTaxAmount,
                totalTaxAmount: totalTaxAmount,
                customerGstin: customerGstin,
                placeOfSupply: placeOfSupply,
                isInterstate: isInterstate,
                extraChargesJson: extraChargesJson,
                paymentMode: paymentMode,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BillRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillRecordsTable,
      BillRecord,
      $$BillRecordsTableFilterComposer,
      $$BillRecordsTableOrderingComposer,
      $$BillRecordsTableAnnotationComposer,
      $$BillRecordsTableCreateCompanionBuilder,
      $$BillRecordsTableUpdateCompanionBuilder,
      (
        BillRecord,
        BaseReferences<_$AppDatabase, $BillRecordsTable, BillRecord>,
      ),
      BillRecord,
      PrefetchHooks Function()
    >;
typedef $$EventOrderRecordsTableCreateCompanionBuilder =
    EventOrderRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> orderType,
      Value<String?> customerId,
      Value<String> customerName,
      Value<String> customerContact,
      Value<String?> customerAddress,
      Value<String> orderName,
      Value<String?> description,
      required DateTime eventDate,
      Value<String?> eventLocation,
      Value<String> subEventsJson,
      Value<String> itemsJson,
      Value<double> eventCharges,
      Value<double> totalAmount,
      Value<double> advanceAmount,
      Value<double> remainingAmount,
      Value<String?> notes,
      Value<int> status,
      Value<String?> convertedBillId,
      Value<String?> customDataJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      required int syncStatus,
    });
typedef $$EventOrderRecordsTableUpdateCompanionBuilder =
    EventOrderRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> orderType,
      Value<String?> customerId,
      Value<String> customerName,
      Value<String> customerContact,
      Value<String?> customerAddress,
      Value<String> orderName,
      Value<String?> description,
      Value<DateTime> eventDate,
      Value<String?> eventLocation,
      Value<String> subEventsJson,
      Value<String> itemsJson,
      Value<double> eventCharges,
      Value<double> totalAmount,
      Value<double> advanceAmount,
      Value<double> remainingAmount,
      Value<String?> notes,
      Value<int> status,
      Value<String?> convertedBillId,
      Value<String?> customDataJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> syncStatus,
    });

class $$EventOrderRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $EventOrderRecordsTable> {
  $$EventOrderRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerContact => $composableBuilder(
    column: $table.customerContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderName => $composableBuilder(
    column: $table.orderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventLocation => $composableBuilder(
    column: $table.eventLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subEventsJson => $composableBuilder(
    column: $table.subEventsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get eventCharges => $composableBuilder(
    column: $table.eventCharges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get advanceAmount => $composableBuilder(
    column: $table.advanceAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingAmount => $composableBuilder(
    column: $table.remainingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get convertedBillId => $composableBuilder(
    column: $table.convertedBillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customDataJson => $composableBuilder(
    column: $table.customDataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventOrderRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventOrderRecordsTable> {
  $$EventOrderRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerContact => $composableBuilder(
    column: $table.customerContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderName => $composableBuilder(
    column: $table.orderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventLocation => $composableBuilder(
    column: $table.eventLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subEventsJson => $composableBuilder(
    column: $table.subEventsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get eventCharges => $composableBuilder(
    column: $table.eventCharges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get advanceAmount => $composableBuilder(
    column: $table.advanceAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingAmount => $composableBuilder(
    column: $table.remainingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get convertedBillId => $composableBuilder(
    column: $table.convertedBillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customDataJson => $composableBuilder(
    column: $table.customDataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventOrderRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventOrderRecordsTable> {
  $$EventOrderRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerContact => $composableBuilder(
    column: $table.customerContact,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderName =>
      $composableBuilder(column: $table.orderName, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumn<String> get eventLocation => $composableBuilder(
    column: $table.eventLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subEventsJson => $composableBuilder(
    column: $table.subEventsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<double> get eventCharges => $composableBuilder(
    column: $table.eventCharges,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get advanceAmount => $composableBuilder(
    column: $table.advanceAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get remainingAmount => $composableBuilder(
    column: $table.remainingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get convertedBillId => $composableBuilder(
    column: $table.convertedBillId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customDataJson => $composableBuilder(
    column: $table.customDataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$EventOrderRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventOrderRecordsTable,
          EventOrderRecord,
          $$EventOrderRecordsTableFilterComposer,
          $$EventOrderRecordsTableOrderingComposer,
          $$EventOrderRecordsTableAnnotationComposer,
          $$EventOrderRecordsTableCreateCompanionBuilder,
          $$EventOrderRecordsTableUpdateCompanionBuilder,
          (
            EventOrderRecord,
            BaseReferences<
              _$AppDatabase,
              $EventOrderRecordsTable,
              EventOrderRecord
            >,
          ),
          EventOrderRecord,
          PrefetchHooks Function()
        > {
  $$EventOrderRecordsTableTableManager(
    _$AppDatabase db,
    $EventOrderRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventOrderRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventOrderRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventOrderRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> orderType = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> customerContact = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                Value<String> orderName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> eventDate = const Value.absent(),
                Value<String?> eventLocation = const Value.absent(),
                Value<String> subEventsJson = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<double> eventCharges = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> advanceAmount = const Value.absent(),
                Value<double> remainingAmount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> convertedBillId = const Value.absent(),
                Value<String?> customDataJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
              }) => EventOrderRecordsCompanion(
                id: id,
                serverId: serverId,
                orderType: orderType,
                customerId: customerId,
                customerName: customerName,
                customerContact: customerContact,
                customerAddress: customerAddress,
                orderName: orderName,
                description: description,
                eventDate: eventDate,
                eventLocation: eventLocation,
                subEventsJson: subEventsJson,
                itemsJson: itemsJson,
                eventCharges: eventCharges,
                totalAmount: totalAmount,
                advanceAmount: advanceAmount,
                remainingAmount: remainingAmount,
                notes: notes,
                status: status,
                convertedBillId: convertedBillId,
                customDataJson: customDataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> orderType = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> customerContact = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                Value<String> orderName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required DateTime eventDate,
                Value<String?> eventLocation = const Value.absent(),
                Value<String> subEventsJson = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<double> eventCharges = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> advanceAmount = const Value.absent(),
                Value<double> remainingAmount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> convertedBillId = const Value.absent(),
                Value<String?> customDataJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required int syncStatus,
              }) => EventOrderRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                orderType: orderType,
                customerId: customerId,
                customerName: customerName,
                customerContact: customerContact,
                customerAddress: customerAddress,
                orderName: orderName,
                description: description,
                eventDate: eventDate,
                eventLocation: eventLocation,
                subEventsJson: subEventsJson,
                itemsJson: itemsJson,
                eventCharges: eventCharges,
                totalAmount: totalAmount,
                advanceAmount: advanceAmount,
                remainingAmount: remainingAmount,
                notes: notes,
                status: status,
                convertedBillId: convertedBillId,
                customDataJson: customDataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventOrderRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventOrderRecordsTable,
      EventOrderRecord,
      $$EventOrderRecordsTableFilterComposer,
      $$EventOrderRecordsTableOrderingComposer,
      $$EventOrderRecordsTableAnnotationComposer,
      $$EventOrderRecordsTableCreateCompanionBuilder,
      $$EventOrderRecordsTableUpdateCompanionBuilder,
      (
        EventOrderRecord,
        BaseReferences<
          _$AppDatabase,
          $EventOrderRecordsTable,
          EventOrderRecord
        >,
      ),
      EventOrderRecord,
      PrefetchHooks Function()
    >;
typedef $$QuotationRecordsTableCreateCompanionBuilder =
    QuotationRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> quotationNumber,
      Value<int> quotationType,
      Value<String?> customerId,
      Value<String> customerName,
      Value<String> customerContact,
      Value<String?> customerAddress,
      Value<String> title,
      Value<String?> description,
      required DateTime referenceDate,
      Value<String?> eventLocation,
      required DateTime validUntil,
      Value<String> subEventsJson,
      Value<String> itemsJson,
      Value<double> eventCharges,
      Value<double> discountPercent,
      Value<double> discountAmount,
      Value<double> totalAmount,
      Value<String?> notes,
      Value<int> status,
      Value<String?> convertedBillId,
      Value<String?> convertedEventOrderId,
      Value<String?> customDataJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      required int syncStatus,
    });
typedef $$QuotationRecordsTableUpdateCompanionBuilder =
    QuotationRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> quotationNumber,
      Value<int> quotationType,
      Value<String?> customerId,
      Value<String> customerName,
      Value<String> customerContact,
      Value<String?> customerAddress,
      Value<String> title,
      Value<String?> description,
      Value<DateTime> referenceDate,
      Value<String?> eventLocation,
      Value<DateTime> validUntil,
      Value<String> subEventsJson,
      Value<String> itemsJson,
      Value<double> eventCharges,
      Value<double> discountPercent,
      Value<double> discountAmount,
      Value<double> totalAmount,
      Value<String?> notes,
      Value<int> status,
      Value<String?> convertedBillId,
      Value<String?> convertedEventOrderId,
      Value<String?> customDataJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> syncStatus,
    });

class $$QuotationRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $QuotationRecordsTable> {
  $$QuotationRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quotationNumber => $composableBuilder(
    column: $table.quotationNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quotationType => $composableBuilder(
    column: $table.quotationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerContact => $composableBuilder(
    column: $table.customerContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get referenceDate => $composableBuilder(
    column: $table.referenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventLocation => $composableBuilder(
    column: $table.eventLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subEventsJson => $composableBuilder(
    column: $table.subEventsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get eventCharges => $composableBuilder(
    column: $table.eventCharges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountPercent => $composableBuilder(
    column: $table.discountPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get convertedBillId => $composableBuilder(
    column: $table.convertedBillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get convertedEventOrderId => $composableBuilder(
    column: $table.convertedEventOrderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customDataJson => $composableBuilder(
    column: $table.customDataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuotationRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuotationRecordsTable> {
  $$QuotationRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quotationNumber => $composableBuilder(
    column: $table.quotationNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quotationType => $composableBuilder(
    column: $table.quotationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerContact => $composableBuilder(
    column: $table.customerContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get referenceDate => $composableBuilder(
    column: $table.referenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventLocation => $composableBuilder(
    column: $table.eventLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subEventsJson => $composableBuilder(
    column: $table.subEventsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get eventCharges => $composableBuilder(
    column: $table.eventCharges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountPercent => $composableBuilder(
    column: $table.discountPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get convertedBillId => $composableBuilder(
    column: $table.convertedBillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get convertedEventOrderId => $composableBuilder(
    column: $table.convertedEventOrderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customDataJson => $composableBuilder(
    column: $table.customDataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuotationRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuotationRecordsTable> {
  $$QuotationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get quotationNumber => $composableBuilder(
    column: $table.quotationNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quotationType => $composableBuilder(
    column: $table.quotationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerContact => $composableBuilder(
    column: $table.customerContact,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get referenceDate => $composableBuilder(
    column: $table.referenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventLocation => $composableBuilder(
    column: $table.eventLocation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subEventsJson => $composableBuilder(
    column: $table.subEventsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<double> get eventCharges => $composableBuilder(
    column: $table.eventCharges,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountPercent => $composableBuilder(
    column: $table.discountPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get convertedBillId => $composableBuilder(
    column: $table.convertedBillId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get convertedEventOrderId => $composableBuilder(
    column: $table.convertedEventOrderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customDataJson => $composableBuilder(
    column: $table.customDataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$QuotationRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuotationRecordsTable,
          QuotationRecord,
          $$QuotationRecordsTableFilterComposer,
          $$QuotationRecordsTableOrderingComposer,
          $$QuotationRecordsTableAnnotationComposer,
          $$QuotationRecordsTableCreateCompanionBuilder,
          $$QuotationRecordsTableUpdateCompanionBuilder,
          (
            QuotationRecord,
            BaseReferences<
              _$AppDatabase,
              $QuotationRecordsTable,
              QuotationRecord
            >,
          ),
          QuotationRecord,
          PrefetchHooks Function()
        > {
  $$QuotationRecordsTableTableManager(
    _$AppDatabase db,
    $QuotationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuotationRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuotationRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuotationRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> quotationNumber = const Value.absent(),
                Value<int> quotationType = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> customerContact = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> referenceDate = const Value.absent(),
                Value<String?> eventLocation = const Value.absent(),
                Value<DateTime> validUntil = const Value.absent(),
                Value<String> subEventsJson = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<double> eventCharges = const Value.absent(),
                Value<double> discountPercent = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> convertedBillId = const Value.absent(),
                Value<String?> convertedEventOrderId = const Value.absent(),
                Value<String?> customDataJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
              }) => QuotationRecordsCompanion(
                id: id,
                serverId: serverId,
                quotationNumber: quotationNumber,
                quotationType: quotationType,
                customerId: customerId,
                customerName: customerName,
                customerContact: customerContact,
                customerAddress: customerAddress,
                title: title,
                description: description,
                referenceDate: referenceDate,
                eventLocation: eventLocation,
                validUntil: validUntil,
                subEventsJson: subEventsJson,
                itemsJson: itemsJson,
                eventCharges: eventCharges,
                discountPercent: discountPercent,
                discountAmount: discountAmount,
                totalAmount: totalAmount,
                notes: notes,
                status: status,
                convertedBillId: convertedBillId,
                convertedEventOrderId: convertedEventOrderId,
                customDataJson: customDataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> quotationNumber = const Value.absent(),
                Value<int> quotationType = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> customerContact = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required DateTime referenceDate,
                Value<String?> eventLocation = const Value.absent(),
                required DateTime validUntil,
                Value<String> subEventsJson = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<double> eventCharges = const Value.absent(),
                Value<double> discountPercent = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> convertedBillId = const Value.absent(),
                Value<String?> convertedEventOrderId = const Value.absent(),
                Value<String?> customDataJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required int syncStatus,
              }) => QuotationRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                quotationNumber: quotationNumber,
                quotationType: quotationType,
                customerId: customerId,
                customerName: customerName,
                customerContact: customerContact,
                customerAddress: customerAddress,
                title: title,
                description: description,
                referenceDate: referenceDate,
                eventLocation: eventLocation,
                validUntil: validUntil,
                subEventsJson: subEventsJson,
                itemsJson: itemsJson,
                eventCharges: eventCharges,
                discountPercent: discountPercent,
                discountAmount: discountAmount,
                totalAmount: totalAmount,
                notes: notes,
                status: status,
                convertedBillId: convertedBillId,
                convertedEventOrderId: convertedEventOrderId,
                customDataJson: customDataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuotationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuotationRecordsTable,
      QuotationRecord,
      $$QuotationRecordsTableFilterComposer,
      $$QuotationRecordsTableOrderingComposer,
      $$QuotationRecordsTableAnnotationComposer,
      $$QuotationRecordsTableCreateCompanionBuilder,
      $$QuotationRecordsTableUpdateCompanionBuilder,
      (
        QuotationRecord,
        BaseReferences<_$AppDatabase, $QuotationRecordsTable, QuotationRecord>,
      ),
      QuotationRecord,
      PrefetchHooks Function()
    >;
typedef $$ExpenseRecordsTableCreateCompanionBuilder =
    ExpenseRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String title,
      Value<String?> description,
      required int category,
      Value<double> amount,
      Value<String?> paymentMethod,
      Value<String?> vendorName,
      Value<String?> receiptNumber,
      Value<bool> isRecurring,
      required DateTime expenseDate,
      Value<String?> notes,
      required int syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ExpenseRecordsTableUpdateCompanionBuilder =
    ExpenseRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> title,
      Value<String?> description,
      Value<int> category,
      Value<double> amount,
      Value<String?> paymentMethod,
      Value<String?> vendorName,
      Value<String?> receiptNumber,
      Value<bool> isRecurring,
      Value<DateTime> expenseDate,
      Value<String?> notes,
      Value<int> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ExpenseRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseRecordsTable> {
  $$ExpenseRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpenseRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseRecordsTable> {
  $$ExpenseRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpenseRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseRecordsTable> {
  $$ExpenseRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ExpenseRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseRecordsTable,
          ExpenseRecord,
          $$ExpenseRecordsTableFilterComposer,
          $$ExpenseRecordsTableOrderingComposer,
          $$ExpenseRecordsTableAnnotationComposer,
          $$ExpenseRecordsTableCreateCompanionBuilder,
          $$ExpenseRecordsTableUpdateCompanionBuilder,
          (
            ExpenseRecord,
            BaseReferences<_$AppDatabase, $ExpenseRecordsTable, ExpenseRecord>,
          ),
          ExpenseRecord,
          PrefetchHooks Function()
        > {
  $$ExpenseRecordsTableTableManager(
    _$AppDatabase db,
    $ExpenseRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> category = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> vendorName = const Value.absent(),
                Value<String?> receiptNumber = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<DateTime> expenseDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ExpenseRecordsCompanion(
                id: id,
                serverId: serverId,
                title: title,
                description: description,
                category: category,
                amount: amount,
                paymentMethod: paymentMethod,
                vendorName: vendorName,
                receiptNumber: receiptNumber,
                isRecurring: isRecurring,
                expenseDate: expenseDate,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required int category,
                Value<double> amount = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> vendorName = const Value.absent(),
                Value<String?> receiptNumber = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                required DateTime expenseDate,
                Value<String?> notes = const Value.absent(),
                required int syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ExpenseRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                title: title,
                description: description,
                category: category,
                amount: amount,
                paymentMethod: paymentMethod,
                vendorName: vendorName,
                receiptNumber: receiptNumber,
                isRecurring: isRecurring,
                expenseDate: expenseDate,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpenseRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseRecordsTable,
      ExpenseRecord,
      $$ExpenseRecordsTableFilterComposer,
      $$ExpenseRecordsTableOrderingComposer,
      $$ExpenseRecordsTableAnnotationComposer,
      $$ExpenseRecordsTableCreateCompanionBuilder,
      $$ExpenseRecordsTableUpdateCompanionBuilder,
      (
        ExpenseRecord,
        BaseReferences<_$AppDatabase, $ExpenseRecordsTable, ExpenseRecord>,
      ),
      ExpenseRecord,
      PrefetchHooks Function()
    >;
typedef $$ShopImageRecordsTableCreateCompanionBuilder =
    ShopImageRecordsCompanion Function({
      Value<int> id,
      required String userId,
      Value<String?> shopLogoBase64,
      Value<String?> signatureBase64,
      Value<String?> qrCodeBase64,
      Value<DateTime?> lastSyncedAt,
      required DateTime updatedAt,
    });
typedef $$ShopImageRecordsTableUpdateCompanionBuilder =
    ShopImageRecordsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String?> shopLogoBase64,
      Value<String?> signatureBase64,
      Value<String?> qrCodeBase64,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime> updatedAt,
    });

class $$ShopImageRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ShopImageRecordsTable> {
  $$ShopImageRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopLogoBase64 => $composableBuilder(
    column: $table.shopLogoBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signatureBase64 => $composableBuilder(
    column: $table.signatureBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrCodeBase64 => $composableBuilder(
    column: $table.qrCodeBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShopImageRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShopImageRecordsTable> {
  $$ShopImageRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopLogoBase64 => $composableBuilder(
    column: $table.shopLogoBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signatureBase64 => $composableBuilder(
    column: $table.signatureBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrCodeBase64 => $composableBuilder(
    column: $table.qrCodeBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShopImageRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShopImageRecordsTable> {
  $$ShopImageRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get shopLogoBase64 => $composableBuilder(
    column: $table.shopLogoBase64,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signatureBase64 => $composableBuilder(
    column: $table.signatureBase64,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qrCodeBase64 => $composableBuilder(
    column: $table.qrCodeBase64,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ShopImageRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShopImageRecordsTable,
          ShopImageRecord,
          $$ShopImageRecordsTableFilterComposer,
          $$ShopImageRecordsTableOrderingComposer,
          $$ShopImageRecordsTableAnnotationComposer,
          $$ShopImageRecordsTableCreateCompanionBuilder,
          $$ShopImageRecordsTableUpdateCompanionBuilder,
          (
            ShopImageRecord,
            BaseReferences<
              _$AppDatabase,
              $ShopImageRecordsTable,
              ShopImageRecord
            >,
          ),
          ShopImageRecord,
          PrefetchHooks Function()
        > {
  $$ShopImageRecordsTableTableManager(
    _$AppDatabase db,
    $ShopImageRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShopImageRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShopImageRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShopImageRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> shopLogoBase64 = const Value.absent(),
                Value<String?> signatureBase64 = const Value.absent(),
                Value<String?> qrCodeBase64 = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ShopImageRecordsCompanion(
                id: id,
                userId: userId,
                shopLogoBase64: shopLogoBase64,
                signatureBase64: signatureBase64,
                qrCodeBase64: qrCodeBase64,
                lastSyncedAt: lastSyncedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                Value<String?> shopLogoBase64 = const Value.absent(),
                Value<String?> signatureBase64 = const Value.absent(),
                Value<String?> qrCodeBase64 = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                required DateTime updatedAt,
              }) => ShopImageRecordsCompanion.insert(
                id: id,
                userId: userId,
                shopLogoBase64: shopLogoBase64,
                signatureBase64: signatureBase64,
                qrCodeBase64: qrCodeBase64,
                lastSyncedAt: lastSyncedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShopImageRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShopImageRecordsTable,
      ShopImageRecord,
      $$ShopImageRecordsTableFilterComposer,
      $$ShopImageRecordsTableOrderingComposer,
      $$ShopImageRecordsTableAnnotationComposer,
      $$ShopImageRecordsTableCreateCompanionBuilder,
      $$ShopImageRecordsTableUpdateCompanionBuilder,
      (
        ShopImageRecord,
        BaseReferences<_$AppDatabase, $ShopImageRecordsTable, ShopImageRecord>,
      ),
      ShopImageRecord,
      PrefetchHooks Function()
    >;
typedef $$CustomerTransactionRecordsTableCreateCompanionBuilder =
    CustomerTransactionRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String customerId,
      Value<String> customerName,
      required int transactionType,
      Value<double> amount,
      Value<double> balanceAfter,
      Value<String?> referenceId,
      Value<String?> referenceType,
      Value<String?> description,
      Value<String?> paymentMethod,
      required DateTime transactionDate,
      required int syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$CustomerTransactionRecordsTableUpdateCompanionBuilder =
    CustomerTransactionRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> customerId,
      Value<String> customerName,
      Value<int> transactionType,
      Value<double> amount,
      Value<double> balanceAfter,
      Value<String?> referenceId,
      Value<String?> referenceType,
      Value<String?> description,
      Value<String?> paymentMethod,
      Value<DateTime> transactionDate,
      Value<int> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CustomerTransactionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerTransactionRecordsTable> {
  $$CustomerTransactionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomerTransactionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerTransactionRecordsTable> {
  $$CustomerTransactionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomerTransactionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerTransactionRecordsTable> {
  $$CustomerTransactionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomerTransactionRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerTransactionRecordsTable,
          CustomerTransactionRecord,
          $$CustomerTransactionRecordsTableFilterComposer,
          $$CustomerTransactionRecordsTableOrderingComposer,
          $$CustomerTransactionRecordsTableAnnotationComposer,
          $$CustomerTransactionRecordsTableCreateCompanionBuilder,
          $$CustomerTransactionRecordsTableUpdateCompanionBuilder,
          (
            CustomerTransactionRecord,
            BaseReferences<
              _$AppDatabase,
              $CustomerTransactionRecordsTable,
              CustomerTransactionRecord
            >,
          ),
          CustomerTransactionRecord,
          PrefetchHooks Function()
        > {
  $$CustomerTransactionRecordsTableTableManager(
    _$AppDatabase db,
    $CustomerTransactionRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerTransactionRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CustomerTransactionRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomerTransactionRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<int> transactionType = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double> balanceAfter = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String?> referenceType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CustomerTransactionRecordsCompanion(
                id: id,
                serverId: serverId,
                customerId: customerId,
                customerName: customerName,
                transactionType: transactionType,
                amount: amount,
                balanceAfter: balanceAfter,
                referenceId: referenceId,
                referenceType: referenceType,
                description: description,
                paymentMethod: paymentMethod,
                transactionDate: transactionDate,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String customerId,
                Value<String> customerName = const Value.absent(),
                required int transactionType,
                Value<double> amount = const Value.absent(),
                Value<double> balanceAfter = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String?> referenceType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                required DateTime transactionDate,
                required int syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CustomerTransactionRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                customerId: customerId,
                customerName: customerName,
                transactionType: transactionType,
                amount: amount,
                balanceAfter: balanceAfter,
                referenceId: referenceId,
                referenceType: referenceType,
                description: description,
                paymentMethod: paymentMethod,
                transactionDate: transactionDate,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomerTransactionRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerTransactionRecordsTable,
      CustomerTransactionRecord,
      $$CustomerTransactionRecordsTableFilterComposer,
      $$CustomerTransactionRecordsTableOrderingComposer,
      $$CustomerTransactionRecordsTableAnnotationComposer,
      $$CustomerTransactionRecordsTableCreateCompanionBuilder,
      $$CustomerTransactionRecordsTableUpdateCompanionBuilder,
      (
        CustomerTransactionRecord,
        BaseReferences<
          _$AppDatabase,
          $CustomerTransactionRecordsTable,
          CustomerTransactionRecord
        >,
      ),
      CustomerTransactionRecord,
      PrefetchHooks Function()
    >;
typedef $$EmployeeRecordsTableCreateCompanionBuilder =
    EmployeeRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String email,
      required String displayName,
      Value<String?> phone,
      Value<String?> counterLabel,
      Value<int> tokenNumber,
      Value<bool> counterAccess,
      Value<double> points,
      Value<DateTime?> dateOfBirth,
      Value<String?> address,
      Value<String?> pinCode,
      Value<String?> govIdNumber,
      Value<String?> govIdType,
      Value<double?> salary,
      Value<DateTime?> dateOfJoining,
      Value<String> allowedModulesJson,
      Value<bool> active,
      Value<int> syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$EmployeeRecordsTableUpdateCompanionBuilder =
    EmployeeRecordsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> email,
      Value<String> displayName,
      Value<String?> phone,
      Value<String?> counterLabel,
      Value<int> tokenNumber,
      Value<bool> counterAccess,
      Value<double> points,
      Value<DateTime?> dateOfBirth,
      Value<String?> address,
      Value<String?> pinCode,
      Value<String?> govIdNumber,
      Value<String?> govIdType,
      Value<double?> salary,
      Value<DateTime?> dateOfJoining,
      Value<String> allowedModulesJson,
      Value<bool> active,
      Value<int> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$EmployeeRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeeRecordsTable> {
  $$EmployeeRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterLabel => $composableBuilder(
    column: $table.counterLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokenNumber => $composableBuilder(
    column: $table.tokenNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get counterAccess => $composableBuilder(
    column: $table.counterAccess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get govIdNumber => $composableBuilder(
    column: $table.govIdNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get govIdType => $composableBuilder(
    column: $table.govIdType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salary => $composableBuilder(
    column: $table.salary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateOfJoining => $composableBuilder(
    column: $table.dateOfJoining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allowedModulesJson => $composableBuilder(
    column: $table.allowedModulesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmployeeRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeeRecordsTable> {
  $$EmployeeRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterLabel => $composableBuilder(
    column: $table.counterLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokenNumber => $composableBuilder(
    column: $table.tokenNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get counterAccess => $composableBuilder(
    column: $table.counterAccess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get govIdNumber => $composableBuilder(
    column: $table.govIdNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get govIdType => $composableBuilder(
    column: $table.govIdType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salary => $composableBuilder(
    column: $table.salary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateOfJoining => $composableBuilder(
    column: $table.dateOfJoining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allowedModulesJson => $composableBuilder(
    column: $table.allowedModulesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmployeeRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeeRecordsTable> {
  $$EmployeeRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get counterLabel => $composableBuilder(
    column: $table.counterLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokenNumber => $composableBuilder(
    column: $table.tokenNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get counterAccess => $composableBuilder(
    column: $table.counterAccess,
    builder: (column) => column,
  );

  GeneratedColumn<double> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get pinCode =>
      $composableBuilder(column: $table.pinCode, builder: (column) => column);

  GeneratedColumn<String> get govIdNumber => $composableBuilder(
    column: $table.govIdNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get govIdType =>
      $composableBuilder(column: $table.govIdType, builder: (column) => column);

  GeneratedColumn<double> get salary =>
      $composableBuilder(column: $table.salary, builder: (column) => column);

  GeneratedColumn<DateTime> get dateOfJoining => $composableBuilder(
    column: $table.dateOfJoining,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allowedModulesJson => $composableBuilder(
    column: $table.allowedModulesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EmployeeRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployeeRecordsTable,
          EmployeeRecord,
          $$EmployeeRecordsTableFilterComposer,
          $$EmployeeRecordsTableOrderingComposer,
          $$EmployeeRecordsTableAnnotationComposer,
          $$EmployeeRecordsTableCreateCompanionBuilder,
          $$EmployeeRecordsTableUpdateCompanionBuilder,
          (
            EmployeeRecord,
            BaseReferences<
              _$AppDatabase,
              $EmployeeRecordsTable,
              EmployeeRecord
            >,
          ),
          EmployeeRecord,
          PrefetchHooks Function()
        > {
  $$EmployeeRecordsTableTableManager(
    _$AppDatabase db,
    $EmployeeRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeeRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeeRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeeRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> counterLabel = const Value.absent(),
                Value<int> tokenNumber = const Value.absent(),
                Value<bool> counterAccess = const Value.absent(),
                Value<double> points = const Value.absent(),
                Value<DateTime?> dateOfBirth = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<String?> govIdNumber = const Value.absent(),
                Value<String?> govIdType = const Value.absent(),
                Value<double?> salary = const Value.absent(),
                Value<DateTime?> dateOfJoining = const Value.absent(),
                Value<String> allowedModulesJson = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EmployeeRecordsCompanion(
                id: id,
                serverId: serverId,
                email: email,
                displayName: displayName,
                phone: phone,
                counterLabel: counterLabel,
                tokenNumber: tokenNumber,
                counterAccess: counterAccess,
                points: points,
                dateOfBirth: dateOfBirth,
                address: address,
                pinCode: pinCode,
                govIdNumber: govIdNumber,
                govIdType: govIdType,
                salary: salary,
                dateOfJoining: dateOfJoining,
                allowedModulesJson: allowedModulesJson,
                active: active,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String email,
                required String displayName,
                Value<String?> phone = const Value.absent(),
                Value<String?> counterLabel = const Value.absent(),
                Value<int> tokenNumber = const Value.absent(),
                Value<bool> counterAccess = const Value.absent(),
                Value<double> points = const Value.absent(),
                Value<DateTime?> dateOfBirth = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<String?> govIdNumber = const Value.absent(),
                Value<String?> govIdType = const Value.absent(),
                Value<double?> salary = const Value.absent(),
                Value<DateTime?> dateOfJoining = const Value.absent(),
                Value<String> allowedModulesJson = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => EmployeeRecordsCompanion.insert(
                id: id,
                serverId: serverId,
                email: email,
                displayName: displayName,
                phone: phone,
                counterLabel: counterLabel,
                tokenNumber: tokenNumber,
                counterAccess: counterAccess,
                points: points,
                dateOfBirth: dateOfBirth,
                address: address,
                pinCode: pinCode,
                govIdNumber: govIdNumber,
                govIdType: govIdType,
                salary: salary,
                dateOfJoining: dateOfJoining,
                allowedModulesJson: allowedModulesJson,
                active: active,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmployeeRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployeeRecordsTable,
      EmployeeRecord,
      $$EmployeeRecordsTableFilterComposer,
      $$EmployeeRecordsTableOrderingComposer,
      $$EmployeeRecordsTableAnnotationComposer,
      $$EmployeeRecordsTableCreateCompanionBuilder,
      $$EmployeeRecordsTableUpdateCompanionBuilder,
      (
        EmployeeRecord,
        BaseReferences<_$AppDatabase, $EmployeeRecordsTable, EmployeeRecord>,
      ),
      EmployeeRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CompanyRecordsTableTableManager get companyRecords =>
      $$CompanyRecordsTableTableManager(_db, _db.companyRecords);
  $$CustomerRecordsTableTableManager get customerRecords =>
      $$CustomerRecordsTableTableManager(_db, _db.customerRecords);
  $$SupplierRecordsTableTableManager get supplierRecords =>
      $$SupplierRecordsTableTableManager(_db, _db.supplierRecords);
  $$ProductRecordsTableTableManager get productRecords =>
      $$ProductRecordsTableTableManager(_db, _db.productRecords);
  $$PurchaseRecordsTableTableManager get purchaseRecords =>
      $$PurchaseRecordsTableTableManager(_db, _db.purchaseRecords);
  $$PurchaseBatchRecordsTableTableManager get purchaseBatchRecords =>
      $$PurchaseBatchRecordsTableTableManager(_db, _db.purchaseBatchRecords);
  $$StockLedgerRecordsTableTableManager get stockLedgerRecords =>
      $$StockLedgerRecordsTableTableManager(_db, _db.stockLedgerRecords);
  $$BillRecordsTableTableManager get billRecords =>
      $$BillRecordsTableTableManager(_db, _db.billRecords);
  $$EventOrderRecordsTableTableManager get eventOrderRecords =>
      $$EventOrderRecordsTableTableManager(_db, _db.eventOrderRecords);
  $$QuotationRecordsTableTableManager get quotationRecords =>
      $$QuotationRecordsTableTableManager(_db, _db.quotationRecords);
  $$ExpenseRecordsTableTableManager get expenseRecords =>
      $$ExpenseRecordsTableTableManager(_db, _db.expenseRecords);
  $$ShopImageRecordsTableTableManager get shopImageRecords =>
      $$ShopImageRecordsTableTableManager(_db, _db.shopImageRecords);
  $$CustomerTransactionRecordsTableTableManager
  get customerTransactionRecords =>
      $$CustomerTransactionRecordsTableTableManager(
        _db,
        _db.customerTransactionRecords,
      );
  $$EmployeeRecordsTableTableManager get employeeRecords =>
      $$EmployeeRecordsTableTableManager(_db, _db.employeeRecords);
}
