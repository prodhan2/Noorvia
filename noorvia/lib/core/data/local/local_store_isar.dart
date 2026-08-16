import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/local_record.dart';

class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  Isar? _isar;
  Future<void>? _opening;

  bool get isReady => _isar?.isOpen ?? false;

  Future<void> init() => _opening ??= _open();

  Future<void> _open() async {
    if (_isar?.isOpen == true) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [LocalRecordSchema],
      directory: dir.path,
      name: 'noorvia_offline',
      inspector: false,
    );
  }

  /// Stable positive 63-bit FNV-1a id for namespace/key pairs.
  int _idFor(String namespace, String key) {
    const int offset = 0xcbf29ce484222325;
    const int prime = 0x100000001b3;
    var hash = offset;
    for (final unit in '$namespace::$key'.codeUnits) {
      hash ^= unit;
      hash = (hash * prime) & 0x7FFFFFFFFFFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }

  Future<void> putJson(
    String namespace,
    String key,
    Map<String, dynamic> value, {
    String syncStatus = 'local',
  }) async {
    await init();
    final db = _isar;
    if (db == null) return;
    final record = LocalRecord()
      ..id = _idFor(namespace, key)
      ..namespace = namespace
      ..key = key
      ..json = jsonEncode(value)
      ..updatedAt = DateTime.now().millisecondsSinceEpoch
      ..syncStatus = syncStatus;
    await db.writeTxn(() async => db.localRecords.put(record));
  }

  Future<Map<String, dynamic>?> getJson(String namespace, String key) async {
    await init();
    final db = _isar;
    if (db == null) return null;
    final record = await db.localRecords.get(_idFor(namespace, key));
    if (record == null || record.namespace != namespace || record.key != key) {
      return null;
    }
    try {
      final decoded = jsonDecode(record.json);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String namespace, String key) async {
    await init();
    final db = _isar;
    if (db == null) return;
    await db.writeTxn(() async => db.localRecords.delete(_idFor(namespace, key)));
  }

  /// Returns all JSON documents in a namespace. This deliberately filters in
  /// Dart so the generic store does not need schema-specific query extensions.
  Future<Map<String, Map<String, dynamic>>> listJson(String namespace) async {
    await init();
    final db = _isar;
    if (db == null) return const {};
    final records = await db.localRecords.where().findAll();
    final result = <String, Map<String, dynamic>>{};
    for (final record in records) {
      if (record.namespace != namespace) continue;
      try {
        final decoded = jsonDecode(record.json);
        if (decoded is Map) {
          result[record.key] = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> clearNamespace(String namespace) async {
    await init();
    final db = _isar;
    if (db == null) return;
    final records = await db.localRecords.where().findAll();
    final ids = records
        .where((record) => record.namespace == namespace)
        .map((record) => record.id)
        .toList();
    if (ids.isEmpty) return;
    await db.writeTxn(() async => db.localRecords.deleteAll(ids));
  }
}
