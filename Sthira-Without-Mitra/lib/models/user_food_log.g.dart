// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_food_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserFoodLogCollection on Isar {
  IsarCollection<UserFoodLog> get userFoodLogs => this.collection();
}

const UserFoodLogSchema = CollectionSchema(
  name: r'UserFoodLog',
  id: -3460086872239754186,
  properties: {
    r'addedAt': PropertySchema(
      id: 0,
      name: r'addedAt',
      type: IsarType.dateTime,
    ),
    r'baseNutrition': PropertySchema(
      id: 1,
      name: r'baseNutrition',
      type: IsarType.object,
      target: r'FoodNutrition',
    ),
    r'isPer100g': PropertySchema(
      id: 2,
      name: r'isPer100g',
      type: IsarType.bool,
    ),
    r'normalizedName': PropertySchema(
      id: 3,
      name: r'normalizedName',
      type: IsarType.string,
    ),
    r'originalName': PropertySchema(
      id: 4,
      name: r'originalName',
      type: IsarType.string,
    ),
    r'provenance': PropertySchema(
      id: 5,
      name: r'provenance',
      type: IsarType.string,
    ),
    r'servingGrams': PropertySchema(
      id: 6,
      name: r'servingGrams',
      type: IsarType.double,
    )
  },
  estimateSize: _userFoodLogEstimateSize,
  serialize: _userFoodLogSerialize,
  deserialize: _userFoodLogDeserialize,
  deserializeProp: _userFoodLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'normalizedName': IndexSchema(
      id: -9115371092206571671,
      name: r'normalizedName',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'normalizedName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'FoodNutrition': FoodNutritionSchema},
  getId: _userFoodLogGetId,
  getLinks: _userFoodLogGetLinks,
  attach: _userFoodLogAttach,
  version: '3.1.0+1',
);

int _userFoodLogEstimateSize(
  UserFoodLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 +
      FoodNutritionSchema.estimateSize(
          object.baseNutrition, allOffsets[FoodNutrition]!, allOffsets);
  bytesCount += 3 + object.normalizedName.length * 3;
  bytesCount += 3 + object.originalName.length * 3;
  {
    final value = object.provenance;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _userFoodLogSerialize(
  UserFoodLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.addedAt);
  writer.writeObject<FoodNutrition>(
    offsets[1],
    allOffsets,
    FoodNutritionSchema.serialize,
    object.baseNutrition,
  );
  writer.writeBool(offsets[2], object.isPer100g);
  writer.writeString(offsets[3], object.normalizedName);
  writer.writeString(offsets[4], object.originalName);
  writer.writeString(offsets[5], object.provenance);
  writer.writeDouble(offsets[6], object.servingGrams);
}

UserFoodLog _userFoodLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserFoodLog(
    addedAt: reader.readDateTime(offsets[0]),
    baseNutrition: reader.readObjectOrNull<FoodNutrition>(
          offsets[1],
          FoodNutritionSchema.deserialize,
          allOffsets,
        ) ??
        FoodNutrition(),
    isPer100g: reader.readBoolOrNull(offsets[2]) ?? false,
    normalizedName: reader.readString(offsets[3]),
    originalName: reader.readString(offsets[4]),
    provenance: reader.readStringOrNull(offsets[5]),
    servingGrams: reader.readDoubleOrNull(offsets[6]),
  );
  object.id = id;
  return object;
}

P _userFoodLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readObjectOrNull<FoodNutrition>(
            offset,
            FoodNutritionSchema.deserialize,
            allOffsets,
          ) ??
          FoodNutrition()) as P;
    case 2:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userFoodLogGetId(UserFoodLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userFoodLogGetLinks(UserFoodLog object) {
  return [];
}

void _userFoodLogAttach(
    IsarCollection<dynamic> col, Id id, UserFoodLog object) {
  object.id = id;
}

extension UserFoodLogByIndex on IsarCollection<UserFoodLog> {
  Future<UserFoodLog?> getByNormalizedName(String normalizedName) {
    return getByIndex(r'normalizedName', [normalizedName]);
  }

  UserFoodLog? getByNormalizedNameSync(String normalizedName) {
    return getByIndexSync(r'normalizedName', [normalizedName]);
  }

  Future<bool> deleteByNormalizedName(String normalizedName) {
    return deleteByIndex(r'normalizedName', [normalizedName]);
  }

  bool deleteByNormalizedNameSync(String normalizedName) {
    return deleteByIndexSync(r'normalizedName', [normalizedName]);
  }

  Future<List<UserFoodLog?>> getAllByNormalizedName(
      List<String> normalizedNameValues) {
    final values = normalizedNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'normalizedName', values);
  }

  List<UserFoodLog?> getAllByNormalizedNameSync(
      List<String> normalizedNameValues) {
    final values = normalizedNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'normalizedName', values);
  }

  Future<int> deleteAllByNormalizedName(List<String> normalizedNameValues) {
    final values = normalizedNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'normalizedName', values);
  }

  int deleteAllByNormalizedNameSync(List<String> normalizedNameValues) {
    final values = normalizedNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'normalizedName', values);
  }

  Future<Id> putByNormalizedName(UserFoodLog object) {
    return putByIndex(r'normalizedName', object);
  }

  Id putByNormalizedNameSync(UserFoodLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'normalizedName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNormalizedName(List<UserFoodLog> objects) {
    return putAllByIndex(r'normalizedName', objects);
  }

  List<Id> putAllByNormalizedNameSync(List<UserFoodLog> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'normalizedName', objects, saveLinks: saveLinks);
  }
}

extension UserFoodLogQueryWhereSort
    on QueryBuilder<UserFoodLog, UserFoodLog, QWhere> {
  QueryBuilder<UserFoodLog, UserFoodLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserFoodLogQueryWhere
    on QueryBuilder<UserFoodLog, UserFoodLog, QWhereClause> {
  QueryBuilder<UserFoodLog, UserFoodLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterWhereClause>
      normalizedNameEqualTo(String normalizedName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'normalizedName',
        value: [normalizedName],
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterWhereClause>
      normalizedNameNotEqualTo(String normalizedName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedName',
              lower: [],
              upper: [normalizedName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedName',
              lower: [normalizedName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedName',
              lower: [normalizedName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedName',
              lower: [],
              upper: [normalizedName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension UserFoodLogQueryFilter
    on QueryBuilder<UserFoodLog, UserFoodLog, QFilterCondition> {
  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition> addedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      addedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'addedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition> addedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'addedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition> addedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'addedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      isPer100gEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPer100g',
        value: value,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'normalizedName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'normalizedName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedName',
        value: '',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      normalizedNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'normalizedName',
        value: '',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalName',
        value: '',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      originalNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalName',
        value: '',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'provenance',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'provenance',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provenance',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'provenance',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'provenance',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'provenance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'provenance',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'provenance',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'provenance',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'provenance',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provenance',
        value: '',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      provenanceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'provenance',
        value: '',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      servingGramsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'servingGrams',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      servingGramsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'servingGrams',
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      servingGramsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      servingGramsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'servingGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      servingGramsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'servingGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition>
      servingGramsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'servingGrams',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension UserFoodLogQueryObject
    on QueryBuilder<UserFoodLog, UserFoodLog, QFilterCondition> {
  QueryBuilder<UserFoodLog, UserFoodLog, QAfterFilterCondition> baseNutrition(
      FilterQuery<FoodNutrition> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'baseNutrition');
    });
  }
}

extension UserFoodLogQueryLinks
    on QueryBuilder<UserFoodLog, UserFoodLog, QFilterCondition> {}

extension UserFoodLogQuerySortBy
    on QueryBuilder<UserFoodLog, UserFoodLog, QSortBy> {
  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> sortByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> sortByAddedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> sortByIsPer100g() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPer100g', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> sortByIsPer100gDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPer100g', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> sortByNormalizedName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedName', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy>
      sortByNormalizedNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedName', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> sortByOriginalName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalName', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy>
      sortByOriginalNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalName', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> sortByProvenance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenance', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> sortByProvenanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenance', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> sortByServingGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingGrams', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy>
      sortByServingGramsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingGrams', Sort.desc);
    });
  }
}

extension UserFoodLogQuerySortThenBy
    on QueryBuilder<UserFoodLog, UserFoodLog, QSortThenBy> {
  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByAddedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByIsPer100g() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPer100g', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByIsPer100gDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPer100g', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByNormalizedName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedName', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy>
      thenByNormalizedNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedName', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByOriginalName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalName', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy>
      thenByOriginalNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalName', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByProvenance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenance', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByProvenanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenance', Sort.desc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy> thenByServingGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingGrams', Sort.asc);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QAfterSortBy>
      thenByServingGramsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingGrams', Sort.desc);
    });
  }
}

extension UserFoodLogQueryWhereDistinct
    on QueryBuilder<UserFoodLog, UserFoodLog, QDistinct> {
  QueryBuilder<UserFoodLog, UserFoodLog, QDistinct> distinctByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addedAt');
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QDistinct> distinctByIsPer100g() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPer100g');
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QDistinct> distinctByNormalizedName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'normalizedName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QDistinct> distinctByOriginalName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QDistinct> distinctByProvenance(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'provenance', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserFoodLog, UserFoodLog, QDistinct> distinctByServingGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingGrams');
    });
  }
}

extension UserFoodLogQueryProperty
    on QueryBuilder<UserFoodLog, UserFoodLog, QQueryProperty> {
  QueryBuilder<UserFoodLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserFoodLog, DateTime, QQueryOperations> addedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addedAt');
    });
  }

  QueryBuilder<UserFoodLog, FoodNutrition, QQueryOperations>
      baseNutritionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseNutrition');
    });
  }

  QueryBuilder<UserFoodLog, bool, QQueryOperations> isPer100gProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPer100g');
    });
  }

  QueryBuilder<UserFoodLog, String, QQueryOperations> normalizedNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'normalizedName');
    });
  }

  QueryBuilder<UserFoodLog, String, QQueryOperations> originalNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalName');
    });
  }

  QueryBuilder<UserFoodLog, String?, QQueryOperations> provenanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'provenance');
    });
  }

  QueryBuilder<UserFoodLog, double?, QQueryOperations> servingGramsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingGrams');
    });
  }
}
