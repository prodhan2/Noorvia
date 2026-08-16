// GENERATED-COMPATIBLE CODE - DO NOT MODIFY BY HAND
// This compact schema intentionally omits query convenience extensions because
// Noorvia addresses records by deterministic Isar Id.

part of 'local_record.dart';

extension GetLocalRecordCollection on Isar {
  IsarCollection<LocalRecord> get localRecords => this.collection<LocalRecord>();
}

const LocalRecordSchema = CollectionSchema(
  name: r'LocalRecord',
  id: 6328055699618027931,
  properties: {
    r'json': PropertySchema(id: 0, name: r'json', type: IsarType.string),
    r'key': PropertySchema(id: 1, name: r'key', type: IsarType.string),
    r'namespace': PropertySchema(id: 2, name: r'namespace', type: IsarType.string),
    r'syncStatus': PropertySchema(id: 3, name: r'syncStatus', type: IsarType.string),
    r'updatedAt': PropertySchema(id: 4, name: r'updatedAt', type: IsarType.long),
  },
  estimateSize: _localRecordEstimateSize,
  serialize: _localRecordSerialize,
  deserialize: _localRecordDeserialize,
  deserializeProp: _localRecordDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _localRecordGetId,
  getLinks: _localRecordGetLinks,
  attach: _localRecordAttach,
  version: '3.3.2',
);

int _localRecordEstimateSize(
  LocalRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.json.length * 3;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.namespace.length * 3;
  bytesCount += 3 + object.syncStatus.length * 3;
  return bytesCount;
}

void _localRecordSerialize(
  LocalRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.json);
  writer.writeString(offsets[1], object.key);
  writer.writeString(offsets[2], object.namespace);
  writer.writeString(offsets[3], object.syncStatus);
  writer.writeLong(offsets[4], object.updatedAt);
}

LocalRecord _localRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalRecord();
  object.id = id;
  object.json = reader.readString(offsets[0]);
  object.key = reader.readString(offsets[1]);
  object.namespace = reader.readString(offsets[2]);
  object.syncStatus = reader.readString(offsets[3]);
  object.updatedAt = reader.readLong(offsets[4]);
  return object;
}

P _localRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return reader.readString(offset) as P;
    case 1:
      return reader.readString(offset) as P;
    case 2:
      return reader.readString(offset) as P;
    case 3:
      return reader.readString(offset) as P;
    case 4:
      return reader.readLong(offset) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localRecordGetId(LocalRecord object) => object.id;
List<IsarLinkBase<dynamic>> _localRecordGetLinks(LocalRecord object) => [];
void _localRecordAttach(IsarCollection<dynamic> col, Id id, LocalRecord object) {
  object.id = id;
}
