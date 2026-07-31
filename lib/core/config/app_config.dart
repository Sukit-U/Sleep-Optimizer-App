class AppConfig {
  AppConfig._();

  /// Single source of truth for the default user ID.
  /// The app has no authentication yet, so all records are saved under this ID.
  static const String defaultUserId = 'default_user';
}
