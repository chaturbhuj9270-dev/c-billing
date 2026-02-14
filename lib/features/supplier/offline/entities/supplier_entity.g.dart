// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSupplierEntityCollection on Isar {
  IsarCollection<SupplierEntity> get supplierEntitys => this.collection();
}

const SupplierEntitySchema = CollectionSchema(
  name: r'SupplierEntity',
  id: 8149616736059475209,
  properties: {
    r'address': PropertySchema(id: 0, name: r'address', type: IsarType.string),
    r'contact': PropertySchema(id: 1, name: r'contact', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'firstName': PropertySchema(
      id: 3,
      name: r'firstName',
      type: IsarType.string,
    ),
    r'fullName': PropertySchema(
      id: 4,
      name: r'fullName',
      type: IsarType.string,
    ),
    r'isActive': PropertySchema(id: 5, name: r'isActive', type: IsarType.bool),
    r'isMarkedForDeletion': PropertySchema(
      id: 6,
      name: r'isMarkedForDeletion',
      type: IsarType.bool,
    ),
    r'lastName': PropertySchema(
      id: 7,
      name: r'lastName',
      type: IsarType.string,
    ),
    r'middleName': PropertySchema(
      id: 8,
      name: r'middleName',
      type: IsarType.string,
    ),
    r'needsSync': PropertySchema(
      id: 9,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'serverId': PropertySchema(
      id: 10,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'supplierCode': PropertySchema(
      id: 11,
      name: r'supplierCode',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 12,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _SupplierEntitysyncStatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _supplierEntityEstimateSize,
  serialize: _supplierEntitySerialize,
  deserialize: _supplierEntityDeserialize,
  deserializeProp: _supplierEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'firstName': IndexSchema(
      id: -2537032818573098835,
      name: r'firstName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'firstName',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'supplierCode': IndexSchema(
      id: -6908271452855759711,
      name: r'supplierCode',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'supplierCode',
          type: IndexType.hash,
          caseSensitive: false,
        ),
      ],
    ),
    r'contact': IndexSchema(
      id: 213978983763356937,
      name: r'contact',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'contact',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'syncStatus': IndexSchema(
      id: 8239539375045684509,
      name: r'syncStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncStatus',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _supplierEntityGetId,
  getLinks: _supplierEntityGetLinks,
  attach: _supplierEntityAttach,
  version: '3.3.0',
);

int _supplierEntityEstimateSize(
  SupplierEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.address.length * 3;
  bytesCount += 3 + object.contact.length * 3;
  bytesCount += 3 + object.firstName.length * 3;
  bytesCount += 3 + object.fullName.length * 3;
  bytesCount += 3 + object.lastName.length * 3;
  bytesCount += 3 + object.middleName.length * 3;
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.supplierCode.length * 3;
  return bytesCount;
}

void _supplierEntitySerialize(
  SupplierEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeString(offsets[1], object.contact);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.firstName);
  writer.writeString(offsets[4], object.fullName);
  writer.writeBool(offsets[5], object.isActive);
  writer.writeBool(offsets[6], object.isMarkedForDeletion);
  writer.writeString(offsets[7], object.lastName);
  writer.writeString(offsets[8], object.middleName);
  writer.writeBool(offsets[9], object.needsSync);
  writer.writeString(offsets[10], object.serverId);
  writer.writeString(offsets[11], object.supplierCode);
  writer.writeByte(offsets[12], object.syncStatus.index);
  writer.writeDateTime(offsets[13], object.updatedAt);
}

SupplierEntity _supplierEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SupplierEntity(
    address: reader.readStringOrNull(offsets[0]) ?? '',
    contact: reader.readString(offsets[1]),
    createdAt: reader.readDateTime(offsets[2]),
    firstName: reader.readString(offsets[3]),
    isActive: reader.readBoolOrNull(offsets[5]) ?? true,
    lastName: reader.readStringOrNull(offsets[7]) ?? '',
    middleName: reader.readStringOrNull(offsets[8]) ?? '',
    serverId: reader.readStringOrNull(offsets[10]),
    supplierCode: reader.readString(offsets[11]),
    syncStatus:
        _SupplierEntitysyncStatusValueEnumMap[reader.readByteOrNull(
          offsets[12],
        )] ??
        SupplierSyncStatus.newRecord,
    updatedAt: reader.readDateTime(offsets[13]),
  );
  object.id = id;
  return object;
}

P _supplierEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 8:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (_SupplierEntitysyncStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              SupplierSyncStatus.newRecord)
          as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SupplierEntitysyncStatusEnumValueMap = {
  'newRecord': 0,
  'updated': 1,
  'deleted': 2,
  'synced': 3,
};
const _SupplierEntitysyncStatusValueEnumMap = {
  0: SupplierSyncStatus.newRecord,
  1: SupplierSyncStatus.updated,
  2: SupplierSyncStatus.deleted,
  3: SupplierSyncStatus.synced,
};

Id _supplierEntityGetId(SupplierEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _supplierEntityGetLinks(SupplierEntity object) {
  return [];
}

void _supplierEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  SupplierEntity object,
) {
  object.id = id;
}

extension SupplierEntityByIndex on IsarCollection<SupplierEntity> {
  Future<SupplierEntity?> getBySupplierCode(String supplierCode) {
    return getByIndex(r'supplierCode', [supplierCode]);
  }

  SupplierEntity? getBySupplierCodeSync(String supplierCode) {
    return getByIndexSync(r'supplierCode', [supplierCode]);
  }

  Future<bool> deleteBySupplierCode(String supplierCode) {
    return deleteByIndex(r'supplierCode', [supplierCode]);
  }

  bool deleteBySupplierCodeSync(String supplierCode) {
    return deleteByIndexSync(r'supplierCode', [supplierCode]);
  }

  Future<List<SupplierEntity?>> getAllBySupplierCode(
    List<String> supplierCodeValues,
  ) {
    final values = supplierCodeValues.map((e) => [e]).toList();
    return getAllByIndex(r'supplierCode', values);
  }

  List<SupplierEntity?> getAllBySupplierCodeSync(
    List<String> supplierCodeValues,
  ) {
    final values = supplierCodeValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'supplierCode', values);
  }

  Future<int> deleteAllBySupplierCode(List<String> supplierCodeValues) {
    final values = supplierCodeValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'supplierCode', values);
  }

  int deleteAllBySupplierCodeSync(List<String> supplierCodeValues) {
    final values = supplierCodeValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'supplierCode', values);
  }

  Future<Id> putBySupplierCode(SupplierEntity object) {
    return putByIndex(r'supplierCode', object);
  }

  Id putBySupplierCodeSync(SupplierEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'supplierCode', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySupplierCode(List<SupplierEntity> objects) {
    return putAllByIndex(r'supplierCode', objects);
  }

  List<Id> putAllBySupplierCodeSync(
    List<SupplierEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'supplierCode', objects, saveLinks: saveLinks);
  }
}

extension SupplierEntityQueryWhereSort
    on QueryBuilder<SupplierEntity, SupplierEntity, QWhere> {
  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhere> anyFirstName() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'firstName'),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhere> anySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncStatus'),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension SupplierEntityQueryWhere
    on QueryBuilder<SupplierEntity, SupplierEntity, QWhereClause> {
  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [null]),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'serverId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  serverIdEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [serverId]),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  serverIdNotEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'serverId',
                lower: [],
                upper: [serverId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'serverId',
                lower: [serverId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'serverId',
                lower: [serverId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'serverId',
                lower: [],
                upper: [serverId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  firstNameEqualTo(String firstName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'firstName', value: [firstName]),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  firstNameNotEqualTo(String firstName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'firstName',
                lower: [],
                upper: [firstName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'firstName',
                lower: [firstName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'firstName',
                lower: [firstName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'firstName',
                lower: [],
                upper: [firstName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  firstNameGreaterThan(String firstName, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'firstName',
          lower: [firstName],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  firstNameLessThan(String firstName, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'firstName',
          lower: [],
          upper: [firstName],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  firstNameBetween(
    String lowerFirstName,
    String upperFirstName, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'firstName',
          lower: [lowerFirstName],
          includeLower: includeLower,
          upper: [upperFirstName],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  firstNameStartsWith(String FirstNamePrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'firstName',
          lower: [FirstNamePrefix],
          upper: ['$FirstNamePrefix\u{FFFFF}'],
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  firstNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'firstName', value: ['']),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  firstNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'firstName', upper: ['']),
            )
            .addWhereClause(
              IndexWhereClause.greaterThan(
                indexName: r'firstName',
                lower: [''],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.greaterThan(
                indexName: r'firstName',
                lower: [''],
              ),
            )
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'firstName', upper: ['']),
            );
      }
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  supplierCodeEqualTo(String supplierCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'supplierCode',
          value: [supplierCode],
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  supplierCodeNotEqualTo(String supplierCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'supplierCode',
                lower: [],
                upper: [supplierCode],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'supplierCode',
                lower: [supplierCode],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'supplierCode',
                lower: [supplierCode],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'supplierCode',
                lower: [],
                upper: [supplierCode],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  contactEqualTo(String contact) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'contact', value: [contact]),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  contactNotEqualTo(String contact) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contact',
                lower: [],
                upper: [contact],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contact',
                lower: [contact],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contact',
                lower: [contact],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contact',
                lower: [],
                upper: [contact],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  syncStatusEqualTo(SupplierSyncStatus syncStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'syncStatus', value: [syncStatus]),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  syncStatusNotEqualTo(SupplierSyncStatus syncStatus) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncStatus',
                lower: [],
                upper: [syncStatus],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncStatus',
                lower: [syncStatus],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncStatus',
                lower: [syncStatus],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncStatus',
                lower: [],
                upper: [syncStatus],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  syncStatusGreaterThan(SupplierSyncStatus syncStatus, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'syncStatus',
          lower: [syncStatus],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  syncStatusLessThan(SupplierSyncStatus syncStatus, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'syncStatus',
          lower: [],
          upper: [syncStatus],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  syncStatusBetween(
    SupplierSyncStatus lowerSyncStatus,
    SupplierSyncStatus upperSyncStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'syncStatus',
          lower: [lowerSyncStatus],
          includeLower: includeLower,
          upper: [upperSyncStatus],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  updatedAtEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'updatedAt', value: [updatedAt]),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  updatedAtNotEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  updatedAtGreaterThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [updatedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  updatedAtLessThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [],
          upper: [updatedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterWhereClause>
  updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [lowerUpdatedAt],
          includeLower: includeLower,
          upper: [upperUpdatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SupplierEntityQueryFilter
    on QueryBuilder<SupplierEntity, SupplierEntity, QFilterCondition> {
  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'address',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'address',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contact',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contact',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contact', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  contactIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contact', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'firstName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'firstName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'firstName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'firstName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'firstName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'firstName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'firstName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'firstName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'firstName', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  firstNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'firstName', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fullName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fullName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fullName', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  fullNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fullName', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isActive', value: value),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  isMarkedForDeletionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isMarkedForDeletion', value: value),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastName', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  lastNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastName', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'middleName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'middleName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'middleName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'middleName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'middleName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'middleName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'middleName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'middleName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'middleName', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  middleNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'middleName', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'needsSync', value: value),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serverId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'serverId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'supplierCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'supplierCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'supplierCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'supplierCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'supplierCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'supplierCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'supplierCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'supplierCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'supplierCode', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  supplierCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'supplierCode', value: ''),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  syncStatusEqualTo(SupplierSyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  syncStatusGreaterThan(SupplierSyncStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  syncStatusLessThan(SupplierSyncStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  syncStatusBetween(
    SupplierSyncStatus lower,
    SupplierSyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SupplierEntityQueryObject
    on QueryBuilder<SupplierEntity, SupplierEntity, QFilterCondition> {}

extension SupplierEntityQueryLinks
    on QueryBuilder<SupplierEntity, SupplierEntity, QFilterCondition> {}

extension SupplierEntityQuerySortBy
    on QueryBuilder<SupplierEntity, SupplierEntity, QSortBy> {
  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contact', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contact', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByFirstName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstName', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByFirstNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstName', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByFullName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByFullNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByLastName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastName', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByLastNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastName', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByMiddleName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'middleName', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByMiddleNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'middleName', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortBySupplierCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierCode', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortBySupplierCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierCode', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SupplierEntityQuerySortThenBy
    on QueryBuilder<SupplierEntity, SupplierEntity, QSortThenBy> {
  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contact', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contact', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByFirstName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstName', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByFirstNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstName', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByFullName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByFullNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByLastName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastName', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByLastNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastName', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByMiddleName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'middleName', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByMiddleNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'middleName', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenBySupplierCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierCode', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenBySupplierCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierCode', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SupplierEntityQueryWhereDistinct
    on QueryBuilder<SupplierEntity, SupplierEntity, QDistinct> {
  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct> distinctByAddress({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct> distinctByContact({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contact', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct> distinctByFirstName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct> distinctByFullName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fullName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct>
  distinctByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct> distinctByLastName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct> distinctByMiddleName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'middleName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct>
  distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct> distinctByServerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct>
  distinctBySupplierCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct>
  distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<SupplierEntity, SupplierEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SupplierEntityQueryProperty
    on QueryBuilder<SupplierEntity, SupplierEntity, QQueryProperty> {
  QueryBuilder<SupplierEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SupplierEntity, String, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<SupplierEntity, String, QQueryOperations> contactProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contact');
    });
  }

  QueryBuilder<SupplierEntity, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SupplierEntity, String, QQueryOperations> firstNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstName');
    });
  }

  QueryBuilder<SupplierEntity, String, QQueryOperations> fullNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fullName');
    });
  }

  QueryBuilder<SupplierEntity, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<SupplierEntity, bool, QQueryOperations>
  isMarkedForDeletionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<SupplierEntity, String, QQueryOperations> lastNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastName');
    });
  }

  QueryBuilder<SupplierEntity, String, QQueryOperations> middleNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'middleName');
    });
  }

  QueryBuilder<SupplierEntity, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<SupplierEntity, String?, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<SupplierEntity, String, QQueryOperations>
  supplierCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierCode');
    });
  }

  QueryBuilder<SupplierEntity, SupplierSyncStatus, QQueryOperations>
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<SupplierEntity, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
