import 'package:isar_community/isar.dart';

part 'local_record.g.dart';

/// Generic offline-first record used by Noorvia.
///
/// Keeping one small schema gives us an Isar-backed KV/document store without
/// coupling feature models to generated database code. Feature repositories
/// store versioned JSON payloads under a namespace + key.
@collection
class LocalRecord {
  Id id = 0;
  String namespace = '';
  String key = '';
  String json = '{}';
  int updatedAt = 0;
  String syncStatus = 'local';
}
