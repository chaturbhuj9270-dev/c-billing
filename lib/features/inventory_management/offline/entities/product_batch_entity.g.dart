// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_batch_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProductBatchEntityCollection on Isar {
  IsarCollection<ProductBatchEntity> get productBatchEntitys =>
      this.collection();
}

const ProductBatchEntitySchema = CollectionSchema(
  name: r'ProductBatchEntity',
  id: -6391583710745510002,
  properties: {
    r'batchNumber': PropertySchema(
      id: 0,
      name: r'batchNumber',
      type: IsarType.string,
    ),
    r'companyId': PropertySchema(
      id: 1,
      name: r'companyId',
      type: IsarType.string,
    ),
    r'companyName': PropertySchema(
      id: 2,
      name: r'companyName',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currentQuantity': PropertySchema(
      id: 4,
      name: r'currentQuantity',
      type: IsarType.double,
    ),
    r'expiryDate': PropertySchema(
      id: 5,
      name: r'expiryDate',
      type: IsarType.dateTime,
    ),
    r'initialQuantity': PropertySchema(
      id: 6,
      name: r'initialQuantity',
      type: IsarType.double,
    ),
    r'isExhausted': PropertySchema(
      id: 7,
      name: r'isExhausted',
      type: IsarType.bool,
    ),
    r'isExpired': PropertySchema(
      id: 8,
      name: r'isExpired',
      type: IsarType.bool,
    ),
    r'isMarkedForDeletion': PropertySchema(
      id: 9,
      name: r'isMarkedForDeletion',
      type: IsarType.bool,
    ),
    r'needsSync': PropertySchema(
      id: 10,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(id: 11, name: r'notes', type: IsarType.string),
    r'productId': PropertySchema(
      id: 12,
      name: r'productId',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 13,
      name: r'productName',
      type: IsarType.string,
    ),
    r'productionDate': PropertySchema(
      id: 14,
      name: r'productionDate',
      type: IsarType.dateTime,
    ),
    r'profitMargin': PropertySchema(
      id: 15,
      name: r'profitMargin',
      type: IsarType.double,
    ),
    r'purchaseDate': PropertySchema(
      id: 16,
      name: r'purchaseDate',
      type: IsarType.dateTime,
    ),
    r'purchaseId': PropertySchema(
      id: 17,
      name: r'purchaseId',
      type: IsarType.string,
    ),
    r'purchasePrice': PropertySchema(
      id: 18,
      name: r'purchasePrice',
      type: IsarType.double,
    ),
    r'quantitySold': PropertySchema(
      id: 19,
      name: r'quantitySold',
      type: IsarType.double,
    ),
    r'salesPrice': PropertySchema(
      id: 20,
      name: r'salesPrice',
      type: IsarType.double,
    ),
    r'serverId': PropertySchema(
      id: 21,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 22,
      name: r'status',
      type: IsarType.byte,
      enumMap: _ProductBatchEntitystatusEnumValueMap,
    ),
    r'supplierId': PropertySchema(
      id: 23,
      name: r'supplierId',
      type: IsarType.string,
    ),
    r'supplierName': PropertySchema(
      id: 24,
      name: r'supplierName',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 25,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _ProductBatchEntitysyncStatusEnumValueMap,
    ),
    r'totalSalesValue': PropertySchema(
      id: 26,
      name: r'totalSalesValue',
      type: IsarType.double,
    ),
    r'totalValue': PropertySchema(
      id: 27,
      name: r'totalValue',
      type: IsarType.double,
    ),
    r'unit': PropertySchema(id: 28, name: r'unit', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 29,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'warrantyMonths': PropertySchema(
      id: 30,
      name: r'warrantyMonths',
      type: IsarType.long,
    ),
  },

  estimateSize: _productBatchEntityEstimateSize,
  serialize: _productBatchEntitySerialize,
  deserialize: _productBatchEntityDeserialize,
  deserializeProp: _productBatchEntityDeserializeProp,
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
    r'companyId': IndexSchema(
      id: 482756417767355356,
      name: r'companyId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'companyId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'batchNumber': IndexSchema(
      id: -5361927408577734280,
      name: r'batchNumber',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'batchNumber',
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
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
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

  getId: _productBatchEntityGetId,
  getLinks: _productBatchEntityGetLinks,
  attach: _productBatchEntityAttach,
  version: '3.3.0',
);

int _productBatchEntityEstimateSize(
  ProductBatchEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.batchNumber.length * 3;
  bytesCount += 3 + object.companyId.length * 3;
  bytesCount += 3 + object.companyName.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.productId.length * 3;
  bytesCount += 3 + object.productName.length * 3;
  {
    final value = object.purchaseId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.supplierId.length * 3;
  bytesCount += 3 + object.supplierName.length * 3;
  bytesCount += 3 + object.unit.length * 3;
  return bytesCount;
}

void _productBatchEntitySerialize(
  ProductBatchEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.batchNumber);
  writer.writeString(offsets[1], object.companyId);
  writer.writeString(offsets[2], object.companyName);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeDouble(offsets[4], object.currentQuantity);
  writer.writeDateTime(offsets[5], object.expiryDate);
  writer.writeDouble(offsets[6], object.initialQuantity);
  writer.writeBool(offsets[7], object.isExhausted);
  writer.writeBool(offsets[8], object.isExpired);
  writer.writeBool(offsets[9], object.isMarkedForDeletion);
  writer.writeBool(offsets[10], object.needsSync);
  writer.writeString(offsets[11], object.notes);
  writer.writeString(offsets[12], object.productId);
  writer.writeString(offsets[13], object.productName);
  writer.writeDateTime(offsets[14], object.productionDate);
  writer.writeDouble(offsets[15], object.profitMargin);
  writer.writeDateTime(offsets[16], object.purchaseDate);
  writer.writeString(offsets[17], object.purchaseId);
  writer.writeDouble(offsets[18], object.purchasePrice);
  writer.writeDouble(offsets[19], object.quantitySold);
  writer.writeDouble(offsets[20], object.salesPrice);
  writer.writeString(offsets[21], object.serverId);
  writer.writeByte(offsets[22], object.status.index);
  writer.writeString(offsets[23], object.supplierId);
  writer.writeString(offsets[24], object.supplierName);
  writer.writeByte(offsets[25], object.syncStatus.index);
  writer.writeDouble(offsets[26], object.totalSalesValue);
  writer.writeDouble(offsets[27], object.totalValue);
  writer.writeString(offsets[28], object.unit);
  writer.writeDateTime(offsets[29], object.updatedAt);
  writer.writeLong(offsets[30], object.warrantyMonths);
}

ProductBatchEntity _productBatchEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProductBatchEntity(
    batchNumber: reader.readString(offsets[0]),
    companyId: reader.readString(offsets[1]),
    companyName: reader.readString(offsets[2]),
    createdAt: reader.readDateTime(offsets[3]),
    currentQuantity: reader.readDouble(offsets[4]),
    expiryDate: reader.readDateTimeOrNull(offsets[5]),
    initialQuantity: reader.readDouble(offsets[6]),
    notes: reader.readStringOrNull(offsets[11]),
    productId: reader.readString(offsets[12]),
    productName: reader.readString(offsets[13]),
    productionDate: reader.readDateTimeOrNull(offsets[14]),
    purchaseDate: reader.readDateTime(offsets[16]),
    purchaseId: reader.readStringOrNull(offsets[17]),
    purchasePrice: reader.readDouble(offsets[18]),
    salesPrice: reader.readDouble(offsets[20]),
    serverId: reader.readStringOrNull(offsets[21]),
    status:
        _ProductBatchEntitystatusValueEnumMap[reader.readByteOrNull(
          offsets[22],
        )] ??
        BatchStatus.active,
    supplierId: reader.readString(offsets[23]),
    supplierName: reader.readString(offsets[24]),
    syncStatus:
        _ProductBatchEntitysyncStatusValueEnumMap[reader.readByteOrNull(
          offsets[25],
        )] ??
        BatchSyncStatus.newRecord,
    unit: reader.readString(offsets[28]),
    updatedAt: reader.readDateTime(offsets[29]),
    warrantyMonths: reader.readLongOrNull(offsets[30]),
  );
  object.id = id;
  return object;
}

P _productBatchEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (reader.readDouble(offset)) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (_ProductBatchEntitystatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              BatchStatus.active)
          as P;
    case 23:
      return (reader.readString(offset)) as P;
    case 24:
      return (reader.readString(offset)) as P;
    case 25:
      return (_ProductBatchEntitysyncStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              BatchSyncStatus.newRecord)
          as P;
    case 26:
      return (reader.readDouble(offset)) as P;
    case 27:
      return (reader.readDouble(offset)) as P;
    case 28:
      return (reader.readString(offset)) as P;
    case 29:
      return (reader.readDateTime(offset)) as P;
    case 30:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ProductBatchEntitystatusEnumValueMap = {
  'active': 0,
  'exhausted': 1,
  'expired': 2,
};
const _ProductBatchEntitystatusValueEnumMap = {
  0: BatchStatus.active,
  1: BatchStatus.exhausted,
  2: BatchStatus.expired,
};
const _ProductBatchEntitysyncStatusEnumValueMap = {
  'newRecord': 0,
  'updated': 1,
  'deleted': 2,
  'synced': 3,
};
const _ProductBatchEntitysyncStatusValueEnumMap = {
  0: BatchSyncStatus.newRecord,
  1: BatchSyncStatus.updated,
  2: BatchSyncStatus.deleted,
  3: BatchSyncStatus.synced,
};

Id _productBatchEntityGetId(ProductBatchEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _productBatchEntityGetLinks(
  ProductBatchEntity object,
) {
  return [];
}

void _productBatchEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  ProductBatchEntity object,
) {
  object.id = id;
}

extension ProductBatchEntityByIndex on IsarCollection<ProductBatchEntity> {
  Future<ProductBatchEntity?> getByBatchNumber(String batchNumber) {
    return getByIndex(r'batchNumber', [batchNumber]);
  }

  ProductBatchEntity? getByBatchNumberSync(String batchNumber) {
    return getByIndexSync(r'batchNumber', [batchNumber]);
  }

  Future<bool> deleteByBatchNumber(String batchNumber) {
    return deleteByIndex(r'batchNumber', [batchNumber]);
  }

  bool deleteByBatchNumberSync(String batchNumber) {
    return deleteByIndexSync(r'batchNumber', [batchNumber]);
  }

  Future<List<ProductBatchEntity?>> getAllByBatchNumber(
    List<String> batchNumberValues,
  ) {
    final values = batchNumberValues.map((e) => [e]).toList();
    return getAllByIndex(r'batchNumber', values);
  }

  List<ProductBatchEntity?> getAllByBatchNumberSync(
    List<String> batchNumberValues,
  ) {
    final values = batchNumberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'batchNumber', values);
  }

  Future<int> deleteAllByBatchNumber(List<String> batchNumberValues) {
    final values = batchNumberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'batchNumber', values);
  }

  int deleteAllByBatchNumberSync(List<String> batchNumberValues) {
    final values = batchNumberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'batchNumber', values);
  }

  Future<Id> putByBatchNumber(ProductBatchEntity object) {
    return putByIndex(r'batchNumber', object);
  }

  Id putByBatchNumberSync(ProductBatchEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'batchNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBatchNumber(List<ProductBatchEntity> objects) {
    return putAllByIndex(r'batchNumber', objects);
  }

  List<Id> putAllByBatchNumberSync(
    List<ProductBatchEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'batchNumber', objects, saveLinks: saveLinks);
  }
}

extension ProductBatchEntityQueryWhereSort
    on QueryBuilder<ProductBatchEntity, ProductBatchEntity, QWhere> {
  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhere>
  anyPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'purchaseDate'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhere>
  anyStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'status'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhere>
  anySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncStatus'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhere>
  anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension ProductBatchEntityQueryWhere
    on QueryBuilder<ProductBatchEntity, ProductBatchEntity, QWhereClause> {
  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [null]),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  serverIdEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [serverId]),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  productIdEqualTo(String productId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'productId', value: [productId]),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  companyIdEqualTo(String companyId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'companyId', value: [companyId]),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  companyIdNotEqualTo(String companyId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'companyId',
                lower: [],
                upper: [companyId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'companyId',
                lower: [companyId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'companyId',
                lower: [companyId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'companyId',
                lower: [],
                upper: [companyId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  batchNumberEqualTo(String batchNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'batchNumber',
          value: [batchNumber],
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  batchNumberNotEqualTo(String batchNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchNumber',
                lower: [],
                upper: [batchNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchNumber',
                lower: [batchNumber],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchNumber',
                lower: [batchNumber],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchNumber',
                lower: [],
                upper: [batchNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  statusEqualTo(BatchStatus status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'status', value: [status]),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  statusNotEqualTo(BatchStatus status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [],
                upper: [status],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [status],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [status],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [],
                upper: [status],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  statusGreaterThan(BatchStatus status, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'status',
          lower: [status],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  statusLessThan(BatchStatus status, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'status',
          lower: [],
          upper: [status],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  statusBetween(
    BatchStatus lowerStatus,
    BatchStatus upperStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'status',
          lower: [lowerStatus],
          includeLower: includeLower,
          upper: [upperStatus],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  syncStatusEqualTo(BatchSyncStatus syncStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'syncStatus', value: [syncStatus]),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterWhereClause>
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

extension ProductBatchEntityQueryFilter
    on QueryBuilder<ProductBatchEntity, ProductBatchEntity, QFilterCondition> {
  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'batchNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'batchNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'batchNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'batchNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'batchNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'batchNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'batchNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'batchNumber',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'batchNumber', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  batchNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'batchNumber', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'companyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'companyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'companyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'companyId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'companyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'companyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'companyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'companyId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'companyId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'companyId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'companyName', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  companyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'companyName', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  currentQuantityEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'currentQuantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  currentQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currentQuantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  currentQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currentQuantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  currentQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currentQuantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  expiryDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'expiryDate'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  expiryDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'expiryDate'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  expiryDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'expiryDate', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  initialQuantityEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'initialQuantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  initialQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'initialQuantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  initialQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'initialQuantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  initialQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'initialQuantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  isExhaustedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isExhausted', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  isExpiredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isExpired', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  isMarkedForDeletionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isMarkedForDeletion', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'needsSync', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  productionDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'productionDate'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  productionDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'productionDate'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  productionDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productionDate', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  profitMarginEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'profitMargin',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  profitMarginGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'profitMargin',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  profitMarginLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'profitMargin',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  profitMarginBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'profitMargin',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'purchaseDate', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'purchaseId'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'purchaseId'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'purchaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'purchaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'purchaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'purchaseId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'purchaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'purchaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'purchaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'purchaseId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'purchaseId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  purchaseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'purchaseId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  quantitySoldEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'quantitySold',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  quantitySoldGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quantitySold',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  quantitySoldLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quantitySold',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  quantitySoldBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quantitySold',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  salesPriceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'salesPrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  salesPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'salesPrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  salesPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'salesPrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  salesPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'salesPrice',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  statusEqualTo(BatchStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  statusGreaterThan(BatchStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  statusLessThan(BatchStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  statusBetween(
    BatchStatus lower,
    BatchStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierIdEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierIdGreaterThan(
    String value, {
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierIdLessThan(
    String value, {
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'supplierId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'supplierId', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierNameEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierNameGreaterThan(
    String value, {
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierNameLessThan(
    String value, {
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierNameBetween(
    String lower,
    String upper, {
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'supplierName', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  supplierNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'supplierName', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  syncStatusEqualTo(BatchSyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  totalSalesValueEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalSalesValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  totalSalesValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalSalesValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  totalSalesValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalSalesValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  totalSalesValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalSalesValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  totalValueEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  totalValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  totalValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  totalValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  unitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'unit', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  unitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'unit', value: ''),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  warrantyMonthsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'warrantyMonths'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  warrantyMonthsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'warrantyMonths'),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
  warrantyMonthsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'warrantyMonths', value: value),
      );
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterFilterCondition>
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

extension ProductBatchEntityQueryObject
    on QueryBuilder<ProductBatchEntity, ProductBatchEntity, QFilterCondition> {}

extension ProductBatchEntityQueryLinks
    on QueryBuilder<ProductBatchEntity, ProductBatchEntity, QFilterCondition> {}

extension ProductBatchEntityQuerySortBy
    on QueryBuilder<ProductBatchEntity, ProductBatchEntity, QSortBy> {
  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByBatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchNumber', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByBatchNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchNumber', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByCompanyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByCompanyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByCurrentQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuantity', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByCurrentQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuantity', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByInitialQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialQuantity', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByInitialQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialQuantity', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByIsExhausted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExhausted', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByIsExhaustedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExhausted', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByProductionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productionDate', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByProductionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productionDate', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByProfitMargin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profitMargin', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByProfitMarginDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profitMargin', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByPurchaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByPurchaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByPurchaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByQuantitySold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantitySold', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByQuantitySoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantitySold', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortBySalesPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salesPrice', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortBySalesPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salesPrice', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByTotalSalesValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSalesValue', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByTotalSalesValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSalesValue', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByTotalValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalValue', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByTotalValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalValue', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByWarrantyMonths() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyMonths', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  sortByWarrantyMonthsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyMonths', Sort.desc);
    });
  }
}

extension ProductBatchEntityQuerySortThenBy
    on QueryBuilder<ProductBatchEntity, ProductBatchEntity, QSortThenBy> {
  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByBatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchNumber', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByBatchNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchNumber', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByCompanyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByCompanyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByCurrentQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuantity', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByCurrentQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuantity', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByInitialQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialQuantity', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByInitialQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialQuantity', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByIsExhausted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExhausted', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByIsExhaustedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExhausted', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByProductionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productionDate', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByProductionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productionDate', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByProfitMargin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profitMargin', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByProfitMarginDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profitMargin', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByPurchaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByPurchaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByPurchaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByQuantitySold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantitySold', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByQuantitySoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantitySold', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenBySalesPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salesPrice', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenBySalesPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salesPrice', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByTotalSalesValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSalesValue', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByTotalSalesValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSalesValue', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByTotalValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalValue', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByTotalValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalValue', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByWarrantyMonths() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyMonths', Sort.asc);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QAfterSortBy>
  thenByWarrantyMonthsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyMonths', Sort.desc);
    });
  }
}

extension ProductBatchEntityQueryWhereDistinct
    on QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct> {
  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByBatchNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'batchNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByCompanyId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'companyId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByCompanyName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'companyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByCurrentQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentQuantity');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiryDate');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByInitialQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'initialQuantity');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByIsExhausted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExhausted');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExpired');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByProductId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByProductName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByProductionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productionDate');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByProfitMargin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profitMargin');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchaseDate');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByPurchaseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchaseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchasePrice');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByQuantitySold() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantitySold');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctBySalesPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'salesPrice');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctBySupplierId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctBySupplierName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByTotalSalesValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalSalesValue');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByTotalValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalValue');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByUnit({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<ProductBatchEntity, ProductBatchEntity, QDistinct>
  distinctByWarrantyMonths() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'warrantyMonths');
    });
  }
}

extension ProductBatchEntityQueryProperty
    on QueryBuilder<ProductBatchEntity, ProductBatchEntity, QQueryProperty> {
  QueryBuilder<ProductBatchEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProductBatchEntity, String, QQueryOperations>
  batchNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'batchNumber');
    });
  }

  QueryBuilder<ProductBatchEntity, String, QQueryOperations>
  companyIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'companyId');
    });
  }

  QueryBuilder<ProductBatchEntity, String, QQueryOperations>
  companyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'companyName');
    });
  }

  QueryBuilder<ProductBatchEntity, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ProductBatchEntity, double, QQueryOperations>
  currentQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentQuantity');
    });
  }

  QueryBuilder<ProductBatchEntity, DateTime?, QQueryOperations>
  expiryDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiryDate');
    });
  }

  QueryBuilder<ProductBatchEntity, double, QQueryOperations>
  initialQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'initialQuantity');
    });
  }

  QueryBuilder<ProductBatchEntity, bool, QQueryOperations>
  isExhaustedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExhausted');
    });
  }

  QueryBuilder<ProductBatchEntity, bool, QQueryOperations> isExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExpired');
    });
  }

  QueryBuilder<ProductBatchEntity, bool, QQueryOperations>
  isMarkedForDeletionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<ProductBatchEntity, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<ProductBatchEntity, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<ProductBatchEntity, String, QQueryOperations>
  productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<ProductBatchEntity, String, QQueryOperations>
  productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<ProductBatchEntity, DateTime?, QQueryOperations>
  productionDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productionDate');
    });
  }

  QueryBuilder<ProductBatchEntity, double, QQueryOperations>
  profitMarginProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profitMargin');
    });
  }

  QueryBuilder<ProductBatchEntity, DateTime, QQueryOperations>
  purchaseDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchaseDate');
    });
  }

  QueryBuilder<ProductBatchEntity, String?, QQueryOperations>
  purchaseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchaseId');
    });
  }

  QueryBuilder<ProductBatchEntity, double, QQueryOperations>
  purchasePriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchasePrice');
    });
  }

  QueryBuilder<ProductBatchEntity, double, QQueryOperations>
  quantitySoldProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantitySold');
    });
  }

  QueryBuilder<ProductBatchEntity, double, QQueryOperations>
  salesPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'salesPrice');
    });
  }

  QueryBuilder<ProductBatchEntity, String?, QQueryOperations>
  serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<ProductBatchEntity, BatchStatus, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<ProductBatchEntity, String, QQueryOperations>
  supplierIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierId');
    });
  }

  QueryBuilder<ProductBatchEntity, String, QQueryOperations>
  supplierNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierName');
    });
  }

  QueryBuilder<ProductBatchEntity, BatchSyncStatus, QQueryOperations>
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<ProductBatchEntity, double, QQueryOperations>
  totalSalesValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalSalesValue');
    });
  }

  QueryBuilder<ProductBatchEntity, double, QQueryOperations>
  totalValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalValue');
    });
  }

  QueryBuilder<ProductBatchEntity, String, QQueryOperations> unitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unit');
    });
  }

  QueryBuilder<ProductBatchEntity, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<ProductBatchEntity, int?, QQueryOperations>
  warrantyMonthsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'warrantyMonths');
    });
  }
}
