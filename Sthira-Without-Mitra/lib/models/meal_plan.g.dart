// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMealPlanCollection on Isar {
  IsarCollection<MealPlan> get mealPlans => this.collection();
}

const MealPlanSchema = CollectionSchema(
  name: r'MealPlan',
  id: 6858060180785015955,
  properties: {
    r'basedOnPlanName': PropertySchema(
      id: 0,
      name: r'basedOnPlanName',
      type: IsarType.string,
    ),
    r'completedCalories': PropertySchema(
      id: 1,
      name: r'completedCalories',
      type: IsarType.long,
    ),
    r'completedMeals': PropertySchema(
      id: 2,
      name: r'completedMeals',
      type: IsarType.long,
    ),
    r'meals': PropertySchema(
      id: 3,
      name: r'meals',
      type: IsarType.objectList,
      target: r'Meal',
    ),
    r'planName': PropertySchema(
      id: 4,
      name: r'planName',
      type: IsarType.string,
    ),
    r'seedVersion': PropertySchema(
      id: 5,
      name: r'seedVersion',
      type: IsarType.long,
    ),
    r'source': PropertySchema(
      id: 6,
      name: r'source',
      type: IsarType.string,
    ),
    r'totalCalories': PropertySchema(
      id: 7,
      name: r'totalCalories',
      type: IsarType.long,
    )
  },
  estimateSize: _mealPlanEstimateSize,
  serialize: _mealPlanSerialize,
  deserialize: _mealPlanDeserialize,
  deserializeProp: _mealPlanDeserializeProp,
  idName: r'id',
  indexes: {
    r'planName': IndexSchema(
      id: -2372009361415681807,
      name: r'planName',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'planName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'Meal': MealSchema, r'MealItem': MealItemSchema},
  getId: _mealPlanGetId,
  getLinks: _mealPlanGetLinks,
  attach: _mealPlanAttach,
  version: '3.1.0+1',
);

int _mealPlanEstimateSize(
  MealPlan object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.basedOnPlanName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.meals.length * 3;
  {
    final offsets = allOffsets[Meal]!;
    for (var i = 0; i < object.meals.length; i++) {
      final value = object.meals[i];
      bytesCount += MealSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.planName.length * 3;
  bytesCount += 3 + object.source.length * 3;
  return bytesCount;
}

void _mealPlanSerialize(
  MealPlan object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.basedOnPlanName);
  writer.writeLong(offsets[1], object.completedCalories);
  writer.writeLong(offsets[2], object.completedMeals);
  writer.writeObjectList<Meal>(
    offsets[3],
    allOffsets,
    MealSchema.serialize,
    object.meals,
  );
  writer.writeString(offsets[4], object.planName);
  writer.writeLong(offsets[5], object.seedVersion);
  writer.writeString(offsets[6], object.source);
  writer.writeLong(offsets[7], object.totalCalories);
}

MealPlan _mealPlanDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MealPlan(
    basedOnPlanName: reader.readStringOrNull(offsets[0]),
    meals: reader.readObjectList<Meal>(
          offsets[3],
          MealSchema.deserialize,
          allOffsets,
          Meal(),
        ) ??
        [],
    planName: reader.readString(offsets[4]),
    seedVersion: reader.readLongOrNull(offsets[5]),
    source: reader.readStringOrNull(offsets[6]) ?? 'user',
    totalCalories: reader.readLong(offsets[7]),
  );
  object.id = id;
  return object;
}

P _mealPlanDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readObjectList<Meal>(
            offset,
            MealSchema.deserialize,
            allOffsets,
            Meal(),
          ) ??
          []) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset) ?? 'user') as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _mealPlanGetId(MealPlan object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mealPlanGetLinks(MealPlan object) {
  return [];
}

void _mealPlanAttach(IsarCollection<dynamic> col, Id id, MealPlan object) {
  object.id = id;
}

extension MealPlanByIndex on IsarCollection<MealPlan> {
  Future<MealPlan?> getByPlanName(String planName) {
    return getByIndex(r'planName', [planName]);
  }

  MealPlan? getByPlanNameSync(String planName) {
    return getByIndexSync(r'planName', [planName]);
  }

  Future<bool> deleteByPlanName(String planName) {
    return deleteByIndex(r'planName', [planName]);
  }

  bool deleteByPlanNameSync(String planName) {
    return deleteByIndexSync(r'planName', [planName]);
  }

  Future<List<MealPlan?>> getAllByPlanName(List<String> planNameValues) {
    final values = planNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'planName', values);
  }

  List<MealPlan?> getAllByPlanNameSync(List<String> planNameValues) {
    final values = planNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'planName', values);
  }

  Future<int> deleteAllByPlanName(List<String> planNameValues) {
    final values = planNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'planName', values);
  }

  int deleteAllByPlanNameSync(List<String> planNameValues) {
    final values = planNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'planName', values);
  }

  Future<Id> putByPlanName(MealPlan object) {
    return putByIndex(r'planName', object);
  }

  Id putByPlanNameSync(MealPlan object, {bool saveLinks = true}) {
    return putByIndexSync(r'planName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPlanName(List<MealPlan> objects) {
    return putAllByIndex(r'planName', objects);
  }

  List<Id> putAllByPlanNameSync(List<MealPlan> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'planName', objects, saveLinks: saveLinks);
  }
}

extension MealPlanQueryWhereSort on QueryBuilder<MealPlan, MealPlan, QWhere> {
  QueryBuilder<MealPlan, MealPlan, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MealPlanQueryWhere on QueryBuilder<MealPlan, MealPlan, QWhereClause> {
  QueryBuilder<MealPlan, MealPlan, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<MealPlan, MealPlan, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterWhereClause> idBetween(
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

  QueryBuilder<MealPlan, MealPlan, QAfterWhereClause> planNameEqualTo(
      String planName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'planName',
        value: [planName],
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterWhereClause> planNameNotEqualTo(
      String planName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'planName',
              lower: [],
              upper: [planName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'planName',
              lower: [planName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'planName',
              lower: [planName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'planName',
              lower: [],
              upper: [planName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MealPlanQueryFilter
    on QueryBuilder<MealPlan, MealPlan, QFilterCondition> {
  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'basedOnPlanName',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'basedOnPlanName',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'basedOnPlanName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'basedOnPlanName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'basedOnPlanName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'basedOnPlanName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'basedOnPlanName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'basedOnPlanName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'basedOnPlanName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'basedOnPlanName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'basedOnPlanName',
        value: '',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      basedOnPlanNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'basedOnPlanName',
        value: '',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      completedCaloriesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      completedCaloriesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      completedCaloriesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      completedCaloriesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedCalories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> completedMealsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedMeals',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      completedMealsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedMeals',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      completedMealsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedMeals',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> completedMealsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedMeals',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> mealsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> mealsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> mealsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> mealsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      mealsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> mealsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'planName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'planName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planName',
        value: '',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> planNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'planName',
        value: '',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> seedVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'seedVersion',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      seedVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'seedVersion',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> seedVersionEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seedVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      seedVersionGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'seedVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> seedVersionLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'seedVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> seedVersionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'seedVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> totalCaloriesEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition>
      totalCaloriesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> totalCaloriesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> totalCaloriesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCalories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MealPlanQueryObject
    on QueryBuilder<MealPlan, MealPlan, QFilterCondition> {
  QueryBuilder<MealPlan, MealPlan, QAfterFilterCondition> mealsElement(
      FilterQuery<Meal> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'meals');
    });
  }
}

extension MealPlanQueryLinks
    on QueryBuilder<MealPlan, MealPlan, QFilterCondition> {}

extension MealPlanQuerySortBy on QueryBuilder<MealPlan, MealPlan, QSortBy> {
  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByBasedOnPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basedOnPlanName', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByBasedOnPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basedOnPlanName', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByCompletedCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCalories', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByCompletedCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCalories', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByCompletedMeals() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedMeals', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByCompletedMealsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedMeals', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortBySeedVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedVersion', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortBySeedVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedVersion', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> sortByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }
}

extension MealPlanQuerySortThenBy
    on QueryBuilder<MealPlan, MealPlan, QSortThenBy> {
  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByBasedOnPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basedOnPlanName', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByBasedOnPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basedOnPlanName', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByCompletedCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCalories', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByCompletedCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCalories', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByCompletedMeals() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedMeals', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByCompletedMealsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedMeals', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenBySeedVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedVersion', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenBySeedVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedVersion', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QAfterSortBy> thenByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }
}

extension MealPlanQueryWhereDistinct
    on QueryBuilder<MealPlan, MealPlan, QDistinct> {
  QueryBuilder<MealPlan, MealPlan, QDistinct> distinctByBasedOnPlanName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'basedOnPlanName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QDistinct> distinctByCompletedCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedCalories');
    });
  }

  QueryBuilder<MealPlan, MealPlan, QDistinct> distinctByCompletedMeals() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedMeals');
    });
  }

  QueryBuilder<MealPlan, MealPlan, QDistinct> distinctByPlanName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'planName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QDistinct> distinctBySeedVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seedVersion');
    });
  }

  QueryBuilder<MealPlan, MealPlan, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MealPlan, MealPlan, QDistinct> distinctByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCalories');
    });
  }
}

extension MealPlanQueryProperty
    on QueryBuilder<MealPlan, MealPlan, QQueryProperty> {
  QueryBuilder<MealPlan, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MealPlan, String?, QQueryOperations> basedOnPlanNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'basedOnPlanName');
    });
  }

  QueryBuilder<MealPlan, int, QQueryOperations> completedCaloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedCalories');
    });
  }

  QueryBuilder<MealPlan, int, QQueryOperations> completedMealsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedMeals');
    });
  }

  QueryBuilder<MealPlan, List<Meal>, QQueryOperations> mealsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meals');
    });
  }

  QueryBuilder<MealPlan, String, QQueryOperations> planNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'planName');
    });
  }

  QueryBuilder<MealPlan, int?, QQueryOperations> seedVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seedVersion');
    });
  }

  QueryBuilder<MealPlan, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<MealPlan, int, QQueryOperations> totalCaloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCalories');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MealSchema = Schema(
  name: r'Meal',
  id: 2462895270179255875,
  properties: {
    r'calories': PropertySchema(
      id: 0,
      name: r'calories',
      type: IsarType.long,
    ),
    r'icon': PropertySchema(
      id: 1,
      name: r'icon',
      type: IsarType.string,
    ),
    r'isCompleted': PropertySchema(
      id: 2,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'items': PropertySchema(
      id: 3,
      name: r'items',
      type: IsarType.objectList,
      target: r'MealItem',
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'suggestions': PropertySchema(
      id: 5,
      name: r'suggestions',
      type: IsarType.stringList,
    ),
    r'type': PropertySchema(
      id: 6,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _mealEstimateSize,
  serialize: _mealSerialize,
  deserialize: _mealDeserialize,
  deserializeProp: _mealDeserializeProp,
);

int _mealEstimateSize(
  Meal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.icon.length * 3;
  bytesCount += 3 + object.items.length * 3;
  {
    final offsets = allOffsets[MealItem]!;
    for (var i = 0; i < object.items.length; i++) {
      final value = object.items[i];
      bytesCount += MealItemSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.suggestions.length * 3;
  {
    for (var i = 0; i < object.suggestions.length; i++) {
      final value = object.suggestions[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _mealSerialize(
  Meal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.calories);
  writer.writeString(offsets[1], object.icon);
  writer.writeBool(offsets[2], object.isCompleted);
  writer.writeObjectList<MealItem>(
    offsets[3],
    allOffsets,
    MealItemSchema.serialize,
    object.items,
  );
  writer.writeString(offsets[4], object.name);
  writer.writeStringList(offsets[5], object.suggestions);
  writer.writeString(offsets[6], object.type);
}

Meal _mealDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Meal(
    calories: reader.readLongOrNull(offsets[0]) ?? 0,
    isCompleted: reader.readBoolOrNull(offsets[2]) ?? false,
    items: reader.readObjectList<MealItem>(
          offsets[3],
          MealItemSchema.deserialize,
          allOffsets,
          MealItem(),
        ) ??
        const [],
    name: reader.readStringOrNull(offsets[4]),
    suggestions: reader.readStringList(offsets[5]) ?? const [],
    type: reader.readStringOrNull(offsets[6]),
  );
  return object;
}

P _mealDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 3:
      return (reader.readObjectList<MealItem>(
            offset,
            MealItemSchema.deserialize,
            allOffsets,
            MealItem(),
          ) ??
          const []) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? const []) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MealQueryFilter on QueryBuilder<Meal, Meal, QFilterCondition> {
  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calories',
        value: value,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calories',
        value: value,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calories',
        value: value,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'icon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'icon',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> iconIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> isCompletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> itemsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> itemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> itemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> itemsLengthBetween(
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

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'suggestions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'suggestions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'suggestions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'suggestions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'suggestions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'suggestions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'suggestions',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestions',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition>
      suggestionsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'suggestions',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestions',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestions',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestions',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestions',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestions',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> suggestionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension MealQueryObject on QueryBuilder<Meal, Meal, QFilterCondition> {
  QueryBuilder<Meal, Meal, QAfterFilterCondition> itemsElement(
      FilterQuery<MealItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'items');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MealItemSchema = Schema(
  name: r'MealItem',
  id: 65289250348097748,
  properties: {
    r'calories': PropertySchema(
      id: 0,
      name: r'calories',
      type: IsarType.long,
    ),
    r'carbsG': PropertySchema(
      id: 1,
      name: r'carbsG',
      type: IsarType.double,
    ),
    r'fatG': PropertySchema(
      id: 2,
      name: r'fatG',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'proteinG': PropertySchema(
      id: 4,
      name: r'proteinG',
      type: IsarType.double,
    ),
    r'quantity': PropertySchema(
      id: 5,
      name: r'quantity',
      type: IsarType.string,
    )
  },
  estimateSize: _mealItemEstimateSize,
  serialize: _mealItemSerialize,
  deserialize: _mealItemDeserialize,
  deserializeProp: _mealItemDeserializeProp,
);

int _mealItemEstimateSize(
  MealItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.quantity;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _mealItemSerialize(
  MealItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.calories);
  writer.writeDouble(offsets[1], object.carbsG);
  writer.writeDouble(offsets[2], object.fatG);
  writer.writeString(offsets[3], object.name);
  writer.writeDouble(offsets[4], object.proteinG);
  writer.writeString(offsets[5], object.quantity);
}

MealItem _mealItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MealItem(
    calories: reader.readLongOrNull(offsets[0]),
    carbsG: reader.readDoubleOrNull(offsets[1]),
    fatG: reader.readDoubleOrNull(offsets[2]),
    name: reader.readStringOrNull(offsets[3]),
    proteinG: reader.readDoubleOrNull(offsets[4]),
    quantity: reader.readStringOrNull(offsets[5]),
  );
  return object;
}

P _mealItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MealItemQueryFilter
    on QueryBuilder<MealItem, MealItem, QFilterCondition> {
  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> caloriesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'calories',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> caloriesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'calories',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> caloriesEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> caloriesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> caloriesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> caloriesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> carbsGIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'carbsG',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> carbsGIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'carbsG',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> carbsGEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbsG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> carbsGGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbsG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> carbsGLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbsG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> carbsGBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbsG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> fatGIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fatG',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> fatGIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fatG',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> fatGEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fatG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> fatGGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fatG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> fatGLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fatG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> fatGBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fatG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> proteinGIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'proteinG',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> proteinGIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'proteinG',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> proteinGEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> proteinGGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> proteinGLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> proteinGBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'quantity',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'quantity',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'quantity',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItem, MealItem, QAfterFilterCondition> quantityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'quantity',
        value: '',
      ));
    });
  }
}

extension MealItemQueryObject
    on QueryBuilder<MealItem, MealItem, QFilterCondition> {}
