// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_order_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEventOrderEntityCollection on Isar {
  IsarCollection<EventOrderEntity> get eventOrderEntitys => this.collection();
}

const EventOrderEntitySchema = CollectionSchema(
  name: r'EventOrderEntity',
  id: -8658813915944641777,
  properties: {
    r'advanceAmount': PropertySchema(
      id: 0,
      name: r'advanceAmount',
      type: IsarType.double,
    ),
    r'convertedBillId': PropertySchema(
      id: 1,
      name: r'convertedBillId',
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
    r'eventCharges': PropertySchema(
      id: 9,
      name: r'eventCharges',
      type: IsarType.double,
    ),
    r'eventDate': PropertySchema(
      id: 10,
      name: r'eventDate',
      type: IsarType.dateTime,
    ),
    r'eventLocation': PropertySchema(
      id: 11,
      name: r'eventLocation',
      type: IsarType.string,
    ),
    r'items': PropertySchema(
      id: 12,
      name: r'items',
      type: IsarType.objectList,

      target: r'OrderItemEmbedded',
    ),
    r'notes': PropertySchema(id: 13, name: r'notes', type: IsarType.string),
    r'orderName': PropertySchema(
      id: 14,
      name: r'orderName',
      type: IsarType.string,
    ),
    r'orderType': PropertySchema(
      id: 15,
      name: r'orderType',
      type: IsarType.long,
    ),
    r'remainingAmount': PropertySchema(
      id: 16,
      name: r'remainingAmount',
      type: IsarType.double,
    ),
    r'serverId': PropertySchema(
      id: 17,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(id: 18, name: r'status', type: IsarType.long),
    r'subEvents': PropertySchema(
      id: 19,
      name: r'subEvents',
      type: IsarType.objectList,

      target: r'SubEventEmbedded',
    ),
    r'syncStatus': PropertySchema(
      id: 20,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _EventOrderEntitysyncStatusEnumValueMap,
    ),
    r'totalAmount': PropertySchema(
      id: 21,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 22,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _eventOrderEntityEstimateSize,
  serialize: _eventOrderEntitySerialize,
  deserialize: _eventOrderEntityDeserialize,
  deserializeProp: _eventOrderEntityDeserializeProp,
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
    r'orderName': IndexSchema(
      id: -167480682097965147,
      name: r'orderName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'orderName',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'eventDate': IndexSchema(
      id: -2827469816326842607,
      name: r'eventDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventDate',
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

  getId: _eventOrderEntityGetId,
  getLinks: _eventOrderEntityGetLinks,
  attach: _eventOrderEntityAttach,
  version: '3.3.2',
);

int _eventOrderEntityEstimateSize(
  EventOrderEntity object,
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
  bytesCount += 3 + object.orderName.length * 3;
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
  return bytesCount;
}

void _eventOrderEntitySerialize(
  EventOrderEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.advanceAmount);
  writer.writeString(offsets[1], object.convertedBillId);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.customDataJson);
  writer.writeString(offsets[4], object.customerAddress);
  writer.writeString(offsets[5], object.customerContact);
  writer.writeString(offsets[6], object.customerId);
  writer.writeString(offsets[7], object.customerName);
  writer.writeString(offsets[8], object.description);
  writer.writeDouble(offsets[9], object.eventCharges);
  writer.writeDateTime(offsets[10], object.eventDate);
  writer.writeString(offsets[11], object.eventLocation);
  writer.writeObjectList<OrderItemEmbedded>(
    offsets[12],
    allOffsets,
    OrderItemEmbeddedSchema.serialize,
    object.items,
  );
  writer.writeString(offsets[13], object.notes);
  writer.writeString(offsets[14], object.orderName);
  writer.writeLong(offsets[15], object.orderType);
  writer.writeDouble(offsets[16], object.remainingAmount);
  writer.writeString(offsets[17], object.serverId);
  writer.writeLong(offsets[18], object.status);
  writer.writeObjectList<SubEventEmbedded>(
    offsets[19],
    allOffsets,
    SubEventEmbeddedSchema.serialize,
    object.subEvents,
  );
  writer.writeByte(offsets[20], object.syncStatus.index);
  writer.writeDouble(offsets[21], object.totalAmount);
  writer.writeDateTime(offsets[22], object.updatedAt);
}

EventOrderEntity _eventOrderEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EventOrderEntity(
    advanceAmount: reader.readDoubleOrNull(offsets[0]) ?? 0.0,
    convertedBillId: reader.readStringOrNull(offsets[1]),
    createdAt: reader.readDateTime(offsets[2]),
    customDataJson: reader.readStringOrNull(offsets[3]),
    customerAddress: reader.readStringOrNull(offsets[4]),
    customerContact: reader.readStringOrNull(offsets[5]) ?? '',
    customerId: reader.readStringOrNull(offsets[6]),
    customerName: reader.readStringOrNull(offsets[7]) ?? '',
    description: reader.readStringOrNull(offsets[8]),
    eventCharges: reader.readDoubleOrNull(offsets[9]) ?? 0.0,
    eventDate: reader.readDateTime(offsets[10]),
    eventLocation: reader.readStringOrNull(offsets[11]),
    items:
        reader.readObjectList<OrderItemEmbedded>(
          offsets[12],
          OrderItemEmbeddedSchema.deserialize,
          allOffsets,
          OrderItemEmbedded(),
        ) ??
        [],
    notes: reader.readStringOrNull(offsets[13]),
    orderName: reader.readStringOrNull(offsets[14]) ?? '',
    orderType: reader.readLongOrNull(offsets[15]) ?? 0,
    remainingAmount: reader.readDoubleOrNull(offsets[16]) ?? 0.0,
    serverId: reader.readStringOrNull(offsets[17]),
    status: reader.readLongOrNull(offsets[18]) ?? 0,
    subEvents:
        reader.readObjectList<SubEventEmbedded>(
          offsets[19],
          SubEventEmbeddedSchema.deserialize,
          allOffsets,
          SubEventEmbedded(),
        ) ??
        [],
    syncStatus:
        _EventOrderEntitysyncStatusValueEnumMap[reader.readByteOrNull(
          offsets[20],
        )] ??
        EventOrderSyncStatus.newRecord,
    totalAmount: reader.readDoubleOrNull(offsets[21]) ?? 0.0,
    updatedAt: reader.readDateTime(offsets[22]),
  );
  object.id = id;
  return object;
}

P _eventOrderEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
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
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readObjectList<OrderItemEmbedded>(
                offset,
                OrderItemEmbeddedSchema.deserialize,
                allOffsets,
                OrderItemEmbedded(),
              ) ??
              [])
          as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 15:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 16:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 19:
      return (reader.readObjectList<SubEventEmbedded>(
                offset,
                SubEventEmbeddedSchema.deserialize,
                allOffsets,
                SubEventEmbedded(),
              ) ??
              [])
          as P;
    case 20:
      return (_EventOrderEntitysyncStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              EventOrderSyncStatus.newRecord)
          as P;
    case 21:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 22:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _EventOrderEntitysyncStatusEnumValueMap = {
  'newRecord': 0,
  'updated': 1,
  'deleted': 2,
  'synced': 3,
};
const _EventOrderEntitysyncStatusValueEnumMap = {
  0: EventOrderSyncStatus.newRecord,
  1: EventOrderSyncStatus.updated,
  2: EventOrderSyncStatus.deleted,
  3: EventOrderSyncStatus.synced,
};

Id _eventOrderEntityGetId(EventOrderEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _eventOrderEntityGetLinks(EventOrderEntity object) {
  return [];
}

void _eventOrderEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  EventOrderEntity object,
) {
  object.id = id;
}

extension EventOrderEntityQueryWhereSort
    on QueryBuilder<EventOrderEntity, EventOrderEntity, QWhere> {
  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhere> anyEventDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'eventDate'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhere> anyStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'status'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension EventOrderEntityQueryWhere
    on QueryBuilder<EventOrderEntity, EventOrderEntity, QWhereClause> {
  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [null]),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  serverIdEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [serverId]),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  customerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'customerId', value: [null]),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  customerIdEqualTo(String? customerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'customerId', value: [customerId]),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  orderNameEqualTo(String orderName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'orderName', value: [orderName]),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  orderNameNotEqualTo(String orderName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'orderName',
                lower: [],
                upper: [orderName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'orderName',
                lower: [orderName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'orderName',
                lower: [orderName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'orderName',
                lower: [],
                upper: [orderName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  eventDateEqualTo(DateTime eventDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'eventDate', value: [eventDate]),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  eventDateNotEqualTo(DateTime eventDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventDate',
                lower: [],
                upper: [eventDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventDate',
                lower: [eventDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventDate',
                lower: [eventDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventDate',
                lower: [],
                upper: [eventDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  eventDateGreaterThan(DateTime eventDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventDate',
          lower: [eventDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  eventDateLessThan(DateTime eventDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventDate',
          lower: [],
          upper: [eventDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  eventDateBetween(
    DateTime lowerEventDate,
    DateTime upperEventDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventDate',
          lower: [lowerEventDate],
          includeLower: includeLower,
          upper: [upperEventDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  statusEqualTo(int status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'status', value: [status]),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterWhereClause>
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

extension EventOrderEntityQueryFilter
    on QueryBuilder<EventOrderEntity, EventOrderEntity, QFilterCondition> {
  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  advanceAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'advanceAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  advanceAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'advanceAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  advanceAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'advanceAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  advanceAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'advanceAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  convertedBillIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'convertedBillId'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  convertedBillIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'convertedBillId'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  convertedBillIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'convertedBillId', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  convertedBillIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'convertedBillId', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customDataJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customDataJson'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customDataJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customDataJson'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customDataJson', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customDataJson', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customerAddress'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customerAddress'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerAddress', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerAddress', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerContactIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerContact', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerContactIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerContact', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customerId'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customerId'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerId', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerId', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerName', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  customerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerName', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'description'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'description'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  eventDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventDate', value: value),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  eventDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eventDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  eventDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eventDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  eventDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eventDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  eventLocationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'eventLocation'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  eventLocationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'eventLocation'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  eventLocationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventLocation', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  eventLocationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventLocation', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  itemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, true, length, true);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, 0, true);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, false, 999999, true);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  itemsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, length, include);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  itemsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, include, 999999, true);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'orderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'orderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'orderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'orderName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'orderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'orderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'orderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'orderName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'orderName', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'orderName', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderTypeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'orderType', value: value),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderTypeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'orderType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderTypeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'orderType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  orderTypeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'orderType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  remainingAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remainingAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  remainingAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remainingAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  remainingAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remainingAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  remainingAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remainingAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  statusEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  subEventsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', length, true, length, true);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  subEventsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', 0, true, 0, true);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  subEventsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', 0, false, 999999, true);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  subEventsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', 0, true, length, include);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  subEventsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'subEvents', length, include, 999999, true);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  syncStatusEqualTo(EventOrderSyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  syncStatusGreaterThan(EventOrderSyncStatus value, {bool include = false}) {
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  syncStatusLessThan(EventOrderSyncStatus value, {bool include = false}) {
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  syncStatusBetween(
    EventOrderSyncStatus lower,
    EventOrderSyncStatus upper, {
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
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

extension EventOrderEntityQueryObject
    on QueryBuilder<EventOrderEntity, EventOrderEntity, QFilterCondition> {
  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  itemsElement(FilterQuery<OrderItemEmbedded> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'items');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterFilterCondition>
  subEventsElement(FilterQuery<SubEventEmbedded> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'subEvents');
    });
  }
}

extension EventOrderEntityQueryLinks
    on QueryBuilder<EventOrderEntity, EventOrderEntity, QFilterCondition> {}

extension EventOrderEntityQuerySortBy
    on QueryBuilder<EventOrderEntity, EventOrderEntity, QSortBy> {
  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByAdvanceAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'advanceAmount', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByAdvanceAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'advanceAmount', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByConvertedBillId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedBillId', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByConvertedBillIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedBillId', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customDataJson', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customDataJson', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomerAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAddress', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomerAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAddress', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomerContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomerContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByEventCharges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCharges', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByEventChargesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCharges', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByEventDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventDate', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByEventDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventDate', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByEventLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByEventLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByOrderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderName', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByOrderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderName', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByOrderType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderType', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByOrderTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderType', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByRemainingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByRemainingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension EventOrderEntityQuerySortThenBy
    on QueryBuilder<EventOrderEntity, EventOrderEntity, QSortThenBy> {
  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByAdvanceAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'advanceAmount', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByAdvanceAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'advanceAmount', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByConvertedBillId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedBillId', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByConvertedBillIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedBillId', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customDataJson', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customDataJson', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomerAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAddress', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomerAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAddress', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomerContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomerContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerContact', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByEventCharges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCharges', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByEventChargesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCharges', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByEventDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventDate', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByEventDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventDate', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByEventLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByEventLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByOrderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderName', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByOrderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderName', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByOrderType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderType', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByOrderTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderType', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByRemainingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByRemainingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension EventOrderEntityQueryWhereDistinct
    on QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct> {
  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByAdvanceAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'advanceAmount');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByConvertedBillId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'convertedBillId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByCustomDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'customDataJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByCustomerAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'customerAddress',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByCustomerContact({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'customerContact',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByCustomerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByCustomerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByEventCharges() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventCharges');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByEventDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventDate');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByEventLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'eventLocation',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct> distinctByNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByOrderName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByOrderType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderType');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByRemainingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingAmount');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension EventOrderEntityQueryProperty
    on QueryBuilder<EventOrderEntity, EventOrderEntity, QQueryProperty> {
  QueryBuilder<EventOrderEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EventOrderEntity, double, QQueryOperations>
  advanceAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'advanceAmount');
    });
  }

  QueryBuilder<EventOrderEntity, String?, QQueryOperations>
  convertedBillIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'convertedBillId');
    });
  }

  QueryBuilder<EventOrderEntity, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<EventOrderEntity, String?, QQueryOperations>
  customDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customDataJson');
    });
  }

  QueryBuilder<EventOrderEntity, String?, QQueryOperations>
  customerAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerAddress');
    });
  }

  QueryBuilder<EventOrderEntity, String, QQueryOperations>
  customerContactProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerContact');
    });
  }

  QueryBuilder<EventOrderEntity, String?, QQueryOperations>
  customerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerId');
    });
  }

  QueryBuilder<EventOrderEntity, String, QQueryOperations>
  customerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerName');
    });
  }

  QueryBuilder<EventOrderEntity, String?, QQueryOperations>
  descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<EventOrderEntity, double, QQueryOperations>
  eventChargesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventCharges');
    });
  }

  QueryBuilder<EventOrderEntity, DateTime, QQueryOperations>
  eventDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventDate');
    });
  }

  QueryBuilder<EventOrderEntity, String?, QQueryOperations>
  eventLocationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventLocation');
    });
  }

  QueryBuilder<EventOrderEntity, List<OrderItemEmbedded>, QQueryOperations>
  itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'items');
    });
  }

  QueryBuilder<EventOrderEntity, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<EventOrderEntity, String, QQueryOperations> orderNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderName');
    });
  }

  QueryBuilder<EventOrderEntity, int, QQueryOperations> orderTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderType');
    });
  }

  QueryBuilder<EventOrderEntity, double, QQueryOperations>
  remainingAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingAmount');
    });
  }

  QueryBuilder<EventOrderEntity, String?, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<EventOrderEntity, int, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<EventOrderEntity, List<SubEventEmbedded>, QQueryOperations>
  subEventsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subEvents');
    });
  }

  QueryBuilder<EventOrderEntity, EventOrderSyncStatus, QQueryOperations>
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<EventOrderEntity, double, QQueryOperations>
  totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<EventOrderEntity, DateTime, QQueryOperations>
  updatedAtProperty() {
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

const SubEventEmbeddedSchema = Schema(
  name: r'SubEventEmbedded',
  id: -5356900810270092634,
  properties: {
    r'charges': PropertySchema(id: 0, name: r'charges', type: IsarType.double),
    r'customDataJson': PropertySchema(
      id: 1,
      name: r'customDataJson',
      type: IsarType.string,
    ),
    r'date': PropertySchema(id: 2, name: r'date', type: IsarType.dateTime),
    r'id': PropertySchema(id: 3, name: r'id', type: IsarType.string),
    r'name': PropertySchema(id: 4, name: r'name', type: IsarType.string),
    r'notes': PropertySchema(id: 5, name: r'notes', type: IsarType.string),
  },

  estimateSize: _subEventEmbeddedEstimateSize,
  serialize: _subEventEmbeddedSerialize,
  deserialize: _subEventEmbeddedDeserialize,
  deserializeProp: _subEventEmbeddedDeserializeProp,
);

int _subEventEmbeddedEstimateSize(
  SubEventEmbedded object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.customDataJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.id;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _subEventEmbeddedSerialize(
  SubEventEmbedded object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.charges);
  writer.writeString(offsets[1], object.customDataJson);
  writer.writeDateTime(offsets[2], object.date);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.notes);
}

SubEventEmbedded _subEventEmbeddedDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SubEventEmbedded(
    charges: reader.readDoubleOrNull(offsets[0]) ?? 0.0,
    customDataJson: reader.readStringOrNull(offsets[1]),
    date: reader.readDateTimeOrNull(offsets[2]),
    id: reader.readStringOrNull(offsets[3]),
    name: reader.readStringOrNull(offsets[4]),
    notes: reader.readStringOrNull(offsets[5]),
  );
  return object;
}

P _subEventEmbeddedDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SubEventEmbeddedQueryFilter
    on QueryBuilder<SubEventEmbedded, SubEventEmbedded, QFilterCondition> {
  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  chargesEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'charges',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  chargesGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'charges',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  chargesLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'charges',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  chargesBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'charges',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  customDataJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customDataJson'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  customDataJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customDataJson'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  customDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customDataJson', value: ''),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  customDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customDataJson', value: ''),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  dateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'date'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  dateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'date'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  dateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'date', value: value),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  dateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  dateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  dateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'date',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idLessThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'name'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'name'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
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

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<SubEventEmbedded, SubEventEmbedded, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }
}

extension SubEventEmbeddedQueryObject
    on QueryBuilder<SubEventEmbedded, SubEventEmbedded, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const OrderItemEmbeddedSchema = Schema(
  name: r'OrderItemEmbedded',
  id: 6372615220027013686,
  properties: {
    r'cgstAmount': PropertySchema(
      id: 0,
      name: r'cgstAmount',
      type: IsarType.double,
    ),
    r'cgstPercent': PropertySchema(
      id: 1,
      name: r'cgstPercent',
      type: IsarType.double,
    ),
    r'discountAmount': PropertySchema(
      id: 2,
      name: r'discountAmount',
      type: IsarType.double,
    ),
    r'discountPercent': PropertySchema(
      id: 3,
      name: r'discountPercent',
      type: IsarType.double,
    ),
    r'hsnCode': PropertySchema(id: 4, name: r'hsnCode', type: IsarType.string),
    r'id': PropertySchema(id: 5, name: r'id', type: IsarType.string),
    r'productId': PropertySchema(
      id: 6,
      name: r'productId',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 7,
      name: r'productName',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(id: 8, name: r'quantity', type: IsarType.long),
    r'rate': PropertySchema(id: 9, name: r'rate', type: IsarType.double),
    r'sgstAmount': PropertySchema(
      id: 10,
      name: r'sgstAmount',
      type: IsarType.double,
    ),
    r'sgstPercent': PropertySchema(
      id: 11,
      name: r'sgstPercent',
      type: IsarType.double,
    ),
    r'subtotal': PropertySchema(
      id: 12,
      name: r'subtotal',
      type: IsarType.double,
    ),
    r'taxAmount': PropertySchema(
      id: 13,
      name: r'taxAmount',
      type: IsarType.double,
    ),
    r'total': PropertySchema(id: 14, name: r'total', type: IsarType.double),
  },

  estimateSize: _orderItemEmbeddedEstimateSize,
  serialize: _orderItemEmbeddedSerialize,
  deserialize: _orderItemEmbeddedDeserialize,
  deserializeProp: _orderItemEmbeddedDeserializeProp,
);

int _orderItemEmbeddedEstimateSize(
  OrderItemEmbedded object,
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
    final value = object.id;
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
  return bytesCount;
}

void _orderItemEmbeddedSerialize(
  OrderItemEmbedded object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.cgstAmount);
  writer.writeDouble(offsets[1], object.cgstPercent);
  writer.writeDouble(offsets[2], object.discountAmount);
  writer.writeDouble(offsets[3], object.discountPercent);
  writer.writeString(offsets[4], object.hsnCode);
  writer.writeString(offsets[5], object.id);
  writer.writeString(offsets[6], object.productId);
  writer.writeString(offsets[7], object.productName);
  writer.writeLong(offsets[8], object.quantity);
  writer.writeDouble(offsets[9], object.rate);
  writer.writeDouble(offsets[10], object.sgstAmount);
  writer.writeDouble(offsets[11], object.sgstPercent);
  writer.writeDouble(offsets[12], object.subtotal);
  writer.writeDouble(offsets[13], object.taxAmount);
  writer.writeDouble(offsets[14], object.total);
}

OrderItemEmbedded _orderItemEmbeddedDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OrderItemEmbedded(
    cgstAmount: reader.readDoubleOrNull(offsets[0]) ?? 0.0,
    cgstPercent: reader.readDoubleOrNull(offsets[1]) ?? 0.0,
    discountAmount: reader.readDoubleOrNull(offsets[2]) ?? 0.0,
    discountPercent: reader.readDoubleOrNull(offsets[3]) ?? 0.0,
    hsnCode: reader.readStringOrNull(offsets[4]),
    id: reader.readStringOrNull(offsets[5]),
    productId: reader.readStringOrNull(offsets[6]),
    productName: reader.readStringOrNull(offsets[7]),
    quantity: reader.readLongOrNull(offsets[8]) ?? 0,
    rate: reader.readDoubleOrNull(offsets[9]) ?? 0.0,
    sgstAmount: reader.readDoubleOrNull(offsets[10]) ?? 0.0,
    sgstPercent: reader.readDoubleOrNull(offsets[11]) ?? 0.0,
    subtotal: reader.readDoubleOrNull(offsets[12]) ?? 0.0,
    taxAmount: reader.readDoubleOrNull(offsets[13]) ?? 0.0,
    total: reader.readDoubleOrNull(offsets[14]) ?? 0.0,
  );
  return object;
}

P _orderItemEmbeddedDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 1:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 2:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 3:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 9:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 10:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 11:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 12:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 13:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 14:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension OrderItemEmbeddedQueryFilter
    on QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QFilterCondition> {
  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  cgstAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  cgstAmountBetween(
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  hsnCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'hsnCode'),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  hsnCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'hsnCode'),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  hsnCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hsnCode', value: ''),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  hsnCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'hsnCode', value: ''),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idLessThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  productIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'productId'),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  productIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'productId'),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  productNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'productName'),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  productNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'productName'),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productName', value: ''),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'quantity', value: value),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  rateEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rate',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  rateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rate',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  rateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rate',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  rateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  sgstAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  sgstAmountBetween(
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
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

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  taxAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'taxAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  taxAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'taxAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  taxAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'taxAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  taxAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'taxAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  totalEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'total',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  totalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'total',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  totalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'total',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QAfterFilterCondition>
  totalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'total',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension OrderItemEmbeddedQueryObject
    on QueryBuilder<OrderItemEmbedded, OrderItemEmbedded, QFilterCondition> {}
