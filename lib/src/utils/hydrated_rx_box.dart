abstract class HydratedRXBox {
  Future<void> write(String key, dynamic value);

  dynamic read(String key);

  Future<void> delete(String key);

  Future<void> clear();
}
