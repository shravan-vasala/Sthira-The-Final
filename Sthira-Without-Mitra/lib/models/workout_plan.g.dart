// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_plan.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWorkoutPlanCollection on Isar {
  IsarCollection<WorkoutPlan> get workoutPlans => this.collection();
}

const WorkoutPlanSchema = CollectionSchema(
  name: r'WorkoutPlan',
  id: 313749700063086650,
  properties: {
    r'basedOnPlanName': PropertySchema(
      id: 0,
      name: r'basedOnPlanName',
      type: IsarType.string,
    ),
    r'days': PropertySchema(
      id: 1,
      name: r'days',
      type: IsarType.objectList,
      target: r'WorkoutDay',
    ),
    r'durationWeeks': PropertySchema(
      id: 2,
      name: r'durationWeeks',
      type: IsarType.long,
    ),
    r'planName': PropertySchema(
      id: 3,
      name: r'planName',
      type: IsarType.string,
    ),
    r'seedVersion': PropertySchema(
      id: 4,
      name: r'seedVersion',
      type: IsarType.long,
    ),
    r'source': PropertySchema(
      id: 5,
      name: r'source',
      type: IsarType.string,
    ),
    r'weeks': PropertySchema(
      id: 6,
      name: r'weeks',
      type: IsarType.objectList,
      target: r'WorkoutWeek',
    )
  },
  estimateSize: _workoutPlanEstimateSize,
  serialize: _workoutPlanSerialize,
  deserialize: _workoutPlanDeserialize,
  deserializeProp: _workoutPlanDeserializeProp,
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
  embeddedSchemas: {
    r'WorkoutWeek': WorkoutWeekSchema,
    r'WorkoutDay': WorkoutDaySchema,
    r'WorkoutSection': WorkoutSectionSchema,
    r'Exercise': ExerciseSchema
  },
  getId: _workoutPlanGetId,
  getLinks: _workoutPlanGetLinks,
  attach: _workoutPlanAttach,
  version: '3.1.0+1',
);

int _workoutPlanEstimateSize(
  WorkoutPlan object,
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
  bytesCount += 3 + object.days.length * 3;
  {
    final offsets = allOffsets[WorkoutDay]!;
    for (var i = 0; i < object.days.length; i++) {
      final value = object.days[i];
      bytesCount += WorkoutDaySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.planName.length * 3;
  bytesCount += 3 + object.source.length * 3;
  {
    final list = object.weeks;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[WorkoutWeek]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              WorkoutWeekSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  return bytesCount;
}

void _workoutPlanSerialize(
  WorkoutPlan object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.basedOnPlanName);
  writer.writeObjectList<WorkoutDay>(
    offsets[1],
    allOffsets,
    WorkoutDaySchema.serialize,
    object.days,
  );
  writer.writeLong(offsets[2], object.durationWeeks);
  writer.writeString(offsets[3], object.planName);
  writer.writeLong(offsets[4], object.seedVersion);
  writer.writeString(offsets[5], object.source);
  writer.writeObjectList<WorkoutWeek>(
    offsets[6],
    allOffsets,
    WorkoutWeekSchema.serialize,
    object.weeks,
  );
}

WorkoutPlan _workoutPlanDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkoutPlan(
    basedOnPlanName: reader.readStringOrNull(offsets[0]),
    days: reader.readObjectList<WorkoutDay>(
          offsets[1],
          WorkoutDaySchema.deserialize,
          allOffsets,
          WorkoutDay(),
        ) ??
        [],
    durationWeeks: reader.readLongOrNull(offsets[2]),
    planName: reader.readString(offsets[3]),
    seedVersion: reader.readLongOrNull(offsets[4]),
    source: reader.readStringOrNull(offsets[5]) ?? 'user',
    weeks: reader.readObjectList<WorkoutWeek>(
      offsets[6],
      WorkoutWeekSchema.deserialize,
      allOffsets,
      WorkoutWeek(),
    ),
  );
  object.id = id;
  return object;
}

P _workoutPlanDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readObjectList<WorkoutDay>(
            offset,
            WorkoutDaySchema.deserialize,
            allOffsets,
            WorkoutDay(),
          ) ??
          []) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset) ?? 'user') as P;
    case 6:
      return (reader.readObjectList<WorkoutWeek>(
        offset,
        WorkoutWeekSchema.deserialize,
        allOffsets,
        WorkoutWeek(),
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _workoutPlanGetId(WorkoutPlan object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _workoutPlanGetLinks(WorkoutPlan object) {
  return [];
}

void _workoutPlanAttach(
    IsarCollection<dynamic> col, Id id, WorkoutPlan object) {
  object.id = id;
}

extension WorkoutPlanByIndex on IsarCollection<WorkoutPlan> {
  Future<WorkoutPlan?> getByPlanName(String planName) {
    return getByIndex(r'planName', [planName]);
  }

  WorkoutPlan? getByPlanNameSync(String planName) {
    return getByIndexSync(r'planName', [planName]);
  }

  Future<bool> deleteByPlanName(String planName) {
    return deleteByIndex(r'planName', [planName]);
  }

  bool deleteByPlanNameSync(String planName) {
    return deleteByIndexSync(r'planName', [planName]);
  }

  Future<List<WorkoutPlan?>> getAllByPlanName(List<String> planNameValues) {
    final values = planNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'planName', values);
  }

  List<WorkoutPlan?> getAllByPlanNameSync(List<String> planNameValues) {
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

  Future<Id> putByPlanName(WorkoutPlan object) {
    return putByIndex(r'planName', object);
  }

  Id putByPlanNameSync(WorkoutPlan object, {bool saveLinks = true}) {
    return putByIndexSync(r'planName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPlanName(List<WorkoutPlan> objects) {
    return putAllByIndex(r'planName', objects);
  }

  List<Id> putAllByPlanNameSync(List<WorkoutPlan> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'planName', objects, saveLinks: saveLinks);
  }
}

extension WorkoutPlanQueryWhereSort
    on QueryBuilder<WorkoutPlan, WorkoutPlan, QWhere> {
  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WorkoutPlanQueryWhere
    on QueryBuilder<WorkoutPlan, WorkoutPlan, QWhereClause> {
  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterWhereClause> idBetween(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterWhereClause> planNameEqualTo(
      String planName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'planName',
        value: [planName],
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterWhereClause> planNameNotEqualTo(
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

extension WorkoutPlanQueryFilter
    on QueryBuilder<WorkoutPlan, WorkoutPlan, QFilterCondition> {
  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      basedOnPlanNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'basedOnPlanName',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      basedOnPlanNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'basedOnPlanName',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      basedOnPlanNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'basedOnPlanName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      basedOnPlanNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'basedOnPlanName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      basedOnPlanNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'basedOnPlanName',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      basedOnPlanNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'basedOnPlanName',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      daysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> daysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      daysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      daysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      daysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      daysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      durationWeeksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationWeeks',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      durationWeeksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationWeeks',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      durationWeeksEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationWeeks',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      durationWeeksGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationWeeks',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      durationWeeksLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationWeeks',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      durationWeeksBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationWeeks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> idBetween(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> planNameEqualTo(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      planNameGreaterThan(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      planNameLessThan(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> planNameBetween(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      planNameStartsWith(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      planNameEndsWith(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      planNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> planNameMatches(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      planNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planName',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      planNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'planName',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      seedVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'seedVersion',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      seedVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'seedVersion',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      seedVersionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seedVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      seedVersionLessThan(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      seedVersionBetween(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> sourceEqualTo(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      sourceGreaterThan(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> sourceLessThan(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> sourceBetween(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      sourceStartsWith(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> sourceEndsWith(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> sourceContains(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> sourceMatches(
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

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> weeksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weeks',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      weeksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weeks',
      ));
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      weeksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> weeksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      weeksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      weeksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      weeksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition>
      weeksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension WorkoutPlanQueryObject
    on QueryBuilder<WorkoutPlan, WorkoutPlan, QFilterCondition> {
  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> daysElement(
      FilterQuery<WorkoutDay> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'days');
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterFilterCondition> weeksElement(
      FilterQuery<WorkoutWeek> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'weeks');
    });
  }
}

extension WorkoutPlanQueryLinks
    on QueryBuilder<WorkoutPlan, WorkoutPlan, QFilterCondition> {}

extension WorkoutPlanQuerySortBy
    on QueryBuilder<WorkoutPlan, WorkoutPlan, QSortBy> {
  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> sortByBasedOnPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basedOnPlanName', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy>
      sortByBasedOnPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basedOnPlanName', Sort.desc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> sortByDurationWeeks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationWeeks', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy>
      sortByDurationWeeksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationWeeks', Sort.desc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> sortByPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> sortByPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.desc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> sortBySeedVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedVersion', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> sortBySeedVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedVersion', Sort.desc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }
}

extension WorkoutPlanQuerySortThenBy
    on QueryBuilder<WorkoutPlan, WorkoutPlan, QSortThenBy> {
  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenByBasedOnPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basedOnPlanName', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy>
      thenByBasedOnPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basedOnPlanName', Sort.desc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenByDurationWeeks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationWeeks', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy>
      thenByDurationWeeksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationWeeks', Sort.desc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenByPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenByPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.desc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenBySeedVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedVersion', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenBySeedVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedVersion', Sort.desc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }
}

extension WorkoutPlanQueryWhereDistinct
    on QueryBuilder<WorkoutPlan, WorkoutPlan, QDistinct> {
  QueryBuilder<WorkoutPlan, WorkoutPlan, QDistinct> distinctByBasedOnPlanName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'basedOnPlanName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QDistinct> distinctByDurationWeeks() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationWeeks');
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QDistinct> distinctByPlanName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'planName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QDistinct> distinctBySeedVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seedVersion');
    });
  }

  QueryBuilder<WorkoutPlan, WorkoutPlan, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }
}

extension WorkoutPlanQueryProperty
    on QueryBuilder<WorkoutPlan, WorkoutPlan, QQueryProperty> {
  QueryBuilder<WorkoutPlan, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WorkoutPlan, String?, QQueryOperations>
      basedOnPlanNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'basedOnPlanName');
    });
  }

  QueryBuilder<WorkoutPlan, List<WorkoutDay>, QQueryOperations> daysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'days');
    });
  }

  QueryBuilder<WorkoutPlan, int?, QQueryOperations> durationWeeksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationWeeks');
    });
  }

  QueryBuilder<WorkoutPlan, String, QQueryOperations> planNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'planName');
    });
  }

  QueryBuilder<WorkoutPlan, int?, QQueryOperations> seedVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seedVersion');
    });
  }

  QueryBuilder<WorkoutPlan, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<WorkoutPlan, List<WorkoutWeek>?, QQueryOperations>
      weeksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weeks');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const WorkoutWeekSchema = Schema(
  name: r'WorkoutWeek',
  id: 4728696235322809906,
  properties: {
    r'days': PropertySchema(
      id: 0,
      name: r'days',
      type: IsarType.objectList,
      target: r'WorkoutDay',
    ),
    r'weekNumber': PropertySchema(
      id: 1,
      name: r'weekNumber',
      type: IsarType.long,
    )
  },
  estimateSize: _workoutWeekEstimateSize,
  serialize: _workoutWeekSerialize,
  deserialize: _workoutWeekDeserialize,
  deserializeProp: _workoutWeekDeserializeProp,
);

int _workoutWeekEstimateSize(
  WorkoutWeek object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.days.length * 3;
  {
    final offsets = allOffsets[WorkoutDay]!;
    for (var i = 0; i < object.days.length; i++) {
      final value = object.days[i];
      bytesCount += WorkoutDaySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _workoutWeekSerialize(
  WorkoutWeek object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<WorkoutDay>(
    offsets[0],
    allOffsets,
    WorkoutDaySchema.serialize,
    object.days,
  );
  writer.writeLong(offsets[1], object.weekNumber);
}

WorkoutWeek _workoutWeekDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkoutWeek(
    days: reader.readObjectList<WorkoutDay>(
          offsets[0],
          WorkoutDaySchema.deserialize,
          allOffsets,
          WorkoutDay(),
        ) ??
        const [],
    weekNumber: reader.readLongOrNull(offsets[1]),
  );
  return object;
}

P _workoutWeekDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<WorkoutDay>(
            offset,
            WorkoutDaySchema.deserialize,
            allOffsets,
            WorkoutDay(),
          ) ??
          const []) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension WorkoutWeekQueryFilter
    on QueryBuilder<WorkoutWeek, WorkoutWeek, QFilterCondition> {
  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      daysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition> daysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      daysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      daysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      daysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      daysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'days',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      weekNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weekNumber',
      ));
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      weekNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weekNumber',
      ));
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      weekNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      weekNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weekNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      weekNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weekNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition>
      weekNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weekNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WorkoutWeekQueryObject
    on QueryBuilder<WorkoutWeek, WorkoutWeek, QFilterCondition> {
  QueryBuilder<WorkoutWeek, WorkoutWeek, QAfterFilterCondition> daysElement(
      FilterQuery<WorkoutDay> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'days');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const WorkoutDaySchema = Schema(
  name: r'WorkoutDay',
  id: -473137167238769109,
  properties: {
    r'dayId': PropertySchema(
      id: 0,
      name: r'dayId',
      type: IsarType.string,
    ),
    r'label': PropertySchema(
      id: 1,
      name: r'label',
      type: IsarType.string,
    ),
    r'sections': PropertySchema(
      id: 2,
      name: r'sections',
      type: IsarType.objectList,
      target: r'WorkoutSection',
    ),
    r'weekday': PropertySchema(
      id: 3,
      name: r'weekday',
      type: IsarType.long,
    )
  },
  estimateSize: _workoutDayEstimateSize,
  serialize: _workoutDaySerialize,
  deserialize: _workoutDayDeserialize,
  deserializeProp: _workoutDayDeserializeProp,
);

int _workoutDayEstimateSize(
  WorkoutDay object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.dayId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.label;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sections.length * 3;
  {
    final offsets = allOffsets[WorkoutSection]!;
    for (var i = 0; i < object.sections.length; i++) {
      final value = object.sections[i];
      bytesCount +=
          WorkoutSectionSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _workoutDaySerialize(
  WorkoutDay object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dayId);
  writer.writeString(offsets[1], object.label);
  writer.writeObjectList<WorkoutSection>(
    offsets[2],
    allOffsets,
    WorkoutSectionSchema.serialize,
    object.sections,
  );
  writer.writeLong(offsets[3], object.weekday);
}

WorkoutDay _workoutDayDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkoutDay(
    dayId: reader.readStringOrNull(offsets[0]),
    label: reader.readStringOrNull(offsets[1]),
    sections: reader.readObjectList<WorkoutSection>(
          offsets[2],
          WorkoutSectionSchema.deserialize,
          allOffsets,
          WorkoutSection(),
        ) ??
        const [],
  );
  return object;
}

P _workoutDayDeserializeProp<P>(
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
      return (reader.readObjectList<WorkoutSection>(
            offset,
            WorkoutSectionSchema.deserialize,
            allOffsets,
            WorkoutSection(),
          ) ??
          const []) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension WorkoutDayQueryFilter
    on QueryBuilder<WorkoutDay, WorkoutDay, QFilterCondition> {
  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dayId',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dayId',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dayId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> dayIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayId',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      dayIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dayId',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'label',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'label',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      sectionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sections',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      sectionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sections',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      sectionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sections',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      sectionsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sections',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      sectionsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sections',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      sectionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sections',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> weekdayIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weekday',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      weekdayIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weekday',
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> weekdayEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekday',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition>
      weekdayGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weekday',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> weekdayLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weekday',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> weekdayBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weekday',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WorkoutDayQueryObject
    on QueryBuilder<WorkoutDay, WorkoutDay, QFilterCondition> {
  QueryBuilder<WorkoutDay, WorkoutDay, QAfterFilterCondition> sectionsElement(
      FilterQuery<WorkoutSection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'sections');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const WorkoutSectionSchema = Schema(
  name: r'WorkoutSection',
  id: 5516242351705836075,
  properties: {
    r'exercises': PropertySchema(
      id: 0,
      name: r'exercises',
      type: IsarType.objectList,
      target: r'Exercise',
    ),
    r'title': PropertySchema(
      id: 1,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _workoutSectionEstimateSize,
  serialize: _workoutSectionSerialize,
  deserialize: _workoutSectionDeserialize,
  deserializeProp: _workoutSectionDeserializeProp,
);

int _workoutSectionEstimateSize(
  WorkoutSection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exercises.length * 3;
  {
    final offsets = allOffsets[Exercise]!;
    for (var i = 0; i < object.exercises.length; i++) {
      final value = object.exercises[i];
      bytesCount += ExerciseSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _workoutSectionSerialize(
  WorkoutSection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<Exercise>(
    offsets[0],
    allOffsets,
    ExerciseSchema.serialize,
    object.exercises,
  );
  writer.writeString(offsets[1], object.title);
}

WorkoutSection _workoutSectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkoutSection(
    exercises: reader.readObjectList<Exercise>(
          offsets[0],
          ExerciseSchema.deserialize,
          allOffsets,
          Exercise(),
        ) ??
        const [],
    title: reader.readStringOrNull(offsets[1]),
  );
  return object;
}

P _workoutSectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<Exercise>(
            offset,
            ExerciseSchema.deserialize,
            allOffsets,
            Exercise(),
          ) ??
          const []) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension WorkoutSectionQueryFilter
    on QueryBuilder<WorkoutSection, WorkoutSection, QFilterCondition> {
  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      exercisesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      exercisesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      exercisesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      exercisesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      exercisesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      exercisesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension WorkoutSectionQueryObject
    on QueryBuilder<WorkoutSection, WorkoutSection, QFilterCondition> {
  QueryBuilder<WorkoutSection, WorkoutSection, QAfterFilterCondition>
      exercisesElement(FilterQuery<Exercise> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'exercises');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ExerciseSchema = Schema(
  name: r'Exercise',
  id: 2972066467915231902,
  properties: {
    r'displayName': PropertySchema(
      id: 0,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'durationSeconds': PropertySchema(
      id: 1,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'instanceId': PropertySchema(
      id: 2,
      name: r'instanceId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'note': PropertySchema(
      id: 4,
      name: r'note',
      type: IsarType.string,
    ),
    r'reps': PropertySchema(
      id: 5,
      name: r'reps',
      type: IsarType.stringList,
    ),
    r'repsDisplay': PropertySchema(
      id: 6,
      name: r'repsDisplay',
      type: IsarType.string,
    ),
    r'restSecondsAfterSet': PropertySchema(
      id: 7,
      name: r'restSecondsAfterSet',
      type: IsarType.long,
    ),
    r'setCount': PropertySchema(
      id: 8,
      name: r'setCount',
      type: IsarType.long,
    ),
    r'sideInfo': PropertySchema(
      id: 9,
      name: r'sideInfo',
      type: IsarType.string,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 10,
      name: r'thumbnailUrl',
      type: IsarType.string,
    ),
    r'weightKg': PropertySchema(
      id: 11,
      name: r'weightKg',
      type: IsarType.double,
    ),
    r'youtubeUrl': PropertySchema(
      id: 12,
      name: r'youtubeUrl',
      type: IsarType.string,
    ),
    r'youtubeVideoId': PropertySchema(
      id: 13,
      name: r'youtubeVideoId',
      type: IsarType.string,
    )
  },
  estimateSize: _exerciseEstimateSize,
  serialize: _exerciseSerialize,
  deserialize: _exerciseDeserialize,
  deserializeProp: _exerciseDeserializeProp,
);

int _exerciseEstimateSize(
  Exercise object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.displayName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.instanceId;
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
  bytesCount += 3 + object.note.length * 3;
  bytesCount += 3 + object.reps.length * 3;
  {
    for (var i = 0; i < object.reps.length; i++) {
      final value = object.reps[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.repsDisplay.length * 3;
  bytesCount += 3 + object.sideInfo.length * 3;
  bytesCount += 3 + object.thumbnailUrl.length * 3;
  {
    final value = object.youtubeUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.youtubeVideoId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _exerciseSerialize(
  Exercise object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.displayName);
  writer.writeLong(offsets[1], object.durationSeconds);
  writer.writeString(offsets[2], object.instanceId);
  writer.writeString(offsets[3], object.name);
  writer.writeString(offsets[4], object.note);
  writer.writeStringList(offsets[5], object.reps);
  writer.writeString(offsets[6], object.repsDisplay);
  writer.writeLong(offsets[7], object.restSecondsAfterSet);
  writer.writeLong(offsets[8], object.setCount);
  writer.writeString(offsets[9], object.sideInfo);
  writer.writeString(offsets[10], object.thumbnailUrl);
  writer.writeDouble(offsets[11], object.weightKg);
  writer.writeString(offsets[12], object.youtubeUrl);
  writer.writeString(offsets[13], object.youtubeVideoId);
}

Exercise _exerciseDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Exercise(
    displayName: reader.readStringOrNull(offsets[0]),
    durationSeconds: reader.readLongOrNull(offsets[1]),
    name: reader.readStringOrNull(offsets[3]),
    note: reader.readStringOrNull(offsets[4]) ?? '',
    reps: reader.readStringList(offsets[5]) ?? const [],
    restSecondsAfterSet: reader.readLongOrNull(offsets[7]) ?? 0,
    sideInfo: reader.readStringOrNull(offsets[9]) ?? 'None',
    weightKg: reader.readDoubleOrNull(offsets[11]),
    youtubeUrl: reader.readStringOrNull(offsets[12]),
  );
  object.instanceId = reader.readStringOrNull(offsets[2]);
  return object;
}

P _exerciseDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 5:
      return (reader.readStringList(offset) ?? const []) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset) ?? 'None') as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ExerciseQueryFilter
    on QueryBuilder<Exercise, Exercise, QFilterCondition> {
  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> displayNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'displayName',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      displayNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'displayName',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> displayNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      displayNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> displayNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> displayNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> displayNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> displayNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      durationSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationSeconds',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      durationSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationSeconds',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      durationSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      durationSecondsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      durationSecondsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      durationSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'instanceId',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      instanceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'instanceId',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'instanceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'instanceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'instanceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'instanceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'instanceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'instanceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'instanceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'instanceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> instanceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'instanceId',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      instanceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'instanceId',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameContains(
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

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      repsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reps',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reps',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      repsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reps',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reps',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reps',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reps',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reps',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reps',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reps',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsDisplayEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repsDisplay',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      repsDisplayGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repsDisplay',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsDisplayLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repsDisplay',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsDisplayBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repsDisplay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsDisplayStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'repsDisplay',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsDisplayEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'repsDisplay',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsDisplayContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'repsDisplay',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsDisplayMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'repsDisplay',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> repsDisplayIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repsDisplay',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      repsDisplayIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'repsDisplay',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      restSecondsAfterSetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restSecondsAfterSet',
        value: value,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      restSecondsAfterSetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'restSecondsAfterSet',
        value: value,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      restSecondsAfterSetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'restSecondsAfterSet',
        value: value,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      restSecondsAfterSetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'restSecondsAfterSet',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> setCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'setCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> setCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'setCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> setCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'setCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> setCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'setCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sideInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sideInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sideInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sideInfo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sideInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sideInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sideInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sideInfo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sideInfo',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> sideInfoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sideInfo',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> thumbnailUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      thumbnailUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> thumbnailUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> thumbnailUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thumbnailUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      thumbnailUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> thumbnailUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> thumbnailUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> thumbnailUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> weightKgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weightKg',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> weightKgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weightKg',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> weightKgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> weightKgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> weightKgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> weightKgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weightKg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'youtubeUrl',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'youtubeUrl',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'youtubeUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'youtubeUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'youtubeUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'youtubeUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'youtubeUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'youtubeUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'youtubeUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'youtubeUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'youtubeUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'youtubeUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeVideoIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'youtubeVideoId',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeVideoIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'youtubeVideoId',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeVideoIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'youtubeVideoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeVideoIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'youtubeVideoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeVideoIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'youtubeVideoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeVideoIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'youtubeVideoId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeVideoIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'youtubeVideoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeVideoIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'youtubeVideoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeVideoIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'youtubeVideoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition> youtubeVideoIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'youtubeVideoId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeVideoIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'youtubeVideoId',
        value: '',
      ));
    });
  }

  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      youtubeVideoIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'youtubeVideoId',
        value: '',
      ));
    });
  }
}

extension ExerciseQueryObject
    on QueryBuilder<Exercise, Exercise, QFilterCondition> {}
