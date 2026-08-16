import '../models/family_models.dart';

class PermissionService {
  /// Checks if member has authority to create/edit shared budgets
  static bool canEditBudget(FamilyMember member) {
    return member.role == FamilyRole.owner || member.role == FamilyRole.adult;
  }

  /// Checks if member can generate family invite codes
  static bool canInviteMembers(FamilyMember member) {
    return member.role == FamilyRole.owner || member.role == FamilyRole.adult;
  }

  /// Checks if member can approve new pending family join requests
  static bool canApproveMembers(FamilyMember member) {
    return member.role == FamilyRole.owner;
  }

  /// Checks if member can delete shared household goals
  static bool canDeleteGoal(FamilyMember member) {
    return member.role == FamilyRole.owner;
  }

  /// Checks if member can manage child monthly allowances
  static bool canManageChildAllowance(FamilyMember member) {
    return member.role == FamilyRole.owner || member.role == FamilyRole.adult;
  }
}
