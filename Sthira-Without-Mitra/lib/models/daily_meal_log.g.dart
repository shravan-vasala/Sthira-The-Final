// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_meal_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyMealLogCollection on Isar {
  IsarCollection<DailyMealLog> get dailyMealLogs => this.collection();
}

const DailyMealLogSchema = CollectionSchema(
  name: r'DailyMealLog',
  id: -1104250001336833861,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.string,
    ),
    r'isarCustomSlots': PropertySchema(
      id: 1,
      name: r'isarCustomSlots',
      type: IsarType.objectList,
      target: r'CustomSlotEntry',
    ),
    r'loggedSlotsCount': PropertySchema(
      id: 2,
      name: r'loggedSlotsCount',
      type: IsarType.long,
    ),
    r'totalCalories': PropertySchema(
      id: 3,
      name: r'totalCalories',
      type: IsarType.long,
    ),
    r'totalCarbs': PropertySchema(
      id: 4,
      name: r'totalCarbs',
      type: IsarType.double,
    ),
    r'totalFat': PropertySchema(
      id: 5,
      name: r'totalFat',
      type: IsarType.double,
    ),
    r'totalProtein': PropertySchema(
      id: 6,
      name: r'totalProtein',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _dailyMealLogEstimateSize,
  serialize: _dailyMealLogSerialize,
  deserialize: _dailyMealLogDeserialize,
  deserializeProp: _dailyMealLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'CustomSlotEntry': CustomSlotEntrySchema,
    r'MealSlotLog': MealSlotLogSchema,
    r'MealItemLog': MealItemLogSchema,
    r'FoodNutrition': FoodNutritionSchema
  },
  getId: _dailyMealLogGetId,
  getLinks: _dailyMealLogGetLinks,
  attach: _dailyMealLogAttach,
  version: '3.1.0+1',
);

int _dailyMealLogEstimateSize(
  DailyMealLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.date.length * 3;
  bytesCount += 3 + object.isarCustomSlots.length * 3;
  {
    final offsets = allOffsets[CustomSlotEntry]!;
    for (var i = 0; i < object.isarCustomSlots.length; i++) {
      final value = object.isarCustomSlots[i];
      bytesCount +=
          CustomSlotEntrySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _dailyMealLogSerialize(
  DailyMealLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.date);
  writer.writeObjectList<CustomSlotEntry>(
    offsets[1],
    allOffsets,
    CustomSlotEntrySchema.serialize,
    object.isarCustomSlots,
  );
  writer.writeLong(offsets[2], object.loggedSlotsCount);
  writer.writeLong(offsets[3], object.totalCalories);
  writer.writeDouble(offsets[4], object.totalCarbs);
  writer.writeDouble(offsets[5], object.totalFat);
  writer.writeDouble(offsets[6], object.totalProtein);
  writer.writeDateTime(offsets[7], object.updatedAt);
}

DailyMealLog _dailyMealLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyMealLog(
    date: reader.readString(offsets[0]),
    updatedAt: reader.readDateTimeOrNull(offsets[7]),
  );
  object.id = id;
  object.isarCustomSlots = reader.readObjectList<CustomSlotEntry>(
        offsets[1],
        CustomSlotEntrySchema.deserialize,
        allOffsets,
        CustomSlotEntry(),
      ) ??
      [];
  return object;
}

P _dailyMealLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readObjectList<CustomSlotEntry>(
            offset,
            CustomSlotEntrySchema.deserialize,
            allOffsets,
            CustomSlotEntry(),
          ) ??
          []) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyMealLogGetId(DailyMealLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyMealLogGetLinks(DailyMealLog object) {
  return [];
}

void _dailyMealLogAttach(
    IsarCollection<dynamic> col, Id id, DailyMealLog object) {
  object.id = id;
}

extension DailyMealLogByIndex on IsarCollection<DailyMealLog> {
  Future<DailyMealLog?> getByDate(String date) {
    return getByIndex(r'date', [date]);
  }

  DailyMealLog? getByDateSync(String date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(String date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(String date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<DailyMealLog?>> getAllByDate(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<DailyMealLog?> getAllByDateSync(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(DailyMealLog object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(DailyMealLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<DailyMealLog> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<DailyMealLog> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension DailyMealLogQueryWhereSort
    on QueryBuilder<DailyMealLog, DailyMealLog, QWhere> {
  QueryBuilder<DailyMealLog, DailyMealLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailyMealLogQueryWhere
    on QueryBuilder<DailyMealLog, DailyMealLog, QWhereClause> {
  QueryBuilder<DailyMealLog, DailyMealLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterWhereClause> dateEqualTo(
      String date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterWhereClause> dateNotEqualTo(
      String date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DailyMealLogQueryFilter
    on QueryBuilder<DailyMealLog, DailyMealLog, QFilterCondition> {
  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> dateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      dateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> dateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> dateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      dateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> dateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> dateContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> dateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      isarCustomSlotsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'isarCustomSlots',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      isarCustomSlotsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'isarCustomSlots',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      isarCustomSlotsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'isarCustomSlots',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      isarCustomSlotsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'isarCustomSlots',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      isarCustomSlotsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'isarCustomSlots',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      isarCustomSlotsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'isarCustomSlots',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      loggedSlotsCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loggedSlotsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      loggedSlotsCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loggedSlotsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      loggedSlotsCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loggedSlotsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      loggedSlotsCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loggedSlotsCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalCaloriesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
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

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalCaloriesLessThan(
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

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalCaloriesBetween(
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

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalCarbsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCarbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalCarbsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCarbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalCarbsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCarbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalCarbsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCarbs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalFatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalFatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalFatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalFatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalFat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalProteinEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalProtein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalProteinGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalProtein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalProteinLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalProtein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      totalProteinBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalProtein',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyMealLogQueryObject
    on QueryBuilder<DailyMealLog, DailyMealLog, QFilterCondition> {
  QueryBuilder<DailyMealLog, DailyMealLog, QAfterFilterCondition>
      isarCustomSlotsElement(FilterQuery<CustomSlotEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'isarCustomSlots');
    });
  }
}

extension DailyMealLogQueryLinks
    on QueryBuilder<DailyMealLog, DailyMealLog, QFilterCondition> {}

extension DailyMealLogQuerySortBy
    on QueryBuilder<DailyMealLog, DailyMealLog, QSortBy> {
  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      sortByLoggedSlotsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loggedSlotsCount', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      sortByLoggedSlotsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loggedSlotsCount', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> sortByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      sortByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> sortByTotalCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCarbs', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      sortByTotalCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCarbs', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> sortByTotalFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFat', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> sortByTotalFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFat', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> sortByTotalProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProtein', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      sortByTotalProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProtein', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DailyMealLogQuerySortThenBy
    on QueryBuilder<DailyMealLog, DailyMealLog, QSortThenBy> {
  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      thenByLoggedSlotsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loggedSlotsCount', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      thenByLoggedSlotsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loggedSlotsCount', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      thenByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByTotalCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCarbs', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      thenByTotalCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCarbs', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByTotalFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFat', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByTotalFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFat', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByTotalProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProtein', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy>
      thenByTotalProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProtein', Sort.desc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DailyMealLogQueryWhereDistinct
    on QueryBuilder<DailyMealLog, DailyMealLog, QDistinct> {
  QueryBuilder<DailyMealLog, DailyMealLog, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QDistinct>
      distinctByLoggedSlotsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loggedSlotsCount');
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QDistinct>
      distinctByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCalories');
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QDistinct> distinctByTotalCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCarbs');
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QDistinct> distinctByTotalFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalFat');
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QDistinct> distinctByTotalProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalProtein');
    });
  }

  QueryBuilder<DailyMealLog, DailyMealLog, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension DailyMealLogQueryProperty
    on QueryBuilder<DailyMealLog, DailyMealLog, QQueryProperty> {
  QueryBuilder<DailyMealLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyMealLog, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailyMealLog, List<CustomSlotEntry>, QQueryOperations>
      isarCustomSlotsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarCustomSlots');
    });
  }

  QueryBuilder<DailyMealLog, int, QQueryOperations> loggedSlotsCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loggedSlotsCount');
    });
  }

  QueryBuilder<DailyMealLog, int, QQueryOperations> totalCaloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCalories');
    });
  }

  QueryBuilder<DailyMealLog, double, QQueryOperations> totalCarbsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCarbs');
    });
  }

  QueryBuilder<DailyMealLog, double, QQueryOperations> totalFatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalFat');
    });
  }

  QueryBuilder<DailyMealLog, double, QQueryOperations> totalProteinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalProtein');
    });
  }

  QueryBuilder<DailyMealLog, DateTime?, QQueryOperations> updatedAtProperty() {
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

const CustomSlotEntrySchema = Schema(
  name: r'CustomSlotEntry',
  id: 3295158037584370866,
  properties: {
    r'key': PropertySchema(
      id: 0,
      name: r'key',
      type: IsarType.string,
    ),
    r'value': PropertySchema(
      id: 1,
      name: r'value',
      type: IsarType.object,
      target: r'MealSlotLog',
    )
  },
  estimateSize: _customSlotEntryEstimateSize,
  serialize: _customSlotEntrySerialize,
  deserialize: _customSlotEntryDeserialize,
  deserializeProp: _customSlotEntryDeserializeProp,
);

int _customSlotEntryEstimateSize(
  CustomSlotEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.key;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.value;
    if (value != null) {
      bytesCount += 3 +
          MealSlotLogSchema.estimateSize(
              value, allOffsets[MealSlotLog]!, allOffsets);
    }
  }
  return bytesCount;
}

void _customSlotEntrySerialize(
  CustomSlotEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.key);
  writer.writeObject<MealSlotLog>(
    offsets[1],
    allOffsets,
    MealSlotLogSchema.serialize,
    object.value,
  );
}

CustomSlotEntry _customSlotEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomSlotEntry();
  object.key = reader.readStringOrNull(offsets[0]);
  object.value = reader.readObjectOrNull<MealSlotLog>(
    offsets[1],
    MealSlotLogSchema.deserialize,
    allOffsets,
  );
  return object;
}

P _customSlotEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readObjectOrNull<MealSlotLog>(
        offset,
        MealSlotLogSchema.deserialize,
        allOffsets,
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension CustomSlotEntryQueryFilter
    on QueryBuilder<CustomSlotEntry, CustomSlotEntry, QFilterCondition> {
  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'key',
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'key',
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'key',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      valueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'value',
      ));
    });
  }

  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition>
      valueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'value',
      ));
    });
  }
}

extension CustomSlotEntryQueryObject
    on QueryBuilder<CustomSlotEntry, CustomSlotEntry, QFilterCondition> {
  QueryBuilder<CustomSlotEntry, CustomSlotEntry, QAfterFilterCondition> value(
      FilterQuery<MealSlotLog> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'value');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MealSlotLogSchema = Schema(
  name: r'MealSlotLog',
  id: 2180190762773051509,
  properties: {
    r'caloriesComplete': PropertySchema(
      id: 0,
      name: r'caloriesComplete',
      type: IsarType.bool,
    ),
    r'confidence': PropertySchema(
      id: 1,
      name: r'confidence',
      type: IsarType.string,
    ),
    r'emoji': PropertySchema(
      id: 2,
      name: r'emoji',
      type: IsarType.string,
    ),
    r'items': PropertySchema(
      id: 3,
      name: r'items',
      type: IsarType.objectList,
      target: r'MealItemLog',
    ),
    r'macrosComplete': PropertySchema(
      id: 4,
      name: r'macrosComplete',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'photoPath': PropertySchema(
      id: 6,
      name: r'photoPath',
      type: IsarType.string,
    ),
    r'photoPaths': PropertySchema(
      id: 7,
      name: r'photoPaths',
      type: IsarType.stringList,
    ),
    r'totalCalories': PropertySchema(
      id: 8,
      name: r'totalCalories',
      type: IsarType.long,
    ),
    r'totalCarbs': PropertySchema(
      id: 9,
      name: r'totalCarbs',
      type: IsarType.double,
    ),
    r'totalFat': PropertySchema(
      id: 10,
      name: r'totalFat',
      type: IsarType.double,
    ),
    r'totalProtein': PropertySchema(
      id: 11,
      name: r'totalProtein',
      type: IsarType.double,
    )
  },
  estimateSize: _mealSlotLogEstimateSize,
  serialize: _mealSlotLogSerialize,
  deserialize: _mealSlotLogDeserialize,
  deserializeProp: _mealSlotLogDeserializeProp,
);

int _mealSlotLogEstimateSize(
  MealSlotLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.confidence;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.emoji;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.items.length * 3;
  {
    final offsets = allOffsets[MealItemLog]!;
    for (var i = 0; i < object.items.length; i++) {
      final value = object.items[i];
      bytesCount += MealItemLogSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.photoPaths.length * 3;
  {
    for (var i = 0; i < object.photoPaths.length; i++) {
      final value = object.photoPaths[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _mealSlotLogSerialize(
  MealSlotLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.caloriesComplete);
  writer.writeString(offsets[1], object.confidence);
  writer.writeString(offsets[2], object.emoji);
  writer.writeObjectList<MealItemLog>(
    offsets[3],
    allOffsets,
    MealItemLogSchema.serialize,
    object.items,
  );
  writer.writeBool(offsets[4], object.macrosComplete);
  writer.writeString(offsets[5], object.name);
  writer.writeString(offsets[6], object.photoPath);
  writer.writeStringList(offsets[7], object.photoPaths);
  writer.writeLong(offsets[8], object.totalCalories);
  writer.writeDouble(offsets[9], object.totalCarbs);
  writer.writeDouble(offsets[10], object.totalFat);
  writer.writeDouble(offsets[11], object.totalProtein);
}

MealSlotLog _mealSlotLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MealSlotLog(
    caloriesComplete: reader.readBoolOrNull(offsets[0]),
    confidence: reader.readStringOrNull(offsets[1]),
    emoji: reader.readStringOrNull(offsets[2]),
    items: reader.readObjectList<MealItemLog>(
          offsets[3],
          MealItemLogSchema.deserialize,
          allOffsets,
          MealItemLog(),
        ) ??
        const [],
    macrosComplete: reader.readBoolOrNull(offsets[4]),
    name: reader.readStringOrNull(offsets[5]),
    photoPath: reader.readStringOrNull(offsets[6]),
    photoPaths: reader.readStringList(offsets[7]) ?? const [],
    totalCalories: reader.readLongOrNull(offsets[8]) ?? 0,
    totalCarbs: reader.readDoubleOrNull(offsets[9]) ?? 0.0,
    totalFat: reader.readDoubleOrNull(offsets[10]) ?? 0.0,
    totalProtein: reader.readDoubleOrNull(offsets[11]) ?? 0.0,
  );
  return object;
}

P _mealSlotLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readObjectList<MealItemLog>(
            offset,
            MealItemLogSchema.deserialize,
            allOffsets,
            MealItemLog(),
          ) ??
          const []) as P;
    case 4:
      return (reader.readBoolOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? const []) as P;
    case 8:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 9:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 10:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 11:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MealSlotLogQueryFilter
    on QueryBuilder<MealSlotLog, MealSlotLog, QFilterCondition> {
  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      caloriesCompleteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'caloriesComplete',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      caloriesCompleteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'caloriesComplete',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      caloriesCompleteEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caloriesComplete',
        value: value,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'confidence',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'confidence',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'confidence',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      confidenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'confidence',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> emojiIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'emoji',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      emojiIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'emoji',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> emojiEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      emojiGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> emojiLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> emojiBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emoji',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> emojiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> emojiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> emojiContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> emojiMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'emoji',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> emojiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emoji',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      emojiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'emoji',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      itemsLengthEqualTo(int length) {
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> itemsIsEmpty() {
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      itemsIsNotEmpty() {
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      itemsLengthLessThan(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      itemsLengthGreaterThan(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      macrosCompleteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'macrosComplete',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      macrosCompleteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'macrosComplete',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      macrosCompleteEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'macrosComplete',
        value: value,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameContains(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photoPath',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photoPath',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoPaths',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoPaths',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPaths',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoPaths',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      photoPathsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoPaths',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalCaloriesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalCaloriesLessThan(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalCaloriesBetween(
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

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalCarbsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCarbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalCarbsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCarbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalCarbsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCarbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalCarbsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCarbs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> totalFatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalFatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalFatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> totalFatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalFat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalProteinEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalProtein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalProteinGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalProtein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalProteinLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalProtein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition>
      totalProteinBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalProtein',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension MealSlotLogQueryObject
    on QueryBuilder<MealSlotLog, MealSlotLog, QFilterCondition> {
  QueryBuilder<MealSlotLog, MealSlotLog, QAfterFilterCondition> itemsElement(
      FilterQuery<MealItemLog> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'items');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MealItemLogSchema = Schema(
  name: r'MealItemLog',
  id: -3515644216177808912,
  properties: {
    r'barcode': PropertySchema(
      id: 0,
      name: r'barcode',
      type: IsarType.string,
    ),
    r'baseNutrition': PropertySchema(
      id: 1,
      name: r'baseNutrition',
      type: IsarType.object,
      target: r'FoodNutrition',
    ),
    r'brand': PropertySchema(
      id: 2,
      name: r'brand',
      type: IsarType.string,
    ),
    r'computedNutrition': PropertySchema(
      id: 3,
      name: r'computedNutrition',
      type: IsarType.object,
      target: r'FoodNutrition',
    ),
    r'consumedGrams': PropertySchema(
      id: 4,
      name: r'consumedGrams',
      type: IsarType.double,
    ),
    r'consumedMl': PropertySchema(
      id: 5,
      name: r'consumedMl',
      type: IsarType.double,
    ),
    r'consumedServings': PropertySchema(
      id: 6,
      name: r'consumedServings',
      type: IsarType.double,
    ),
    r'isPer100g': PropertySchema(
      id: 7,
      name: r'isPer100g',
      type: IsarType.bool,
    ),
    r'macrosKnown': PropertySchema(
      id: 8,
      name: r'macrosKnown',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 9,
      name: r'name',
      type: IsarType.string,
    ),
    r'nutritionBasis': PropertySchema(
      id: 10,
      name: r'nutritionBasis',
      type: IsarType.string,
    ),
    r'portion': PropertySchema(
      id: 11,
      name: r'portion',
      type: IsarType.string,
    ),
    r'provenance': PropertySchema(
      id: 12,
      name: r'provenance',
      type: IsarType.string,
    ),
    r'resolved': PropertySchema(
      id: 13,
      name: r'resolved',
      type: IsarType.bool,
    ),
    r'servingGrams': PropertySchema(
      id: 14,
      name: r'servingGrams',
      type: IsarType.double,
    )
  },
  estimateSize: _mealItemLogEstimateSize,
  serialize: _mealItemLogSerialize,
  deserialize: _mealItemLogDeserialize,
  deserializeProp: _mealItemLogDeserializeProp,
);

int _mealItemLogEstimateSize(
  MealItemLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.barcode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.baseNutrition;
    if (value != null) {
      bytesCount += 3 +
          FoodNutritionSchema.estimateSize(
              value, allOffsets[FoodNutrition]!, allOffsets);
    }
  }
  {
    final value = object.brand;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.computedNutrition;
    if (value != null) {
      bytesCount += 3 +
          FoodNutritionSchema.estimateSize(
              value, allOffsets[FoodNutrition]!, allOffsets);
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.nutritionBasis;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.portion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.provenance;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _mealItemLogSerialize(
  MealItemLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.barcode);
  writer.writeObject<FoodNutrition>(
    offsets[1],
    allOffsets,
    FoodNutritionSchema.serialize,
    object.baseNutrition,
  );
  writer.writeString(offsets[2], object.brand);
  writer.writeObject<FoodNutrition>(
    offsets[3],
    allOffsets,
    FoodNutritionSchema.serialize,
    object.computedNutrition,
  );
  writer.writeDouble(offsets[4], object.consumedGrams);
  writer.writeDouble(offsets[5], object.consumedMl);
  writer.writeDouble(offsets[6], object.consumedServings);
  writer.writeBool(offsets[7], object.isPer100g);
  writer.writeBool(offsets[8], object.macrosKnown);
  writer.writeString(offsets[9], object.name);
  writer.writeString(offsets[10], object.nutritionBasis);
  writer.writeString(offsets[11], object.portion);
  writer.writeString(offsets[12], object.provenance);
  writer.writeBool(offsets[13], object.resolved);
  writer.writeDouble(offsets[14], object.servingGrams);
}

MealItemLog _mealItemLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MealItemLog(
    barcode: reader.readStringOrNull(offsets[0]),
    baseNutrition: reader.readObjectOrNull<FoodNutrition>(
      offsets[1],
      FoodNutritionSchema.deserialize,
      allOffsets,
    ),
    brand: reader.readStringOrNull(offsets[2]),
    computedNutrition: reader.readObjectOrNull<FoodNutrition>(
      offsets[3],
      FoodNutritionSchema.deserialize,
      allOffsets,
    ),
    consumedGrams: reader.readDoubleOrNull(offsets[4]),
    consumedMl: reader.readDoubleOrNull(offsets[5]),
    consumedServings: reader.readDoubleOrNull(offsets[6]),
    isPer100g: reader.readBoolOrNull(offsets[7]) ?? false,
    macrosKnown: reader.readBoolOrNull(offsets[8]),
    name: reader.readStringOrNull(offsets[9]),
    nutritionBasis: reader.readStringOrNull(offsets[10]),
    portion: reader.readStringOrNull(offsets[11]),
    provenance: reader.readStringOrNull(offsets[12]),
    resolved: reader.readBoolOrNull(offsets[13]) ?? true,
    servingGrams: reader.readDoubleOrNull(offsets[14]),
  );
  return object;
}

P _mealItemLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readObjectOrNull<FoodNutrition>(
        offset,
        FoodNutritionSchema.deserialize,
        allOffsets,
      )) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readObjectOrNull<FoodNutrition>(
        offset,
        FoodNutritionSchema.deserialize,
        allOffsets,
      )) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 8:
      return (reader.readBoolOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MealItemLogQueryFilter
    on QueryBuilder<MealItemLog, MealItemLog, QFilterCondition> {
  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      barcodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'barcode',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      barcodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'barcode',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> barcodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      barcodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> barcodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> barcodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'barcode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      barcodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> barcodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> barcodeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> barcodeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'barcode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      barcodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcode',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      barcodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'barcode',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      baseNutritionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'baseNutrition',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      baseNutritionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'baseNutrition',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> brandIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'brand',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      brandIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'brand',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> brandEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      brandGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> brandLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> brandBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'brand',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> brandStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> brandEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> brandContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> brandMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'brand',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> brandIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brand',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      brandIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'brand',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      computedNutritionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'computedNutrition',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      computedNutritionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'computedNutrition',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedGramsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'consumedGrams',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedGramsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'consumedGrams',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedGramsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consumedGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedGramsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'consumedGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedGramsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'consumedGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedGramsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'consumedGrams',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedMlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'consumedMl',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedMlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'consumedMl',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedMlEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consumedMl',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedMlGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'consumedMl',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedMlLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'consumedMl',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedMlBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'consumedMl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedServingsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'consumedServings',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedServingsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'consumedServings',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedServingsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consumedServings',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedServingsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'consumedServings',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedServingsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'consumedServings',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      consumedServingsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'consumedServings',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      isPer100gEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPer100g',
        value: value,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      macrosKnownIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'macrosKnown',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      macrosKnownIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'macrosKnown',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      macrosKnownEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'macrosKnown',
        value: value,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameContains(
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nutritionBasis',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nutritionBasis',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nutritionBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nutritionBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nutritionBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nutritionBasis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nutritionBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nutritionBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nutritionBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nutritionBasis',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nutritionBasis',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      nutritionBasisIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nutritionBasis',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      portionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'portion',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      portionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'portion',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> portionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'portion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      portionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'portion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> portionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'portion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> portionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'portion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      portionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'portion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> portionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'portion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> portionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'portion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> portionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'portion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      portionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'portion',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      portionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'portion',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      provenanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'provenance',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      provenanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'provenance',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      provenanceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'provenance',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      provenanceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'provenance',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      provenanceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provenance',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      provenanceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'provenance',
        value: '',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> resolvedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resolved',
        value: value,
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      servingGramsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'servingGrams',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      servingGramsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'servingGrams',
      ));
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
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

extension MealItemLogQueryObject
    on QueryBuilder<MealItemLog, MealItemLog, QFilterCondition> {
  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition> baseNutrition(
      FilterQuery<FoodNutrition> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'baseNutrition');
    });
  }

  QueryBuilder<MealItemLog, MealItemLog, QAfterFilterCondition>
      computedNutrition(FilterQuery<FoodNutrition> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'computedNutrition');
    });
  }
}
