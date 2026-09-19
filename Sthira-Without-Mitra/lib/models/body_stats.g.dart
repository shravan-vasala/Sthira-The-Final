// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_stats.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBodyStatsCollection on Isar {
  IsarCollection<BodyStats> get bodyStats => this.collection();
}

const BodyStatsSchema = CollectionSchema(
  name: r'BodyStats',
  id: 588362406387139318,
  properties: {
    r'chest': PropertySchema(
      id: 0,
      name: r'chest',
      type: IsarType.double,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.string,
    ),
    r'hips': PropertySchema(
      id: 2,
      name: r'hips',
      type: IsarType.double,
    ),
    r'leftArm': PropertySchema(
      id: 3,
      name: r'leftArm',
      type: IsarType.double,
    ),
    r'leftThigh': PropertySchema(
      id: 4,
      name: r'leftThigh',
      type: IsarType.double,
    ),
    r'neck': PropertySchema(
      id: 5,
      name: r'neck',
      type: IsarType.double,
    ),
    r'rightArm': PropertySchema(
      id: 6,
      name: r'rightArm',
      type: IsarType.double,
    ),
    r'rightThigh': PropertySchema(
      id: 7,
      name: r'rightThigh',
      type: IsarType.double,
    ),
    r'unit': PropertySchema(
      id: 8,
      name: r'unit',
      type: IsarType.string,
    ),
    r'waist': PropertySchema(
      id: 9,
      name: r'waist',
      type: IsarType.double,
    )
  },
  estimateSize: _bodyStatsEstimateSize,
  serialize: _bodyStatsSerialize,
  deserialize: _bodyStatsDeserialize,
  deserializeProp: _bodyStatsDeserializeProp,
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
  getId: _bodyStatsGetId,
  getLinks: _bodyStatsGetLinks,
  attach: _bodyStatsAttach,
  version: '3.1.0+1',
);

int _bodyStatsEstimateSize(
  BodyStats object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.date.length * 3;
  bytesCount += 3 + object.unit.length * 3;
  return bytesCount;
}

void _bodyStatsSerialize(
  BodyStats object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.chest);
  writer.writeString(offsets[1], object.date);
  writer.writeDouble(offsets[2], object.hips);
  writer.writeDouble(offsets[3], object.leftArm);
  writer.writeDouble(offsets[4], object.leftThigh);
  writer.writeDouble(offsets[5], object.neck);
  writer.writeDouble(offsets[6], object.rightArm);
  writer.writeDouble(offsets[7], object.rightThigh);
  writer.writeString(offsets[8], object.unit);
  writer.writeDouble(offsets[9], object.waist);
}

BodyStats _bodyStatsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BodyStats(
    chest: reader.readDoubleOrNull(offsets[0]),
    date: reader.readString(offsets[1]),
    hips: reader.readDoubleOrNull(offsets[2]),
    leftArm: reader.readDoubleOrNull(offsets[3]),
    leftThigh: reader.readDoubleOrNull(offsets[4]),
    neck: reader.readDoubleOrNull(offsets[5]),
    rightArm: reader.readDoubleOrNull(offsets[6]),
    rightThigh: reader.readDoubleOrNull(offsets[7]),
    unit: reader.readStringOrNull(offsets[8]) ?? 'cm',
    waist: reader.readDoubleOrNull(offsets[9]),
  );
  object.id = id;
  return object;
}

P _bodyStatsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset) ?? 'cm') as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bodyStatsGetId(BodyStats object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _bodyStatsGetLinks(BodyStats object) {
  return [];
}

void _bodyStatsAttach(IsarCollection<dynamic> col, Id id, BodyStats object) {
  object.id = id;
}

extension BodyStatsByIndex on IsarCollection<BodyStats> {
  Future<BodyStats?> getByDate(String date) {
    return getByIndex(r'date', [date]);
  }

  BodyStats? getByDateSync(String date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(String date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(String date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<BodyStats?>> getAllByDate(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<BodyStats?> getAllByDateSync(List<String> dateValues) {
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

  Future<Id> putByDate(BodyStats object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(BodyStats object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<BodyStats> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<BodyStats> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension BodyStatsQueryWhereSort
    on QueryBuilder<BodyStats, BodyStats, QWhere> {
  QueryBuilder<BodyStats, BodyStats, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BodyStatsQueryWhere
    on QueryBuilder<BodyStats, BodyStats, QWhereClause> {
  QueryBuilder<BodyStats, BodyStats, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<BodyStats, BodyStats, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterWhereClause> idBetween(
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

  QueryBuilder<BodyStats, BodyStats, QAfterWhereClause> dateEqualTo(
      String date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterWhereClause> dateNotEqualTo(
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

extension BodyStatsQueryFilter
    on QueryBuilder<BodyStats, BodyStats, QFilterCondition> {
  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> chestIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chest',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> chestIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chest',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> chestEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> chestGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> chestLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> chestBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chest',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateEqualTo(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateGreaterThan(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateLessThan(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateBetween(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateStartsWith(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateEndsWith(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateContains(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateMatches(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> hipsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hips',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> hipsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hips',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> hipsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hips',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> hipsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hips',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> hipsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hips',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> hipsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hips',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> idBetween(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftArmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'leftArm',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftArmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'leftArm',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftArmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leftArm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftArmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'leftArm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftArmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'leftArm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftArmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'leftArm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftThighIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'leftThigh',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition>
      leftThighIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'leftThigh',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftThighEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leftThigh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition>
      leftThighGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'leftThigh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftThighLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'leftThigh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> leftThighBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'leftThigh',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> neckIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'neck',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> neckIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'neck',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> neckEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'neck',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> neckGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'neck',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> neckLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'neck',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> neckBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'neck',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> rightArmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rightArm',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition>
      rightArmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rightArm',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> rightArmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rightArm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> rightArmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rightArm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> rightArmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rightArm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> rightArmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rightArm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> rightThighIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rightThigh',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition>
      rightThighIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rightThigh',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> rightThighEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rightThigh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition>
      rightThighGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rightThigh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> rightThighLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rightThigh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> rightThighBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rightThigh',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitEqualTo(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitGreaterThan(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitLessThan(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitBetween(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitStartsWith(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitEndsWith(
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

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'unit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unit',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> unitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'unit',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> waistIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'waist',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> waistIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'waist',
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> waistEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waist',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> waistGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waist',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> waistLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waist',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterFilterCondition> waistBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waist',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension BodyStatsQueryObject
    on QueryBuilder<BodyStats, BodyStats, QFilterCondition> {}

extension BodyStatsQueryLinks
    on QueryBuilder<BodyStats, BodyStats, QFilterCondition> {}

extension BodyStatsQuerySortBy on QueryBuilder<BodyStats, BodyStats, QSortBy> {
  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByChest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByChestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByHips() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByHipsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByLeftArm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leftArm', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByLeftArmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leftArm', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByLeftThigh() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leftThigh', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByLeftThighDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leftThigh', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByNeck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neck', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByNeckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neck', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByRightArm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rightArm', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByRightArmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rightArm', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByRightThigh() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rightThigh', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByRightThighDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rightThigh', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByWaist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> sortByWaistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.desc);
    });
  }
}

extension BodyStatsQuerySortThenBy
    on QueryBuilder<BodyStats, BodyStats, QSortThenBy> {
  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByChest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByChestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByHips() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByHipsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByLeftArm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leftArm', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByLeftArmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leftArm', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByLeftThigh() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leftThigh', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByLeftThighDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leftThigh', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByNeck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neck', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByNeckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neck', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByRightArm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rightArm', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByRightArmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rightArm', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByRightThigh() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rightThigh', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByRightThighDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rightThigh', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByWaist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.asc);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QAfterSortBy> thenByWaistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.desc);
    });
  }
}

extension BodyStatsQueryWhereDistinct
    on QueryBuilder<BodyStats, BodyStats, QDistinct> {
  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByChest() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chest');
    });
  }

  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByHips() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hips');
    });
  }

  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByLeftArm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'leftArm');
    });
  }

  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByLeftThigh() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'leftThigh');
    });
  }

  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByNeck() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'neck');
    });
  }

  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByRightArm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rightArm');
    });
  }

  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByRightThigh() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rightThigh');
    });
  }

  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByUnit(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BodyStats, BodyStats, QDistinct> distinctByWaist() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waist');
    });
  }
}

extension BodyStatsQueryProperty
    on QueryBuilder<BodyStats, BodyStats, QQueryProperty> {
  QueryBuilder<BodyStats, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BodyStats, double?, QQueryOperations> chestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chest');
    });
  }

  QueryBuilder<BodyStats, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<BodyStats, double?, QQueryOperations> hipsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hips');
    });
  }

  QueryBuilder<BodyStats, double?, QQueryOperations> leftArmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'leftArm');
    });
  }

  QueryBuilder<BodyStats, double?, QQueryOperations> leftThighProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'leftThigh');
    });
  }

  QueryBuilder<BodyStats, double?, QQueryOperations> neckProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'neck');
    });
  }

  QueryBuilder<BodyStats, double?, QQueryOperations> rightArmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rightArm');
    });
  }

  QueryBuilder<BodyStats, double?, QQueryOperations> rightThighProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rightThigh');
    });
  }

  QueryBuilder<BodyStats, String, QQueryOperations> unitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unit');
    });
  }

  QueryBuilder<BodyStats, double?, QQueryOperations> waistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waist');
    });
  }
}
