class User {
  final String userId;
  String theme;

  User({
    required this.userId,
    this.theme = 'dark', // Default theme
  });

  // Factory constructor for creating a User from Firestore data
  factory User.fromFirestore(Map<String, dynamic> data) {
    return User(
      userId: data['userId'] ?? '',
      theme: data['theme'] ?? 'dark',
    );
  }

  // Method to convert User to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'theme': theme,
    };
  }
}