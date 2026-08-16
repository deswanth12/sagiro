import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'billing_constants.dart';
import 'models/purchase_record.dart';

class PurchaseManager {
  final InAppPurchase? _iapInstance;
  InAppPurchase get _iap => _iapInstance ?? InAppPurchase.instance;

  PurchaseManager({InAppPurchase? iap}) : _iapInstance = iap;

  Future<bool> isStoreAvailable() async {
    return await _iap.isAvailable();
  }

  Future<List<ProductDetails>> queryProductDetails(Set<String> skus) async {
    final response = await _iap.queryProductDetails(skus);
    return response.productDetails;
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    final purchaseParam = PurchaseParam(productDetails: productDetails);

    if (productDetails.id == BillingConstants.skuProLifetime) {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
  }

  PurchaseRecord parsePurchaseDetails(PurchaseDetails purchase) {
    return PurchaseRecord(
      orderId: purchase.purchaseID ?? '',
      productId: purchase.productID,
      purchaseToken: purchase.verificationData.serverVerificationData,
      purchaseTime: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(purchase.transactionDate ?? '') ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      expiryTime: purchase.productID == BillingConstants.skuProYearly
          ? DateTime.now().add(const Duration(days: 365))
          : (purchase.productID == BillingConstants.skuProMonthly
              ? DateTime.now().add(const Duration(days: 30))
              : null),
      isAcknowledged: purchase.pendingCompletePurchase == false,
      signature: purchase.verificationData.localVerificationData,
    );
  }
}
