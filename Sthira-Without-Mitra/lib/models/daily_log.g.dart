// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyLogCollection on Isar {
  IsarCollection<DailyLog> get dailyLogs => this.collection();
}

const DailyLogSchema = CollectionSchema(
  name: r'DailyLog',
  id: -3995615497450705259,
  properties: {
    r'bodyFat': PropertySchema(
      id: 0,
      name: r'bodyFat',
      type: IsarType.double,
    ),
    r'checkInUpdatedAt': PropertySchema(
      id: 1,
      name: r'checkInUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(
      id: 2,
      name: r'date',
      type: IsarType.string,
    ),
    r'dayFeeling': PropertySchema(
      id: 3,
      name: r'dayFeeling',
      type: IsarType.string,
    ),
    r'dayNote': PropertySchema(
      id: 4,
      name: r'dayNote',
      type: IsarType.string,
    ),
    r'hasAnyActivity': PropertySchema(
      id: 5,
      name: r'hasAnyActivity',
      type: IsarType.bool,
    ),
    r'screenTimeMinutes': PropertySchema(
      id: 6,
      name: r'screenTimeMinutes',
      type: IsarType.long,
    ),
    r'sleepHours': PropertySchema(
      id: 7,
      name: r'sleepHours',
      type: IsarType.double,
    ),
    r'sleepSource': PropertySchema(
      id: 8,
      name: r'sleepSource',
      type: IsarType.string,
    ),
    r'steps': PropertySchema(
      id: 9,
      name: r'steps',
      type: IsarType.long,
    ),
    r'stepsSource': PropertySchema(
      id: 10,
      name: r'stepsSource',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'waterMl': PropertySchema(
      id: 12,
      name: r'waterMl',
      type: IsarType.long,
    ),
    r'weight': PropertySchema(
      id: 13,
      name: r'weight',
      type: IsarType.double,
    ),
    r'workoutCompleted': PropertySchema(
      id: 14,
      name: r'workoutCompleted',
      type: IsarType.bool,
    ),
    r'workoutDayId': PropertySchema(
      id: 15,
      name: r'workoutDayId',
      type: IsarType.string,
    ),
    r'workoutStatus': PropertySchema(
      id: 16,
      name: r'workoutStatus',
      type: IsarType.string,
    )
  },
  estimateSize: _dailyLogEstimateSize,
  serialize: _dailyLogSerialize,
  deserialize: _dailyLogDeserialize,
  deserializeProp: _dailyLogDeserializeProp,
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
  embeddedSchemas: {},
  getId: _dailyLogGetId,
  getLinks: _dailyLogGetLinks,
  attach: _dailyLogAttach,
  version: '3.1.0+1',
);

int _dailyLogEstimateSize(
  DailyLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.date.length * 3;
  {
    final value = object.dayFeeling;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dayNote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sleepSource;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.stepsSource;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.workoutDayId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.workoutStatus;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dailyLogSerialize(
  DailyLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.bodyFat);
  writer.writeDateTime(offsets[1], object.checkInUpdatedAt);
  writer.writeString(offsets[2], object.date);
  writer.writeString(offsets[3], object.dayFeeling);
  writer.writeString(offsets[4], object.dayNote);
  writer.writeBool(offsets[5], object.hasAnyActivity);
  writer.writeLong(offsets[6], object.screenTimeMinutes);
  writer.writeDouble(offsets[7], object.sleepHours);
  writer.writeString(offsets[8], object.sleepSource);
  writer.writeLong(offsets[9], object.steps);
  writer.writeString(offsets[10], object.stepsSource);
  writer.writeDateTime(offsets[11], object.updatedAt);
  writer.writeLong(offsets[12], object.waterMl);
  writer.writeDouble(offsets[13], object.weight);
  writer.writeBool(offsets[14], object.workoutCompleted);
  writer.writeString(offsets[15], object.workoutDayId);
  writer.writeString(offsets[16], object.workoutStatus);
}

DailyLog _dailyLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyLog(
    bodyFat: reader.readDoubleOrNull(offsets[0]),
    checkInUpdatedAt: reader.readDateTimeOrNull(offsets[1]),
    date: reader.readString(offsets[2]),
    dayFeeling: reader.readStringOrNull(offsets[3]),
    dayNote: reader.readStringOrNull(offsets[4]),
    screenTimeMinutes: reader.readLongOrNull(offsets[6]),
    sleepHours: reader.readDoubleOrNull(offsets[7]),
    sleepSource: reader.readStringOrNull(offsets[8]),
    steps: reader.readLongOrNull(offsets[9]),
    stepsSource: reader.readStringOrNull(offsets[10]),
    updatedAt: reader.readDateTimeOrNull(offsets[11]),
    waterMl: reader.readLongOrNull(offsets[12]),
    weight: reader.readDoubleOrNull(offsets[13]),
    workoutDayId: reader.readStringOrNull(offsets[15]),
    workoutStatus: reader.readStringOrNull(offsets[16]),
  );
  object.id = id;
  return object;
}

P _dailyLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyLogGetId(DailyLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyLogGetLinks(DailyLog object) {
  return [];
}

void _dailyLogAttach(IsarCollection<dynamic> col, Id id, DailyLog object) {
  object.id = id;
}

extension DailyLogByIndex on IsarCollection<DailyLog> {
  Future<DailyLog?> getByDate(String date) {
    return getByIndex(r'date', [date]);
  }

  DailyLog? getByDateSync(String date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(String date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(String date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<DailyLog?>> getAllByDate(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<DailyLog?> getAllByDateSync(List<String> dateValues) {
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

  Future<Id> putByDate(DailyLog object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(DailyLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<DailyLog> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<DailyLog> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension DailyLogQueryWhereSort on QueryBuilder<DailyLog, DailyLog, QWhere> {
  QueryBuilder<DailyLog, DailyLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailyLogQueryWhere on QueryBuilder<DailyLog, DailyLog, QWhereClause> {
  QueryBuilder<DailyLog, DailyLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DailyLog, DailyLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<DailyLog, DailyLog, QAfterWhereClause> dateEqualTo(String date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterWhereClause> dateNotEqualTo(
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

extension DailyLogQueryFilter
    on QueryBuilder<DailyLog, DailyLog, QFilterCondition> {
  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> bodyFatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyFat',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> bodyFatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyFat',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> bodyFatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> bodyFatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> bodyFatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> bodyFatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyFat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      checkInUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'checkInUpdatedAt',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      checkInUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'checkInUpdatedAt',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      checkInUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checkInUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      checkInUpdatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'checkInUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      checkInUpdatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'checkInUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      checkInUpdatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'checkInUpdatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateEqualTo(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateGreaterThan(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateLessThan(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateBetween(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateStartsWith(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateEndsWith(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateContains(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateMatches(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dayFeeling',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      dayFeelingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dayFeeling',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayFeeling',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayFeeling',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayFeeling',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayFeeling',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dayFeeling',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dayFeeling',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dayFeeling',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dayFeeling',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayFeelingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayFeeling',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      dayFeelingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dayFeeling',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dayNote',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dayNote',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dayNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dayNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dayNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dayNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayNote',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> dayNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dayNote',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> hasAnyActivityEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasAnyActivity',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      screenTimeMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'screenTimeMinutes',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      screenTimeMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'screenTimeMinutes',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      screenTimeMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'screenTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      screenTimeMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'screenTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      screenTimeMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'screenTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      screenTimeMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'screenTimeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepHoursIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sleepHours',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      sleepHoursIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sleepHours',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepHoursEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepHoursGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepHoursLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepHoursBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepHours',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepSourceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sleepSource',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      sleepSourceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sleepSource',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepSourceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      sleepSourceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepSourceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepSourceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepSource',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepSourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sleepSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepSourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sleepSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepSourceContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sleepSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepSourceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sleepSource',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> sleepSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepSource',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      sleepSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sleepSource',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'steps',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'steps',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'steps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsSourceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stepsSource',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      stepsSourceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stepsSource',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsSourceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stepsSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      stepsSourceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stepsSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsSourceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stepsSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsSourceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stepsSource',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsSourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stepsSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsSourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stepsSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsSourceContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stepsSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsSourceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stepsSource',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> stepsSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stepsSource',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      stepsSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stepsSource',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> waterMlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'waterMl',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> waterMlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'waterMl',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> waterMlEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waterMl',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> waterMlGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waterMl',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> waterMlLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waterMl',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> waterMlBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waterMl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> weightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> weightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> weightEqualTo(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> weightGreaterThan(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> weightLessThan(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> weightBetween(
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

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutDayIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'workoutDayId',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutDayIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'workoutDayId',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutDayIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutDayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutDayIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workoutDayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutDayIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workoutDayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutDayIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workoutDayId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutDayIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'workoutDayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutDayIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'workoutDayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutDayIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'workoutDayId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutDayIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'workoutDayId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutDayIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutDayId',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutDayIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'workoutDayId',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'workoutStatus',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'workoutStatus',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutStatusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workoutStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workoutStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workoutStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'workoutStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'workoutStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutStatusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'workoutStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition> workoutStatusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'workoutStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterFilterCondition>
      workoutStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'workoutStatus',
        value: '',
      ));
    });
  }
}

extension DailyLogQueryObject
    on QueryBuilder<DailyLog, DailyLog, QFilterCondition> {}

extension DailyLogQueryLinks
    on QueryBuilder<DailyLog, DailyLog, QFilterCondition> {}

extension DailyLogQuerySortBy on QueryBuilder<DailyLog, DailyLog, QSortBy> {
  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByBodyFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByCheckInUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkInUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByCheckInUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkInUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByDayFeeling() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayFeeling', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByDayFeelingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayFeeling', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByDayNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayNote', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByDayNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayNote', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByHasAnyActivity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAnyActivity', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByHasAnyActivityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAnyActivity', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByScreenTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'screenTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByScreenTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'screenTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortBySleepHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepHours', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortBySleepHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepHours', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortBySleepSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSource', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortBySleepSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSource', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByStepsSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepsSource', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByStepsSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepsSource', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWaterMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterMl', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWaterMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterMl', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWorkoutCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutCompleted', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWorkoutCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutCompleted', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWorkoutDayId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDayId', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWorkoutDayIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDayId', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWorkoutStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutStatus', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> sortByWorkoutStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutStatus', Sort.desc);
    });
  }
}

extension DailyLogQuerySortThenBy
    on QueryBuilder<DailyLog, DailyLog, QSortThenBy> {
  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByBodyFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByCheckInUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkInUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByCheckInUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkInUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByDayFeeling() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayFeeling', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByDayFeelingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayFeeling', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByDayNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayNote', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByDayNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayNote', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByHasAnyActivity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAnyActivity', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByHasAnyActivityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAnyActivity', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByScreenTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'screenTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByScreenTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'screenTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenBySleepHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepHours', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenBySleepHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepHours', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenBySleepSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSource', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenBySleepSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSource', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByStepsSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepsSource', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByStepsSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepsSource', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWaterMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterMl', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWaterMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterMl', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWorkoutCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutCompleted', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWorkoutCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutCompleted', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWorkoutDayId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDayId', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWorkoutDayIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutDayId', Sort.desc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWorkoutStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutStatus', Sort.asc);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QAfterSortBy> thenByWorkoutStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutStatus', Sort.desc);
    });
  }
}

extension DailyLogQueryWhereDistinct
    on QueryBuilder<DailyLog, DailyLog, QDistinct> {
  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyFat');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByCheckInUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checkInUpdatedAt');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByDayFeeling(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayFeeling', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByDayNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayNote', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByHasAnyActivity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasAnyActivity');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByScreenTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'screenTimeMinutes');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctBySleepHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepHours');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctBySleepSource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepSource', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'steps');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByStepsSource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stepsSource', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByWaterMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waterMl');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByWorkoutCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutCompleted');
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByWorkoutDayId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutDayId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyLog, DailyLog, QDistinct> distinctByWorkoutStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutStatus',
          caseSensitive: caseSensitive);
    });
  }
}

extension DailyLogQueryProperty
    on QueryBuilder<DailyLog, DailyLog, QQueryProperty> {
  QueryBuilder<DailyLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyLog, double?, QQueryOperations> bodyFatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyFat');
    });
  }

  QueryBuilder<DailyLog, DateTime?, QQueryOperations>
      checkInUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkInUpdatedAt');
    });
  }

  QueryBuilder<DailyLog, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailyLog, String?, QQueryOperations> dayFeelingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayFeeling');
    });
  }

  QueryBuilder<DailyLog, String?, QQueryOperations> dayNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayNote');
    });
  }

  QueryBuilder<DailyLog, bool, QQueryOperations> hasAnyActivityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasAnyActivity');
    });
  }

  QueryBuilder<DailyLog, int?, QQueryOperations> screenTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'screenTimeMinutes');
    });
  }

  QueryBuilder<DailyLog, double?, QQueryOperations> sleepHoursProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepHours');
    });
  }

  QueryBuilder<DailyLog, String?, QQueryOperations> sleepSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepSource');
    });
  }

  QueryBuilder<DailyLog, int?, QQueryOperations> stepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'steps');
    });
  }

  QueryBuilder<DailyLog, String?, QQueryOperations> stepsSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stepsSource');
    });
  }

  QueryBuilder<DailyLog, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<DailyLog, int?, QQueryOperations> waterMlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waterMl');
    });
  }

  QueryBuilder<DailyLog, double?, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }

  QueryBuilder<DailyLog, bool, QQueryOperations> workoutCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutCompleted');
    });
  }

  QueryBuilder<DailyLog, String?, QQueryOperations> workoutDayIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutDayId');
    });
  }

  QueryBuilder<DailyLog, String?, QQueryOperations> workoutStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutStatus');
    });
  }
}
