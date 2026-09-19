// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanned_meal_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetScannedMealLogCollection on Isar {
  IsarCollection<ScannedMealLog> get scannedMealLogs => this.collection();
}

const ScannedMealLogSchema = CollectionSchema(
  name: r'ScannedMealLog',
  id: -717276445189106011,
  properties: {
    r'carbsGrams': PropertySchema(
      id: 0,
      name: r'carbsGrams',
      type: IsarType.double,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.string,
    ),
    r'estimatedCalories': PropertySchema(
      id: 2,
      name: r'estimatedCalories',
      type: IsarType.long,
    ),
    r'fatGrams': PropertySchema(
      id: 3,
      name: r'fatGrams',
      type: IsarType.double,
    ),
    r'foodName': PropertySchema(
      id: 4,
      name: r'foodName',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 5,
      name: r'id',
      type: IsarType.string,
    ),
    r'mealType': PropertySchema(
      id: 6,
      name: r'mealType',
      type: IsarType.string,
    ),
    r'photoPath': PropertySchema(
      id: 7,
      name: r'photoPath',
      type: IsarType.string,
    ),
    r'portionMultiplier': PropertySchema(
      id: 8,
      name: r'portionMultiplier',
      type: IsarType.double,
    ),
    r'proteinGrams': PropertySchema(
      id: 9,
      name: r'proteinGrams',
      type: IsarType.double,
    ),
    r'timestamp': PropertySchema(
      id: 10,
      name: r'timestamp',
      type: IsarType.string,
    ),
    r'totalCalories': PropertySchema(
      id: 11,
      name: r'totalCalories',
      type: IsarType.long,
    ),
    r'totalCarbs': PropertySchema(
      id: 12,
      name: r'totalCarbs',
      type: IsarType.double,
    ),
    r'totalFat': PropertySchema(
      id: 13,
      name: r'totalFat',
      type: IsarType.double,
    ),
    r'totalProtein': PropertySchema(
      id: 14,
      name: r'totalProtein',
      type: IsarType.double,
    )
  },
  estimateSize: _scannedMealLogEstimateSize,
  serialize: _scannedMealLogSerialize,
  deserialize: _scannedMealLogDeserialize,
  deserializeProp: _scannedMealLogDeserializeProp,
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
  getId: _scannedMealLogGetId,
  getLinks: _scannedMealLogGetLinks,
  attach: _scannedMealLogAttach,
  version: '3.1.0+1',
);

int _scannedMealLogEstimateSize(
  ScannedMealLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.date.length * 3;
  bytesCount += 3 + object.foodName.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.mealType.length * 3;
  bytesCount += 3 + object.photoPath.length * 3;
  bytesCount += 3 + object.timestamp.length * 3;
  return bytesCount;
}

void _scannedMealLogSerialize(
  ScannedMealLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.carbsGrams);
  writer.writeString(offsets[1], object.date);
  writer.writeLong(offsets[2], object.estimatedCalories);
  writer.writeDouble(offsets[3], object.fatGrams);
  writer.writeString(offsets[4], object.foodName);
  writer.writeString(offsets[5], object.id);
  writer.writeString(offsets[6], object.mealType);
  writer.writeString(offsets[7], object.photoPath);
  writer.writeDouble(offsets[8], object.portionMultiplier);
  writer.writeDouble(offsets[9], object.proteinGrams);
  writer.writeString(offsets[10], object.timestamp);
  writer.writeLong(offsets[11], object.totalCalories);
  writer.writeDouble(offsets[12], object.totalCarbs);
  writer.writeDouble(offsets[13], object.totalFat);
  writer.writeDouble(offsets[14], object.totalProtein);
}

ScannedMealLog _scannedMealLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ScannedMealLog(
    carbsGrams: reader.readDouble(offsets[0]),
    date: reader.readString(offsets[1]),
    estimatedCalories: reader.readLong(offsets[2]),
    fatGrams: reader.readDouble(offsets[3]),
    foodName: reader.readString(offsets[4]),
    id: reader.readString(offsets[5]),
    mealType: reader.readString(offsets[6]),
    photoPath: reader.readString(offsets[7]),
    portionMultiplier: reader.readDoubleOrNull(offsets[8]) ?? 1.0,
    proteinGrams: reader.readDouble(offsets[9]),
    timestamp: reader.readString(offsets[10]),
  );
  object.idInternal = id;
  return object;
}

P _scannedMealLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset) ?? 1.0) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _scannedMealLogGetId(ScannedMealLog object) {
  return object.idInternal;
}

List<IsarLinkBase<dynamic>> _scannedMealLogGetLinks(ScannedMealLog object) {
  return [];
}

void _scannedMealLogAttach(
    IsarCollection<dynamic> col, Id id, ScannedMealLog object) {
  object.idInternal = id;
}

extension ScannedMealLogByIndex on IsarCollection<ScannedMealLog> {
  Future<ScannedMealLog?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  ScannedMealLog? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<ScannedMealLog?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<ScannedMealLog?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(ScannedMealLog object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(ScannedMealLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<ScannedMealLog> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<ScannedMealLog> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension ScannedMealLogQueryWhereSort
    on QueryBuilder<ScannedMealLog, ScannedMealLog, QWhere> {
  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterWhere> anyIdInternal() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ScannedMealLogQueryWhere
    on QueryBuilder<ScannedMealLog, ScannedMealLog, QWhereClause> {
  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterWhereClause>
      idInternalEqualTo(Id idInternal) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: idInternal,
        upper: idInternal,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterWhereClause>
      idInternalNotEqualTo(Id idInternal) {
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterWhereClause>
      idInternalGreaterThan(Id idInternal, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: idInternal, includeLower: include),
      );
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterWhereClause>
      idInternalLessThan(Id idInternal, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: idInternal, includeUpper: include),
      );
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterWhereClause>
      idInternalBetween(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterWhereClause> idNotEqualTo(
      String id) {
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

extension ScannedMealLogQueryFilter
    on QueryBuilder<ScannedMealLog, ScannedMealLog, QFilterCondition> {
  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      carbsGramsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbsGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      carbsGramsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbsGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      carbsGramsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbsGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      carbsGramsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbsGrams',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      dateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      dateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      estimatedCaloriesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estimatedCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      estimatedCaloriesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estimatedCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      estimatedCaloriesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estimatedCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      estimatedCaloriesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estimatedCalories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      fatGramsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fatGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      fatGramsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fatGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      fatGramsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fatGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      fatGramsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fatGrams',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'foodName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'foodName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'foodName',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      foodNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'foodName',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idStartsWith(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idEndsWith(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idInternalEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idInternal',
        value: value,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idInternalGreaterThan(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idInternalLessThan(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      idInternalBetween(
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mealType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mealType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mealType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mealType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mealType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mealType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mealType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealType',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      mealTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mealType',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      photoPathEqualTo(
    String value, {
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      photoPathGreaterThan(
    String value, {
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      photoPathLessThan(
    String value, {
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      photoPathBetween(
    String lower,
    String upper, {
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      photoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      photoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      photoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      photoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      portionMultiplierEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'portionMultiplier',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      portionMultiplierGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'portionMultiplier',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      portionMultiplierLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'portionMultiplier',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      portionMultiplierBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'portionMultiplier',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      proteinGramsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      proteinGramsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      proteinGramsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinGrams',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      proteinGramsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinGrams',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timestamp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timestamp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timestamp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timestamp',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      timestampIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timestamp',
        value: '',
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
      totalCaloriesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterFilterCondition>
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

extension ScannedMealLogQueryObject
    on QueryBuilder<ScannedMealLog, ScannedMealLog, QFilterCondition> {}

extension ScannedMealLogQueryLinks
    on QueryBuilder<ScannedMealLog, ScannedMealLog, QFilterCondition> {}

extension ScannedMealLogQuerySortBy
    on QueryBuilder<ScannedMealLog, ScannedMealLog, QSortBy> {
  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByCarbsGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsGrams', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByCarbsGramsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsGrams', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByEstimatedCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedCalories', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByEstimatedCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedCalories', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortByFatGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatGrams', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByFatGramsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatGrams', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortByFoodName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodName', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByFoodNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodName', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortByMealType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealType', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByMealTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealType', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortByPhotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByPhotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByPortionMultiplier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portionMultiplier', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByPortionMultiplierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portionMultiplier', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByProteinGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinGrams', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByProteinGramsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinGrams', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByTotalCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCarbs', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByTotalCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCarbs', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> sortByTotalFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFat', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByTotalFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFat', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByTotalProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProtein', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      sortByTotalProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProtein', Sort.desc);
    });
  }
}

extension ScannedMealLogQuerySortThenBy
    on QueryBuilder<ScannedMealLog, ScannedMealLog, QSortThenBy> {
  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByCarbsGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsGrams', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByCarbsGramsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsGrams', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByEstimatedCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedCalories', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByEstimatedCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedCalories', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenByFatGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatGrams', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByFatGramsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatGrams', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenByFoodName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodName', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByFoodNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodName', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByIdInternal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idInternal', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByIdInternalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idInternal', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenByMealType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealType', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByMealTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealType', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenByPhotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByPhotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByPortionMultiplier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portionMultiplier', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByPortionMultiplierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portionMultiplier', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByProteinGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinGrams', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByProteinGramsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinGrams', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByTotalCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCarbs', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByTotalCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCarbs', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy> thenByTotalFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFat', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByTotalFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFat', Sort.desc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByTotalProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProtein', Sort.asc);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QAfterSortBy>
      thenByTotalProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProtein', Sort.desc);
    });
  }
}

extension ScannedMealLogQueryWhereDistinct
    on QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct> {
  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct>
      distinctByCarbsGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbsGrams');
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct>
      distinctByEstimatedCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estimatedCalories');
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct> distinctByFatGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fatGrams');
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct> distinctByFoodName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'foodName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct> distinctByMealType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mealType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct> distinctByPhotoPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct>
      distinctByPortionMultiplier() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'portionMultiplier');
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct>
      distinctByProteinGrams() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinGrams');
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct> distinctByTimestamp(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct>
      distinctByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCalories');
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct>
      distinctByTotalCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCarbs');
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct> distinctByTotalFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalFat');
    });
  }

  QueryBuilder<ScannedMealLog, ScannedMealLog, QDistinct>
      distinctByTotalProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalProtein');
    });
  }
}

extension ScannedMealLogQueryProperty
    on QueryBuilder<ScannedMealLog, ScannedMealLog, QQueryProperty> {
  QueryBuilder<ScannedMealLog, int, QQueryOperations> idInternalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idInternal');
    });
  }

  QueryBuilder<ScannedMealLog, double, QQueryOperations> carbsGramsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbsGrams');
    });
  }

  QueryBuilder<ScannedMealLog, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<ScannedMealLog, int, QQueryOperations>
      estimatedCaloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estimatedCalories');
    });
  }

  QueryBuilder<ScannedMealLog, double, QQueryOperations> fatGramsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fatGrams');
    });
  }

  QueryBuilder<ScannedMealLog, String, QQueryOperations> foodNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'foodName');
    });
  }

  QueryBuilder<ScannedMealLog, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ScannedMealLog, String, QQueryOperations> mealTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mealType');
    });
  }

  QueryBuilder<ScannedMealLog, String, QQueryOperations> photoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoPath');
    });
  }

  QueryBuilder<ScannedMealLog, double, QQueryOperations>
      portionMultiplierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'portionMultiplier');
    });
  }

  QueryBuilder<ScannedMealLog, double, QQueryOperations>
      proteinGramsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinGrams');
    });
  }

  QueryBuilder<ScannedMealLog, String, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<ScannedMealLog, int, QQueryOperations> totalCaloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCalories');
    });
  }

  QueryBuilder<ScannedMealLog, double, QQueryOperations> totalCarbsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCarbs');
    });
  }

  QueryBuilder<ScannedMealLog, double, QQueryOperations> totalFatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalFat');
    });
  }

  QueryBuilder<ScannedMealLog, double, QQueryOperations>
      totalProteinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalProtein');
    });
  }
}
