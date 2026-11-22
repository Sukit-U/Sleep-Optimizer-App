import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class LocaleProvider with ChangeNotifier {
  final StorageService _storageService;
  Locale _locale;

  LocaleProvider({required this._storageService})
    : _locale = const Locale('th');

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    // Thai is the permanent application language. Legacy persisted English
    // locale settings are intentionally ignored.
    _locale = const Locale('th');
    notifyListeners();
  }

  Future<void> setLocale(String localeCode) async {
    _locale = const Locale('th');
    await _storageService.saveLocale('th');
    notifyListeners();
  }
}

