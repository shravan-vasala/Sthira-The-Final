// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHabitCollection on Isar {
  IsarCollection<Habit> get habits => this.collection();
}

const HabitSchema = CollectionSchema(
  name: r'Habit',
  id: 3896650575830519340,
  properties: {
    r'activeDays': PropertySchema(
      id: 0,
      name: r'activeDays',
      type: IsarType.longList,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'goalDirection': PropertySchema(
      id: 2,
      name: r'goalDirection',
      type: IsarType.byte,
      enumMap: _HabitgoalDirectionEnumValueMap,
    ),
    r'icon': PropertySchema(
      id: 3,
      name: r'icon',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 4,
      name: r'id',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'order': PropertySchema(
      id: 6,
      name: r'order',
      type: IsarType.long,
    ),
    r'step': PropertySchema(
      id: 7,
      name: r'step',
      type: IsarType.double,
    ),
    r'target': PropertySchema(
      id: 8,
      name: r'target',
      type: IsarType.double,
    ),
    r'type': PropertySchema(
      id: 9,
      name: r'type',
      type: IsarType.byte,
      enumMap: _HabittypeEnumValueMap,
    ),
    r'unit': PropertySchema(
      id: 10,
      name: r'unit',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _habitEstimateSize,
  serialize: _habitSerialize,
  deserialize: _habitDeserialize,
  deserializeProp: _habitDeserializeProp,
  idName: r'idInternal',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _habitGetId,
  getLinks: _habitGetLinks,
  attach: _habitAttach,
  version: '3.1.0+1',
);

int _habitEstimateSize(
  Habit object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.activeDays;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.icon.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.unit.length * 3;
  return bytesCount;
}

void _habitSerialize(
  Habit object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLongList(offsets[0], object.activeDays);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeByte(offsets[2], object.goalDirection.index);
  writer.writeString(offsets[3], object.icon);
  writer.writeString(offsets[4], object.id);
  writer.writeString(offsets[5], object.name);
  writer.writeLong(offsets[6], object.order);
  writer.writeDouble(offsets[7], object.step);
  writer.writeDouble(offsets[8], object.target);
  writer.writeByte(offsets[9], object.type.index);
  writer.writeString(offsets[10], object.unit);
  writer.writeDateTime(offsets[11], object.updatedAt);
}

Habit _habitDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Habit(
    activeDays: reader.readLongList(offsets[0]),
    goalDirection:
        _HabitgoalDirectionValueEnumMap[reader.readByteOrNull(offsets[2])] ??
            GoalDirection.atLeast,
    icon: reader.readString(offsets[3]),
    id: reader.readString(offsets[4]),
    name: reader.readString(offsets[5]),
    order: reader.readLongOrNull(offsets[6]) ?? 0,
    step: reader.readDoubleOrNull(offsets[7]) ?? 1.0,
    target: reader.readDouble(offsets[8]),
    type: _HabittypeValueEnumMap[reader.readByteOrNull(offsets[9])] ??
        HabitType.checkbox,
    unit: reader.readStringOrNull(offsets[10]) ?? '',
    updatedAt: reader.readDateTimeOrNull(offsets[11]),
  );
  object.createdAt = reader.readDateTime(offsets[1]);
  object.idInternal = id;
  return object;
}

P _habitDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongList(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (_HabitgoalDirectionValueEnumMap[reader.readByteOrNull(offset)] ??
          GoalDirection.atLeast) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 7:
      return (reader.readDoubleOrNull(offset) ?? 1.0) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (_HabittypeValueEnumMap[reader.readByteOrNull(offset)] ??
          HabitType.checkbox) as P;
    case 10:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _HabitgoalDirectionEnumValueMap = {
  'atLeast': 0,
  'atMost': 1,
};
const _HabitgoalDirectionValueEnumMap = {
  0: GoalDirection.atLeast,
  1: GoalDirection.atMost,
};
const _HabittypeEnumValueMap = {
  'checkbox': 0,
  'counter': 1,
  'autoSteps': 2,
  'autoSleep': 3,
  'autoFromScreenTime': 4,
  'timer': 5,
};
const _HabittypeValueEnumMap = {
  0: HabitType.checkbox,
  1: HabitType.counter,
  2: HabitType.autoSteps,
  3: HabitType.autoSleep,
  4: HabitType.autoFromScreenTime,
  5: HabitType.timer,
};

Id _habitGetId(Habit object) {
  return object.idInternal;
}

List<IsarLinkBase<dynamic>> _habitGetLinks(Habit object) {
  return [];
}

void _habitAttach(IsarCollection<dynamic> col, Id id, Habit object) {
  object.idInternal = id;
}

extension HabitByIndex on IsarCollection<Habit> {
  Future<Habit?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  Habit? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<Habit?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<Habit?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(Habit object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(Habit object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<Habit> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<Habit> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension HabitQueryWhereSort on QueryBuilder<Habit, Habit, QWhere> {
  QueryBuilder<Habit, Habit, QAfterWhere> anyIdInternal() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HabitQueryWhere on QueryBuilder<Habit, Habit, QWhereClause> {
  QueryBuilder<Habit, Habit, QAfterWhereClause> idInternalEqualTo(
      Id idInternal) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: idInternal,
        upper: idInternal,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterWhereClause> idInternalNotEqualTo(
      Id idInternal) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: idInternal, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: idInternal, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: idInternal, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: idInternal, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Habit, Habit, QAfterWhereClause> idInternalGreaterThan(
      Id idInternal,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: idInternal, includeLower: include),
      );
    });
  }

  QueryBuilder<Habit, Habit, QAfterWhereClause> idInternalLessThan(
      Id idInternal,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: idInternal, includeUpper: include),
      );
    });
  }

  QueryBuilder<Habit, Habit, QAfterWhereClause> idInternalBetween(
    Id lowerIdInternal,
    Id upperIdInternal, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIdInternal,
        includeLower: includeLower,
        upper: upperIdInternal,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterWhereClause> idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterWhereClause> idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension HabitQueryFilter on QueryBuilder<Habit, Habit, QFilterCondition> {
  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'activeDays',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'activeDays',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysElementEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition>
      activeDaysElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activeDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activeDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activeDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeDays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeDays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeDays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeDays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeDays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> activeDaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeDays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> goalDirectionEqualTo(
      GoalDirection value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalDirection',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> goalDirectionGreaterThan(
    GoalDirection value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'goalDirection',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> goalDirectionLessThan(
    GoalDirection value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'goalDirection',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> goalDirectionBetween(
    GoalDirection lower,
    GoalDirection upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'goalDirection',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconEqualTo(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconGreaterThan(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconLessThan(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconBetween(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconStartsWith(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconEndsWith(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'icon',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> iconIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idInternalEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idInternal',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idInternalGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idInternal',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idInternalLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idInternal',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> idInternalBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idInternal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameEqualTo(
    String value, {
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameGreaterThan(
    String value, {
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameLessThan(
    String value, {
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> orderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> orderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> orderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> orderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'order',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> stepEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'step',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> stepGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'step',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> stepLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'step',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> stepBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'step',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> targetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'target',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> targetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'target',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> targetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'target',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> targetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'target',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> typeEqualTo(
      HabitType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> typeGreaterThan(
    HabitType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> typeLessThan(
    HabitType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> typeBetween(
    HabitType lower,
    HabitType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'unit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unit',
        value: '',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> unitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'unit',
        value: '',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Habit, Habit, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<Habit, Habit, QAfterFilterCondition> updatedAtBetween(
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

extension HabitQueryObject on QueryBuilder<Habit, Habit, QFilterCondition> {}

extension HabitQueryLinks on QueryBuilder<Habit, Habit, QFilterCondition> {}

extension HabitQuerySortBy on QueryBuilder<Habit, Habit, QSortBy> {
  QueryBuilder<Habit, Habit, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByGoalDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalDirection', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByGoalDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalDirection', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'step', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByStepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'step', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension HabitQuerySortThenBy on QueryBuilder<Habit, Habit, QSortThenBy> {
  QueryBuilder<Habit, Habit, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByGoalDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalDirection', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByGoalDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalDirection', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByIdInternal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idInternal', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByIdInternalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idInternal', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'step', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByStepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'step', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Habit, Habit, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension HabitQueryWhereDistinct on QueryBuilder<Habit, Habit, QDistinct> {
  QueryBuilder<Habit, Habit, QDistinct> distinctByActiveDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activeDays');
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByGoalDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalDirection');
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByIcon(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'icon', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'order');
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'step');
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'target');
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByUnit(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Habit, Habit, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension HabitQueryProperty on QueryBuilder<Habit, Habit, QQueryProperty> {
  QueryBuilder<Habit, int, QQueryOperations> idInternalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idInternal');
    });
  }

  QueryBuilder<Habit, List<int>?, QQueryOperations> activeDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activeDays');
    });
  }

  QueryBuilder<Habit, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Habit, GoalDirection, QQueryOperations> goalDirectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalDirection');
    });
  }

  QueryBuilder<Habit, String, QQueryOperations> iconProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'icon');
    });
  }

  QueryBuilder<Habit, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Habit, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Habit, int, QQueryOperations> orderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'order');
    });
  }

  QueryBuilder<Habit, double, QQueryOperations> stepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'step');
    });
  }

  QueryBuilder<Habit, double, QQueryOperations> targetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'target');
    });
  }

  QueryBuilder<Habit, HabitType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<Habit, String, QQueryOperations> unitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unit');
    });
  }

  QueryBuilder<Habit, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHabitCompletionCollection on Isar {
  IsarCollection<HabitCompletion> get habitCompletions => this.collection();
}

const HabitCompletionSchema = CollectionSchema(
  name: r'HabitCompletion',
  id: -9119310967514767545,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.string,
    ),
    r'isarCompletions': PropertySchema(
      id: 1,
      name: r'isarCompletions',
      type: IsarType.string,
    ),
    r'isarOverrides': PropertySchema(
      id: 2,
      name: r'isarOverrides',
      type: IsarType.string,
    ),
    r'isarStreaks': PropertySchema(
      id: 3,
      name: r'isarStreaks',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 4,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _habitCompletionEstimateSize,
  serialize: _habitCompletionSerialize,
  deserialize: _habitCompletionDeserialize,
  deserializeProp: _habitCompletionDeserializeProp,
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
  getId: _habitCompletionGetId,
  getLinks: _habitCompletionGetLinks,
  attach: _habitCompletionAttach,
  version: '3.1.0+1',
);

int _habitCompletionEstimateSize(
  HabitCompletion object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.date.length * 3;
  bytesCount += 3 + object.isarCompletions.length * 3;
  bytesCount += 3 + object.isarOverrides.length * 3;
  bytesCount += 3 + object.isarStreaks.length * 3;
  return bytesCount;
}

void _habitCompletionSerialize(
  HabitCompletion object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.date);
  writer.writeString(offsets[1], object.isarCompletions);
  writer.writeString(offsets[2], object.isarOverrides);
  writer.writeString(offsets[3], object.isarStreaks);
  writer.writeDateTime(offsets[4], object.updatedAt);
}

HabitCompletion _habitCompletionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HabitCompletion(
    date: reader.readString(offsets[0]),
    updatedAt: reader.readDateTimeOrNull(offsets[4]),
  );
  object.id = id;
  object.isarCompletions = reader.readString(offsets[1]);
  object.isarOverrides = reader.readString(offsets[2]);
  object.isarStreaks = reader.readString(offsets[3]);
  return object;
}

P _habitCompletionDeserializeProp<P>(
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
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _habitCompletionGetId(HabitCompletion object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _habitCompletionGetLinks(HabitCompletion object) {
  return [];
}

void _habitCompletionAttach(
    IsarCollection<dynamic> col, Id id, HabitCompletion object) {
  object.id = id;
}

extension HabitCompletionByIndex on IsarCollection<HabitCompletion> {
  Future<HabitCompletion?> getByDate(String date) {
    return getByIndex(r'date', [date]);
  }

  HabitCompletion? getByDateSync(String date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(String date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(String date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<HabitCompletion?>> getAllByDate(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<HabitCompletion?> getAllByDateSync(List<String> dateValues) {
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

  Future<Id> putByDate(HabitCompletion object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(HabitCompletion object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<HabitCompletion> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<HabitCompletion> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension HabitCompletionQueryWhereSort
    on QueryBuilder<HabitCompletion, HabitCompletion, QWhere> {
  QueryBuilder<HabitCompletion, HabitCompletion, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HabitCompletionQueryWhere
    on QueryBuilder<HabitCompletion, HabitCompletion, QWhereClause> {
  QueryBuilder<HabitCompletion, HabitCompletion, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterWhereClause>
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterWhereClause> idBetween(
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterWhereClause> dateEqualTo(
      String date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterWhereClause>
      dateNotEqualTo(String date) {
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

extension HabitCompletionQueryFilter
    on QueryBuilder<HabitCompletion, HabitCompletion, QFilterCondition> {
  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      dateEqualTo(
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      dateLessThan(
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      dateBetween(
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      dateEndsWith(
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      dateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      dateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarCompletions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarCompletions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarCompletions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarCompletions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'isarCompletions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'isarCompletions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'isarCompletions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'isarCompletions',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarCompletions',
        value: '',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarCompletionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'isarCompletions',
        value: '',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarOverrides',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarOverrides',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarOverrides',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarOverrides',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'isarOverrides',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'isarOverrides',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'isarOverrides',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'isarOverrides',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarOverrides',
        value: '',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarOverridesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'isarOverrides',
        value: '',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarStreaks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarStreaks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarStreaks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarStreaks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'isarStreaks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'isarStreaks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'isarStreaks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'isarStreaks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarStreaks',
        value: '',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      isarStreaksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'isarStreaks',
        value: '',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
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

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterFilterCondition>
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

extension HabitCompletionQueryObject
    on QueryBuilder<HabitCompletion, HabitCompletion, QFilterCondition> {}

extension HabitCompletionQueryLinks
    on QueryBuilder<HabitCompletion, HabitCompletion, QFilterCondition> {}

extension HabitCompletionQuerySortBy
    on QueryBuilder<HabitCompletion, HabitCompletion, QSortBy> {
  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      sortByIsarCompletions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarCompletions', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      sortByIsarCompletionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarCompletions', Sort.desc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      sortByIsarOverrides() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarOverrides', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      sortByIsarOverridesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarOverrides', Sort.desc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      sortByIsarStreaks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarStreaks', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      sortByIsarStreaksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarStreaks', Sort.desc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension HabitCompletionQuerySortThenBy
    on QueryBuilder<HabitCompletion, HabitCompletion, QSortThenBy> {
  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      thenByIsarCompletions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarCompletions', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      thenByIsarCompletionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarCompletions', Sort.desc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      thenByIsarOverrides() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarOverrides', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      thenByIsarOverridesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarOverrides', Sort.desc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      thenByIsarStreaks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarStreaks', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      thenByIsarStreaksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarStreaks', Sort.desc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension HabitCompletionQueryWhereDistinct
    on QueryBuilder<HabitCompletion, HabitCompletion, QDistinct> {
  QueryBuilder<HabitCompletion, HabitCompletion, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QDistinct>
      distinctByIsarCompletions({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isarCompletions',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QDistinct>
      distinctByIsarOverrides({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isarOverrides',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QDistinct>
      distinctByIsarStreaks({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isarStreaks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HabitCompletion, HabitCompletion, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension HabitCompletionQueryProperty
    on QueryBuilder<HabitCompletion, HabitCompletion, QQueryProperty> {
  QueryBuilder<HabitCompletion, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HabitCompletion, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<HabitCompletion, String, QQueryOperations>
      isarCompletionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarCompletions');
    });
  }

  QueryBuilder<HabitCompletion, String, QQueryOperations>
      isarOverridesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarOverrides');
    });
  }

  QueryBuilder<HabitCompletion, String, QQueryOperations>
      isarStreaksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarStreaks');
    });
  }

  QueryBuilder<HabitCompletion, DateTime?, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
