import 'package:encrypt/encrypt.dart';

class AesEncryption {
  late final Key key;
  late final IV iv;
  late final Encrypter encrypter;

  AesEncryption(String aesEnabledString) { // 32位 = AES128 // 64位 = AES256
    key = Key.fromUtf8(aesEnabledString); //其余使用时使用cipherKey获取
    iv = IV.fromLength(16);    // AES block size is 16 bytes
    encrypter = Encrypter(AES(key));
  }

  String encrypt(String plaintext) {
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return encrypted.base64;
  }

  String decrypt(String ciphertext) {
    final Encrypted encrypted = Encrypted.fromBase64(ciphertext);
    final decrypted = encrypter.decrypt(encrypted, iv:iv);
    return decrypted;
  }
}