import 'dart:convert';

enum SplitParticipantStatus { pending, paid }

class SplitBillParticipant {
  const SplitBillParticipant({
    required this.id,
    required this.name,
    required this.shareAmount,
    this.status = SplitParticipantStatus.pending,
    this.paidAt,
    this.qrPayload,
  });

  final String id;
  final String name;
  final double shareAmount;
  final SplitParticipantStatus status;
  final DateTime? paidAt;
  final String? qrPayload;

  bool get isPaid => status == SplitParticipantStatus.paid;

  SplitBillParticipant copyWith({
    String? id,
    String? name,
    double? shareAmount,
    SplitParticipantStatus? status,
    DateTime? paidAt,
    String? qrPayload,
  }) {
    return SplitBillParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      shareAmount: shareAmount ?? this.shareAmount,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      qrPayload: qrPayload ?? this.qrPayload,
    );
  }

  String generateQrPayload(String billId, String billTitle) {
    if (qrPayload != null && qrPayload!.isNotEmpty) return qrPayload!;
    final data = {
      'type': 'split_bill_payment',
      'billId': billId,
      'participantId': id,
      'participantName': name,
      'amount': shareAmount,
      'billTitle': billTitle,
    };
    return jsonEncode(data);
  }

  String get monogram {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class SplitBill {
  const SplitBill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.category,
    required this.createdAt,
    required this.createdBy,
    required this.participants,
  });

  final String id;
  final String title;
  final double totalAmount;
  final String category;
  final DateTime createdAt;
  final String createdBy;
  final List<SplitBillParticipant> participants;

  double get paidAmount {
    return participants
        .where((p) => p.isPaid)
        .fold(0.0, (sum, p) => sum + p.shareAmount);
  }

  double get remainingBalance {
    final rem = totalAmount - paidAmount;
    return rem < 0 ? 0.0 : rem;
  }

  int get paidCount => participants.where((p) => p.isPaid).length;

  int get totalCount => participants.length;

  bool get isSettled => remainingBalance <= 0.001;

  double get progress => totalAmount <= 0 ? 1.0 : (paidAmount / totalAmount).clamp(0.0, 1.0);

  SplitBill copyWith({
    String? id,
    String? title,
    double? totalAmount,
    String? category,
    DateTime? createdAt,
    String? createdBy,
    List<SplitBillParticipant>? participants,
  }) {
    return SplitBill(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
    );
  }
}
