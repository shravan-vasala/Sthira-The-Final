// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_pr.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetExercisePrCollection on Isar {
  IsarCollection<ExercisePr> get exercisePrs => this.collection();
}

const ExercisePrSchema = CollectionSchema(
  name: r'ExercisePr',
  id: 2738814868750311113,
  properties: {
    r'estimated1RM': PropertySchema(
      id: 0,
      name: r'estimated1RM',
      type: IsarType.double,
    ),
    r'exerciseName': PropertySchema(
      id: 1,
      name: r'exerciseName',
      type: IsarType.string,
    ),
    r'maxReps': PropertySchema(
      id: 2,
      name: r'maxReps',
      type: IsarType.long,
    ),
    r'maxRepsWeight': PropertySchema(
      id: 3,
      name: r'maxRepsWeight',
      type: IsarType.double,
    ),
    r'maxVolume': PropertySchema(
      id: 4,
      name: r'maxVolume',
      type: IsarType.double,
    ),
    r'maxWeight': PropertySchema(
      id: 5,
      name: r'maxWeight',
      type: IsarType.double,
    ),
    r'maxWeightReps': PropertySchema(
      id: 6,
      name: r'maxWeightReps',
      type: IsarType.long,
    )
  },
  estimateSize: _exercisePrEstimateSize,
  serialize: _exercisePrSerialize,
  deserialize: _exercisePrDeserialize,
  deserializeProp: _exercisePrDeserializeProp,
  idName: r'id',
  indexes: {
    r'exerciseName': IndexSchema(
      id: 4205715828964724693,
      name: r'exerciseName',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'exerciseName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _exercisePrGetId,
  getLinks: _exercisePrGetLinks,
  attach: _exercisePrAttach,
  version: '3.1.0+1',
);

int _exercisePrEstimateSize(
  ExercisePr object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exerciseName.length * 3;
  return bytesCount;
}

void _exercisePrSerialize(
  ExercisePr object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.estimated1RM);
  writer.writeString(offsets[1], object.exerciseName);
  writer.writeLong(offsets[2], object.maxReps);
  writer.writeDouble(offsets[3], object.maxRepsWeight);
  writer.writeDouble(offsets[4], object.maxVolume);
  writer.writeDouble(offsets[5], object.maxWeight);
  writer.writeLong(offsets[6], object.maxWeightReps);
}

ExercisePr _exercisePrDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExercisePr(
    estimated1RM: reader.readDoubleOrNull(offsets[0]) ?? 0.0,
    exerciseName: reader.readString(offsets[1]),
    maxReps: reader.readLongOrNull(offsets[2]) ?? 0,
    maxRepsWeight: reader.readDoubleOrNull(offsets[3]) ?? 0.0,
    maxVolume: reader.readDoubleOrNull(offsets[4]) ?? 0.0,
    maxWeight: reader.readDoubleOrNull(offsets[5]) ?? 0.0,
    maxWeightReps: reader.readLongOrNull(offsets[6]) ?? 0,
  );
  object.id = id;
  return object;
}

P _exercisePrDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 3:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 4:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 5:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 6:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _exercisePrGetId(ExercisePr object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _exercisePrGetLinks(ExercisePr object) {
  return [];
}

void _exercisePrAttach(IsarCollection<dynamic> col, Id id, ExercisePr object) {
  object.id = id;
}

extension ExercisePrByIndex on IsarCollection<ExercisePr> {
  Future<ExercisePr?> getByExerciseName(String exerciseName) {
    return getByIndex(r'exerciseName', [exerciseName]);
  }

  ExercisePr? getByExerciseNameSync(String exerciseName) {
    return getByIndexSync(r'exerciseName', [exerciseName]);
  }

  Future<bool> deleteByExerciseName(String exerciseName) {
    return deleteByIndex(r'exerciseName', [exerciseName]);
  }

  bool deleteByExerciseNameSync(String exerciseName) {
    return deleteByIndexSync(r'exerciseName', [exerciseName]);
  }

  Future<List<ExercisePr?>> getAllByExerciseName(
      List<String> exerciseNameValues) {
    final values = exerciseNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'exerciseName', values);
  }

  List<ExercisePr?> getAllByExerciseNameSync(List<String> exerciseNameValues) {
    final values = exerciseNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'exerciseName', values);
  }

  Future<int> deleteAllByExerciseName(List<String> exerciseNameValues) {
    final values = exerciseNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'exerciseName', values);
  }

  int deleteAllByExerciseNameSync(List<String> exerciseNameValues) {
    final values = exerciseNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'exerciseName', values);
  }

  Future<Id> putByExerciseName(ExercisePr object) {
    return putByIndex(r'exerciseName', object);
  }

  Id putByExerciseNameSync(ExercisePr object, {bool saveLinks = true}) {
    return putByIndexSync(r'exerciseName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByExerciseName(List<ExercisePr> objects) {
    return putAllByIndex(r'exerciseName', objects);
  }

  List<Id> putAllByExerciseNameSync(List<ExercisePr> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'exerciseName', objects, saveLinks: saveLinks);
  }
}

extension ExercisePrQueryWhereSort
    on QueryBuilder<ExercisePr, ExercisePr, QWhere> {
  QueryBuilder<ExercisePr, ExercisePr, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ExercisePrQueryWhere
    on QueryBuilder<ExercisePr, ExercisePr, QWhereClause> {
  QueryBuilder<ExercisePr, ExercisePr, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<ExercisePr, ExercisePr, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterWhereClause> idBetween(
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

  QueryBuilder<ExercisePr, ExercisePr, QAfterWhereClause> exerciseNameEqualTo(
      String exerciseName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'exerciseName',
        value: [exerciseName],
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterWhereClause>
      exerciseNameNotEqualTo(String exerciseName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseName',
              lower: [],
              upper: [exerciseName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseName',
              lower: [exerciseName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseName',
              lower: [exerciseName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseName',
              lower: [],
              upper: [exerciseName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ExercisePrQueryFilter
    on QueryBuilder<ExercisePr, ExercisePr, QFilterCondition> {
  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      estimated1RMEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estimated1RM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      estimated1RMGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estimated1RM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      estimated1RMLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estimated1RM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      estimated1RMBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estimated1RM',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exerciseName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      exerciseNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> maxRepsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxReps',
        value: value,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxRepsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxReps',
        value: value,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> maxRepsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxReps',
        value: value,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> maxRepsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxReps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxRepsWeightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxRepsWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxRepsWeightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxRepsWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxRepsWeightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxRepsWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxRepsWeightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxRepsWeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> maxVolumeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxVolumeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> maxVolumeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> maxVolumeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxVolume',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> maxWeightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxWeightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> maxWeightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition> maxWeightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxWeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxWeightRepsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxWeightReps',
        value: value,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxWeightRepsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxWeightReps',
        value: value,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxWeightRepsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxWeightReps',
        value: value,
      ));
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterFilterCondition>
      maxWeightRepsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxWeightReps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ExercisePrQueryObject
    on QueryBuilder<ExercisePr, ExercisePr, QFilterCondition> {}

extension ExercisePrQueryLinks
    on QueryBuilder<ExercisePr, ExercisePr, QFilterCondition> {}

extension ExercisePrQuerySortBy
    on QueryBuilder<ExercisePr, ExercisePr, QSortBy> {
  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByEstimated1RM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimated1RM', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByEstimated1RMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimated1RM', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByExerciseName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByExerciseNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxReps', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxReps', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxRepsWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxRepsWeight', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxRepsWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxRepsWeight', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxVolume', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxVolume', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeight', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeight', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxWeightReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeightReps', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> sortByMaxWeightRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeightReps', Sort.desc);
    });
  }
}

extension ExercisePrQuerySortThenBy
    on QueryBuilder<ExercisePr, ExercisePr, QSortThenBy> {
  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByEstimated1RM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimated1RM', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByEstimated1RMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimated1RM', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByExerciseName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByExerciseNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxReps', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxReps', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxRepsWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxRepsWeight', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxRepsWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxRepsWeight', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxVolume', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxVolume', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeight', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeight', Sort.desc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxWeightReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeightReps', Sort.asc);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QAfterSortBy> thenByMaxWeightRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeightReps', Sort.desc);
    });
  }
}

extension ExercisePrQueryWhereDistinct
    on QueryBuilder<ExercisePr, ExercisePr, QDistinct> {
  QueryBuilder<ExercisePr, ExercisePr, QDistinct> distinctByEstimated1RM() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estimated1RM');
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QDistinct> distinctByExerciseName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exerciseName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QDistinct> distinctByMaxReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxReps');
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QDistinct> distinctByMaxRepsWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxRepsWeight');
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QDistinct> distinctByMaxVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxVolume');
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QDistinct> distinctByMaxWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxWeight');
    });
  }

  QueryBuilder<ExercisePr, ExercisePr, QDistinct> distinctByMaxWeightReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxWeightReps');
    });
  }
}

extension ExercisePrQueryProperty
    on QueryBuilder<ExercisePr, ExercisePr, QQueryProperty> {
  QueryBuilder<ExercisePr, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ExercisePr, double, QQueryOperations> estimated1RMProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estimated1RM');
    });
  }

  QueryBuilder<ExercisePr, String, QQueryOperations> exerciseNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exerciseName');
    });
  }

  QueryBuilder<ExercisePr, int, QQueryOperations> maxRepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxReps');
    });
  }

  QueryBuilder<ExercisePr, double, QQueryOperations> maxRepsWeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxRepsWeight');
    });
  }

  QueryBuilder<ExercisePr, double, QQueryOperations> maxVolumeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxVolume');
    });
  }

  QueryBuilder<ExercisePr, double, QQueryOperations> maxWeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxWeight');
    });
  }

  QueryBuilder<ExercisePr, int, QQueryOperations> maxWeightRepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxWeightReps');
    });
  }
}
