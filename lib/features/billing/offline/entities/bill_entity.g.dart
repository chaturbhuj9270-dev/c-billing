// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBillEntityCollection on Isar {
  IsarCollection<BillEntity> get billEntitys => this.collection();
}

const BillEntitySchema = CollectionSchema(
  name: r'BillEntity',
  id: 1964707223455112648,
  properties: {
    r'billDate': PropertySchema(
      id: 0,
      name: r'billDate',
      type: IsarType.dateTime,
    ),
    r'cgstAmount': PropertySchema(
      id: 1,
      name: r'cgstAmount',
      type: IsarType.double,
    ),
    r'cgstPercent': PropertySchema(
      id: 2,
      name: r'cgstPercent',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'customerContact': PropertySchema(
      id: 4,
      name: r'customerContact',
      type: IsarType.string,
    ),
    r'customerId': PropertySchema(
      id: 5,
      name: r'customerId',
      type: IsarType.string,
    ),
    r'customerName': PropertySchema(
      id: 6,
      name: r'customerName',
      type: IsarType.string,
    ),
    r'discountAmount': PropertySchema(
      id: 7,
      name: r'discountAmount',
      type: IsarType.double,
    ),
    r'discountPercent': PropertySchema(
      id: 8,
      name: r'discountPercent',
      type: IsarType.double,
    ),
    r'finalAmount': PropertySchema(
      id: 9,
      name: r'finalAmount',
      type: IsarType.double,
    ),
    r'isGstApplied': PropertySchema(
      id: 10,
      name: r'isGstApplied',
      type: IsarType.bool,
    ),
    r'isMarkedForDeletion': PropertySchema(
      id: 11,
      name: r'isMarkedForDeletion',
      type: IsarType.bool,
    ),
    r'isTaxInclusive': PropertySchema(
      id: 12,
      name: r'isTaxInclusive',
      type: IsarType.bool,
    ),
    r'items': PropertySchema(
      id: 13,
      name: r'items',
      type: IsarType.objectList,

      target: r'BillItemEmbedded',
    ),
    r'needsSync': PropertySchema(
      id: 14,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(id: 15, name: r'notes', type: IsarType.string),
    r'otherTaxAmount': PropertySchema(
      id: 16,
      name: r'otherTaxAmount',
      type: IsarType.double,
    ),
    r'otherTaxName': PropertySchema(
      id: 17,
      name: r'otherTaxName',
      type: IsarType.string,
    ),
    r'otherTaxPercent': PropertySchema(
      id: 18,
      name: r'otherTaxPercent',
      type: IsarType.double,
    ),
    r'paidAmount': PropertySchema(
      id: 19,
      name: r'paidAmount',
      type: IsarType.double,
    ),
    r'paymentStatus': PropertySchema(
      id: 20,
      name: r'paymentStatus',
      type: IsarType.byte,
      enumMap: _BillEntitypaymentStatusEnumValueMap,
    ),
    r'pendingAmount': PropertySchema(
      id: 21,
      name: r'pendingAmount',
      type: IsarType.double,
    ),
    r'returnDate': PropertySchema(
      id: 22,
      name: r'returnDate',
      type: IsarType.dateTime,
    ),
    r'returnStatus': PropertySchema(
      id: 23,
      name: r'returnStatus',
      type: IsarType.bool,
    ),
    r'serverId': PropertySchema(
      id: 24,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'sgstAmount': PropertySchema(
      id: 25,
      name: r'sgstAmount',
      type: IsarType.double,
    ),
    r'sgstPercent': PropertySchema(
      id: 26,
      name: r'sgstPercent',
      type: IsarType.double,
    ),
    r'syncStatus': PropertySchema(
      id: 27,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _BillEntitysyncStatusEnumValueMap,
    ),
    r'totalAmount': PropertySchema(
      id: 28,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'totalQuantity': PropertySchema(
      id: 29,
      name: r'totalQuantity',
      type: IsarType.long,
    ),
    r'totalTaxAmount': PropertySchema(
      id: 30,
      name: r'totalTaxAmount',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 31,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _billEntityEstimateSize,
  serialize: _billEntitySerialize,
  deserialize: _billEntityDeserialize,
  deserializeProp: _billEntityDeserializeProp,
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
    r'customerId': IndexSchema(
      id: 1498639901530368639,
      name: r'customerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'customerId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'billDate': IndexSchema(
      id: 4448995553089607416,
      name: r'billDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'billDate',
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
  embeddedSchemas: {r'BillItemEmbedded': BillItemEmbeddedSchema},

  getId: _billEntityGetId,
  getLinks: _billEntityGetLinks,
  attach: _billEntityAttach,
  version: '3.3.0',
);

int _billEntityEstimateSize(
  BillEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.customerContact;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customerName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.items.length * 3;
  {
    final offsets = allOffsets[BillItemEmbedded]!;
    for (var i = 0; i < object.items.length; i++) {
      final value = object.items[i];
      bytesCount += BillItemEmbeddedSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.otherTaxName;
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
  return bytesCount;
}

void _billEntitySerialize(
  BillEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.billDate);
  writer.writeDouble(offsets[1], object.cgstAmount);
  writer.writeDouble(offsets[2], object.cgstPercent);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.customerContact);
  writer.writeString(offsets[5], object.customerId);
  writer.writeString(offsets[6], object.customerName);
  writer.writeDouble(offsets[7], object.discountAmount);
  writer.writeDouble(offsets[8], object.discountPercent);
  writer.writeDouble(offsets[9], object.finalAmount);
  writer.writeBool(offsets[10], object.isGstApplied);
  writer.writeBool(offsets[11], object.isMarkedForDeletion);
  writer.writeBool(offsets[12], object.isTaxInclusive);
  writer.writeObjectList<BillItemEmbedded>(
    offsets[13],
    allOffsets,
    BillItemEmbeddedSchema.serialize,
    object.items,
  );
  writer.writeBool(offsets[14], object.needsSync);
  writer.writeString(offsets[15], object.notes);
  writer.writeDouble(offsets[16], object.otherTaxAmount);
  writer.writeString(offsets[17], object.otherTaxName);
  writer.writeDouble(offsets[18], object.otherTaxPercent);
  writer.writeDouble(offsets[19], object.paidAmount);
  writer.writeByte(offsets[20], object.paymentStatus.index);
  writer.writeDouble(offsets[21], object.pendingAmount);
  writer.writeDateTime(offsets[22], object.returnDate);
  writer.writeBool(offsets[23], object.returnStatus);
  writer.writeString(offsets[24], object.serverId);
  writer.writeDouble(offsets[25], object.sgstAmount);
  writer.writeDouble(offsets[26], object.sgstPercent);
  writer.writeByte(offsets[27], object.syncStatus.index);
  writer.writeDouble(offsets[28], object.totalAmount);
  writer.writeLong(offsets[29], object.totalQuantity);
  writer.writeDouble(offsets[30], object.totalTaxAmount);
  writer.writeDateTime(offsets[31], object.updatedAt);
}

BillEntity _billEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BillEntity(
    billDate: reader.readDateTime(offsets[0]),
    cgstAmount: reader.readDoubleOrNull(offsets[1]) ?? 0.0,
    cgstPercent: reader.readDoubleOrNull(offsets[2]) ?? 0.0,
    createdAt: reader.readDateTime(offsets[3]),
    customerContact: reader.readStringOrNull(offsets[4]),
    customerId: reader.readStringOrNull(offsets[5]),
    customerName: reader.readStringOrNull(offsets[6]),
    discountAmount: reader.readDoubleOrNull(offsets[7]) ?? 0.0,
    discountPercent: reader.readDoubleOrNull(offsets[8]) ?? 0.0,
    finalAmount: reader.readDoubleOrNull(offsets[9]) ?? 0.0,
    isGstApplied: reader.readBoolOrNull(offsets[10]) ?? false,
    isTaxInclusive: reader.readBoolOrNull(offsets[12]) ?? false,
    items:
        reader.readObjectList<BillItemEmbedded>(
          offsets[13],
          BillItemEmbeddedSchema.deserialize,
          allOffsets,
          BillItemEmbedded(),
        ) ??
        const [],
    notes: reader.readStringOrNull(offsets[15]),
    otherTaxAmount: reader.readDoubleOrNull(offsets[16]) ?? 0.0,
    otherTaxName: reader.readStringOrNull(offsets[17]),
    otherTaxPercent: reader.readDoubleOrNull(offsets[18]) ?? 0.0,
    paidAmount: reader.readDoubleOrNull(offsets[19]) ?? 0.0,
    paymentStatus:
        _BillEntitypaymentStatusValueEnumMap[reader.readByteOrNull(
          offsets[20],
        )] ??
        BillPaymentStatus.paid,
    pendingAmount: reader.readDoubleOrNull(offsets[21]) ?? 0.0,
    returnDate: reader.readDateTimeOrNull(offsets[22]),
    returnStatus: reader.readBoolOrNull(offsets[23]) ?? false,
    serverId: reader.readStringOrNull(offsets[24]),
    sgstAmount: reader.readDoubleOrNull(offsets[25]) ?? 0.0,
    sgstPercent: reader.readDoubleOrNull(offsets[26]) ?? 0.0,
    syncStatus:
        _BillEntitysyncStatusValueEnumMap[reader.readByteOrNull(offsets[27])] ??
        BillSyncStatus.newRecord,
    totalAmount: reader.readDoubleOrNull(offsets[28]) ?? 0.0,
    totalQuantity: reader.readLongOrNull(offsets[29]) ?? 0,
    totalTaxAmount: reader.readDoubleOrNull(offsets[30]) ?? 0.0,
    updatedAt: reader.readDateTime(offsets[31]),
  );
  object.id = id;
  return object;
}

P _billEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 2:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 8:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 9:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 10:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 13:
      return (reader.readObjectList<BillItemEmbedded>(
                offset,
                BillItemEmbeddedSchema.deserialize,
                allOffsets,
                BillItemEmbedded(),
              ) ??
              const [])
          as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 19:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 20:
      return (_BillEntitypaymentStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              BillPaymentStatus.paid)
          as P;
    case 21:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 22:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 23:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 26:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 27:
      return (_BillEntitysyncStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              BillSyncStatus.newRecord)
          as P;
    case 28:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 29:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 30:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 31:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _BillEntitypaymentStatusEnumValueMap = {
  'paid': 0,
  'partiallyPaid': 1,
  'pending': 2,
};
const _BillEntitypaymentStatusValueEnumMap = {
  0: BillPaymentStatus.paid,
  1: BillPaymentStatus.partiallyPaid,
  2: BillPaymentStatus.pending,
};
const _BillEntitysyncStatusEnumValueMap = {
  'newRecord': 0,
  'updated': 1,
  'deleted': 2,
  'synced': 3,
};
const _BillEntitysyncStatusValueEnumMap = {
  0: BillSyncStatus.newRecord,
  1: BillSyncStatus.updated,
  2: BillSyncStatus.deleted,
  3: BillSyncStatus.synced,
};

Id _billEntityGetId(BillEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _billEntityGetLinks(BillEntity object) {
  return [];
}

void _billEntityAttach(IsarCollection<dynamic> col, Id id, BillEntity object) {
  object.id = id;
}

extension BillEntityQueryWhereSort
    on QueryBuilder<BillEntity, BillEntity, QWhere> {
  QueryBuilder<BillEntity, BillEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhere> anyBillDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'billDate'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhere> anySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncStatus'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension BillEntityQueryWhere
    on QueryBuilder<BillEntity, BillEntity, QWhereClause> {
  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [null]),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> serverIdIsNotNull() {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> serverIdEqualTo(
    String? serverId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [serverId]),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> serverIdNotEqualTo(
    String? serverId,
  ) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> customerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'customerId', value: [null]),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause>
  customerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'customerId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> customerIdEqualTo(
    String? customerId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'customerId', value: [customerId]),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> customerIdNotEqualTo(
    String? customerId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'customerId',
                lower: [],
                upper: [customerId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'customerId',
                lower: [customerId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'customerId',
                lower: [customerId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'customerId',
                lower: [],
                upper: [customerId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> billDateEqualTo(
    DateTime billDate,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'billDate', value: [billDate]),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> billDateNotEqualTo(
    DateTime billDate,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'billDate',
                lower: [],
                upper: [billDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'billDate',
                lower: [billDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'billDate',
                lower: [billDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'billDate',
                lower: [],
                upper: [billDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> billDateGreaterThan(
    DateTime billDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'billDate',
          lower: [billDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> billDateLessThan(
    DateTime billDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'billDate',
          lower: [],
          upper: [billDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> billDateBetween(
    DateTime lowerBillDate,
    DateTime upperBillDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'billDate',
          lower: [lowerBillDate],
          includeLower: includeLower,
          upper: [upperBillDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> syncStatusEqualTo(
    BillSyncStatus syncStatus,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'syncStatus', value: [syncStatus]),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> syncStatusNotEqualTo(
    BillSyncStatus syncStatus,
  ) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> syncStatusGreaterThan(
    BillSyncStatus syncStatus, {
    bool include = false,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> syncStatusLessThan(
    BillSyncStatus syncStatus, {
    bool include = false,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> syncStatusBetween(
    BillSyncStatus lowerSyncStatus,
    BillSyncStatus upperSyncStatus, {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> createdAtEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> createdAtNotEqualTo(
    DateTime createdAt,
  ) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterWhereClause> createdAtBetween(
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

extension BillEntityQueryFilter
    on QueryBuilder<BillEntity, BillEntity, QFilterCondition> {
  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> billDateEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'billDate', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  billDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'billDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> billDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'billDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> billDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'billDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> cgstAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cgstAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  cgstAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cgstAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  cgstAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cgstAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> cgstAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cgstAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  cgstPercentEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cgstPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  cgstPercentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cgstPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  cgstPercentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cgstPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  cgstPercentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cgstPercent',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customerContact'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customerContact'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'customerContact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'customerContact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'customerContact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'customerContact',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'customerContact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'customerContact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'customerContact',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'customerContact',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerContact', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerContactIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerContact', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customerId'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customerId'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> customerIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'customerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'customerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'customerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> customerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'customerId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'customerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'customerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'customerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> customerIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'customerId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerId', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerId', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customerName'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customerName'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'customerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'customerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'customerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'customerName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'customerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'customerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'customerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'customerName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerName', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  customerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerName', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  discountAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'discountAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  discountAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'discountAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  discountAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'discountAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  discountAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'discountAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  discountPercentEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'discountPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  discountPercentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'discountPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  discountPercentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'discountPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  discountPercentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'discountPercent',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  finalAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'finalAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  finalAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'finalAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  finalAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'finalAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  finalAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'finalAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  isGstAppliedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isGstApplied', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  isMarkedForDeletionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isMarkedForDeletion', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  isTaxInclusiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isTaxInclusive', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  itemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, true, length, true);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, 0, true);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, false, 999999, true);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  itemsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, length, include);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  itemsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, include, 999999, true);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  itemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> needsSyncEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'needsSync', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesGreaterThan(
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesLessThan(
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesBetween(
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'otherTaxAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'otherTaxAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'otherTaxAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'otherTaxAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'otherTaxName'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'otherTaxName'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'otherTaxName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'otherTaxName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'otherTaxName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'otherTaxName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'otherTaxName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'otherTaxName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'otherTaxName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'otherTaxName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'otherTaxName', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'otherTaxName', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxPercentEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'otherTaxPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxPercentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'otherTaxPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxPercentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'otherTaxPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  otherTaxPercentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'otherTaxPercent',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> paidAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'paidAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  paidAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paidAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  paidAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paidAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> paidAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paidAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  paymentStatusEqualTo(BillPaymentStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paymentStatus', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  paymentStatusGreaterThan(BillPaymentStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paymentStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  paymentStatusLessThan(BillPaymentStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paymentStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  paymentStatusBetween(
    BillPaymentStatus lower,
    BillPaymentStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paymentStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  pendingAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pendingAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  pendingAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pendingAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  pendingAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pendingAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  pendingAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pendingAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  returnDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'returnDate'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  returnDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'returnDate'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> returnDateEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'returnDate', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  returnDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'returnDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  returnDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'returnDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> returnDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'returnDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  returnStatusEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'returnStatus', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> serverIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> serverIdLessThan(
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> serverIdBetween(
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> serverIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> serverIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> sgstAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sgstAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  sgstAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sgstAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  sgstAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sgstAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> sgstAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sgstAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  sgstPercentEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sgstPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  sgstPercentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sgstPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  sgstPercentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sgstPercent',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  sgstPercentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sgstPercent',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> syncStatusEqualTo(
    BillSyncStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  syncStatusGreaterThan(BillSyncStatus value, {bool include = false}) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  syncStatusLessThan(BillSyncStatus value, {bool include = false}) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> syncStatusBetween(
    BillSyncStatus lower,
    BillSyncStatus upper, {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalQuantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalQuantity', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalQuantityGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalQuantity',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalQuantityLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalQuantity',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalQuantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalQuantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalTaxAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalTaxAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalTaxAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalTaxAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalTaxAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalTaxAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
  totalTaxAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalTaxAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition>
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
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

  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> updatedAtBetween(
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

extension BillEntityQueryObject
    on QueryBuilder<BillEntity, BillEntity, QFilterCondition> {
  QueryBuilder<BillEntity, BillEntity, QAfterFilterCondition> itemsElement(
    FilterQuery<BillItemEmbedded> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'items');
    });
  }
}

extension BillEntityQueryLinks
    on QueryBuilder<BillEntity, BillEntity, QFilterCondition> {}

extension BillEntityQuerySortBy
    on QueryBuilder<BillEntity, BillEntity, QSortBy> {
  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByBillDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billDate', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByBillDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billDate', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCgstPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstPercent', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCgstPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstPercent', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCustomerContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  sortByCustomerContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  sortByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  sortByDiscountPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByFinalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByFinalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByIsGstApplied() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGstApplied', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByIsGstAppliedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGstApplied', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  sortByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  sortByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByIsTaxInclusive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTaxInclusive', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  sortByIsTaxInclusiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTaxInclusive', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByOtherTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  sortByOtherTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByOtherTaxName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxName', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByOtherTaxNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxName', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByOtherTaxPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxPercent', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  sortByOtherTaxPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxPercent', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByPaidAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByPaymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByPaymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByPendingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByPendingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByReturnDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnDate', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByReturnDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnDate', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByReturnStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnStatus', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByReturnStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnStatus', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortBySgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortBySgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortBySgstPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstPercent', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortBySgstPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstPercent', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByTotalQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByTotalQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByTotalTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTaxAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  sortByTotalTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTaxAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension BillEntityQuerySortThenBy
    on QueryBuilder<BillEntity, BillEntity, QSortThenBy> {
  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByBillDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billDate', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByBillDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billDate', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCgstPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstPercent', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCgstPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cgstPercent', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCustomerContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  thenByCustomerContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  thenByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  thenByDiscountPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByFinalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByFinalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByIsGstApplied() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGstApplied', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByIsGstAppliedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGstApplied', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  thenByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  thenByIsMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMarkedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByIsTaxInclusive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTaxInclusive', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  thenByIsTaxInclusiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTaxInclusive', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByOtherTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  thenByOtherTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByOtherTaxName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxName', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByOtherTaxNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxName', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByOtherTaxPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxPercent', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  thenByOtherTaxPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherTaxPercent', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByPaidAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByPaymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByPaymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByPendingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByPendingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByReturnDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnDate', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByReturnDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnDate', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByReturnStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnStatus', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByReturnStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnStatus', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenBySgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenBySgstAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenBySgstPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstPercent', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenBySgstPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sgstPercent', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByTotalQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByTotalQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByTotalTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTaxAmount', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy>
  thenByTotalTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTaxAmount', Sort.desc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension BillEntityQueryWhereDistinct
    on QueryBuilder<BillEntity, BillEntity, QDistinct> {
  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByBillDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'billDate');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByCgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cgstAmount');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByCgstPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cgstPercent');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByCustomerContact({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'customerContact',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByCustomerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByCustomerName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountAmount');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountPercent');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByFinalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'finalAmount');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByIsGstApplied() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isGstApplied');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct>
  distinctByIsMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByIsTaxInclusive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTaxInclusive');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByOtherTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherTaxAmount');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByOtherTaxName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherTaxName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByOtherTaxPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherTaxPercent');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paidAmount');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByPaymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentStatus');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByPendingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingAmount');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByReturnDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'returnDate');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByReturnStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'returnStatus');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByServerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctBySgstAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sgstAmount');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctBySgstPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sgstPercent');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByTotalQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalQuantity');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByTotalTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalTaxAmount');
    });
  }

  QueryBuilder<BillEntity, BillEntity, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension BillEntityQueryProperty
    on QueryBuilder<BillEntity, BillEntity, QQueryProperty> {
  QueryBuilder<BillEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BillEntity, DateTime, QQueryOperations> billDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'billDate');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> cgstAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cgstAmount');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> cgstPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cgstPercent');
    });
  }

  QueryBuilder<BillEntity, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<BillEntity, String?, QQueryOperations>
  customerContactProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerContact');
    });
  }

  QueryBuilder<BillEntity, String?, QQueryOperations> customerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerId');
    });
  }

  QueryBuilder<BillEntity, String?, QQueryOperations> customerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerName');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> discountAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountAmount');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> discountPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountPercent');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> finalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'finalAmount');
    });
  }

  QueryBuilder<BillEntity, bool, QQueryOperations> isGstAppliedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isGstApplied');
    });
  }

  QueryBuilder<BillEntity, bool, QQueryOperations>
  isMarkedForDeletionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMarkedForDeletion');
    });
  }

  QueryBuilder<BillEntity, bool, QQueryOperations> isTaxInclusiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTaxInclusive');
    });
  }

  QueryBuilder<BillEntity, List<BillItemEmbedded>, QQueryOperations>
  itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'items');
    });
  }

  QueryBuilder<BillEntity, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<BillEntity, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> otherTaxAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherTaxAmount');
    });
  }

  QueryBuilder<BillEntity, String?, QQueryOperations> otherTaxNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherTaxName');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> otherTaxPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherTaxPercent');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> paidAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paidAmount');
    });
  }

  QueryBuilder<BillEntity, BillPaymentStatus, QQueryOperations>
  paymentStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentStatus');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> pendingAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingAmount');
    });
  }

  QueryBuilder<BillEntity, DateTime?, QQueryOperations> returnDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'returnDate');
    });
  }

  QueryBuilder<BillEntity, bool, QQueryOperations> returnStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'returnStatus');
    });
  }

  QueryBuilder<BillEntity, String?, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> sgstAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sgstAmount');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> sgstPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sgstPercent');
    });
  }

  QueryBuilder<BillEntity, BillSyncStatus, QQueryOperations>
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<BillEntity, int, QQueryOperations> totalQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalQuantity');
    });
  }

  QueryBuilder<BillEntity, double, QQueryOperations> totalTaxAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalTaxAmount');
    });
  }

  QueryBuilder<BillEntity, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const BillItemEmbeddedSchema = Schema(
  name: r'BillItemEmbedded',
  id: 2336104038497063482,
  properties: {
    r'hsnCode': PropertySchema(id: 0, name: r'hsnCode', type: IsarType.string),
    r'itemId': PropertySchema(id: 1, name: r'itemId', type: IsarType.string),
    r'productId': PropertySchema(
      id: 2,
      name: r'productId',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 3,
      name: r'productName',
      type: IsarType.string,
    ),
    r'purchasePrice': PropertySchema(
      id: 4,
      name: r'purchasePrice',
      type: IsarType.double,
    ),
    r'quantity': PropertySchema(
      id: 5,
      name: r'quantity',
      type: IsarType.double,
    ),
    r'returnedQuantity': PropertySchema(
      id: 6,
      name: r'returnedQuantity',
      type: IsarType.double,
    ),
    r'sellUnit': PropertySchema(
      id: 7,
      name: r'sellUnit',
      type: IsarType.string,
    ),
    r'sellingPrice': PropertySchema(
      id: 8,
      name: r'sellingPrice',
      type: IsarType.double,
    ),
    r'subtotal': PropertySchema(
      id: 9,
      name: r'subtotal',
      type: IsarType.double,
    ),
    r'unit': PropertySchema(id: 10, name: r'unit', type: IsarType.string),
  },

  estimateSize: _billItemEmbeddedEstimateSize,
  serialize: _billItemEmbeddedSerialize,
  deserialize: _billItemEmbeddedDeserialize,
  deserializeProp: _billItemEmbeddedDeserializeProp,
);

int _billItemEmbeddedEstimateSize(
  BillItemEmbedded object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.hsnCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.itemId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.productId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.productName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sellUnit;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.unit;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _billItemEmbeddedSerialize(
  BillItemEmbedded object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.hsnCode);
  writer.writeString(offsets[1], object.itemId);
  writer.writeString(offsets[2], object.productId);
  writer.writeString(offsets[3], object.productName);
  writer.writeDouble(offsets[4], object.purchasePrice);
  writer.writeDouble(offsets[5], object.quantity);
  writer.writeDouble(offsets[6], object.returnedQuantity);
  writer.writeString(offsets[7], object.sellUnit);
  writer.writeDouble(offsets[8], object.sellingPrice);
  writer.writeDouble(offsets[9], object.subtotal);
  writer.writeString(offsets[10], object.unit);
}

BillItemEmbedded _billItemEmbeddedDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BillItemEmbedded(
    hsnCode: reader.readStringOrNull(offsets[0]),
    itemId: reader.readStringOrNull(offsets[1]),
    productId: reader.readStringOrNull(offsets[2]),
    productName: reader.readStringOrNull(offsets[3]),
    purchasePrice: reader.readDoubleOrNull(offsets[4]) ?? 0.0,
    quantity: reader.readDoubleOrNull(offsets[5]) ?? 0.0,
    returnedQuantity: reader.readDoubleOrNull(offsets[6]) ?? 0.0,
    sellUnit: reader.readStringOrNull(offsets[7]),
    sellingPrice: reader.readDoubleOrNull(offsets[8]) ?? 0.0,
    subtotal: reader.readDoubleOrNull(offsets[9]) ?? 0.0,
    unit: reader.readStringOrNull(offsets[10]),
  );
  return object;
}

P _billItemEmbeddedDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 5:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 6:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 9:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension BillItemEmbeddedQueryFilter
    on QueryBuilder<BillItemEmbedded, BillItemEmbedded, QFilterCondition> {
  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'hsnCode'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'hsnCode'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'hsnCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'hsnCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'hsnCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'hsnCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'hsnCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'hsnCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'hsnCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'hsnCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hsnCode', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  hsnCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'hsnCode', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'itemId'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'itemId'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'itemId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'itemId', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  itemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'itemId', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'productId'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'productId'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productIdEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productIdGreaterThan(
    String? value, {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productIdLessThan(
    String? value, {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'productName'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'productName'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productNameEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productNameGreaterThan(
    String? value, {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productNameLessThan(
    String? value, {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productNameBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  quantityEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'quantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  quantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  quantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  quantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  returnedQuantityEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'returnedQuantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  returnedQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'returnedQuantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  returnedQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'returnedQuantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  returnedQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'returnedQuantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sellUnit'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sellUnit'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sellUnit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sellUnit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sellUnit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sellUnit',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sellUnit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sellUnit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sellUnit',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sellUnit',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sellUnit', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  sellUnitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sellUnit', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  subtotalEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subtotal',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  subtotalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subtotal',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  subtotalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subtotal',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  subtotalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subtotal',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  unitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'unit'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  unitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'unit'),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  unitEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  unitGreaterThan(
    String? value, {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  unitLessThan(
    String? value, {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  unitBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  unitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'unit', value: ''),
      );
    });
  }

  QueryBuilder<BillItemEmbedded, BillItemEmbedded, QAfterFilterCondition>
  unitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'unit', value: ''),
      );
    });
  }
}

extension BillItemEmbeddedQueryObject
    on QueryBuilder<BillItemEmbedded, BillItemEmbedded, QFilterCondition> {}
