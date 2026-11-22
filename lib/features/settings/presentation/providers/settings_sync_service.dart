import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/pending_theme_storage.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/repositories/settings_repository.dart';

enum SettingsSyncState { idle, pending, syncing, synced, failed }

class SettingsSyncService extends ChangeNotifier {
  SettingsSyncService({
    required this.userId,
    SettingsRepository? repository,
    this._storage,
    this._pendingStorage,
  }) : _repository = repository ?? FirestoreSettingsRepository();

  final String userId;
  final dynamic _repository;
  final StorageService? _storage;
  final PendingThemeStorage? _pendingStorage;

  SettingsSyncState _state = SettingsSyncState.idle;
  SettingsSyncState get state => _state;

  String? _lastError;
  String? get lastError => _lastError;

  int _generation = 0;
  bool _inFlight = false;
  String? _pendingValue;

  Future<StorageService> get _store async =>
      _storage ?? await StorageService.create();

  Future<PendingThemeStorage> get _pendingStore async =>
      _pendingStorage ??
      PendingThemeStorage(await SharedPreferences.getInstance());

  Future<void> saveTheme(String theme) async {
    final storage = await _store;
    await storage.saveTheme(theme);

    final pending = await _pendingStore;
    await pending.savePendingTheme(userId, theme);

    _generation++;
    final gen = _generation;
    _pendingValue = theme;
    _state = SettingsSyncState.pending;
    notifyListeners();
    _kick(gen);
  }

  void _kick(int gen) {
    if (_inFlight) return;
    _run(gen);
  }

  Future<void> _run(int gen) async {
    if (_pendingValue == null) return;
    _inFlight = true;
    _state = SettingsSyncState.syncing;
    notifyListeners();
    final value = _pendingValue!;
    try {
      await _repository.syncSettings(userId: userId, theme: value);
      if (gen != _generation) {
        _inFlight = false;
        _kick(_generation);
        return;
      }
      final pending = await _pendingStore;
      await pending.clearPendingTheme(userId);
      _pendingValue = null;
      _state = SettingsSyncState.synced;
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
      _state = SettingsSyncState.failed;
    } finally {
      _inFlight = false;
      notifyListeners();
      if (_pendingValue != null) _kick(_generation);
    }
  }

  Future<void> recover() async {
    final pending = await _pendingStore;
    final pendingData = pending.loadPendingTheme(userId);
    if (pendingData != null) {
      await saveTheme(pendingData['theme']!);
    }
  }
}
