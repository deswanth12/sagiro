class UserModel {
  final String userId;
  final String name;
  final String email;
  final String? profilePhotoUrl;
  final String provider;
  final bool isEmailVerified;
  final String preferredCurrency;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
    required this.provider,
    required this.isEmailVerified,
    required this.preferredCurrency,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'email': email,
        'profilePhotoUrl': profilePhotoUrl,
        'provider': provider,
        'isEmailVerified': isEmailVerified,
        'preferredCurrency': preferredCurrency,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        profilePhotoUrl: map['profilePhotoUrl'],
        provider: map['provider'] ?? 'email',
        isEmailVerified: map['isEmailVerified'] ?? false,
        preferredCurrency: map['preferredCurrency'] ?? 'INR',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
      );
}

class UserSession {
  final String sessionId;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final bool isCurrentDevice;
  final DateTime lastActiveAt;

  const UserSession({
    required this.sessionId,
    required this.deviceName,
    required this.platform,
    required this.ipAddress,
    required this.isCurrentDevice,
    required this.lastActiveAt,
  });
}
