class Settings {
  final String userId;
  String theme;

  Settings({
    required this.userId,
    this.theme = 'dark', // Default theme
  });

  // Factory constructor for creating Settings from Firestore data
  factory Settings.fromFirestore(Map<String, dynamic> data) {
    return Settings(
      userId: data['userId'] ?? '',
      theme: data['theme'] ?? 'dark',
    );
  }

  // Method to convert Settings to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'theme': theme,
    };
  }
}