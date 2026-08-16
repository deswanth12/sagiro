class PurchaseRecord {
  final String orderId;
  final String productId;
  final String purchaseToken;
  final DateTime purchaseTime;
  final DateTime? expiryTime;
  final bool isAcknowledged;
  final String signature;

  PurchaseRecord({
    required this.orderId,
    required this.productId,
    required this.purchaseToken,
    required this.purchaseTime,
    this.expiryTime,
    required this.isAcknowledged,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'productId': productId,
        'purchaseToken': purchaseToken,
        'purchaseTime': purchaseTime.toIso8601String(),
        'expiryTime': expiryTime?.toIso8601String(),
        'isAcknowledged': isAcknowledged,
        'signature': signature,
      };

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      orderId: json['orderId'] ?? '',
      productId: json['productId'] ?? '',
      purchaseToken: json['purchaseToken'] ?? '',
      purchaseTime: DateTime.parse(json['purchaseTime']),
      expiryTime: json['expiryTime'] != null
          ? DateTime.parse(json['expiryTime'])
          : null,
      isAcknowledged: json['isAcknowledged'] ?? false,
      signature: json['signature'] ?? '',
    );
  }
}
