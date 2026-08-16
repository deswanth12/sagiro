import '../models/user_model.dart';

class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final String? errorMessage;

  const AuthResult({
    required this.isSuccess,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.errorMessage,
  });
}

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  UserModel? _currentUser;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  /// Registration Flow
  Future<AuthResult> register(
      {required String name,
      required String email,
      required String password}) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      return const AuthResult(
          isSuccess: false, errorMessage: 'All fields are required.');
    }
    if (password.length < 6) {
      return const AuthResult(
          isSuccess: false,
          errorMessage: 'Password must be at least 6 characters.');
    }

    _currentUser = UserModel(
      userId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      provider: 'email',
      isEmailVerified: false,
      preferredCurrency: 'INR',
      createdAt: DateTime.now(),
    );
    _isAuthenticated = true;

    return AuthResult(
      isSuccess: true,
      user: _currentUser,
    );
  }

  /// Login Flow
  Future<AuthResult> login(
      {required String email, required String password}) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return const AuthResult(
          isSuccess: false, errorMessage: 'Email and password are required.');
    }
    if (password.length < 6) {
      return const AuthResult(
          isSuccess: false, errorMessage: 'Invalid email or password.');
    }

    _currentUser = UserModel(
      userId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: email.split('@').first,
      email: email,
      provider: 'email',
      isEmailVerified: true,
      preferredCurrency: 'INR',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    _isAuthenticated = true;

    return AuthResult(
      isSuccess: true,
      user: _currentUser,
    );
  }

  /// Refresh Token Rotation
  Future<AuthResult> rotateRefreshToken(String oldRefreshToken) async {
    if (!_isAuthenticated || _currentUser == null) {
      return const AuthResult(
          isSuccess: false, errorMessage: 'Not authenticated.');
    }

    return AuthResult(
      isSuccess: true,
      user: _currentUser,
    );
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
  }

  /// Get Active Sessions
  List<UserSession> getActiveSessions() {
    if (!_isAuthenticated) return [];
    return [
      UserSession(
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceName: 'Current Device',
        platform: 'Android',
        ipAddress: '',
        isCurrentDevice: true,
        lastActiveAt: DateTime.now(),
      ),
    ];
  }
}
