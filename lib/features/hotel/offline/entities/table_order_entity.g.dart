// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_order_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTableOrderEntityCollection on Isar {
  IsarCollection<TableOrderEntity> get tableOrderEntitys => this.collection();
}

const TableOrderEntitySchema = CollectionSchema(
  name: r'TableOrderEntity',
  id: 4089797471510129330,
  properties: {
    r'billNumber': PropertySchema(
      id: 0,
      name: r'billNumber',
      type: IsarType.string,
    ),
    r'billedAt': PropertySchema(
      id: 1,
      name: r'billedAt',
      type: IsarType.dateTime,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'guestName': PropertySchema(
      id: 3,
      name: r'guestName',
      type: IsarType.string,
    ),
    r'guestPhone': PropertySchema(
      id: 4,
      name: r'guestPhone',
      type: IsarType.string,
    ),
    r'itemsJson': PropertySchema(
      id: 5,
      name: r'itemsJson',
      type: IsarType.string,
    ),
    r'localTableId': PropertySchema(
      id: 6,
      name: r'localTableId',
      type: IsarType.long,
    ),
    r'notes': PropertySchema(id: 7, name: r'notes', type: IsarType.string),
    r'occupiedSeats': PropertySchema(
      id: 8,
      name: r'occupiedSeats',
      type: IsarType.long,
    ),
    r'sentToKitchenAt': PropertySchema(
      id: 9,
      name: r'sentToKitchenAt',
      type: IsarType.dateTime,
    ),
    r'servedAt': PropertySchema(
      id: 10,
      name: r'servedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 11,
      name: r'status',
      type: IsarType.string,
      enumMap: _TableOrderEntitystatusEnumValueMap,
    ),
    r'tableNumber': PropertySchema(
      id: 12,
      name: r'tableNumber',
      type: IsarType.string,
    ),
    r'totalAmount': PropertySchema(
      id: 13,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 14,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _tableOrderEntityEstimateSize,
  serialize: _tableOrderEntitySerialize,
  deserialize: _tableOrderEntityDeserialize,
  deserializeProp: _tableOrderEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'localTableId': IndexSchema(
      id: -7114396178017931682,
      name: r'localTableId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'localTableId',
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
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _tableOrderEntityGetId,
  getLinks: _tableOrderEntityGetLinks,
  attach: _tableOrderEntityAttach,
  version: '3.3.2',
);

int _tableOrderEntityEstimateSize(
  TableOrderEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.billNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestPhone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.itemsJson.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.name.length * 3;
  bytesCount += 3 + object.tableNumber.length * 3;
  return bytesCount;
}

void _tableOrderEntitySerialize(
  TableOrderEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.billNumber);
  writer.writeDateTime(offsets[1], object.billedAt);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.guestName);
  writer.writeString(offsets[4], object.guestPhone);
  writer.writeString(offsets[5], object.itemsJson);
  writer.writeLong(offsets[6], object.localTableId);
  writer.writeString(offsets[7], object.notes);
  writer.writeLong(offsets[8], object.occupiedSeats);
  writer.writeDateTime(offsets[9], object.sentToKitchenAt);
  writer.writeDateTime(offsets[10], object.servedAt);
  writer.writeString(offsets[11], object.status.name);
  writer.writeString(offsets[12], object.tableNumber);
  writer.writeDouble(offsets[13], object.totalAmount);
  writer.writeDateTime(offsets[14], object.updatedAt);
}

TableOrderEntity _tableOrderEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TableOrderEntity();
  object.billNumber = reader.readStringOrNull(offsets[0]);
  object.billedAt = reader.readDateTimeOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.guestName = reader.readStringOrNull(offsets[3]);
  object.guestPhone = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.itemsJson = reader.readString(offsets[5]);
  object.localTableId = reader.readLong(offsets[6]);
  object.notes = reader.readStringOrNull(offsets[7]);
  object.occupiedSeats = reader.readLong(offsets[8]);
  object.sentToKitchenAt = reader.readDateTimeOrNull(offsets[9]);
  object.servedAt = reader.readDateTimeOrNull(offsets[10]);
  object.status =
      _TableOrderEntitystatusValueEnumMap[reader.readStringOrNull(
        offsets[11],
      )] ??
      TableOrderStatus.open;
  object.tableNumber = reader.readString(offsets[12]);
  object.totalAmount = reader.readDouble(offsets[13]);
  object.updatedAt = reader.readDateTime(offsets[14]);
  return object;
}

P _tableOrderEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (_TableOrderEntitystatusValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              TableOrderStatus.open)
          as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TableOrderEntitystatusEnumValueMap = {
  r'open': r'open',
  r'sentToKitchen': r'sentToKitchen',
  r'served': r'served',
  r'billed': r'billed',
  r'cancelled': r'cancelled',
};
const _TableOrderEntitystatusValueEnumMap = {
  r'open': TableOrderStatus.open,
  r'sentToKitchen': TableOrderStatus.sentToKitchen,
  r'served': TableOrderStatus.served,
  r'billed': TableOrderStatus.billed,
  r'cancelled': TableOrderStatus.cancelled,
};

Id _tableOrderEntityGetId(TableOrderEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _tableOrderEntityGetLinks(TableOrderEntity object) {
  return [];
}

void _tableOrderEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  TableOrderEntity object,
) {
  object.id = id;
}

extension TableOrderEntityQueryWhereSort
    on QueryBuilder<TableOrderEntity, TableOrderEntity, QWhere> {
  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhere>
  anyLocalTableId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'localTableId'),
      );
    });
  }
}

extension TableOrderEntityQueryWhere
    on QueryBuilder<TableOrderEntity, TableOrderEntity, QWhereClause> {
  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
  localTableIdEqualTo(int localTableId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'localTableId',
          value: [localTableId],
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
  localTableIdNotEqualTo(int localTableId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localTableId',
                lower: [],
                upper: [localTableId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localTableId',
                lower: [localTableId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localTableId',
                lower: [localTableId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localTableId',
                lower: [],
                upper: [localTableId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
  localTableIdGreaterThan(int localTableId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'localTableId',
          lower: [localTableId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
  localTableIdLessThan(int localTableId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'localTableId',
          lower: [],
          upper: [localTableId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
  localTableIdBetween(
    int lowerLocalTableId,
    int upperLocalTableId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'localTableId',
          lower: [lowerLocalTableId],
          includeLower: includeLower,
          upper: [upperLocalTableId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
  statusEqualTo(TableOrderStatus status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'status', value: [status]),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterWhereClause>
  statusNotEqualTo(TableOrderStatus status) {
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
}

extension TableOrderEntityQueryFilter
    on QueryBuilder<TableOrderEntity, TableOrderEntity, QFilterCondition> {
  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'billNumber'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'billNumber'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'billNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'billNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'billNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'billNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'billNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'billNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'billNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'billNumber',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'billNumber', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'billNumber', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'billedAt'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'billedAt'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'billedAt', value: value),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'billedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'billedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  billedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'billedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'guestName'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'guestName'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'guestName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'guestName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'guestName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'guestName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'guestName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'guestName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'guestName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'guestName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'guestName', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'guestName', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'guestPhone'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'guestPhone'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'guestPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'guestPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'guestPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'guestPhone',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'guestPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'guestPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'guestPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'guestPhone',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'guestPhone', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  guestPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'guestPhone', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'itemsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'itemsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'itemsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'itemsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'itemsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'itemsJson', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  itemsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'itemsJson', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  localTableIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localTableId', value: value),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  localTableIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localTableId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  localTableIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localTableId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  localTableIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localTableId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  occupiedSeatsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'occupiedSeats', value: value),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  occupiedSeatsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'occupiedSeats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  occupiedSeatsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'occupiedSeats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  occupiedSeatsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'occupiedSeats',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  sentToKitchenAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sentToKitchenAt'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  sentToKitchenAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sentToKitchenAt'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  sentToKitchenAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sentToKitchenAt', value: value),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  sentToKitchenAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sentToKitchenAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  sentToKitchenAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sentToKitchenAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  sentToKitchenAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sentToKitchenAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  servedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'servedAt'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  servedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'servedAt'),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  servedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'servedAt', value: value),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  servedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'servedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  servedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'servedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  servedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'servedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusEqualTo(TableOrderStatus value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusGreaterThan(
    TableOrderStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusLessThan(
    TableOrderStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusBetween(
    TableOrderStatus lower,
    TableOrderStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tableNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tableNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tableNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tableNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tableNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tableNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tableNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tableNumber',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tableNumber', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  tableNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tableNumber', value: ''),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterFilterCondition>
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

extension TableOrderEntityQueryObject
    on QueryBuilder<TableOrderEntity, TableOrderEntity, QFilterCondition> {}

extension TableOrderEntityQueryLinks
    on QueryBuilder<TableOrderEntity, TableOrderEntity, QFilterCondition> {}

extension TableOrderEntityQuerySortBy
    on QueryBuilder<TableOrderEntity, TableOrderEntity, QSortBy> {
  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByBillNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billNumber', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByBillNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billNumber', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByBilledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billedAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByBilledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billedAt', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByGuestName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestName', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByGuestNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestName', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByGuestPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPhone', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByGuestPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPhone', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByItemsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByItemsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByLocalTableId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localTableId', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByLocalTableIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localTableId', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByOccupiedSeats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occupiedSeats', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByOccupiedSeatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occupiedSeats', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortBySentToKitchenAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentToKitchenAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortBySentToKitchenAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentToKitchenAt', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByServedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servedAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByServedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servedAt', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByTableNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByTableNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension TableOrderEntityQuerySortThenBy
    on QueryBuilder<TableOrderEntity, TableOrderEntity, QSortThenBy> {
  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByBillNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billNumber', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByBillNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billNumber', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByBilledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billedAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByBilledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billedAt', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByGuestName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestName', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByGuestNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestName', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByGuestPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPhone', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByGuestPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPhone', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByItemsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByItemsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByLocalTableId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localTableId', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByLocalTableIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localTableId', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByOccupiedSeats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occupiedSeats', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByOccupiedSeatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occupiedSeats', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenBySentToKitchenAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentToKitchenAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenBySentToKitchenAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentToKitchenAt', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByServedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servedAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByServedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servedAt', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByTableNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByTableNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension TableOrderEntityQueryWhereDistinct
    on QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct> {
  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByBillNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'billNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByBilledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'billedAt');
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByGuestName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByGuestPhone({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestPhone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByItemsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByLocalTableId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localTableId');
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct> distinctByNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByOccupiedSeats() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occupiedSeats');
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctBySentToKitchenAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sentToKitchenAt');
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByServedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servedAt');
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct> distinctByStatus({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByTableNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tableNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension TableOrderEntityQueryProperty
    on QueryBuilder<TableOrderEntity, TableOrderEntity, QQueryProperty> {
  QueryBuilder<TableOrderEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TableOrderEntity, String?, QQueryOperations>
  billNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'billNumber');
    });
  }

  QueryBuilder<TableOrderEntity, DateTime?, QQueryOperations>
  billedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'billedAt');
    });
  }

  QueryBuilder<TableOrderEntity, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TableOrderEntity, String?, QQueryOperations>
  guestNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestName');
    });
  }

  QueryBuilder<TableOrderEntity, String?, QQueryOperations>
  guestPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestPhone');
    });
  }

  QueryBuilder<TableOrderEntity, String, QQueryOperations> itemsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemsJson');
    });
  }

  QueryBuilder<TableOrderEntity, int, QQueryOperations> localTableIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localTableId');
    });
  }

  QueryBuilder<TableOrderEntity, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<TableOrderEntity, int, QQueryOperations>
  occupiedSeatsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occupiedSeats');
    });
  }

  QueryBuilder<TableOrderEntity, DateTime?, QQueryOperations>
  sentToKitchenAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sentToKitchenAt');
    });
  }

  QueryBuilder<TableOrderEntity, DateTime?, QQueryOperations>
  servedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servedAt');
    });
  }

  QueryBuilder<TableOrderEntity, TableOrderStatus, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<TableOrderEntity, String, QQueryOperations>
  tableNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tableNumber');
    });
  }

  QueryBuilder<TableOrderEntity, double, QQueryOperations>
  totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<TableOrderEntity, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
