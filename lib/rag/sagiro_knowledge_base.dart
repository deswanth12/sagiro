/// Centralized Structured Knowledge Layer for Sagiro Guide Bot.
/// Provides authoritative feature descriptions, screen locations, and navigation paths.
class SagiroKnowledgeBase {
  static const Map<String, String> features = {
    'safe_today':
        'Safe Today calculates how much money you can safely spend today after reserving funds for your fixed expenses, savings goals, and month-to-date spending.',
    'timeline':
        'Timeline displays your transactions in chronological order. You can view credits, debits, search transactions, view merchant insights, and split expenses.',
    'fixed_expenses':
        'Fixed Expenses lets you track recurring bills, subscriptions, EMI, and rent (Monthly, Weekly, Yearly). Active fixed expenses are automatically reserved in Safe Today.',
    'budgets':
        'Budgets tracks your overall monthly target, category spending limits, and predicted month-end spending velocity.',
    'goals':
        'Goals helps you track savings targets with progress percentages, target dates, and remaining required amounts.',
    'accounts':
        'Accounts lets you track balances across bank accounts (SBI, HDFC, ICICI, Axis), cash, and UPI wallets in one place.',
    'vault':
        'Vault is Sagiro’s local privacy fortress. All data is encrypted on-device with zero plaintext cloud uploads, supporting E2EE .ppbackup file backups.',
    'import_center':
        'Import Center imports bank statements (PDF, CSV, XLS, XLSX, images) using Android Storage Access Framework (SAF) with 100% on-device parsing.',
    'pro':
        'Sagiro Pro unlocks unlimited AI Guide queries, advanced spending insights, custom categories, and priority feature access via ₹499 Lifetime plan.',
    'sms_detection':
        'SMS transaction detection reads incoming bank SMS messages locally on your phone to automatically log debits and credits without sending data to servers.',
  };

  static const Map<String, String> navigationPaths = {
    'expenses': 'Open Timeline to view your transactions.',
    'add_expense': 'Open Timeline → tap + Add Expense.',
    'goals': 'Open Goals to view your savings targets.',
    'add_goal': 'Open Goals → tap + Add Goal.',
    'fixed_expenses': 'Open Budget → Fixed Expenses.',
    'recurring': 'Open Budget → Fixed Expenses.',
    'bills': 'Open Budget → Fixed Expenses.',
    'backup': 'Open Vault → Backup.',
    'restore': 'Open Vault → Restore.',
    'vault': 'Open Vault tab from the main navigation.',
    'settings': 'Open Settings from the main navigation.',
    'accounts': 'Open Accounts overview from the Dashboard or Control Center.',
    'import': 'Open Import Center from Settings or Dashboard.',
  };
}
