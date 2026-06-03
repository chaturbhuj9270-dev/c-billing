// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotation_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetQuotationEntityCollection on Isar {
  IsarCollection<QuotationEntity> get quotationEntitys => this.collection();
}

const QuotationEntitySchema = CollectionSchema(
  name: r'QuotationEntity',
  id: -7617856732553923070,
  properties: {
    r'convertedBillId': PropertySchema(
      id: 0,
      name: r'convertedBillId',
      type: IsarType.string,
    ),
    r'convertedEventOrderId': PropertySchema(
      id: 1,
      name: r'convertedEventOrderId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'customDataJson': PropertySchema(
      id: 3,
      name: r'customDataJson',
      type: IsarType.string,
    ),
    r'customerAddress': PropertySchema(
      id: 4,
      name: r'customerAddress',
      type: IsarType.string,
    ),
    r'customerContact': PropertySchema(
      id: 5,
      name: r'customerContact',
      type: IsarType.string,
    ),
    r'customerId': PropertySchema(
      id: 6,
      name: r'customerId',
      type: IsarType.string,
    ),
    r'customerName': PropertySchema(
      id: 7,
      name: r'customerName',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 8,
      name: r'description',
      type: IsarType.string,
    ),
    r'discountAmount': PropertySchema(
      id: 9,
      name: r'discountAmount',
      type: IsarType.double,
    ),
    r'discountPercent': PropertySchema(
      id: 10,
      name: r'discountPercent',
      type: IsarType.double,
    ),
    r'eventCharges': PropertySchema(
      id: 11,
      name: r'eventCharges',
      type: IsarType.double,
    ),
    r'eventLocation': PropertySchema(
      id: 12,
      name: r'eventLocation',
      type: IsarType.string,
    ),
    r'items': PropertySchema(
      id: 13,
      name: r'items',
      type: IsarType.objectList,

      target: r'OrderItemEmbedded',
    ),
    r'notes': PropertySchema(id: 14, name: r'notes', type: IsarType.string),
    r'quotationNumber': PropertySchema(
      id: 15,
      name: r'quotationNumber',
      type: IsarType.string,
    ),
    r'quotationType': PropertySchema(
      id: 16,
      name: r'quotationType',
      type: IsarType.long,
    ),
    r'referenceDate': PropertySchema(
      id: 17,
      name: r'referenceDate',
      type: IsarType.dateTime,
    ),
    r'serverId': PropertySchema(
      id: 18,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(id: 19, name: r'status', type: IsarType.long),
    r'subEvents': PropertySchema(
      id: 20,
      name: r'subEvents',
      type: IsarType.objectList,

      target: r'SubEventEmbedded',
    ),
    r'syncStatus': PropertySchema(
      id: 21,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _QuotationEntitysyncStatusEnumValueMap,
    ),
    r'title': PropertySchema(id: 22, name: r'title', type: IsarType.string),
    r'totalAmount': PropertySchema(
      id: 23,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 24,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'validUntil': PropertySchema(
      id: 25,
      name: r'validUntil',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _quotationEntityEstimateSize,
  serialize: _quotationEntitySerialize,
  deserialize: _quotationEntityDeserialize,
  deserializeProp: _quotationEntityDeserializeProp,
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
    r'quotationNumber': IndexSchema(
      id: -2731158400638475626,
      name: r'quotationNumber',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'quotationNumber',
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
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'referenceDate': IndexSchema(
      id: -9030900268725656147,
      name: r'referenceDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'referenceDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'validUntil': IndexSchema(
      id: -7656686825200414006,
      name: r'validUntil',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'validUntil',
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
  embeddedSchemas: {
    r'SubEventEmbedded': SubEventEmbeddedSchema,
    r'OrderItemEmbedded': OrderItemEmbeddedSchema,
  },

  getId: _quotationEntityGetId,
  getLinks: _quotationEntityGetLinks,
  attach: _quotationEntityAttach,
  version: '3.3.2',
);

int _quotationEntityEstimateSize(
  QuotationEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.convertedBillId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.convertedEventOrderId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customDataJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customerAddress;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.customerContact.length * 3;
  {
    final value = object.customerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.customerName.length * 3;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.eventLocation;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.items.length * 3;
  {
    final offsets = allOffsets[OrderItemEmbedded]!;
    for (var i = 0; i < object.items.length; i++) {
      final value = object.items[i];
      bytesCount += OrderItemEmbeddedSchema.estimateSize(
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
  bytesCount += 3 + object.quotationNumber.length * 3;
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.subEvents.length * 3;
  {
    final offsets = allOffsets[SubEventEmbedded]!;
    for (var i = 0; i < object.subEvents.length; i++) {
      final value = object.subEvents[i];
      bytesCount += SubEventEmbeddedSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _quotationEntitySerialize(
  QuotationEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.convertedBillId);
  writer.writeString(offsets[1], object.convertedEventOrderId);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.customDataJson);
  writer.writeString(offsets[4], object.customerAddress);
  writer.writeString(offsets[5], object.customerContact);
  writer.writeString(offsets[6], object.customerId);
  writer.writeString(offsets[7], object.customerName);
  writer.writeString(offsets[8], object.description);
  writer.writeDouble(offsets[9], object.discountAmount);
  writer.writeDouble(offsets[10], object.discountPercent);
  writer.writeDouble(offsets[11], object.eventCharges);
  writer.writeString(offsets[12], object.eventLocation);
  writer.writeObjectList<OrderItemEmbedded>(
    offsets[13],
    allOffsets,
    OrderItemEmbeddedSchema.serialize,
    object.items,
  );
  writer.writeString(offsets[14], object.notes);
  writer.writeString(offsets[15], object.quotationNumber);
  writer.writeLong(offsets[16], object.quotationType);
  writer.writeDateTime(offsets[17], object.referenceDate);
  writer.writeString(offsets[18], object.serverId);
  writer.writeLong(offsets[19], object.status);
  writer.writeObjectList<SubEventEmbedded>(
    offsets[20],
    allOffsets,
    SubEventEmbeddedSchema.serialize,
    object.subEvents,
  );
  writer.writeByte(offsets[21], object.syncStatus.index);
  writer.writeString(offsets[22], object.title);
  writer.writeDouble(offsets[23], object.totalAmount);
  writer.writeDateTime(offsets[24], object.updatedAt);
  writer.writeDateTime(offsets[25], object.validUntil);
}

QuotationEntity _quotationEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = QuotationEntity(
    convertedBillId: reader.readStringOrNull(offsets[0]),
    convertedEventOrderId: reader.readStringOrNull(offsets[1]),
    createdAt: reader.readDateTime(offsets[2]),
    customDataJson: reader.readStringOrNull(offsets[3]),
    customerAddress: reader.readStringOrNull(offsets[4]),
    customerContact: reader.readStringOrNull(offsets[5]) ?? '',
    customerId: reader.readStringOrNull(offsets[6]),
    customerName: reader.readStringOrNull(offsets[7]) ?? '',
    description: reader.readStringOrNull(offsets[8]),
    discountAmount: reader.readDoubleOrNull(offsets[9]) ?? 0.0,
    discountPercent: reader.readDoubleOrNull(offsets[10]) ?? 0.0,
    eventCharges: reader.readDoubleOrNull(offsets[11]) ?? 0.0,
    eventLocation: reader.readStringOrNull(offsets[12]),
    items:
        reader.readObjectList<OrderItemEmbedded>(
          offsets[13],
          OrderItemEmbeddedSchema.deserialize,
          allOffsets,
          OrderItemEmbedded(),
        ) ??
        [],
    notes: reader.readStringOrNull(offsets[14]),
    quotationNumber: reader.readStringOrNull(offsets[15]) ?? '',
    quotationType: reader.readLongOrNull(offsets[16]) ?? 0,
    referenceDate: reader.readDateTime(offsets[17]),
    serverId: reader.readStringOrNull(offsets[18]),
    status: reader.readLongOrNull(offsets[19]) ?? 0,
    subEvents:
        reader.readObjectList<SubEventEmbedded>(
          offsets[20],
          SubEventEmbeddedSchema.deserialize,
          allOffsets,
          SubEventEmbedded(),
        ) ??
        [],
    syncStatus:
        _QuotationEntitysyncStatusValueEnumMap[reader.readByteOrNull(
          offsets[21],
        )] ??
        QuotationSyncStatus.newRecord,
    title: reader.readStringOrNull(offsets[22]) ?? '',
    totalAmount: reader.readDoubleOrNull(offsets[23]) ?? 0.0,
    updatedAt: reader.readDateTime(offsets[24]),
    validUntil: reader.readDateTime(offsets[25]),
  );
  object.id = id;
  return object;
}

P _quotationEntityDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 10:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 11:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readObjectList<OrderItemEmbedded>(
                offset,
                OrderItemEmbeddedSchema.deserialize,
                allOffsets,
                OrderItemEmbedded(),
              ) ??
              [])
          as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 16:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 17:
      return (reader.readDateTime(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 20:
      return (reader.readObjectList<SubEventEmbedded>(
                offset,
                SubEventEmbeddedSchema.deserialize,
                allOffsets,
                SubEventEmbedded(),
              ) ??
              [])
          as P;
    case 21:
      return (_QuotationEntitysyncStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              QuotationSyncStatus.newRecord)
          as P;
    case 22:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 23:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 24:
      return (reader.readDateTime(offset)) as P;
    case 25:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _QuotationEntitysyncStatusEnumValueMap = {
  'newRecord': 0,
  'updated': 1,
  'deleted': 2,
  'synced': 3,
};
const _QuotationEntitysyncStatusValueEnumMap = {
  0: QuotationSyncStatus.newRecord,
  1: QuotationSyncStatus.updated,
  2: QuotationSyncStatus.deleted,
  3: QuotationSyncStatus.synced,
};

Id _quotationEntityGetId(QuotationEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _quotationEntityGetLinks(QuotationEntity object) {
  return [];
}

void _quotationEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  QuotationEntity object,
) {
  object.id = id;
}

extension QuotationEntityQueryWhereSort
    on QueryBuilder<QuotationEntity, QuotationEntity, QWhere> {
  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhere>
  anyReferenceDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'referenceDate'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhere> anyValidUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'validUntil'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhere> anyStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'status'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension QuotationEntityQueryWhere
    on QueryBuilder<QuotationEntity, QuotationEntity, QWhereClause> {
  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [null]),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  serverIdEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [serverId]),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  quotationNumberEqualTo(String quotationNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'quotationNumber',
          value: [quotationNumber],
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  quotationNumberNotEqualTo(String quotationNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'quotationNumber',
                lower: [],
                upper: [quotationNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'quotationNumber',
                lower: [quotationNumber],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'quotationNumber',
                lower: [quotationNumber],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'quotationNumber',
                lower: [],
                upper: [quotationNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  customerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'customerId', value: [null]),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  customerIdEqualTo(String? customerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'customerId', value: [customerId]),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  customerIdNotEqualTo(String? customerId) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  titleEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: [title]),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  titleNotEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [],
                upper: [title],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [title],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [title],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [],
                upper: [title],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  referenceDateEqualTo(DateTime referenceDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'referenceDate',
          value: [referenceDate],
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  referenceDateNotEqualTo(DateTime referenceDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'referenceDate',
                lower: [],
                upper: [referenceDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'referenceDate',
                lower: [referenceDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'referenceDate',
                lower: [referenceDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'referenceDate',
                lower: [],
                upper: [referenceDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  referenceDateGreaterThan(DateTime referenceDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'referenceDate',
          lower: [referenceDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  referenceDateLessThan(DateTime referenceDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'referenceDate',
          lower: [],
          upper: [referenceDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  referenceDateBetween(
    DateTime lowerReferenceDate,
    DateTime upperReferenceDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'referenceDate',
          lower: [lowerReferenceDate],
          includeLower: includeLower,
          upper: [upperReferenceDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  validUntilEqualTo(DateTime validUntil) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'validUntil', value: [validUntil]),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  validUntilNotEqualTo(DateTime validUntil) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'validUntil',
                lower: [],
                upper: [validUntil],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'validUntil',
                lower: [validUntil],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'validUntil',
                lower: [validUntil],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'validUntil',
                lower: [],
                upper: [validUntil],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  validUntilGreaterThan(DateTime validUntil, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'validUntil',
          lower: [validUntil],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  validUntilLessThan(DateTime validUntil, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'validUntil',
          lower: [],
          upper: [validUntil],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  validUntilBetween(
    DateTime lowerValidUntil,
    DateTime upperValidUntil, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'validUntil',
          lower: [lowerValidUntil],
          includeLower: includeLower,
          upper: [upperValidUntil],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  statusEqualTo(int status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'status', value: [status]),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  statusNotEqualTo(int status) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  statusGreaterThan(int status, {bool include = false}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  statusLessThan(int status, {bool include = false}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  statusBetween(
    int lowerStatus,
    int upperStatus, {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterWhereClause>
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

extension QuotationEntityQueryFilter
    on QueryBuilder<QuotationEntity, QuotationEntity, QFilterCondition> {
  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'convertedBillId'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'convertedBillId'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'convertedBillId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'convertedBillId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'convertedBillId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'convertedBillId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'convertedBillId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'convertedBillId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'convertedBillId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'convertedBillId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'convertedBillId', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedBillIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'convertedBillId', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'convertedEventOrderId'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'convertedEventOrderId'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'convertedEventOrderId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'convertedEventOrderId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'convertedEventOrderId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'convertedEventOrderId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'convertedEventOrderId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'convertedEventOrderId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'convertedEventOrderId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'convertedEventOrderId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'convertedEventOrderId', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  convertedEventOrderIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'convertedEventOrderId',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customDataJson'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customDataJson'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'customDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'customDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'customDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'customDataJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'customDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'customDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'customDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'customDataJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customDataJson', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customDataJson', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customerAddress'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customerAddress'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'customerAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'customerAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'customerAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'customerAddress',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'customerAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'customerAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'customerAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'customerAddress',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerAddress', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerAddress', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerContactEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerContactGreaterThan(
    String value, {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerContactLessThan(
    String value, {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerContactBetween(
    String lower,
    String upper, {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerContactIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerContact', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerContactIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerContact', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customerId'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customerId'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerIdEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerIdBetween(
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerId', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerId', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerNameEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerNameGreaterThan(
    String value, {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerNameLessThan(
    String value, {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerNameBetween(
    String lower,
    String upper, {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerName', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  customerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerName', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'description'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'description'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'description',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'description',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventChargesEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eventCharges',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventChargesGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eventCharges',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventChargesLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eventCharges',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventChargesBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eventCharges',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'eventLocation'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'eventLocation'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eventLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eventLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eventLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eventLocation',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eventLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eventLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eventLocation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eventLocation',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventLocation', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  eventLocationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventLocation', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  itemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, true, length, true);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, 0, true);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, false, 999999, true);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  itemsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, length, include);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  itemsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, include, 999999, true);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'quotationNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quotationNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quotationNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quotationNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'quotationNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'quotationNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'quotationNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'quotationNumber',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'quotationNumber', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'quotationNumber', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationTypeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'quotationType', value: value),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationTypeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quotationType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationTypeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quotationType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  quotationTypeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quotationType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  referenceDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'referenceDate', value: value),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  referenceDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'referenceDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  referenceDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'referenceDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  referenceDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'referenceDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  statusEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  statusGreaterThan(int value, {bool include = false}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  statusLessThan(int value, {bool include = false}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  statusBetween(
    int lower,
    int upper, {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  subEventsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', length, true, length, true);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  subEventsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', 0, true, 0, true);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  subEventsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', 0, false, 999999, true);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  subEventsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', 0, true, length, include);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  subEventsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', length, include, 999999, true);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  subEventsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subEvents',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  syncStatusEqualTo(QuotationSyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  syncStatusGreaterThan(QuotationSyncStatus value, {bool include = false}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  syncStatusLessThan(QuotationSyncStatus value, {bool include = false}) {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  syncStatusBetween(
    QuotationSyncStatus lower,
    QuotationSyncStatus upper, {
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
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

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  validUntilEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'validUntil', value: value),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  validUntilGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'validUntil',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  validUntilLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'validUntil',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  validUntilBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'validUntil',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension QuotationEntityQueryObject
    on QueryBuilder<QuotationEntity, QuotationEntity, QFilterCondition> {
  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  itemsElement(FilterQuery<OrderItemEmbedded> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'items');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterFilterCondition>
  subEventsElement(FilterQuery<SubEventEmbedded> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'subEvents');
    });
  }
}

extension QuotationEntityQueryLinks
    on QueryBuilder<QuotationEntity, QuotationEntity, QFilterCondition> {}

extension QuotationEntityQuerySortBy
    on QueryBuilder<QuotationEntity, QuotationEntity, QSortBy> {
  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByConvertedBillId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedBillId', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByConvertedBillIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedBillId', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByConvertedEventOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedEventOrderId', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByConvertedEventOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedEventOrderId', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customDataJson', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customDataJson', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomerAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAddress', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomerAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAddress', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomerContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomerContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByDiscountPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByEventCharges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCharges', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByEventChargesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCharges', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByEventLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByEventLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByQuotationNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quotationNumber', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByQuotationNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quotationNumber', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByQuotationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quotationType', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByQuotationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quotationType', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByReferenceDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceDate', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByReferenceDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceDate', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByValidUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validUntil', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  sortByValidUntilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validUntil', Sort.desc);
    });
  }
}

extension QuotationEntityQuerySortThenBy
    on QueryBuilder<QuotationEntity, QuotationEntity, QSortThenBy> {
  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByConvertedBillId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedBillId', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByConvertedBillIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedBillId', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByConvertedEventOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedEventOrderId', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByConvertedEventOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedEventOrderId', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customDataJson', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customDataJson', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomerAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAddress', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomerAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAddress', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomerContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomerContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByDiscountPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercent', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByEventCharges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCharges', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByEventChargesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCharges', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByEventLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByEventLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByQuotationNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quotationNumber', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByQuotationNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quotationNumber', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByQuotationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quotationType', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByQuotationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quotationType', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByReferenceDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceDate', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByReferenceDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceDate', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByValidUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validUntil', Sort.asc);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QAfterSortBy>
  thenByValidUntilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validUntil', Sort.desc);
    });
  }
}

extension QuotationEntityQueryWhereDistinct
    on QueryBuilder<QuotationEntity, QuotationEntity, QDistinct> {
  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByConvertedBillId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'convertedBillId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByConvertedEventOrderId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'convertedEventOrderId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByCustomDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'customDataJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByCustomerAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'customerAddress',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByCustomerContact({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'customerContact',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByCustomerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByCustomerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountAmount');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByDiscountPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountPercent');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByEventCharges() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventCharges');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByEventLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'eventLocation',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct> distinctByNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByQuotationNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'quotationNumber',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByQuotationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quotationType');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByReferenceDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceDate');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct> distinctByServerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<QuotationEntity, QuotationEntity, QDistinct>
  distinctByValidUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'validUntil');
    });
  }
}

extension QuotationEntityQueryProperty
    on QueryBuilder<QuotationEntity, QuotationEntity, QQueryProperty> {
  QueryBuilder<QuotationEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<QuotationEntity, String?, QQueryOperations>
  convertedBillIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'convertedBillId');
    });
  }

  QueryBuilder<QuotationEntity, String?, QQueryOperations>
  convertedEventOrderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'convertedEventOrderId');
    });
  }

  QueryBuilder<QuotationEntity, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<QuotationEntity, String?, QQueryOperations>
  customDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customDataJson');
    });
  }

  QueryBuilder<QuotationEntity, String?, QQueryOperations>
  customerAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerAddress');
    });
  }

  QueryBuilder<QuotationEntity, String, QQueryOperations>
  customerContactProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerContact');
    });
  }

  QueryBuilder<QuotationEntity, String?, QQueryOperations>
  customerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerId');
    });
  }

  QueryBuilder<QuotationEntity, String, QQueryOperations>
  customerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerName');
    });
  }

  QueryBuilder<QuotationEntity, String?, QQueryOperations>
  descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<QuotationEntity, double, QQueryOperations>
  discountAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountAmount');
    });
  }

  QueryBuilder<QuotationEntity, double, QQueryOperations>
  discountPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountPercent');
    });
  }

  QueryBuilder<QuotationEntity, double, QQueryOperations>
  eventChargesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventCharges');
    });
  }

  QueryBuilder<QuotationEntity, String?, QQueryOperations>
  eventLocationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventLocation');
    });
  }

  QueryBuilder<QuotationEntity, List<OrderItemEmbedded>, QQueryOperations>
  itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'items');
    });
  }

  QueryBuilder<QuotationEntity, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<QuotationEntity, String, QQueryOperations>
  quotationNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quotationNumber');
    });
  }

  QueryBuilder<QuotationEntity, int, QQueryOperations> quotationTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quotationType');
    });
  }

  QueryBuilder<QuotationEntity, DateTime, QQueryOperations>
  referenceDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceDate');
    });
  }

  QueryBuilder<QuotationEntity, String?, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<QuotationEntity, int, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<QuotationEntity, List<SubEventEmbedded>, QQueryOperations>
  subEventsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subEvents');
    });
  }

  QueryBuilder<QuotationEntity, QuotationSyncStatus, QQueryOperations>
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<QuotationEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<QuotationEntity, double, QQueryOperations>
  totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<QuotationEntity, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<QuotationEntity, DateTime, QQueryOperations>
  validUntilProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'validUntil');
    });
  }
}
