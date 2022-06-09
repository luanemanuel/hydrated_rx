import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart'; // ignore: implementation_imports
import 'package:hydrated_rx/src/utils/hydrated_rx_box.dart';
import 'package:hydrated_rx/src/utils/hydrated_rx_cipher.dart';
import 'package:synchronized/synchronized.dart';

class HydratedRxStorage implements HydratedRXBox {
  HydratedRxStorage(this._box);

  final Box _box;
  static final _lock = Lock();
  static HydratedRxStorage? _instance;
  static late HiveInterface hive;

  static Future<HydratedRxStorage> build({
    required Directory storageDir,
    HydratedRXCipher? encryptionCipher,
  }) {
    return _lock.synchronized(() async {
      if (_instance != null) {
        return _instance!;
      }

      Box<dynamic> box;
      hive = HiveImpl();

      hive.init(storageDir.path);
      box = await hive.openBox(
        'hydrated_rx',
        encryptionCipher: encryptionCipher,
      );

      return _instance = HydratedRxStorage(box);
    });
  }

  @override
  Future<void> clear() async {
    if (_box.isOpen) {
      _instance = null;
      return _lock.synchronized(_box.clear);
    }
  }

  @override
  Future<void> delete(String key) async {
    if (_box.isOpen) {
      return _lock.synchronized(() => _box.delete(key));
    }
  }

  @override
  dynamic read(String key) => _box.isOpen ? _box.get(key) : null;

  @override
  Future<void> write(String key, dynamic value) async {
    if (_box.isOpen) {
      return _lock.synchronized(() => _box.put(key, value));
    }
  }
}
