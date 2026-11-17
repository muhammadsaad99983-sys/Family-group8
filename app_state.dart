import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person.dart';
import '../services/vault.dart';
import 'strings.dart';

class AppState extends ChangeNotifier {
  List<Person> people = [];
  ThemeMode themeMode = ThemeMode.system;
  String lang = 'ur';
  bool loggedIn = false;
  bool hasPassword = false;
  late SharedPreferences _p;

  String tr(String k) => trLang(lang, k);

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    lang = _p.getString('lang') ?? 'ur';
    themeMode = ThemeMode.values[_p.getInt('theme') ?? 0];
    hasPassword = await Vault.hasPassword();
  }

  Future<bool> login(String pw) async {
    if (!await Vault.verify(pw)) return false;
    people = await Vault.load();
    loggedIn = true;
    notifyListeners();
    return true;
  }

  Future<void> setupPassword(String pw) async {
    await Vault.setPassword(pw);
    hasPassword = true;
    people = await Vault.load();
    loggedIn = true;
    notifyListeners();
  }

  Future<bool> changePassword(String old, String nw) async {
    if (!await Vault.verify(old)) return false;
    await Vault.setPassword(nw);
    return true;
  }

  void logout() {
    loggedIn = false;
    people = [];
    notifyListeners();
  }

  Future<void> upsert(Person p) async {
    final i = people.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      people[i] = p;
    } else {
      people.add(p);
    }
    await Vault.save(people);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    people.removeWhere((x) => x.id == id);
    await Vault.save(people);
    notifyListeners();
  }

  void setLang(String l) {
    lang = l;
    _p.setString('lang', l);
    notifyListeners();
  }

  void setTheme(ThemeMode m) {
    themeMode = m;
    _p.setInt('theme', m.index);
    notifyListeners();
  }
}
