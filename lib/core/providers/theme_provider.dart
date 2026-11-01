import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  final StorageService _storageService;
  ThemeMode _themeMode;

  ThemeProvider({required StorageService storageService})
      : _storageService = storageService,
        _themeMode = storageService.loadTheme() == 'light'
            ? ThemeMode.light
            : ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    _storageService.saveTheme(themeMode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _storageService.saveTheme(_themeMode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }
}
