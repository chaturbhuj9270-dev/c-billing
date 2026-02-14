// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_batch_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPurchaseBatchEntityCollection on Isar {
  IsarCollection<PurchaseBatchEntity> get purchaseBatchEntitys =>
      this.collection();
}

const PurchaseBatchEntitySchema = CollectionSchema(
  name: r'PurchaseBatchEntity',
  id: -3691434164641764836,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'companyName': PropertySchema(
      id: 1,
      name: r'companyName',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'expiryDate': PropertySchema(
      id: 3,
      name: r'expiryDate',
      type: IsarType.dateTime,
    ),
    r'hasStock': PropertySchema(id: 4, name: r'hasStock', type: IsarType.bool),
    r'isConsumed': PropertySchema(
      id: 5,
      name: r'isConsumed',
      type: IsarType.bool,
    ),
    r'isMarkedForDeletion': PropertySchema(
      id: 6,
      name: r'isMarkedForDeletion',
      type: IsarType.bool,
    ),
    r'modelName': PropertySchema(
      id: 7,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'needsSync': PropertySchema(
      id: 8,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(id: 9, name: r'notes', type: IsarType.string),
    r'productId': PropertySchema(
      id: 10,
      name: r'productId',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 11,
      name: r'productName',
      type: IsarType.string,
    ),
    r'productUniqueKey': PropertySchema(
      id: 12,
      name: r'productUniqueKey',
      type: IsarType.string,
    ),
    r'productionDate': PropertySchema(
      id: 13,
      name: r'productionDate',
      type: IsarType.dateTime,
    ),
    r'purchaseDate': PropertySchema(
      id: 14,
      name: r'purchaseDate',
      type: IsarType.dateTime,
    ),
    r'purchasePrice': PropertySchema(
      id: 15,
      name: r'purchasePrice',
      type: IsarType.double,
    ),
    r'quantityPurchased': PropertySchema(
      id: 16,
      name: r'quantityPurchased',
      type: IsarType.long,
    ),
    r'quantityRemaining': PropertySchema(
      id: 17,
      name: r'quantityRemaining',
      type: IsarType.long,
    ),
    r'sellingPrice': PropertySchema(
      id: 18,
      name: r'sellingPrice',
      type: IsarType.double,
    ),
    r'serverId': PropertySchema(
      id: 19,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'supplierId': PropertySchema(
      id: 20,
      name: r'supplierId',
      type: IsarType.string,
    ),
    r'supplierName': PropertySchema(
      id: 21,
      name: r'supplierName',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 22,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _PurchaseBatchEntitysyncStatusEnumValueMap,
    ),
    r'unit': PropertySchema(id: 23, name: r'unit', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 24,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'warrantyMonths': PropertySchema(
      id: 25,
      name: r'warrantyMonths',
      type: IsarType.long,
    ),
  },

  estimateSize: _purchaseBatchEntityEstimateSize,
  serialize: _purchaseBatchEntitySerialize,
  deserialize: _purchaseBatchEntityDeserialize,
  deserializeProp: _purchaseBatchEntityDeserializeProp,
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
    r'productId': IndexSchema(
      id: 5580769080710688203,
      name: r'productId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'productId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'companyName': IndexSchema(
      id: 6530936739720993813,
      name: r'companyName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'companyName',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'productUniqueKey': IndexSchema(
      id: 2650035106637530557,
      name: r'productUniqueKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'productUniqueKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'purchaseDate': IndexSchema(
      id: 1174684625301313566,
      name: r'purchaseDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'purchaseDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'supplierId': IndexSchema(
      id: -7509772217447508349,
      name: r'supplierId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'supplierId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'expiryDate': IndexSchema(
      id: -1636839555668080254,
      name: r'expiryDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'expiryDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'isConsumed': IndexSchema(
      id: 1265324810271792707,
      name: r'isConsumed',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isConsumed',
          type: IndexType.value,
          caseSensitive: false,
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
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _purchaseBatchEntityGetId,
  getLinks: _purchaseBatchEntityGetLinks,
  attach: _purchaseBatchEntityAttach,
  version: '3.3.0',
);

int _purchaseBatchEntityEstimateSize(
  PurchaseBatchEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.companyName.length * 3;
  bytesCount += 3 + object.modelName.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.productId.length * 3;
  bytesCount += 3 + object.productName.length * 3;
  bytesCount += 3 + object.productUniqueKey.length * 3;
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.supplierId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.supplierName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.unit.length * 3;
  return bytesCount;
}

void _purchaseBatchEntitySerialize(
  PurchaseBatchEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.companyName);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDateTime(offsets[3], object.expiryDate);
  writer.writeBool(offsets[4], object.hasStock);
  writer.writeBool(offsets[5], object.isConsumed);
  writer.writeBool(offsets[6], object.isMarkedForDeletion);
  writer.writeString(offsets[7], object.modelName);
  writer.writeBool(offsets[8], object.needsSync);
  writer.writeString(offsets[9], object.notes);
  writer.writeString(offsets[10], object.productId);
  writer.writeString(offsets[11], object.productName);
  writer.writeString(offsets[12], object.productUniqueKey);
  writer.writeDateTime(offsets[13], object.productionDate);
  writer.writeDateTime(offsets[14], object.purchaseDate);
  writer.writeDouble(offsets[15], object.purchasePrice);
  writer.writeLong(offsets[16], object.quantityPurchased);
  writer.writeLong(offsets[17], object.quantityRemaining);
  writer.writeDouble(offsets[18], object.sellingPrice);
  writer.writeString(offsets[19], object.serverId);
  writer.writeString(offsets[20], object.supplierId);
  writer.writeString(offsets[21], object.supplierName);
  writer.writeByte(offsets[22], object.syncStatus.index);
  writer.writeString(offsets[23], object.unit);
  writer.writeDateTime(offsets[24], object.updatedAt);
  writer.writeLong(offsets[25], object.warrantyMonths);
}

PurchaseBatchEntity _purchaseBatchEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PurchaseBatchEntity(
    category: reader.readStringOrNull(offsets[0]) ?? '',
    companyName: reader.readString(offsets[1]),
    createdAt: reader.readDateTime(offsets[2]),
    expiryDate: reader.readDateTimeOrNull(offsets[3]),
    isConsumed: reader.readBoolOrNull(offsets[5]) ?? false,
    modelName: reader.readStringOrNull(offsets[7]) ?? '',
    notes: reader.readStringOrNull(offsets[9]),
    productId: reader.readString(offsets[10]),
    productName: reader.readString(offsets[11]),
    productUniqueKey: reader.readString(offsets[12]),
    productionDate: reader.readDateTimeOrNull(offsets[13]),
    purchaseDate: reader.readDateTime(offsets[14]),
    purchasePrice: reader.readDouble(offsets[15]),
    quantityPurchased: reader.readLong(offsets[16]),
    quantityRemaining: reader.readLong(offsets[17]),
    sellingPrice: reader.readDouble(offsets[18]),
    serverId: reader.readStringOrNull(offsets[19]),
    supplierId: reader.readStringOrNull(offsets[20]),
    supplierName: reader.readStringOrNull(offsets[21]),
    syncStatus:
        _PurchaseBatchEntitysyncStatusValueEnumMap[reader.readByteOrNull(
          offsets[22],
        )] ??
        BatchSyncStatus.newRecord,
    unit: reader.readStringOrNull(offsets[23]) ?? 'pcs',
    updatedAt: reader.readDateTime(offsets[24]),
    warrantyMonths: reader.readLongOrNull(offsets[25]),
  );
  object.id = id;
  return object;
}

P _purchaseBatchEntityDeserializeProp<P>(
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
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (_PurchaseBatchEntitysyncStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              BatchSyncStatus.newRecord)
          as P;
    case 23:
      return (reader.readStringOrNull(offset) ?? 'pcs') as P;
    case 24:
      return (reader.readDateTime(offset)) as P;
    case 25:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PurchaseBatchEntitysyncStatusEnumValueMap = {
  'newRecord': 0,
  'updated': 1,
  'deleted': 2,
  'synced': 3,
};
const _PurchaseBatchEntitysyncStatusValueEnumMap = {
  0: BatchSyncStatus.newRecord,
  1: BatchSyncStatus.updated,
  2: BatchSyncStatus.deleted,
  3: BatchSyncStatus.synced,
};

Id _purchaseBatchEntityGetId(PurchaseBatchEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _purchaseBatchEntityGetLinks(
  PurchaseBatchEntity object,
) {
  return [];
}

void _purchaseBatchEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  PurchaseBatchEntity object,
) {
  object.id = id;
}

extension PurchaseBatchEntityQueryWhereSort
    on QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QWhere> {
  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhere>
  anyPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'purchaseDate'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhere>
  anyExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'expiryDate'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhere>
  anyIsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isConsumed'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhere>
  anySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncStatus'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhere>
  anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension PurchaseBatchEntityQueryWhere
    on QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QWhereClause> {
  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  idBetween(
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [null]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  serverIdEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [serverId]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  productIdEqualTo(String productId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'productId', value: [productId]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  productIdNotEqualTo(String productId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'productId',
                lower: [],
                upper: [productId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'productId',
                lower: [productId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'productId',
                lower: [productId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'productId',
                lower: [],
                upper: [productId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  companyNameEqualTo(String companyName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'companyName',
          value: [companyName],
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  companyNameNotEqualTo(String companyName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'companyName',
                lower: [],
                upper: [companyName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'companyName',
                lower: [companyName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'companyName',
                lower: [companyName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'companyName',
                lower: [],
                upper: [companyName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  productUniqueKeyEqualTo(String productUniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'productUniqueKey',
          value: [productUniqueKey],
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  productUniqueKeyNotEqualTo(String productUniqueKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'productUniqueKey',
                lower: [],
                upper: [productUniqueKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'productUniqueKey',
                lower: [productUniqueKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'productUniqueKey',
                lower: [productUniqueKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'productUniqueKey',
                lower: [],
                upper: [productUniqueKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  purchaseDateEqualTo(DateTime purchaseDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'purchaseDate',
          value: [purchaseDate],
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  purchaseDateNotEqualTo(DateTime purchaseDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'purchaseDate',
                lower: [],
                upper: [purchaseDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'purchaseDate',
                lower: [purchaseDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'purchaseDate',
                lower: [purchaseDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'purchaseDate',
                lower: [],
                upper: [purchaseDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  purchaseDateGreaterThan(DateTime purchaseDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'purchaseDate',
          lower: [purchaseDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  purchaseDateLessThan(DateTime purchaseDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'purchaseDate',
          lower: [],
          upper: [purchaseDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  purchaseDateBetween(
    DateTime lowerPurchaseDate,
    DateTime upperPurchaseDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'purchaseDate',
          lower: [lowerPurchaseDate],
          includeLower: includeLower,
          upper: [upperPurchaseDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  supplierIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'supplierId', value: [null]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  supplierIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'supplierId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  supplierIdEqualTo(String? supplierId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'supplierId', value: [supplierId]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  supplierIdNotEqualTo(String? supplierId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'supplierId',
                lower: [],
                upper: [supplierId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'supplierId',
                lower: [supplierId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'supplierId',
                lower: [supplierId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'supplierId',
                lower: [],
                upper: [supplierId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  expiryDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'expiryDate', value: [null]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  expiryDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expiryDate',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  expiryDateEqualTo(DateTime? expiryDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'expiryDate', value: [expiryDate]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  expiryDateNotEqualTo(DateTime? expiryDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expiryDate',
                lower: [],
                upper: [expiryDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expiryDate',
                lower: [expiryDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expiryDate',
                lower: [expiryDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expiryDate',
                lower: [],
                upper: [expiryDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  expiryDateGreaterThan(DateTime? expiryDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expiryDate',
          lower: [expiryDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  expiryDateLessThan(DateTime? expiryDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expiryDate',
          lower: [],
          upper: [expiryDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  expiryDateBetween(
    DateTime? lowerExpiryDate,
    DateTime? upperExpiryDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expiryDate',
          lower: [lowerExpiryDate],
          includeLower: includeLower,
          upper: [upperExpiryDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  isConsumedEqualTo(bool isConsumed) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isConsumed', value: [isConsumed]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  isConsumedNotEqualTo(bool isConsumed) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isConsumed',
                lower: [],
                upper: [isConsumed],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isConsumed',
                lower: [isConsumed],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isConsumed',
                lower: [isConsumed],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isConsumed',
                lower: [],
                upper: [isConsumed],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  syncStatusEqualTo(BatchSyncStatus syncStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'syncStatus', value: [syncStatus]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  syncStatusNotEqualTo(BatchSyncStatus syncStatus) {
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  syncStatusGreaterThan(BatchSyncStatus syncStatus, {bool include = false}) {
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  syncStatusLessThan(BatchSyncStatus syncStatus, {bool include = false}) {
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  syncStatusBetween(
    BatchSyncStatus lowerSyncStatus,
    BatchSyncStatus upperSyncStatus, {
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  createdAtGreaterThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [createdAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  createdAtLessThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [],
          upper: [createdAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterWhereClause>
  createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [lowerCreatedAt],
          includeLower: includeLower,
          upper: [upperCreatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PurchaseBatchEntityQueryFilter
    on
        QueryBuilder<
          PurchaseBatchEntity,
          PurchaseBatchEntity,
          QFilterCondition
        > {
  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'companyName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'companyName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'companyName', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  companyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'companyName', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  expiryDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'expiryDate'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  expiryDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'expiryDate'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  expiryDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'expiryDate', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  expiryDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'expiryDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  expiryDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'expiryDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  expiryDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'expiryDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  hasStockEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasStock', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  idBetween(
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  isConsumedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isConsumed', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  isMarkedForDeletionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isMarkedForDeletion', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modelName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'modelName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  modelNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'needsSync', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'notes',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'productId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'productId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'productName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'productName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'productName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'productName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'productName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'productName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'productName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'productName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'productUniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'productUniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'productUniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'productUniqueKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'productUniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'productUniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'productUniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'productUniqueKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productUniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productUniqueKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productUniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productionDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'productionDate'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productionDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'productionDate'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productionDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productionDate', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productionDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'productionDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productionDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'productionDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  productionDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'productionDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  purchaseDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'purchaseDate', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  purchaseDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'purchaseDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  purchaseDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'purchaseDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  purchaseDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'purchaseDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  purchasePriceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'purchasePrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  purchasePriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'purchasePrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  purchasePriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'purchasePrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  purchasePriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'purchasePrice',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  quantityPurchasedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'quantityPurchased', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  quantityPurchasedGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quantityPurchased',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  quantityPurchasedLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quantityPurchased',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  quantityPurchasedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quantityPurchased',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  quantityRemainingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'quantityRemaining', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  quantityRemainingGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quantityRemaining',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  quantityRemainingLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quantityRemaining',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  quantityRemainingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quantityRemaining',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  sellingPriceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sellingPrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  sellingPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sellingPrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  sellingPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sellingPrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  sellingPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sellingPrice',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'supplierId'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'supplierId'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'supplierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'supplierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'supplierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'supplierId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'supplierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'supplierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'supplierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'supplierId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'supplierId', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'supplierId', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'supplierName'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'supplierName'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'supplierName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'supplierName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'supplierName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'supplierName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'supplierName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'supplierName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'supplierName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'supplierName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'supplierName', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  supplierNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'supplierName', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  syncStatusEqualTo(BatchSyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  syncStatusGreaterThan(BatchSyncStatus value, {bool include = false}) {
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  syncStatusLessThan(BatchSyncStatus value, {bool include = false}) {
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  syncStatusBetween(
    BatchSyncStatus lower,
    BatchSyncStatus upper, {
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'unit',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'unit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'unit',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'unit', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  unitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'unit', value: ''),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  warrantyMonthsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'warrantyMonths'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  warrantyMonthsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'warrantyMonths'),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  warrantyMonthsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'warrantyMonths', value: value),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  warrantyMonthsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'warrantyMonths',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  warrantyMonthsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'warrantyMonths',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterFilterCondition>
  warrantyMonthsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'warrantyMonths',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PurchaseBatchEntityQueryObject
    on
        QueryBuilder<
          PurchaseBatchEntity,
          PurchaseBatchEntity,
          QFilterCondition
        > {}

extension PurchaseBatchEntityQueryLinks
    on
        QueryBuilder<
          PurchaseBatchEntity,
          PurchaseBatchEntity,
          QFilterCondition
        > {}

extension PurchaseBatchEntityQuerySortBy
    on QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QSortBy> {
  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByHasStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasStock', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByHasStockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasStock', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByIsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConsumed', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByIsConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConsumed', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByProductUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUniqueKey', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByProductUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUniqueKey', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByProductionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productionDate', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByProductionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productionDate', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByPurchaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByQuantityPurchased() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityPurchased', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByQuantityPurchasedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityPurchased', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByQuantityRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityRemaining', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByQuantityRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityRemaining', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortBySellingPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortBySellingPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByWarrantyMonths() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyMonths', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  sortByWarrantyMonthsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyMonths', Sort.desc);
    });
  }
}

extension PurchaseBatchEntityQuerySortThenBy
    on QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QSortThenBy> {
  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByHasStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasStock', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByHasStockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasStock', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByIsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConsumed', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByIsConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConsumed', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByProductUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUniqueKey', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByProductUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUniqueKey', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByProductionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productionDate', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByProductionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productionDate', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByPurchaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByQuantityPurchased() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityPurchased', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByQuantityPurchasedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityPurchased', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByQuantityRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityRemaining', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByQuantityRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityRemaining', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenBySellingPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenBySellingPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByWarrantyMonths() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyMonths', Sort.asc);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QAfterSortBy>
  thenByWarrantyMonthsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyMonths', Sort.desc);
    });
  }
}

extension PurchaseBatchEntityQueryWhereDistinct
    on QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct> {
  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByCompanyName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'companyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiryDate');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByHasStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasStock');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByIsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isConsumed');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByModelName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByProductId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByProductName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByProductUniqueKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'productUniqueKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByProductionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productionDate');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchaseDate');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchasePrice');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByQuantityPurchased() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantityPurchased');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByQuantityRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantityRemaining');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctBySellingPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellingPrice');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctBySupplierId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctBySupplierName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByUnit({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QDistinct>
  distinctByWarrantyMonths() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'warrantyMonths');
    });
  }
}

extension PurchaseBatchEntityQueryProperty
    on QueryBuilder<PurchaseBatchEntity, PurchaseBatchEntity, QQueryProperty> {
  QueryBuilder<PurchaseBatchEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String, QQueryOperations>
  companyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'companyName');
    });
  }

  QueryBuilder<PurchaseBatchEntity, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PurchaseBatchEntity, DateTime?, QQueryOperations>
  expiryDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiryDate');
    });
  }

  QueryBuilder<PurchaseBatchEntity, bool, QQueryOperations> hasStockProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasStock');
    });
  }

  QueryBuilder<PurchaseBatchEntity, bool, QQueryOperations>
  isConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isConsumed');
    });
  }

  QueryBuilder<PurchaseBatchEntity, bool, QQueryOperations>
  isMarkedForDeletionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String, QQueryOperations>
  modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<PurchaseBatchEntity, bool, QQueryOperations>
  needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String, QQueryOperations>
  productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String, QQueryOperations>
  productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String, QQueryOperations>
  productUniqueKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productUniqueKey');
    });
  }

  QueryBuilder<PurchaseBatchEntity, DateTime?, QQueryOperations>
  productionDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productionDate');
    });
  }

  QueryBuilder<PurchaseBatchEntity, DateTime, QQueryOperations>
  purchaseDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchaseDate');
    });
  }

  QueryBuilder<PurchaseBatchEntity, double, QQueryOperations>
  purchasePriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchasePrice');
    });
  }

  QueryBuilder<PurchaseBatchEntity, int, QQueryOperations>
  quantityPurchasedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantityPurchased');
    });
  }

  QueryBuilder<PurchaseBatchEntity, int, QQueryOperations>
  quantityRemainingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantityRemaining');
    });
  }

  QueryBuilder<PurchaseBatchEntity, double, QQueryOperations>
  sellingPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellingPrice');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String?, QQueryOperations>
  serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String?, QQueryOperations>
  supplierIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierId');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String?, QQueryOperations>
  supplierNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierName');
    });
  }

  QueryBuilder<PurchaseBatchEntity, BatchSyncStatus, QQueryOperations>
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<PurchaseBatchEntity, String, QQueryOperations> unitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unit');
    });
  }

  QueryBuilder<PurchaseBatchEntity, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<PurchaseBatchEntity, int?, QQueryOperations>
  warrantyMonthsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'warrantyMonths');
    });
  }
}
