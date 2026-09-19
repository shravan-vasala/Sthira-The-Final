// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_search_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFoodSearchCacheCollection on Isar {
  IsarCollection<FoodSearchCache> get foodSearchCaches => this.collection();
}

const FoodSearchCacheSchema = CollectionSchema(
  name: r'FoodSearchCache',
  id: 8207814819397925303,
  properties: {
    r'cachedResponseJson': PropertySchema(
      id: 0,
      name: r'cachedResponseJson',
      type: IsarType.string,
    ),
    r'normalizedQuery': PropertySchema(
      id: 1,
      name: r'normalizedQuery',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 2,
      name: r'schemaVersion',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _foodSearchCacheEstimateSize,
  serialize: _foodSearchCacheSerialize,
  deserialize: _foodSearchCacheDeserialize,
  deserializeProp: _foodSearchCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'normalizedQuery': IndexSchema(
      id: -8869323565622634762,
      name: r'normalizedQuery',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'normalizedQuery',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _foodSearchCacheGetId,
  getLinks: _foodSearchCacheGetLinks,
  attach: _foodSearchCacheAttach,
  version: '3.1.0+1',
);

int _foodSearchCacheEstimateSize(
  FoodSearchCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cachedResponseJson.length * 3;
  bytesCount += 3 + object.normalizedQuery.length * 3;
  bytesCount += 3 + object.schemaVersion.length * 3;
  return bytesCount;
}

void _foodSearchCacheSerialize(
  FoodSearchCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cachedResponseJson);
  writer.writeString(offsets[1], object.normalizedQuery);
  writer.writeString(offsets[2], object.schemaVersion);
  writer.writeDateTime(offsets[3], object.timestamp);
}

FoodSearchCache _foodSearchCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FoodSearchCache(
    cachedResponseJson: reader.readString(offsets[0]),
    normalizedQuery: reader.readString(offsets[1]),
    schemaVersion: reader.readString(offsets[2]),
    timestamp: reader.readDateTime(offsets[3]),
  );
  object.id = id;
  return object;
}

P _foodSearchCacheDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _foodSearchCacheGetId(FoodSearchCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _foodSearchCacheGetLinks(FoodSearchCache object) {
  return [];
}

void _foodSearchCacheAttach(
    IsarCollection<dynamic> col, Id id, FoodSearchCache object) {
  object.id = id;
}

extension FoodSearchCacheByIndex on IsarCollection<FoodSearchCache> {
  Future<FoodSearchCache?> getByNormalizedQuery(String normalizedQuery) {
    return getByIndex(r'normalizedQuery', [normalizedQuery]);
  }

  FoodSearchCache? getByNormalizedQuerySync(String normalizedQuery) {
    return getByIndexSync(r'normalizedQuery', [normalizedQuery]);
  }

  Future<bool> deleteByNormalizedQuery(String normalizedQuery) {
    return deleteByIndex(r'normalizedQuery', [normalizedQuery]);
  }

  bool deleteByNormalizedQuerySync(String normalizedQuery) {
    return deleteByIndexSync(r'normalizedQuery', [normalizedQuery]);
  }

  Future<List<FoodSearchCache?>> getAllByNormalizedQuery(
      List<String> normalizedQueryValues) {
    final values = normalizedQueryValues.map((e) => [e]).toList();
    return getAllByIndex(r'normalizedQuery', values);
  }

  List<FoodSearchCache?> getAllByNormalizedQuerySync(
      List<String> normalizedQueryValues) {
    final values = normalizedQueryValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'normalizedQuery', values);
  }

  Future<int> deleteAllByNormalizedQuery(List<String> normalizedQueryValues) {
    final values = normalizedQueryValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'normalizedQuery', values);
  }

  int deleteAllByNormalizedQuerySync(List<String> normalizedQueryValues) {
    final values = normalizedQueryValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'normalizedQuery', values);
  }

  Future<Id> putByNormalizedQuery(FoodSearchCache object) {
    return putByIndex(r'normalizedQuery', object);
  }

  Id putByNormalizedQuerySync(FoodSearchCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'normalizedQuery', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNormalizedQuery(List<FoodSearchCache> objects) {
    return putAllByIndex(r'normalizedQuery', objects);
  }

  List<Id> putAllByNormalizedQuerySync(List<FoodSearchCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'normalizedQuery', objects, saveLinks: saveLinks);
  }
}

extension FoodSearchCacheQueryWhereSort
    on QueryBuilder<FoodSearchCache, FoodSearchCache, QWhere> {
  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FoodSearchCacheQueryWhere
    on QueryBuilder<FoodSearchCache, FoodSearchCache, QWhereClause> {
  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterWhereClause>
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

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterWhereClause>
      normalizedQueryEqualTo(String normalizedQuery) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'normalizedQuery',
        value: [normalizedQuery],
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterWhereClause>
      normalizedQueryNotEqualTo(String normalizedQuery) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedQuery',
              lower: [],
              upper: [normalizedQuery],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedQuery',
              lower: [normalizedQuery],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedQuery',
              lower: [normalizedQuery],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedQuery',
              lower: [],
              upper: [normalizedQuery],
              includeUpper: false,
            ));
      }
    });
  }
}

extension FoodSearchCacheQueryFilter
    on QueryBuilder<FoodSearchCache, FoodSearchCache, QFilterCondition> {
  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedResponseJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedResponseJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedResponseJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedResponseJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cachedResponseJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cachedResponseJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cachedResponseJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cachedResponseJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedResponseJson',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      cachedResponseJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cachedResponseJson',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'normalizedQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'normalizedQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'normalizedQuery',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'normalizedQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'normalizedQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'normalizedQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'normalizedQuery',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedQuery',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      normalizedQueryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'normalizedQuery',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schemaVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'schemaVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'schemaVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'schemaVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'schemaVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'schemaVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'schemaVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'schemaVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schemaVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      schemaVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'schemaVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FoodSearchCacheQueryObject
    on QueryBuilder<FoodSearchCache, FoodSearchCache, QFilterCondition> {}

extension FoodSearchCacheQueryLinks
    on QueryBuilder<FoodSearchCache, FoodSearchCache, QFilterCondition> {}

extension FoodSearchCacheQuerySortBy
    on QueryBuilder<FoodSearchCache, FoodSearchCache, QSortBy> {
  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      sortByCachedResponseJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedResponseJson', Sort.asc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      sortByCachedResponseJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedResponseJson', Sort.desc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      sortByNormalizedQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedQuery', Sort.asc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      sortByNormalizedQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedQuery', Sort.desc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension FoodSearchCacheQuerySortThenBy
    on QueryBuilder<FoodSearchCache, FoodSearchCache, QSortThenBy> {
  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      thenByCachedResponseJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedResponseJson', Sort.asc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      thenByCachedResponseJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedResponseJson', Sort.desc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      thenByNormalizedQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedQuery', Sort.asc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      thenByNormalizedQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedQuery', Sort.desc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension FoodSearchCacheQueryWhereDistinct
    on QueryBuilder<FoodSearchCache, FoodSearchCache, QDistinct> {
  QueryBuilder<FoodSearchCache, FoodSearchCache, QDistinct>
      distinctByCachedResponseJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedResponseJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QDistinct>
      distinctByNormalizedQuery({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'normalizedQuery',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QDistinct>
      distinctBySchemaVersion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FoodSearchCache, FoodSearchCache, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension FoodSearchCacheQueryProperty
    on QueryBuilder<FoodSearchCache, FoodSearchCache, QQueryProperty> {
  QueryBuilder<FoodSearchCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FoodSearchCache, String, QQueryOperations>
      cachedResponseJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedResponseJson');
    });
  }

  QueryBuilder<FoodSearchCache, String, QQueryOperations>
      normalizedQueryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'normalizedQuery');
    });
  }

  QueryBuilder<FoodSearchCache, String, QQueryOperations>
      schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<FoodSearchCache, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
