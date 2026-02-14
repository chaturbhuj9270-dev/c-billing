// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_ledger_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStockLedgerEntityCollection on Isar {
  IsarCollection<StockLedgerEntity> get stockLedgerEntitys => this.collection();
}

const StockLedgerEntitySchema = CollectionSchema(
  name: r'StockLedgerEntity',
  id: 49222876430352971,
  properties: {
    r'balanceQuantity': PropertySchema(
      id: 0,
      name: r'balanceQuantity',
      type: IsarType.long,
    ),
    r'balanceValue': PropertySchema(
      id: 1,
      name: r'balanceValue',
      type: IsarType.double,
    ),
    r'batchId': PropertySchema(id: 2, name: r'batchId', type: IsarType.string),
    r'companyName': PropertySchema(
      id: 3,
      name: r'companyName',
      type: IsarType.string,
    ),
    r'costPrice': PropertySchema(
      id: 4,
      name: r'costPrice',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 5,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isInbound': PropertySchema(
      id: 6,
      name: r'isInbound',
      type: IsarType.bool,
    ),
    r'isMarkedForDeletion': PropertySchema(
      id: 7,
      name: r'isMarkedForDeletion',
      type: IsarType.bool,
    ),
    r'isOutbound': PropertySchema(
      id: 8,
      name: r'isOutbound',
      type: IsarType.bool,
    ),
    r'ledgerType': PropertySchema(
      id: 9,
      name: r'ledgerType',
      type: IsarType.byte,
      enumMap: _StockLedgerEntityledgerTypeEnumValueMap,
    ),
    r'localBatchId': PropertySchema(
      id: 10,
      name: r'localBatchId',
      type: IsarType.long,
    ),
    r'modelName': PropertySchema(
      id: 11,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'needsSync': PropertySchema(
      id: 12,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(id: 13, name: r'notes', type: IsarType.string),
    r'productId': PropertySchema(
      id: 14,
      name: r'productId',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 15,
      name: r'productName',
      type: IsarType.string,
    ),
    r'productUniqueKey': PropertySchema(
      id: 16,
      name: r'productUniqueKey',
      type: IsarType.string,
    ),
    r'profit': PropertySchema(id: 17, name: r'profit', type: IsarType.double),
    r'quantity': PropertySchema(id: 18, name: r'quantity', type: IsarType.long),
    r'referenceId': PropertySchema(
      id: 19,
      name: r'referenceId',
      type: IsarType.string,
    ),
    r'referenceType': PropertySchema(
      id: 20,
      name: r'referenceType',
      type: IsarType.string,
    ),
    r'sellingPrice': PropertySchema(
      id: 21,
      name: r'sellingPrice',
      type: IsarType.double,
    ),
    r'serverId': PropertySchema(
      id: 22,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 23,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _StockLedgerEntitysyncStatusEnumValueMap,
    ),
    r'totalCost': PropertySchema(
      id: 24,
      name: r'totalCost',
      type: IsarType.double,
    ),
    r'totalRevenue': PropertySchema(
      id: 25,
      name: r'totalRevenue',
      type: IsarType.double,
    ),
    r'transactionDate': PropertySchema(
      id: 26,
      name: r'transactionDate',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _stockLedgerEntityEstimateSize,
  serialize: _stockLedgerEntitySerialize,
  deserialize: _stockLedgerEntityDeserialize,
  deserializeProp: _stockLedgerEntityDeserializeProp,
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
    r'batchId': IndexSchema(
      id: -5468368523860846432,
      name: r'batchId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'batchId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'ledgerType': IndexSchema(
      id: 4211967145891972597,
      name: r'ledgerType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ledgerType',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'referenceId': IndexSchema(
      id: -8118621180780534330,
      name: r'referenceId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'referenceId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'transactionDate': IndexSchema(
      id: 3386085016894654755,
      name: r'transactionDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'transactionDate',
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

  getId: _stockLedgerEntityGetId,
  getLinks: _stockLedgerEntityGetLinks,
  attach: _stockLedgerEntityAttach,
  version: '3.3.0',
);

int _stockLedgerEntityEstimateSize(
  StockLedgerEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.batchId.length * 3;
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
  bytesCount += 3 + object.referenceId.length * 3;
  bytesCount += 3 + object.referenceType.length * 3;
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _stockLedgerEntitySerialize(
  StockLedgerEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.balanceQuantity);
  writer.writeDouble(offsets[1], object.balanceValue);
  writer.writeString(offsets[2], object.batchId);
  writer.writeString(offsets[3], object.companyName);
  writer.writeDouble(offsets[4], object.costPrice);
  writer.writeDateTime(offsets[5], object.createdAt);
  writer.writeBool(offsets[6], object.isInbound);
  writer.writeBool(offsets[7], object.isMarkedForDeletion);
  writer.writeBool(offsets[8], object.isOutbound);
  writer.writeByte(offsets[9], object.ledgerType.index);
  writer.writeLong(offsets[10], object.localBatchId);
  writer.writeString(offsets[11], object.modelName);
  writer.writeBool(offsets[12], object.needsSync);
  writer.writeString(offsets[13], object.notes);
  writer.writeString(offsets[14], object.productId);
  writer.writeString(offsets[15], object.productName);
  writer.writeString(offsets[16], object.productUniqueKey);
  writer.writeDouble(offsets[17], object.profit);
  writer.writeLong(offsets[18], object.quantity);
  writer.writeString(offsets[19], object.referenceId);
  writer.writeString(offsets[20], object.referenceType);
  writer.writeDouble(offsets[21], object.sellingPrice);
  writer.writeString(offsets[22], object.serverId);
  writer.writeByte(offsets[23], object.syncStatus.index);
  writer.writeDouble(offsets[24], object.totalCost);
  writer.writeDouble(offsets[25], object.totalRevenue);
  writer.writeDateTime(offsets[26], object.transactionDate);
}

StockLedgerEntity _stockLedgerEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StockLedgerEntity(
    balanceQuantity: reader.readLong(offsets[0]),
    balanceValue: reader.readDouble(offsets[1]),
    batchId: reader.readString(offsets[2]),
    companyName: reader.readStringOrNull(offsets[3]) ?? '',
    costPrice: reader.readDouble(offsets[4]),
    createdAt: reader.readDateTime(offsets[5]),
    ledgerType:
        _StockLedgerEntityledgerTypeValueEnumMap[reader.readByteOrNull(
          offsets[9],
        )] ??
        LedgerTransactionType.PURCHASE,
    localBatchId: reader.readLongOrNull(offsets[10]),
    modelName: reader.readStringOrNull(offsets[11]) ?? '',
    notes: reader.readStringOrNull(offsets[13]),
    productId: reader.readString(offsets[14]),
    productName: reader.readString(offsets[15]),
    productUniqueKey: reader.readString(offsets[16]),
    profit: reader.readDoubleOrNull(offsets[17]) ?? 0.0,
    quantity: reader.readLong(offsets[18]),
    referenceId: reader.readString(offsets[19]),
    referenceType: reader.readStringOrNull(offsets[20]) ?? '',
    sellingPrice: reader.readDoubleOrNull(offsets[21]) ?? 0.0,
    serverId: reader.readStringOrNull(offsets[22]),
    syncStatus:
        _StockLedgerEntitysyncStatusValueEnumMap[reader.readByteOrNull(
          offsets[23],
        )] ??
        LedgerSyncStatus.newRecord,
    totalCost: reader.readDouble(offsets[24]),
    totalRevenue: reader.readDoubleOrNull(offsets[25]) ?? 0.0,
    transactionDate: reader.readDateTime(offsets[26]),
  );
  object.id = id;
  return object;
}

P _stockLedgerEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (_StockLedgerEntityledgerTypeValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              LedgerTransactionType.PURCHASE)
          as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 18:
      return (reader.readLong(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 21:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (_StockLedgerEntitysyncStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              LedgerSyncStatus.newRecord)
          as P;
    case 24:
      return (reader.readDouble(offset)) as P;
    case 25:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 26:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _StockLedgerEntityledgerTypeEnumValueMap = {
  'PURCHASE': 0,
  'SALE': 1,
  'ADJUSTMENT': 2,
  'SALE_RETURN': 3,
  'PURCHASE_RETURN': 4,
  'TRANSFER': 5,
  'OPENING_STOCK': 6,
};
const _StockLedgerEntityledgerTypeValueEnumMap = {
  0: LedgerTransactionType.PURCHASE,
  1: LedgerTransactionType.SALE,
  2: LedgerTransactionType.ADJUSTMENT,
  3: LedgerTransactionType.SALE_RETURN,
  4: LedgerTransactionType.PURCHASE_RETURN,
  5: LedgerTransactionType.TRANSFER,
  6: LedgerTransactionType.OPENING_STOCK,
};
const _StockLedgerEntitysyncStatusEnumValueMap = {
  'newRecord': 0,
  'updated': 1,
  'deleted': 2,
  'synced': 3,
};
const _StockLedgerEntitysyncStatusValueEnumMap = {
  0: LedgerSyncStatus.newRecord,
  1: LedgerSyncStatus.updated,
  2: LedgerSyncStatus.deleted,
  3: LedgerSyncStatus.synced,
};

Id _stockLedgerEntityGetId(StockLedgerEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _stockLedgerEntityGetLinks(
  StockLedgerEntity object,
) {
  return [];
}

void _stockLedgerEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  StockLedgerEntity object,
) {
  object.id = id;
}

extension StockLedgerEntityQueryWhereSort
    on QueryBuilder<StockLedgerEntity, StockLedgerEntity, QWhere> {
  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhere>
  anyLedgerType() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'ledgerType'),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhere>
  anyTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'transactionDate'),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhere>
  anySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncStatus'),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhere>
  anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension StockLedgerEntityQueryWhere
    on QueryBuilder<StockLedgerEntity, StockLedgerEntity, QWhereClause> {
  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [null]),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  serverIdEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [serverId]),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  productIdEqualTo(String productId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'productId', value: [productId]),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  batchIdEqualTo(String batchId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'batchId', value: [batchId]),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  batchIdNotEqualTo(String batchId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchId',
                lower: [],
                upper: [batchId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchId',
                lower: [batchId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchId',
                lower: [batchId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchId',
                lower: [],
                upper: [batchId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  ledgerTypeEqualTo(LedgerTransactionType ledgerType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'ledgerType', value: [ledgerType]),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  ledgerTypeNotEqualTo(LedgerTransactionType ledgerType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ledgerType',
                lower: [],
                upper: [ledgerType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ledgerType',
                lower: [ledgerType],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ledgerType',
                lower: [ledgerType],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ledgerType',
                lower: [],
                upper: [ledgerType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  ledgerTypeGreaterThan(
    LedgerTransactionType ledgerType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'ledgerType',
          lower: [ledgerType],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  ledgerTypeLessThan(LedgerTransactionType ledgerType, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'ledgerType',
          lower: [],
          upper: [ledgerType],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  ledgerTypeBetween(
    LedgerTransactionType lowerLedgerType,
    LedgerTransactionType upperLedgerType, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'ledgerType',
          lower: [lowerLedgerType],
          includeLower: includeLower,
          upper: [upperLedgerType],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  referenceIdEqualTo(String referenceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'referenceId',
          value: [referenceId],
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  referenceIdNotEqualTo(String referenceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'referenceId',
                lower: [],
                upper: [referenceId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'referenceId',
                lower: [referenceId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'referenceId',
                lower: [referenceId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'referenceId',
                lower: [],
                upper: [referenceId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  transactionDateEqualTo(DateTime transactionDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'transactionDate',
          value: [transactionDate],
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  transactionDateNotEqualTo(DateTime transactionDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'transactionDate',
                lower: [],
                upper: [transactionDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'transactionDate',
                lower: [transactionDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'transactionDate',
                lower: [transactionDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'transactionDate',
                lower: [],
                upper: [transactionDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  transactionDateGreaterThan(DateTime transactionDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'transactionDate',
          lower: [transactionDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  transactionDateLessThan(DateTime transactionDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'transactionDate',
          lower: [],
          upper: [transactionDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  transactionDateBetween(
    DateTime lowerTransactionDate,
    DateTime upperTransactionDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'transactionDate',
          lower: [lowerTransactionDate],
          includeLower: includeLower,
          upper: [upperTransactionDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  syncStatusEqualTo(LedgerSyncStatus syncStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'syncStatus', value: [syncStatus]),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  syncStatusNotEqualTo(LedgerSyncStatus syncStatus) {
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  syncStatusGreaterThan(LedgerSyncStatus syncStatus, {bool include = false}) {
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  syncStatusLessThan(LedgerSyncStatus syncStatus, {bool include = false}) {
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  syncStatusBetween(
    LedgerSyncStatus lowerSyncStatus,
    LedgerSyncStatus upperSyncStatus, {
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterWhereClause>
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

extension StockLedgerEntityQueryFilter
    on QueryBuilder<StockLedgerEntity, StockLedgerEntity, QFilterCondition> {
  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  balanceQuantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'balanceQuantity', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  balanceQuantityGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'balanceQuantity',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  balanceQuantityLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'balanceQuantity',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  balanceQuantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'balanceQuantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  balanceValueEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'balanceValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  balanceValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'balanceValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  balanceValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'balanceValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  balanceValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'balanceValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'batchId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'batchId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'batchId', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  batchIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'batchId', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  companyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'companyName', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  companyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'companyName', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  costPriceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'costPrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  costPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'costPrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  costPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'costPrice',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  costPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'costPrice',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  isInboundEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isInbound', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  isMarkedForDeletionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isMarkedForDeletion', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  isOutboundEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isOutbound', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  ledgerTypeEqualTo(LedgerTransactionType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ledgerType', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  ledgerTypeGreaterThan(LedgerTransactionType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ledgerType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  ledgerTypeLessThan(LedgerTransactionType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ledgerType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  ledgerTypeBetween(
    LedgerTransactionType lower,
    LedgerTransactionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ledgerType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  localBatchIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'localBatchId'),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  localBatchIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'localBatchId'),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  localBatchIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localBatchId', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  localBatchIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localBatchId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  localBatchIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localBatchId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  localBatchIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localBatchId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  modelNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  modelNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'needsSync', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  productUniqueKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productUniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  productUniqueKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productUniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  profitEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'profit',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  profitGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'profit',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  profitLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'profit',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  profitBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'profit',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'quantity', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  quantityGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quantity',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  quantityLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quantity',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  quantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'referenceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'referenceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'referenceId', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'referenceId', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'referenceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'referenceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'referenceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'referenceType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'referenceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'referenceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'referenceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'referenceType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'referenceType', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  referenceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'referenceType', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  syncStatusEqualTo(LedgerSyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  syncStatusGreaterThan(LedgerSyncStatus value, {bool include = false}) {
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  syncStatusLessThan(LedgerSyncStatus value, {bool include = false}) {
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  syncStatusBetween(
    LedgerSyncStatus lower,
    LedgerSyncStatus upper, {
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

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  totalCostEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalCost',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  totalCostGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalCost',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  totalCostLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalCost',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  totalCostBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalCost',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  totalRevenueEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalRevenue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  totalRevenueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalRevenue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  totalRevenueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalRevenue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  totalRevenueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalRevenue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  transactionDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'transactionDate', value: value),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  transactionDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'transactionDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  transactionDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'transactionDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterFilterCondition>
  transactionDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'transactionDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension StockLedgerEntityQueryObject
    on QueryBuilder<StockLedgerEntity, StockLedgerEntity, QFilterCondition> {}

extension StockLedgerEntityQueryLinks
    on QueryBuilder<StockLedgerEntity, StockLedgerEntity, QFilterCondition> {}

extension StockLedgerEntityQuerySortBy
    on QueryBuilder<StockLedgerEntity, StockLedgerEntity, QSortBy> {
  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByBalanceQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceQuantity', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByBalanceQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceQuantity', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByBalanceValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceValue', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByBalanceValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceValue', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByCostPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByIsInbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInbound', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByIsInboundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInbound', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByIsOutbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOutbound', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByIsOutboundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOutbound', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByLedgerType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ledgerType', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByLedgerTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ledgerType', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByLocalBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localBatchId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByLocalBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localBatchId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByProductUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUniqueKey', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByProductUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUniqueKey', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByProfit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profit', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByProfitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profit', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByReferenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByReferenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortBySellingPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortBySellingPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByTotalCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByTotalRevenue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalRevenue', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByTotalRevenueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalRevenue', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  sortByTransactionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.desc);
    });
  }
}

extension StockLedgerEntityQuerySortThenBy
    on QueryBuilder<StockLedgerEntity, StockLedgerEntity, QSortThenBy> {
  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByBalanceQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceQuantity', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByBalanceQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceQuantity', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByBalanceValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceValue', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByBalanceValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceValue', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByCostPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByIsInbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInbound', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByIsInboundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInbound', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByIsOutbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOutbound', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByIsOutboundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOutbound', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByLedgerType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ledgerType', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByLedgerTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ledgerType', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByLocalBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localBatchId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByLocalBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localBatchId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByProductUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUniqueKey', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByProductUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUniqueKey', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByProfit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profit', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByProfitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profit', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByReferenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByReferenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenBySellingPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenBySellingPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByTotalCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByTotalRevenue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalRevenue', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByTotalRevenueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalRevenue', Sort.desc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.asc);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QAfterSortBy>
  thenByTransactionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.desc);
    });
  }
}

extension StockLedgerEntityQueryWhereDistinct
    on QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct> {
  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByBalanceQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balanceQuantity');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByBalanceValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balanceValue');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByBatchId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'batchId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByCompanyName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'companyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'costPrice');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByIsInbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isInbound');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByIsOutbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOutbound');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByLedgerType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ledgerType');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByLocalBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localBatchId');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByModelName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByProductId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByProductName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByProductUniqueKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'productUniqueKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByProfit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profit');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByReferenceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByReferenceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'referenceType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctBySellingPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellingPrice');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCost');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByTotalRevenue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalRevenue');
    });
  }

  QueryBuilder<StockLedgerEntity, StockLedgerEntity, QDistinct>
  distinctByTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionDate');
    });
  }
}

extension StockLedgerEntityQueryProperty
    on QueryBuilder<StockLedgerEntity, StockLedgerEntity, QQueryProperty> {
  QueryBuilder<StockLedgerEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<StockLedgerEntity, int, QQueryOperations>
  balanceQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balanceQuantity');
    });
  }

  QueryBuilder<StockLedgerEntity, double, QQueryOperations>
  balanceValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balanceValue');
    });
  }

  QueryBuilder<StockLedgerEntity, String, QQueryOperations> batchIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'batchId');
    });
  }

  QueryBuilder<StockLedgerEntity, String, QQueryOperations>
  companyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'companyName');
    });
  }

  QueryBuilder<StockLedgerEntity, double, QQueryOperations>
  costPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'costPrice');
    });
  }

  QueryBuilder<StockLedgerEntity, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<StockLedgerEntity, bool, QQueryOperations> isInboundProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isInbound');
    });
  }

  QueryBuilder<StockLedgerEntity, bool, QQueryOperations>
  isMarkedForDeletionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<StockLedgerEntity, bool, QQueryOperations> isOutboundProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOutbound');
    });
  }

  QueryBuilder<StockLedgerEntity, LedgerTransactionType, QQueryOperations>
  ledgerTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ledgerType');
    });
  }

  QueryBuilder<StockLedgerEntity, int?, QQueryOperations>
  localBatchIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localBatchId');
    });
  }

  QueryBuilder<StockLedgerEntity, String, QQueryOperations>
  modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<StockLedgerEntity, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<StockLedgerEntity, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<StockLedgerEntity, String, QQueryOperations>
  productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<StockLedgerEntity, String, QQueryOperations>
  productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<StockLedgerEntity, String, QQueryOperations>
  productUniqueKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productUniqueKey');
    });
  }

  QueryBuilder<StockLedgerEntity, double, QQueryOperations> profitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profit');
    });
  }

  QueryBuilder<StockLedgerEntity, int, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<StockLedgerEntity, String, QQueryOperations>
  referenceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceId');
    });
  }

  QueryBuilder<StockLedgerEntity, String, QQueryOperations>
  referenceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceType');
    });
  }

  QueryBuilder<StockLedgerEntity, double, QQueryOperations>
  sellingPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellingPrice');
    });
  }

  QueryBuilder<StockLedgerEntity, String?, QQueryOperations>
  serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<StockLedgerEntity, LedgerSyncStatus, QQueryOperations>
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<StockLedgerEntity, double, QQueryOperations>
  totalCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCost');
    });
  }

  QueryBuilder<StockLedgerEntity, double, QQueryOperations>
  totalRevenueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalRevenue');
    });
  }

  QueryBuilder<StockLedgerEntity, DateTime, QQueryOperations>
  transactionDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionDate');
    });
  }
}
