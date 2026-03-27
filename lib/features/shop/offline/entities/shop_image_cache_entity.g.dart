// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_image_cache_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetShopImageCacheEntityCollection on Isar {
  IsarCollection<ShopImageCacheEntity> get shopImageCacheEntitys =>
      this.collection();
}

const ShopImageCacheEntitySchema = CollectionSchema(
  name: r'ShopImageCacheEntity',
  id: -5557500754905219390,
  properties: {
    r'hasAnyImages': PropertySchema(
      id: 0,
      name: r'hasAnyImages',
      type: IsarType.bool,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 1,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'qrCodeBase64': PropertySchema(
      id: 2,
      name: r'qrCodeBase64',
      type: IsarType.string,
    ),
    r'shopLogoBase64': PropertySchema(
      id: 3,
      name: r'shopLogoBase64',
      type: IsarType.string,
    ),
    r'signatureBase64': PropertySchema(
      id: 4,
      name: r'signatureBase64',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(id: 6, name: r'userId', type: IsarType.string),
  },

  estimateSize: _shopImageCacheEntityEstimateSize,
  serialize: _shopImageCacheEntitySerialize,
  deserialize: _shopImageCacheEntityDeserialize,
  deserializeProp: _shopImageCacheEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _shopImageCacheEntityGetId,
  getLinks: _shopImageCacheEntityGetLinks,
  attach: _shopImageCacheEntityAttach,
  version: '3.3.2',
);

int _shopImageCacheEntityEstimateSize(
  ShopImageCacheEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.qrCodeBase64;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.shopLogoBase64;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.signatureBase64;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _shopImageCacheEntitySerialize(
  ShopImageCacheEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.hasAnyImages);
  writer.writeDateTime(offsets[1], object.lastSyncedAt);
  writer.writeString(offsets[2], object.qrCodeBase64);
  writer.writeString(offsets[3], object.shopLogoBase64);
  writer.writeString(offsets[4], object.signatureBase64);
  writer.writeDateTime(offsets[5], object.updatedAt);
  writer.writeString(offsets[6], object.userId);
}

ShopImageCacheEntity _shopImageCacheEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ShopImageCacheEntity(
    lastSyncedAt: reader.readDateTimeOrNull(offsets[1]),
    qrCodeBase64: reader.readStringOrNull(offsets[2]),
    shopLogoBase64: reader.readStringOrNull(offsets[3]),
    signatureBase64: reader.readStringOrNull(offsets[4]),
    updatedAt: reader.readDateTime(offsets[5]),
    userId: reader.readString(offsets[6]),
  );
  object.id = id;
  return object;
}

P _shopImageCacheEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _shopImageCacheEntityGetId(ShopImageCacheEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _shopImageCacheEntityGetLinks(
  ShopImageCacheEntity object,
) {
  return [];
}

void _shopImageCacheEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  ShopImageCacheEntity object,
) {
  object.id = id;
}

extension ShopImageCacheEntityByIndex on IsarCollection<ShopImageCacheEntity> {
  Future<ShopImageCacheEntity?> getByUserId(String userId) {
    return getByIndex(r'userId', [userId]);
  }

  ShopImageCacheEntity? getByUserIdSync(String userId) {
    return getByIndexSync(r'userId', [userId]);
  }

  Future<bool> deleteByUserId(String userId) {
    return deleteByIndex(r'userId', [userId]);
  }

  bool deleteByUserIdSync(String userId) {
    return deleteByIndexSync(r'userId', [userId]);
  }

  Future<List<ShopImageCacheEntity?>> getAllByUserId(
    List<String> userIdValues,
  ) {
    final values = userIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'userId', values);
  }

  List<ShopImageCacheEntity?> getAllByUserIdSync(List<String> userIdValues) {
    final values = userIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'userId', values);
  }

  Future<int> deleteAllByUserId(List<String> userIdValues) {
    final values = userIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'userId', values);
  }

  int deleteAllByUserIdSync(List<String> userIdValues) {
    final values = userIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'userId', values);
  }

  Future<Id> putByUserId(ShopImageCacheEntity object) {
    return putByIndex(r'userId', object);
  }

  Id putByUserIdSync(ShopImageCacheEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'userId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUserId(List<ShopImageCacheEntity> objects) {
    return putAllByIndex(r'userId', objects);
  }

  List<Id> putAllByUserIdSync(
    List<ShopImageCacheEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'userId', objects, saveLinks: saveLinks);
  }
}

extension ShopImageCacheEntityQueryWhereSort
    on QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QWhere> {
  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ShopImageCacheEntityQueryWhere
    on QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QWhereClause> {
  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterWhereClause>
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

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterWhereClause>
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

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterWhereClause>
  userIdEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'userId', value: [userId]),
      );
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterWhereClause>
  userIdNotEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId',
                lower: [],
                upper: [userId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId',
                lower: [userId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId',
                lower: [userId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId',
                lower: [],
                upper: [userId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension ShopImageCacheEntityQueryFilter
    on
        QueryBuilder<
          ShopImageCacheEntity,
          ShopImageCacheEntity,
          QFilterCondition
        > {
  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  hasAnyImagesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasAnyImages', value: value),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSyncedAt'),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSyncedAt'),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  lastSyncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncedAt', value: value),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  lastSyncedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  lastSyncedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  lastSyncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'qrCodeBase64'),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'qrCodeBase64'),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64EqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'qrCodeBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'qrCodeBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'qrCodeBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'qrCodeBase64',
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64StartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'qrCodeBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64EndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'qrCodeBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'qrCodeBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'qrCodeBase64',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'qrCodeBase64', value: ''),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  qrCodeBase64IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'qrCodeBase64', value: ''),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'shopLogoBase64'),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'shopLogoBase64'),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64EqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shopLogoBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shopLogoBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shopLogoBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shopLogoBase64',
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64StartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shopLogoBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64EndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shopLogoBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shopLogoBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shopLogoBase64',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shopLogoBase64', value: ''),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  shopLogoBase64IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shopLogoBase64', value: ''),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'signatureBase64'),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'signatureBase64'),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64EqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'signatureBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'signatureBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'signatureBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'signatureBase64',
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64StartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'signatureBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64EndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'signatureBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'signatureBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'signatureBase64',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'signatureBase64', value: ''),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  signatureBase64IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'signatureBase64', value: ''),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
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

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userId',
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
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userId', value: ''),
      );
    });
  }

  QueryBuilder<
    ShopImageCacheEntity,
    ShopImageCacheEntity,
    QAfterFilterCondition
  >
  userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userId', value: ''),
      );
    });
  }
}

extension ShopImageCacheEntityQueryObject
    on
        QueryBuilder<
          ShopImageCacheEntity,
          ShopImageCacheEntity,
          QFilterCondition
        > {}

extension ShopImageCacheEntityQueryLinks
    on
        QueryBuilder<
          ShopImageCacheEntity,
          ShopImageCacheEntity,
          QFilterCondition
        > {}

extension ShopImageCacheEntityQuerySortBy
    on QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QSortBy> {
  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByHasAnyImages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAnyImages', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByHasAnyImagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAnyImages', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByQrCodeBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrCodeBase64', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByQrCodeBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrCodeBase64', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByShopLogoBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shopLogoBase64', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByShopLogoBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shopLogoBase64', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortBySignatureBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signatureBase64', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortBySignatureBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signatureBase64', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension ShopImageCacheEntityQuerySortThenBy
    on QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QSortThenBy> {
  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByHasAnyImages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAnyImages', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByHasAnyImagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAnyImages', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByQrCodeBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrCodeBase64', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByQrCodeBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrCodeBase64', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByShopLogoBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shopLogoBase64', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByShopLogoBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shopLogoBase64', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenBySignatureBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signatureBase64', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenBySignatureBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signatureBase64', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QAfterSortBy>
  thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension ShopImageCacheEntityQueryWhereDistinct
    on QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QDistinct> {
  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QDistinct>
  distinctByHasAnyImages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasAnyImages');
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QDistinct>
  distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QDistinct>
  distinctByQrCodeBase64({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'qrCodeBase64', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QDistinct>
  distinctByShopLogoBase64({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'shopLogoBase64',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QDistinct>
  distinctBySignatureBase64({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'signatureBase64',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<ShopImageCacheEntity, ShopImageCacheEntity, QDistinct>
  distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension ShopImageCacheEntityQueryProperty
    on
        QueryBuilder<
          ShopImageCacheEntity,
          ShopImageCacheEntity,
          QQueryProperty
        > {
  QueryBuilder<ShopImageCacheEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ShopImageCacheEntity, bool, QQueryOperations>
  hasAnyImagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasAnyImages');
    });
  }

  QueryBuilder<ShopImageCacheEntity, DateTime?, QQueryOperations>
  lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<ShopImageCacheEntity, String?, QQueryOperations>
  qrCodeBase64Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'qrCodeBase64');
    });
  }

  QueryBuilder<ShopImageCacheEntity, String?, QQueryOperations>
  shopLogoBase64Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shopLogoBase64');
    });
  }

  QueryBuilder<ShopImageCacheEntity, String?, QQueryOperations>
  signatureBase64Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'signatureBase64');
    });
  }

  QueryBuilder<ShopImageCacheEntity, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<ShopImageCacheEntity, String, QQueryOperations>
  userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
