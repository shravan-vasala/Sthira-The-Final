// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetExerciseLogCollection on Isar {
  IsarCollection<ExerciseLog> get exerciseLogs => this.collection();
}

const ExerciseLogSchema = CollectionSchema(
  name: r'ExerciseLog',
  id: 6307021889001100190,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.string,
    ),
    r'exerciseName': PropertySchema(
      id: 1,
      name: r'exerciseName',
      type: IsarType.string,
    ),
    r'instanceId': PropertySchema(
      id: 2,
      name: r'instanceId',
      type: IsarType.string,
    ),
    r'key': PropertySchema(
      id: 3,
      name: r'key',
      type: IsarType.string,
    ),
    r'maxWeight': PropertySchema(
      id: 4,
      name: r'maxWeight',
      type: IsarType.double,
    ),
    r'sets': PropertySchema(
      id: 5,
      name: r'sets',
      type: IsarType.objectList,
      target: r'SetLog',
    ),
    r'totalReps': PropertySchema(
      id: 6,
      name: r'totalReps',
      type: IsarType.long,
    ),
    r'totalVolume': PropertySchema(
      id: 7,
      name: r'totalVolume',
      type: IsarType.double,
    )
  },
  estimateSize: _exerciseLogEstimateSize,
  serialize: _exerciseLogSerialize,
  deserialize: _exerciseLogDeserialize,
  deserializeProp: _exerciseLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'date_instanceId': IndexSchema(
      id: -3163923839009351063,
      name: r'date_instanceId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'instanceId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'SetLog': SetLogSchema},
  getId: _exerciseLogGetId,
  getLinks: _exerciseLogGetLinks,
  attach: _exerciseLogAttach,
  version: '3.1.0+1',
);

int _exerciseLogEstimateSize(
  ExerciseLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.date.length * 3;
  bytesCount += 3 + object.exerciseName.length * 3;
  bytesCount += 3 + object.instanceId.length * 3;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.sets.length * 3;
  {
    final offsets = allOffsets[SetLog]!;
    for (var i = 0; i < object.sets.length; i++) {
      final value = object.sets[i];
      bytesCount += SetLogSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _exerciseLogSerialize(
  ExerciseLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.date);
  writer.writeString(offsets[1], object.exerciseName);
  writer.writeString(offsets[2], object.instanceId);
  writer.writeString(offsets[3], object.key);
  writer.writeDouble(offsets[4], object.maxWeight);
  writer.writeObjectList<SetLog>(
    offsets[5],
    allOffsets,
    SetLogSchema.serialize,
    object.sets,
  );
  writer.writeLong(offsets[6], object.totalReps);
  writer.writeDouble(offsets[7], object.totalVolume);
}

ExerciseLog _exerciseLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExerciseLog(
    date: reader.readString(offsets[0]),
    exerciseName: reader.readString(offsets[1]),
    instanceId: reader.readString(offsets[2]),
    sets: reader.readObjectList<SetLog>(
          offsets[5],
          SetLogSchema.deserialize,
          allOffsets,
          SetLog(),
        ) ??
        [],
  );
  object.id = id;
  return object;
}

P _exerciseLogDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readObjectList<SetLog>(
            offset,
            SetLogSchema.deserialize,
            allOffsets,
            SetLog(),
          ) ??
          []) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _exerciseLogGetId(ExerciseLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _exerciseLogGetLinks(ExerciseLog object) {
  return [];
}

void _exerciseLogAttach(
    IsarCollection<dynamic> col, Id id, ExerciseLog object) {
  object.id = id;
}

extension ExerciseLogByIndex on IsarCollection<ExerciseLog> {
  Future<ExerciseLog?> getByDateInstanceId(String date, String instanceId) {
    return getByIndex(r'date_instanceId', [date, instanceId]);
  }

  ExerciseLog? getByDateInstanceIdSync(String date, String instanceId) {
    return getByIndexSync(r'date_instanceId', [date, instanceId]);
  }

  Future<bool> deleteByDateInstanceId(String date, String instanceId) {
    return deleteByIndex(r'date_instanceId', [date, instanceId]);
  }

  bool deleteByDateInstanceIdSync(String date, String instanceId) {
    return deleteByIndexSync(r'date_instanceId', [date, instanceId]);
  }

  Future<List<ExerciseLog?>> getAllByDateInstanceId(
      List<String> dateValues, List<String> instanceIdValues) {
    final len = dateValues.length;
    assert(instanceIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([dateValues[i], instanceIdValues[i]]);
    }

    return getAllByIndex(r'date_instanceId', values);
  }

  List<ExerciseLog?> getAllByDateInstanceIdSync(
      List<String> dateValues, List<String> instanceIdValues) {
    final len = dateValues.length;
    assert(instanceIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([dateValues[i], instanceIdValues[i]]);
    }

    return getAllByIndexSync(r'date_instanceId', values);
  }

  Future<int> deleteAllByDateInstanceId(
      List<String> dateValues, List<String> instanceIdValues) {
    final len = dateValues.length;
    assert(instanceIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([dateValues[i], instanceIdValues[i]]);
    }

    return deleteAllByIndex(r'date_instanceId', values);
  }

  int deleteAllByDateInstanceIdSync(
      List<String> dateValues, List<String> instanceIdValues) {
    final len = dateValues.length;
    assert(instanceIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([dateValues[i], instanceIdValues[i]]);
    }

    return deleteAllByIndexSync(r'date_instanceId', values);
  }

  Future<Id> putByDateInstanceId(ExerciseLog object) {
    return putByIndex(r'date_instanceId', object);
  }

  Id putByDateInstanceIdSync(ExerciseLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'date_instanceId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateInstanceId(List<ExerciseLog> objects) {
    return putAllByIndex(r'date_instanceId', objects);
  }

  List<Id> putAllByDateInstanceIdSync(List<ExerciseLog> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date_instanceId', objects, saveLinks: saveLinks);
  }
}

extension ExerciseLogQueryWhereSort
    on QueryBuilder<ExerciseLog, ExerciseLog, QWhere> {
  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ExerciseLogQueryWhere
    on QueryBuilder<ExerciseLog, ExerciseLog, QWhereClause> {
  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhereClause>
      dateEqualToAnyInstanceId(String date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date_instanceId',
        value: [date],
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhereClause>
      dateNotEqualToAnyInstanceId(String date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date_instanceId',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date_instanceId',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date_instanceId',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date_instanceId',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhereClause>
      dateInstanceIdEqualTo(String date, String instanceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date_instanceId',
        value: [date, instanceId],
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterWhereClause>
      dateEqualToInstanceIdNotEqualTo(String date, String instanceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date_instanceId',
              lower: [date],
              upper: [date, instanceId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date_instanceId',
              lower: [date, instanceId],
              includeLower: false,
              upper: [date],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date_instanceId',
              lower: [date, instanceId],
              includeLower: false,
              upper: [date],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date_instanceId',
              lower: [date],
              upper: [date, instanceId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ExerciseLogQueryFilter
    on QueryBuilder<ExerciseLog, ExerciseLog, QFilterCondition> {
  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> dateEqualTo(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> dateGreaterThan(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> dateLessThan(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> dateBetween(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> dateStartsWith(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> dateEndsWith(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> dateContains(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> dateMatches(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      exerciseNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      exerciseNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      exerciseNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      exerciseNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdEqualTo(
    String value, {
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdGreaterThan(
    String value, {
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdLessThan(
    String value, {
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdStartsWith(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdEndsWith(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'instanceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'instanceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'instanceId',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      instanceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'instanceId',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> keyEqualTo(
    String value, {
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> keyGreaterThan(
    String value, {
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> keyLessThan(
    String value, {
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> keyStartsWith(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> keyEndsWith(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> keyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> keyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      maxWeightEqualTo(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      maxWeightLessThan(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      maxWeightBetween(
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

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      setsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sets',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> setsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sets',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      setsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sets',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      setsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sets',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      setsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sets',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      setsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sets',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      totalRepsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalReps',
        value: value,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      totalRepsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalReps',
        value: value,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      totalRepsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalReps',
        value: value,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      totalRepsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalReps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      totalVolumeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      totalVolumeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      totalVolumeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition>
      totalVolumeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalVolume',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension ExerciseLogQueryObject
    on QueryBuilder<ExerciseLog, ExerciseLog, QFilterCondition> {
  QueryBuilder<ExerciseLog, ExerciseLog, QAfterFilterCondition> setsElement(
      FilterQuery<SetLog> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'sets');
    });
  }
}

extension ExerciseLogQueryLinks
    on QueryBuilder<ExerciseLog, ExerciseLog, QFilterCondition> {}

extension ExerciseLogQuerySortBy
    on QueryBuilder<ExerciseLog, ExerciseLog, QSortBy> {
  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByExerciseName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy>
      sortByExerciseNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByInstanceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'instanceId', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByInstanceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'instanceId', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByMaxWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeight', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByMaxWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeight', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByTotalReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalReps', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByTotalRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalReps', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByTotalVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalVolume', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> sortByTotalVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalVolume', Sort.desc);
    });
  }
}

extension ExerciseLogQuerySortThenBy
    on QueryBuilder<ExerciseLog, ExerciseLog, QSortThenBy> {
  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByExerciseName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy>
      thenByExerciseNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByInstanceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'instanceId', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByInstanceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'instanceId', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByMaxWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeight', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByMaxWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxWeight', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByTotalReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalReps', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByTotalRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalReps', Sort.desc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByTotalVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalVolume', Sort.asc);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QAfterSortBy> thenByTotalVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalVolume', Sort.desc);
    });
  }
}

extension ExerciseLogQueryWhereDistinct
    on QueryBuilder<ExerciseLog, ExerciseLog, QDistinct> {
  QueryBuilder<ExerciseLog, ExerciseLog, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QDistinct> distinctByExerciseName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exerciseName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QDistinct> distinctByInstanceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'instanceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QDistinct> distinctByMaxWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxWeight');
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QDistinct> distinctByTotalReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalReps');
    });
  }

  QueryBuilder<ExerciseLog, ExerciseLog, QDistinct> distinctByTotalVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalVolume');
    });
  }
}

extension ExerciseLogQueryProperty
    on QueryBuilder<ExerciseLog, ExerciseLog, QQueryProperty> {
  QueryBuilder<ExerciseLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ExerciseLog, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<ExerciseLog, String, QQueryOperations> exerciseNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exerciseName');
    });
  }

  QueryBuilder<ExerciseLog, String, QQueryOperations> instanceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'instanceId');
    });
  }

  QueryBuilder<ExerciseLog, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<ExerciseLog, double, QQueryOperations> maxWeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxWeight');
    });
  }

  QueryBuilder<ExerciseLog, List<SetLog>, QQueryOperations> setsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sets');
    });
  }

  QueryBuilder<ExerciseLog, int, QQueryOperations> totalRepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalReps');
    });
  }

  QueryBuilder<ExerciseLog, double, QQueryOperations> totalVolumeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalVolume');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SetLogSchema = Schema(
  name: r'SetLog',
  id: 7663625254499761518,
  properties: {
    r'durationSeconds': PropertySchema(
      id: 0,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'reps': PropertySchema(
      id: 1,
      name: r'reps',
      type: IsarType.long,
    ),
    r'setNumber': PropertySchema(
      id: 2,
      name: r'setNumber',
      type: IsarType.long,
    ),
    r'weight': PropertySchema(
      id: 3,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _setLogEstimateSize,
  serialize: _setLogSerialize,
  deserialize: _setLogDeserialize,
  deserializeProp: _setLogDeserializeProp,
);

int _setLogEstimateSize(
  SetLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _setLogSerialize(
  SetLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.durationSeconds);
  writer.writeLong(offsets[1], object.reps);
  writer.writeLong(offsets[2], object.setNumber);
  writer.writeDouble(offsets[3], object.weight);
}

SetLog _setLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SetLog(
    durationSeconds: reader.readLongOrNull(offsets[0]),
    reps: reader.readLongOrNull(offsets[1]),
    setNumber: reader.readLongOrNull(offsets[2]),
    weight: reader.readDoubleOrNull(offsets[3]),
  );
  return object;
}

P _setLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SetLogQueryFilter on QueryBuilder<SetLog, SetLog, QFilterCondition> {
  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> durationSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationSeconds',
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition>
      durationSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationSeconds',
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> durationSecondsEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition>
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

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> durationSecondsLessThan(
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

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> durationSecondsBetween(
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

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> repsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reps',
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> repsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reps',
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> repsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reps',
        value: value,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> repsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reps',
        value: value,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> repsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reps',
        value: value,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> repsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> setNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'setNumber',
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> setNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'setNumber',
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> setNumberEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'setNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> setNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'setNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> setNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'setNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> setNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'setNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> weightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> weightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> weightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> weightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> weightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetLog, SetLog, QAfterFilterCondition> weightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension SetLogQueryObject on QueryBuilder<SetLog, SetLog, QFilterCondition> {}
