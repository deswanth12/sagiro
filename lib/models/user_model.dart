class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.isPremium,
    required this.createdAt,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'isPremium': isPremium,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin.toIso8601String(),
      };
}

class LocalUserModel {
  final String deviceId;
  final String currency;
  final String themeMode;
  final double monthlyBudget;
  final bool isGuestMode;

  LocalUserModel({
    required this.deviceId,
    this.currency = 'INR (₹)',
    this.themeMode = 'Deep Obsidian',
    required this.monthlyBudget,
    this.isGuestMode = true,
  });
}
