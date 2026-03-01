// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_transaction_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomerTransactionEntityCollection on Isar {
  IsarCollection<CustomerTransactionEntity> get customerTransactionEntitys =>
      this.collection();
}

const CustomerTransactionEntitySchema = CollectionSchema(
  name: r'CustomerTransactionEntity',
  id: 5849172234778136530,
  properties: {
    r'amount': PropertySchema(id: 0, name: r'amount', type: IsarType.double),
    r'balanceAfter': PropertySchema(
      id: 1,
      name: r'balanceAfter',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'customerId': PropertySchema(
      id: 3,
      name: r'customerId',
      type: IsarType.string,
    ),
    r'customerName': PropertySchema(
      id: 4,
      name: r'customerName',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'paymentMethod': PropertySchema(
      id: 6,
      name: r'paymentMethod',
      type: IsarType.string,
    ),
    r'referenceId': PropertySchema(
      id: 7,
      name: r'referenceId',
      type: IsarType.string,
    ),
    r'referenceType': PropertySchema(
      id: 8,
      name: r'referenceType',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 9,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 10,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _CustomerTransactionEntitysyncStatusEnumValueMap,
    ),
    r'transactionDate': PropertySchema(
      id: 11,
      name: r'transactionDate',
      type: IsarType.dateTime,
    ),
    r'transactionType': PropertySchema(
      id: 12,
      name: r'transactionType',
      type: IsarType.byte,
      enumMap: _CustomerTransactionEntitytransactionTypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _customerTransactionEntityEstimateSize,
  serialize: _customerTransactionEntitySerialize,
  deserialize: _customerTransactionEntityDeserialize,
  deserializeProp: _customerTransactionEntityDeserializeProp,
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

  getId: _customerTransactionEntityGetId,
  getLinks: _customerTransactionEntityGetLinks,
  attach: _customerTransactionEntityAttach,
  version: '3.3.0',
);

int _customerTransactionEntityEstimateSize(
  CustomerTransactionEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.customerId.length * 3;
  bytesCount += 3 + object.customerName.length * 3;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentMethod;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.referenceId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.referenceType;
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

void _customerTransactionEntitySerialize(
  CustomerTransactionEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeDouble(offsets[1], object.balanceAfter);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.customerId);
  writer.writeString(offsets[4], object.customerName);
  writer.writeString(offsets[5], object.description);
  writer.writeString(offsets[6], object.paymentMethod);
  writer.writeString(offsets[7], object.referenceId);
  writer.writeString(offsets[8], object.referenceType);
  writer.writeString(offsets[9], object.serverId);
  writer.writeByte(offsets[10], object.syncStatus.index);
  writer.writeDateTime(offsets[11], object.transactionDate);
  writer.writeByte(offsets[12], object.transactionType.index);
  writer.writeDateTime(offsets[13], object.updatedAt);
}

CustomerTransactionEntity _customerTransactionEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomerTransactionEntity(
    amount: reader.readDouble(offsets[0]),
    balanceAfter: reader.readDouble(offsets[1]),
    createdAt: reader.readDateTime(offsets[2]),
    customerId: reader.readString(offsets[3]),
    customerName: reader.readString(offsets[4]),
    description: reader.readStringOrNull(offsets[5]),
    paymentMethod: reader.readStringOrNull(offsets[6]),
    referenceId: reader.readStringOrNull(offsets[7]),
    referenceType: reader.readStringOrNull(offsets[8]),
    serverId: reader.readStringOrNull(offsets[9]),
    syncStatus:
        _CustomerTransactionEntitysyncStatusValueEnumMap[reader.readByteOrNull(
          offsets[10],
        )] ??
        TransactionSyncStatus.newRecord,
    transactionDate: reader.readDateTime(offsets[11]),
    transactionType:
        _CustomerTransactionEntitytransactionTypeValueEnumMap[reader
            .readByteOrNull(offsets[12])] ??
        TransactionType.payment,
    updatedAt: reader.readDateTime(offsets[13]),
  );
  object.id = id;
  return object;
}

P _customerTransactionEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (_CustomerTransactionEntitysyncStatusValueEnumMap[reader
                  .readByteOrNull(offset)] ??
              TransactionSyncStatus.newRecord)
          as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (_CustomerTransactionEntitytransactionTypeValueEnumMap[reader
                  .readByteOrNull(offset)] ??
              TransactionType.payment)
          as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CustomerTransactionEntitysyncStatusEnumValueMap = {
  'newRecord': 0,
  'updated': 1,
  'deleted': 2,
  'synced': 3,
};
const _CustomerTransactionEntitysyncStatusValueEnumMap = {
  0: TransactionSyncStatus.newRecord,
  1: TransactionSyncStatus.updated,
  2: TransactionSyncStatus.deleted,
  3: TransactionSyncStatus.synced,
};
const _CustomerTransactionEntitytransactionTypeEnumValueMap = {
  'payment': 0,
  'billCreated': 1,
  'billReturn': 2,
  'adjustment': 3,
};
const _CustomerTransactionEntitytransactionTypeValueEnumMap = {
  0: TransactionType.payment,
  1: TransactionType.billCreated,
  2: TransactionType.billReturn,
  3: TransactionType.adjustment,
};

Id _customerTransactionEntityGetId(CustomerTransactionEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customerTransactionEntityGetLinks(
  CustomerTransactionEntity object,
) {
  return [];
}

void _customerTransactionEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  CustomerTransactionEntity object,
) {
  object.id = id;
}

extension CustomerTransactionEntityQueryWhereSort
    on
        QueryBuilder<
          CustomerTransactionEntity,
          CustomerTransactionEntity,
          QWhere
        > {
  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhere
  >
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhere
  >
  anyTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'transactionDate'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhere
  >
  anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension CustomerTransactionEntityQueryWhere
    on
        QueryBuilder<
          CustomerTransactionEntity,
          CustomerTransactionEntity,
          QWhereClause
        > {
  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [null]),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
  serverIdEqualTo(String? serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'serverId', value: [serverId]),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
  customerIdEqualTo(String customerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'customerId', value: [customerId]),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
  customerIdNotEqualTo(String customerId) {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterWhereClause
  >
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

extension CustomerTransactionEntityQueryFilter
    on
        QueryBuilder<
          CustomerTransactionEntity,
          CustomerTransactionEntity,
          QFilterCondition
        > {
  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  amountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'amount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  balanceAfterEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'balanceAfter',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  balanceAfterGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'balanceAfter',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  balanceAfterLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'balanceAfter',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  balanceAfterBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'balanceAfter',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  customerIdEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  customerIdGreaterThan(
    String value, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  customerIdLessThan(
    String value, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  customerIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  customerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerId', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  customerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerId', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  customerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customerName', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  customerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customerName', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'description'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'description'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'paymentMethod'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'paymentMethod'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paymentMethod',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'paymentMethod',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paymentMethod', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  paymentMethodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'paymentMethod', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'referenceId'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'referenceId'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceIdEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceIdGreaterThan(
    String? value, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceIdLessThan(
    String? value, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'referenceId', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'referenceId', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'referenceType'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'referenceType'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceTypeEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceTypeGreaterThan(
    String? value, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceTypeLessThan(
    String? value, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceTypeBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'referenceType', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  referenceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'referenceType', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  syncStatusEqualTo(TransactionSyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  syncStatusGreaterThan(TransactionSyncStatus value, {bool include = false}) {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  syncStatusLessThan(TransactionSyncStatus value, {bool include = false}) {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  syncStatusBetween(
    TransactionSyncStatus lower,
    TransactionSyncStatus upper, {
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  transactionDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'transactionDate', value: value),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  transactionTypeEqualTo(TransactionType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'transactionType', value: value),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  transactionTypeGreaterThan(TransactionType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'transactionType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  transactionTypeLessThan(TransactionType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'transactionType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  transactionTypeBetween(
    TransactionType lower,
    TransactionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'transactionType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterFilterCondition
  >
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

extension CustomerTransactionEntityQueryObject
    on
        QueryBuilder<
          CustomerTransactionEntity,
          CustomerTransactionEntity,
          QFilterCondition
        > {}

extension CustomerTransactionEntityQueryLinks
    on
        QueryBuilder<
          CustomerTransactionEntity,
          CustomerTransactionEntity,
          QFilterCondition
        > {}

extension CustomerTransactionEntityQuerySortBy
    on
        QueryBuilder<
          CustomerTransactionEntity,
          CustomerTransactionEntity,
          QSortBy
        > {
  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByBalanceAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByBalanceAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByReferenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByReferenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByTransactionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CustomerTransactionEntityQuerySortThenBy
    on
        QueryBuilder<
          CustomerTransactionEntity,
          CustomerTransactionEntity,
          QSortThenBy
        > {
  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByBalanceAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByBalanceAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByReferenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByReferenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByTransactionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    CustomerTransactionEntity,
    QAfterSortBy
  >
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CustomerTransactionEntityQueryWhereDistinct
    on
        QueryBuilder<
          CustomerTransactionEntity,
          CustomerTransactionEntity,
          QDistinct
        > {
  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByBalanceAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balanceAfter');
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByCustomerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByCustomerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByPaymentMethod({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'paymentMethod',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByReferenceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByReferenceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'referenceType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionDate');
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionType');
    });
  }

  QueryBuilder<CustomerTransactionEntity, CustomerTransactionEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CustomerTransactionEntityQueryProperty
    on
        QueryBuilder<
          CustomerTransactionEntity,
          CustomerTransactionEntity,
          QQueryProperty
        > {
  QueryBuilder<CustomerTransactionEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomerTransactionEntity, double, QQueryOperations>
  amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<CustomerTransactionEntity, double, QQueryOperations>
  balanceAfterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balanceAfter');
    });
  }

  QueryBuilder<CustomerTransactionEntity, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CustomerTransactionEntity, String, QQueryOperations>
  customerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerId');
    });
  }

  QueryBuilder<CustomerTransactionEntity, String, QQueryOperations>
  customerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerName');
    });
  }

  QueryBuilder<CustomerTransactionEntity, String?, QQueryOperations>
  descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<CustomerTransactionEntity, String?, QQueryOperations>
  paymentMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMethod');
    });
  }

  QueryBuilder<CustomerTransactionEntity, String?, QQueryOperations>
  referenceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceId');
    });
  }

  QueryBuilder<CustomerTransactionEntity, String?, QQueryOperations>
  referenceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceType');
    });
  }

  QueryBuilder<CustomerTransactionEntity, String?, QQueryOperations>
  serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<
    CustomerTransactionEntity,
    TransactionSyncStatus,
    QQueryOperations
  >
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<CustomerTransactionEntity, DateTime, QQueryOperations>
  transactionDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionDate');
    });
  }

  QueryBuilder<CustomerTransactionEntity, TransactionType, QQueryOperations>
  transactionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionType');
    });
  }

  QueryBuilder<CustomerTransactionEntity, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
