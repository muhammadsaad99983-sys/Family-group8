import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/person.dart';

/// Encrypted local storage (AES-256) + password hashing.
class Vault {
  static const _s = FlutterSecureStorage();

  static String _hash(String pw, String salt) {
    var h = utf8.encode('$salt:$pw');
    for (var i = 0; i < 20000; i++) {
      h = sha256.convert(h).bytes;
    }
    return base64Encode(h);
  }

  static Future<bool> hasPassword() async =>
      (await _s.read(key: 'pw_hash')) != null;

  static Future<void> setPassword(String pw) async {
    final r = Random.secure();
    final salt = base64Encode(List<int>.generate(16, (_) => r.nextInt(256)));
    await _s.write(key: 'pw_salt', value: salt);
    await _s.write(key: 'pw_hash', value: _hash(pw, salt));
  }

  static Future<bool> verify(String pw) async {
    final salt = await _s.read(key: 'pw_salt');
    final hash = await _s.read(key: 'pw_hash');
    if (salt == null || hash == null) return false;
    return _hash(pw, salt) == hash;
  }

  static Future<enc.Key> _key() async {
    var k = await _s.read(key: 'data_key');
    if (k == null) {
      k = base64Encode(enc.Key.fromSecureRandom(32).bytes);
      await _s.write(key: 'data_key', value: k);
    }
    return enc.Key(base64Decode(k));
  }

  static Future<Directory> dir() => getApplicationDocumentsDirectory();

  static Future<File> _file() async =>
      File('${(await dir()).path}/family.dat');

  static Future<List<Person>> load() async {
    final f = await _file();
    if (!await f.exists()) return [];
    try {
      final parts = (await f.readAsString()).split(':');
      final e = enc.Encrypter(enc.AES(await _key(), mode: enc.AESMode.cbc));
      final txt = e.decrypt64(parts[1], iv: enc.IV.fromBase64(parts[0]));
      return (jsonDecode(txt) as List)
          .map((x) => Person.fromJson(Map<String, dynamic>.from(x)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Person> people) async {
    final iv = enc.IV.fromSecureRandom(16);
    final e = enc.Encrypter(enc.AES(await _key(), mode: enc.AESMode.cbc));
    final data = e.encrypt(jsonEncode(people.map((p) => p.toJson()).toList()),
        iv: iv);
    await (await _file()).writeAsString('${iv.base64}:${data.base64}');
  }
}
