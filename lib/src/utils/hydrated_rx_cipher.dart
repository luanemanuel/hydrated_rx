import 'dart:typed_data';

import 'package:hive/hive.dart';

abstract class HydratedRXCipher implements HiveCipher {
  @override
  int calculateKeyCrc();

  @override
  int decrypt(
    Uint8List inp,
    int inpOff,
    int inpLength,
    Uint8List out,
    int outOff,
  );

  @override
  int encrypt(
    Uint8List inp,
    int inpOff,
    int inpLength,
    Uint8List out,
    int outOff,
  );

  @override
  int maxEncryptedSize(Uint8List inp);
}
