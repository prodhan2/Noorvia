/// Web/test fallback. Noorvia's Android/iOS app uses the Isar implementation.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  Future<void> init() async {}
  bool get isReady => false;

  Future<void> putJson(
    String namespace,
    String key,
    Map<String, dynamic> value, {
    String syncStatus = 'local',
  }) async {}

  Future<Map<String, dynamic>?> getJson(String namespace, String key) async => null;
  Future<void> delete(String namespace, String key) async {}
  Future<Map<String, Map<String, dynamic>>> listJson(String namespace) async => const {};
  Future<void> clearNamespace(String namespace) async {}
}
