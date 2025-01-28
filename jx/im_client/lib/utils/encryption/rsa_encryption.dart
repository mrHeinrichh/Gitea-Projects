import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import "package:pointycastle/export.dart";
import "package:asn1lib/asn1lib.dart";

List<int> decodePEM(String pem) {
  var startsWith = [
    "-----BEGIN PUBLIC KEY-----",
    "-----BEGIN PRIVATE KEY-----",
    "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
    "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
  ];
  var endsWith = [
    "-----END PUBLIC KEY-----",
    "-----END PRIVATE KEY-----",
    "-----END PGP PUBLIC KEY BLOCK-----",
    "-----END PGP PRIVATE KEY BLOCK-----",
  ];
  bool isOpenPgp = pem.contains('BEGIN PGP');

  for (var s in startsWith) {
    if (pem.startsWith(s)) {
      pem = pem.substring(s.length);
    }
  }

  for (var s in endsWith) {
    if (pem.endsWith(s)) {
      pem = pem.substring(0, pem.length - s.length);
    }
  }

  if (isOpenPgp) {
    var index = pem.indexOf('\r\n');
    pem = pem.substring(0, index);
  }

  pem = pem.replaceAll('\n', '');
  pem = pem.replaceAll('\r', '');

  return base64.decode(pem);
}

class RSAEncryption {
  static (String, String) generateKeyPair() {
    var keyParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 1024, 12);

    var secureRandom = FortunaRandom();
    var random = Random.secure();
    List<int> seeds = [];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    var rngParams = ParametersWithRandom(keyParams, secureRandom);
    var k = RSAKeyGenerator();
    k.init(rngParams);
    var v = k.generateKeyPair();
    var kp = AsymmetricKeyPair(v.publicKey as RSAPublicKey, v.privateKey as RSAPrivateKey);
    return (encodePublicKeyToPem(kp.publicKey), encodePrivateKeyToPem(kp.privateKey));
  }

  static String encrypt(String plaintext, String publicKeyString) {
    RSAPublicKey publicKey = parsePublicKeyFromPem(publicKeyString);
    var cipher = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    var cipherBytes = cipher.process(Uint8List.fromList(plaintext.codeUnits));
    return base64.encode(cipherBytes);
  }

  static String decrypt(String ciphertext, String privateKeyString) {
    RSAPrivateKey privateKey = parsePrivateKeyFromPem(privateKeyString);
    var cipherBytes = base64.decode(ciphertext);
    var cipher = RSAEngine()
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    var decrypted = cipher.process(Uint8List.fromList(cipherBytes));

    return String.fromCharCodes(decrypted);
  }

  static String signMessage(String message, String privateKey) {
    // Hash the message
    final hashedMessage = sha256.convert(utf8.encode(message)).bytes;
    RSAPrivateKey pk = parsePrivateKeyFromPem(privateKey);
    final signer = Signer("SHA-256/RSA")
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(pk));
    RSASignature signature = signer.generateSignature(Uint8List.fromList(hashedMessage)) as RSASignature;
    Uint8List bytes = signature.bytes;
    return base64Encode(bytes);
  }


  static String getSignatureText(String signature) {
    Uint8List bytes = base64Decode(signature);
    String updated = "";
    for (int i = 0;i<bytes.length;i++) {
      if (i != 0) {
        if (i % 8 == 0 ) {
          updated += "\n";
        } else{
          updated += "  ";
        }
      }
      int x = bytes[i];
      updated += x.toRadixString(16);
    }
    return updated;
  }

  static bool verifySignature(String message, String publicKey, String base64Signature) {
    Uint8List bytes = base64Decode(base64Signature);
    RSASignature signature = RSASignature(bytes);
    final hashedMessage = sha256.convert(utf8.encode(message)).bytes;
    RSAPublicKey pubK = parsePublicKeyFromPem(publicKey);
    final signer = Signer("SHA-256/RSA")
      ..init(false, PublicKeyParameter<RSAPublicKey>(pubK));
    var verified = signer.verifySignature(Uint8List.fromList(hashedMessage), signature);
    return verified;
  }

  static RSAPublicKey parsePublicKeyFromPem(pemString) {
    List<int> publicKeyDER = decodePEM(pemString);
    var asn1Parser = ASN1Parser(Uint8List.fromList(publicKeyDER));
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    var publicKeyBitString = topLevelSeq.elements[1];

    var publicKeyAsn = ASN1Parser(publicKeyBitString.contentBytes());
    ASN1Sequence publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
    var modulus = publicKeySeq.elements[0] as ASN1Integer;
    var exponent = publicKeySeq.elements[1] as ASN1Integer;

    RSAPublicKey rsaPublicKey = RSAPublicKey(
        modulus.valueAsBigInteger,
        exponent.valueAsBigInteger
    );

    return rsaPublicKey;
  }

  static bool isValidPrivateKey(String decrypted) {
    return decrypted.contains("-----BEGIN PRIVATE KEY-----");
  }

  static RSAPrivateKey parsePrivateKeyFromPem(pemString) {
    List<int> privateKeyDER = decodePEM(pemString);
    var asn1Parser = ASN1Parser(Uint8List.fromList(privateKeyDER));
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    var privateKey = topLevelSeq.elements[2];

    asn1Parser = ASN1Parser(privateKey.contentBytes());
    var pkSeq = asn1Parser.nextObject() as ASN1Sequence;

    var modulus = pkSeq.elements[1] as ASN1Integer;
    var privateExponent = pkSeq.elements[3] as ASN1Integer;
    var p = pkSeq.elements[4] as ASN1Integer;
    var q = pkSeq.elements[5] as ASN1Integer;

    RSAPrivateKey rsaPrivateKey = RSAPrivateKey(
        modulus.valueAsBigInteger,
        privateExponent.valueAsBigInteger,
        p.valueAsBigInteger,
        q.valueAsBigInteger
    );

    return rsaPrivateKey;
  }

  static String encodePublicKeyToPem(RSAPublicKey publicKey) {
    var algorithmSeq = ASN1Sequence();
    var algorithmAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1]));
    var paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    var publicKeySeq = ASN1Sequence();
    publicKeySeq.add(ASN1Integer(publicKey.modulus!));
    publicKeySeq.add(ASN1Integer(publicKey.exponent!));
    var publicKeySeqBitString = ASN1BitString(Uint8List.fromList(publicKeySeq.encodedBytes));

    var topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqBitString);
    var dataBase64 = base64.encode(topLevelSeq.encodedBytes);

    return """-----BEGIN PUBLIC KEY-----\r\n$dataBase64\r\n-----END PUBLIC KEY-----""";
  }

  static String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    var version = ASN1Integer(BigInt.from(0));

    var algorithmSeq = ASN1Sequence();
    var algorithmAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1]));
    var paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    var privateKeySeq = ASN1Sequence();
    var modulus = ASN1Integer(privateKey.n!);
    var publicExponent = ASN1Integer(BigInt.parse('65537'));
    var privateExponent = ASN1Integer(privateKey.d!);
    var p = ASN1Integer(privateKey.p!);
    var q = ASN1Integer(privateKey.q!);
    var dP = privateKey.d! % (privateKey.p! - BigInt.from(1));
    var exp1 = ASN1Integer(dP);
    var dQ = privateKey.d! % (privateKey.q! - BigInt.from(1));
    var exp2 = ASN1Integer(dQ);
    var iQ = privateKey.q!.modInverse(privateKey.p!);
    var co = ASN1Integer(iQ);

    privateKeySeq.add(version);
    privateKeySeq.add(modulus);
    privateKeySeq.add(publicExponent);
    privateKeySeq.add(privateExponent);
    privateKeySeq.add(p);
    privateKeySeq.add(q);
    privateKeySeq.add(exp1);
    privateKeySeq.add(exp2);
    privateKeySeq.add(co);
    var publicKeySeqOctetString = ASN1OctetString(Uint8List.fromList(privateKeySeq.encodedBytes));

    var topLevelSeq = ASN1Sequence();
    topLevelSeq.add(version);
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqOctetString);
    var dataBase64 = base64.encode(topLevelSeq.encodedBytes);

    return """-----BEGIN PRIVATE KEY-----\r\n$dataBase64\r\n-----END PRIVATE KEY-----""";
  }
}