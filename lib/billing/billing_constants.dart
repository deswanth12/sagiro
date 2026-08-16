class BillingConstants {
  // Product SKUs registered in Google Play Console
  static const String skuProMonthly = 'com.sagiro.pro.monthly';
  static const String skuProYearly = 'com.sagiro.pro.yearly';
  static const String skuProLifetime = 'com.sagiro.pro.lifetime';

  static const Set<String> allSkus = {
    skuProMonthly,
    skuProYearly,
    skuProLifetime,
  };

  // Secure Storage Keys
  static const String keyPlanType = 'sec_billing_plan_type';
  static const String keyPurchaseToken = 'sec_billing_purchase_token';
  static const String keyPurchaseDate = 'sec_billing_purchase_date';
  static const String keyExpiryDate = 'sec_billing_expiry_date';
  static const String keyPremiumStatus = 'sec_billing_premium_status';
  static const String keyFirebaseUid = 'sec_billing_firebase_uid';

  // Error Messages
  static const String errPlayStoreUnavailable =
      'Google Play Store services are unavailable on this device.';
  static const String errItemUnavailable =
      'The selected subscription plan is currently unavailable in the Play Store.';
  static const String errPurchaseCanceled = 'The purchase flow was canceled.';
  static const String errAlreadyOwned =
      'You already own an active subscription for this plan.';
  static const String errVerificationFailed =
      'Purchase verification failed. Please try restoring your purchases.';
}
