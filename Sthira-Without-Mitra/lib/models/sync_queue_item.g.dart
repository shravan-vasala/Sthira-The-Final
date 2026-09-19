// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncQueueItemCollection on Isar {
  IsarCollection<SyncQueueItem> get syncQueueItems => this.collection();
}

const SyncQueueItemSchema = CollectionSchema(
  name: r'SyncQueueItem',
  id: 599395208720970483,
  properties: {
    r'attempts': PropertySchema(
      id: 0,
      name: r'attempts',
      type: IsarType.long,
    ),
    r'collection': PropertySchema(
      id: 1,
      name: r'collection',
      type: IsarType.string,
    ),
    r'docId': PropertySchema(
      id: 2,
      name: r'docId',
      type: IsarType.string,
    ),
    r'lastError': PropertySchema(
      id: 3,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'payload': PropertySchema(
      id: 4,
      name: r'payload',
      type: IsarType.string,
    ),
    r'quarantined': PropertySchema(
      id: 5,
      name: r'quarantined',
      type: IsarType.bool,
    ),
    r'timestamp': PropertySchema(
      id: 6,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'uid': PropertySchema(
      id: 7,
      name: r'uid',
      type: IsarType.string,
    )
  },
  estimateSize: _syncQueueItemEstimateSize,
  serialize: _syncQueueItemSerialize,
  deserialize: _syncQueueItemDeserialize,
  deserializeProp: _syncQueueItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'collection': IndexSchema(
      id: -1843270535372135219,
      name: r'collection',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'collection',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'docId': IndexSchema(
      id: -9164048795576814174,
      name: r'docId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'docId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'uid_timestamp': IndexSchema(
      id: -8350540550717848864,
      name: r'uid_timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _syncQueueItemGetId,
  getLinks: _syncQueueItemGetLinks,
  attach: _syncQueueItemAttach,
  version: '3.1.0+1',
);

int _syncQueueItemEstimateSize(
  SyncQueueItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.collection.length * 3;
  bytesCount += 3 + object.docId.length * 3;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.payload.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _syncQueueItemSerialize(
  SyncQueueItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.attempts);
  writer.writeString(offsets[1], object.collection);
  writer.writeString(offsets[2], object.docId);
  writer.writeString(offsets[3], object.lastError);
  writer.writeString(offsets[4], object.payload);
  writer.writeBool(offsets[5], object.quarantined);
  writer.writeDateTime(offsets[6], object.timestamp);
  writer.writeString(offsets[7], object.uid);
}

SyncQueueItem _syncQueueItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncQueueItem(
    attempts: reader.readLongOrNull(offsets[0]) ?? 0,
    collection: reader.readString(offsets[1]),
    docId: reader.readString(offsets[2]),
    lastError: reader.readStringOrNull(offsets[3]),
    payload: reader.readString(offsets[4]),
    quarantined: reader.readBoolOrNull(offsets[5]) ?? false,
    timestamp: reader.readDateTime(offsets[6]),
    uid: reader.readString(offsets[7]),
  );
  object.id = id;
  return object;
}

P _syncQueueItemDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncQueueItemGetId(SyncQueueItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncQueueItemGetLinks(SyncQueueItem object) {
  return [];
}

void _syncQueueItemAttach(
    IsarCollection<dynamic> col, Id id, SyncQueueItem object) {
  object.id = id;
}

extension SyncQueueItemQueryWhereSort
    on QueryBuilder<SyncQueueItem, SyncQueueItem, QWhere> {
  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncQueueItemQueryWhere
    on QueryBuilder<SyncQueueItem, SyncQueueItem, QWhereClause> {
  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause> idBetween(
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

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause>
      collectionEqualTo(String collection) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'collection',
        value: [collection],
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause>
      collectionNotEqualTo(String collection) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'collection',
              lower: [],
              upper: [collection],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'collection',
              lower: [collection],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'collection',
              lower: [collection],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'collection',
              lower: [],
              upper: [collection],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause> docIdEqualTo(
      String docId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'docId',
        value: [docId],
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause> docIdNotEqualTo(
      String docId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'docId',
              lower: [],
              upper: [docId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'docId',
              lower: [docId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'docId',
              lower: [docId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'docId',
              lower: [],
              upper: [docId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause>
      uidEqualToAnyTimestamp(String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid_timestamp',
        value: [uid],
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause>
      uidNotEqualToAnyTimestamp(String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_timestamp',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_timestamp',
              lower: [uid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_timestamp',
              lower: [uid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_timestamp',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause>
      uidTimestampEqualTo(String uid, DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid_timestamp',
        value: [uid, timestamp],
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause>
      uidEqualToTimestampNotEqualTo(String uid, DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_timestamp',
              lower: [uid],
              upper: [uid, timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_timestamp',
              lower: [uid, timestamp],
              includeLower: false,
              upper: [uid],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_timestamp',
              lower: [uid, timestamp],
              includeLower: false,
              upper: [uid],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_timestamp',
              lower: [uid],
              upper: [uid, timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause>
      uidEqualToTimestampGreaterThan(
    String uid,
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uid_timestamp',
        lower: [uid, timestamp],
        includeLower: include,
        upper: [uid],
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause>
      uidEqualToTimestampLessThan(
    String uid,
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uid_timestamp',
        lower: [uid],
        upper: [uid, timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterWhereClause>
      uidEqualToTimestampBetween(
    String uid,
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uid_timestamp',
        lower: [uid, lowerTimestamp],
        includeLower: includeLower,
        upper: [uid, upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SyncQueueItemQueryFilter
    on QueryBuilder<SyncQueueItem, SyncQueueItem, QFilterCondition> {
  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      attemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      attemptsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      attemptsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      attemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attempts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'collection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'collection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'collection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'collection',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'collection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'collection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'collection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'collection',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'collection',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      collectionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'collection',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'docId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'docId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'docId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'docId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'docId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'docId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'docId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'docId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'docId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      docIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'docId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payload',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payload',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      payloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payload',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      quarantinedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quarantined',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition> uidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition> uidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition> uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition> uidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition> uidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterFilterCondition>
      uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }
}

extension SyncQueueItemQueryObject
    on QueryBuilder<SyncQueueItem, SyncQueueItem, QFilterCondition> {}

extension SyncQueueItemQueryLinks
    on QueryBuilder<SyncQueueItem, SyncQueueItem, QFilterCondition> {}

extension SyncQueueItemQuerySortBy
    on QueryBuilder<SyncQueueItem, SyncQueueItem, QSortBy> {
  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      sortByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByCollection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      sortByCollectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByDocId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'docId', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByDocIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'docId', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByQuarantined() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quarantined', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      sortByQuarantinedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quarantined', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension SyncQueueItemQuerySortThenBy
    on QueryBuilder<SyncQueueItem, SyncQueueItem, QSortThenBy> {
  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      thenByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByCollection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      thenByCollectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByDocId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'docId', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByDocIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'docId', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByQuarantined() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quarantined', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      thenByQuarantinedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quarantined', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension SyncQueueItemQueryWhereDistinct
    on QueryBuilder<SyncQueueItem, SyncQueueItem, QDistinct> {
  QueryBuilder<SyncQueueItem, SyncQueueItem, QDistinct> distinctByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attempts');
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QDistinct> distinctByCollection(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'collection', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QDistinct> distinctByDocId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'docId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QDistinct> distinctByLastError(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QDistinct> distinctByPayload(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payload', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QDistinct>
      distinctByQuarantined() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quarantined');
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<SyncQueueItem, SyncQueueItem, QDistinct> distinctByUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension SyncQueueItemQueryProperty
    on QueryBuilder<SyncQueueItem, SyncQueueItem, QQueryProperty> {
  QueryBuilder<SyncQueueItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncQueueItem, int, QQueryOperations> attemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attempts');
    });
  }

  QueryBuilder<SyncQueueItem, String, QQueryOperations> collectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collection');
    });
  }

  QueryBuilder<SyncQueueItem, String, QQueryOperations> docIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'docId');
    });
  }

  QueryBuilder<SyncQueueItem, String?, QQueryOperations> lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<SyncQueueItem, String, QQueryOperations> payloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payload');
    });
  }

  QueryBuilder<SyncQueueItem, bool, QQueryOperations> quarantinedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quarantined');
    });
  }

  QueryBuilder<SyncQueueItem, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<SyncQueueItem, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}
