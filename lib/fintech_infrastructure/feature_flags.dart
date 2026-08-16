class FeatureFlagsEngine {
  static final Map<String, bool> _flags = {
    'family_mode': true,
    'premium_ai': true,
    'beta_reports': true,
    'expense_prediction': true,
    'shared_shopping_list': false,
  };

  static bool isEnabled(String flagKey) {
    return _flags[flagKey] ?? false;
  }

  static void setFlag(String flagKey, bool enabled) {
    _flags[flagKey] = enabled;
  }
}
