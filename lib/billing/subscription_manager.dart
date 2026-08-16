import 'package:firebase_auth/firebase_auth.dart';
import 'billing_repository.dart';
import 'feature_access.dart';
import 'models/premium_entitlement.dart';

class SubscriptionManager {
  final BillingRepository _repository;
  PremiumEntitlement _currentEntitlement = PremiumEntitlement.free;

  SubscriptionManager({BillingRepository? repository})
      : _repository = repository ?? BillingRepository();

  PremiumEntitlement get currentEntitlement => _currentEntitlement;
  bool get isPro => _currentEntitlement.isActive;

  Future<void> initialize() async {
    _currentEntitlement = await _repository.loadEntitlement();
    FeatureAccess.updateEntitlement(_currentEntitlement);

    // Sync with Firebase Auth user if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentEntitlement.isEntitled) {
      await _repository.saveEntitlement(
        planType: _currentEntitlement.planType,
        purchaseToken: _currentEntitlement.purchaseToken ?? 'firebase_synced',
        purchaseDate: _currentEntitlement.purchaseDate ?? DateTime.now(),
        expiryDate: _currentEntitlement.expiryDate,
        firebaseUid: user.uid,
      );
    }
  }

  Future<void> setEntitlement(PremiumEntitlement entitlement) async {
    _currentEntitlement = entitlement;
    FeatureAccess.updateEntitlement(entitlement);
    if (entitlement.isEntitled) {
      await _repository.saveEntitlement(
        planType: entitlement.planType,
        purchaseToken: entitlement.purchaseToken ?? 'token',
        purchaseDate: entitlement.purchaseDate ?? DateTime.now(),
        expiryDate: entitlement.expiryDate,
        firebaseUid: FirebaseAuth.instance.currentUser?.uid,
      );
    } else {
      await _repository.clearEntitlement();
    }
  }
}
