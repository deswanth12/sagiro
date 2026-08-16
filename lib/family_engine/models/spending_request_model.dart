enum SpendingRequestStatus { pending, approved, declined }

class SpendingRequest {
  final String id;
  final String familyId;
  final String requesterId;
  final String requesterName;
  final String title;
  final double amount;
  final String reason;
  final SpendingRequestStatus status;
  final DateTime createdAt;

  const SpendingRequest({
    required this.id,
    required this.familyId,
    required this.requesterId,
    required this.requesterName,
    required this.title,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'title': title,
      'amount': amount,
      'reason': reason,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SpendingRequest.fromMap(Map<String, dynamic> map) {
    return SpendingRequest(
      id: map['id'] as String,
      familyId: map['familyId'] as String? ?? 'fam_main',
      requesterId: map['requesterId'] as String? ?? 'default_profile',
      requesterName: map['requesterName'] as String? ?? 'Family Member',
      title: map['title'] as String? ?? 'Expense Request',
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'] as String? ?? '',
      status: SpendingRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SpendingRequestStatus.pending,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
