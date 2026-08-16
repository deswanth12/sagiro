import '../models/user_model.dart';

/// AuthPermissionService — Centralized authorization gate.
///
/// Finding 3 cleanup: removed three dead stubs that were never wired into UI
/// or feature guards (canAccessPremium, canManageFamily, canViewAdminPanel).
/// If premium-gating is needed in future, wire through SubscriptionManager
/// rather than re-adding email-verification proxies here.
class AuthPermissionService {
  /// Centralized check for account deletion permissions.
  /// Any authenticated user (guest or signed-in) may delete their own account.
  static bool canDeleteAccount(UserModel? user) {
    if (user == null) return false;
    return true;
  }
}
