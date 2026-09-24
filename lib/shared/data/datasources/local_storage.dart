import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local simples (chave → JSON) usada no lugar de uma API.
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorage> create() async => LocalStorage(await SharedPreferences.getInstance());

  List<Map<String, dynamic>>? readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) => _prefs.setString(key, jsonEncode(value));

  String? readString(String key) => _prefs.getString(key);

  Future<void> writeString(String key, String? value) =>
      value == null ? _prefs.remove(key) : _prefs.setString(key, value);

  bool readBool(String key) => _prefs.getBool(key) ?? false;

  Future<void> writeBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> clear() => _prefs.clear();
}
