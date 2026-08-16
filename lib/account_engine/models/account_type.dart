enum AccountCategory {
  savings,
  salary,
  current,
  creditCard,
  loan,
  wallet,
}

extension AccountCategoryExtension on AccountCategory {
  String get displayName {
    switch (this) {
      case AccountCategory.savings:
        return 'Savings Account';
      case AccountCategory.salary:
        return 'Salary Account';
      case AccountCategory.current:
        return 'Current Account';
      case AccountCategory.creditCard:
        return 'Credit Card';
      case AccountCategory.loan:
        return 'Loan Account';
      case AccountCategory.wallet:
        return 'UPI Wallet / Cash';
    }
  }

  String get defaultEmoji {
    switch (this) {
      case AccountCategory.savings:
        return '🏦';
      case AccountCategory.salary:
        return '💼';
      case AccountCategory.current:
        return '🏢';
      case AccountCategory.creditCard:
        return '💳';
      case AccountCategory.loan:
        return '📑';
      case AccountCategory.wallet:
        return '📱';
    }
  }

  bool get isLiability =>
      this == AccountCategory.creditCard || this == AccountCategory.loan;
}
