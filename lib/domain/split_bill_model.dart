import 'dart:convert';

// ---------------------------------------------------------------------------
// Enumerations
// ---------------------------------------------------------------------------

enum SplitParticipantStatus { pending, paid }

/// How the total is divided among participants.
enum SplitMode {
  /// Divide the total equally among everyone (host included).
  equal,

  /// Each participant has a manually entered fixed amount.
  custom,

  /// Each participant has a manually entered percentage; they must sum to 100.
  percentage,
}

// ---------------------------------------------------------------------------
// SplitBillParticipant
// ---------------------------------------------------------------------------

class SplitBillParticipant {
  const SplitBillParticipant({
    required this.id,
    required this.name,
    required this.shareAmount,
    this.sharePercentage,
    this.note,
    this.status = SplitParticipantStatus.pending,
    this.paidAt,
    this.qrPayload,
  });

  final String id;
  final String name;

  /// Resolved monetary share (always populated regardless of split mode).
  final double shareAmount;

  /// Only set when [SplitBill.splitMode] is [SplitMode.percentage].
  final double? sharePercentage;

  /// Optional free-text note visible on the participant's row (e.g. "paid
  /// by card", "owes from last trip").
  final String? note;

  final SplitParticipantStatus status;
  final DateTime? paidAt;

  /// Pre-built JSON QR payload.  Null until [generateQrPayload] is called.
  final String? qrPayload;

  // ---- Computed -----------------------------------------------------------

  bool get isPaid => status == SplitParticipantStatus.paid;

  String get monogram {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ---- QR -----------------------------------------------------------------

  /// Returns the JSON string that encodes this participant's payment details.
  /// On a real device this value is embedded in the QR code and scanned back.
  String generateQrPayload(String billId, String billTitle) {
    if (qrPayload != null && qrPayload!.isNotEmpty) return qrPayload!;
    return jsonEncode({
      'type': 'split_bill_payment',
      'billId': billId,
      'participantId': id,
      'participantName': name,
      'amount': shareAmount,
      'billTitle': billTitle,
    });
  }

  /// Returns the JSON string that encodes a bill-join invitation.
  /// Scanning this QR lets a new user join the bill as a participant.
  static String buildJoinPayload({
    required String billId,
    required String billTitle,
    required double totalAmount,
    required String category,
  }) {
    return jsonEncode({
      'type': 'split_bill_join',
      'billId': billId,
      'billTitle': billTitle,
      'totalAmount': totalAmount,
      'category': category,
    });
  }

  // ---- Immutable copy -----------------------------------------------------

  SplitBillParticipant copyWith({
    String? id,
    String? name,
    double? shareAmount,
    double? sharePercentage,
    String? note,
    SplitParticipantStatus? status,
    DateTime? paidAt,
    String? qrPayload,
  }) {
    return SplitBillParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      shareAmount: shareAmount ?? this.shareAmount,
      sharePercentage: sharePercentage ?? this.sharePercentage,
      note: note ?? this.note,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      qrPayload: qrPayload ?? this.qrPayload,
    );
  }
}

// ---------------------------------------------------------------------------
// SplitBill
// ---------------------------------------------------------------------------

class SplitBill {
  const SplitBill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.category,
    required this.createdAt,
    required this.createdBy,
    required this.participants,
    this.splitMode = SplitMode.equal,
    this.description,
  });

  final String id;
  final String title;
  final double totalAmount;
  final String category;
  final DateTime createdAt;
  final String createdBy;
  final List<SplitBillParticipant> participants;

  /// How shares are divided.
  final SplitMode splitMode;

  /// Optional longer description / memo for the bill.
  final String? description;

  // ---- Computed -----------------------------------------------------------

  double get paidAmount =>
      participants.where((p) => p.isPaid).fold(0.0, (s, p) => s + p.shareAmount);

  double get remainingBalance {
    final rem = totalAmount - paidAmount;
    return rem < 0 ? 0.0 : rem;
  }

  int get paidCount => participants.where((p) => p.isPaid).length;
  int get totalCount => participants.length;

  bool get isSettled => remainingBalance <= 0.001;

  double get progress =>
      totalAmount <= 0 ? 1.0 : (paidAmount / totalAmount).clamp(0.0, 1.0);

  // ---- Join QR payload ----------------------------------------------------

  String get joinQrPayload => SplitBillParticipant.buildJoinPayload(
        billId: id,
        billTitle: title,
        totalAmount: totalAmount,
        category: category,
      );

  // ---- Immutable copy -----------------------------------------------------

  SplitBill copyWith({
    String? id,
    String? title,
    double? totalAmount,
    String? category,
    DateTime? createdAt,
    String? createdBy,
    List<SplitBillParticipant>? participants,
    SplitMode? splitMode,
    String? description,
  }) {
    return SplitBill(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      splitMode: splitMode ?? this.splitMode,
      description: description ?? this.description,
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: build a participant list from split-mode inputs
// ---------------------------------------------------------------------------

/// Resolves a validated list of [SplitBillParticipant]s from raw form inputs.
///
/// Always inserts "You (Host)" as the first participant with status=paid.
List<SplitBillParticipant> buildParticipants({
  required String billId,
  required double totalAmount,
  required SplitMode mode,

  /// Names of non-host participants, in order.
  required List<String> names,

  /// Used only when [mode] == [SplitMode.custom].
  /// Length must match [names] + 1 (host is index 0).
  List<double>? customAmounts,

  /// Used only when [mode] == [SplitMode.percentage].
  /// Length must match [names] + 1 (host is index 0). Must sum to 100.
  List<double>? percentages,

  /// Optional per-participant notes; same length as [names] + 1.
  List<String?>? notes,
}) {
  final cleanNames = names.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
  final totalPeople = cleanNames.length + 1; // host + guests

  double resolveShare(int index) {
    return switch (mode) {
      SplitMode.equal => totalAmount / totalPeople,
      SplitMode.custom =>
        (customAmounts != null && index < customAmounts.length)
            ? customAmounts[index]
            : totalAmount / totalPeople,
      SplitMode.percentage =>
        (percentages != null && index < percentages.length)
            ? (percentages[index] / 100) * totalAmount
            : totalAmount / totalPeople,
    };
  }

  double? resolvePct(int index) => switch (mode) {
        SplitMode.percentage =>
          (percentages != null && index < percentages.length)
              ? percentages[index]
              : null,
        _ => null,
      };

  final now = DateTime.now();
  final result = <SplitBillParticipant>[];

  // Host (index 0) – always auto-paid.
  result.add(SplitBillParticipant(
    id: 'p_${billId}_host',
    name: 'You (Host)',
    shareAmount: resolveShare(0),
    sharePercentage: resolvePct(0),
    note: notes != null && notes.isNotEmpty ? notes[0] : null,
    status: SplitParticipantStatus.paid,
    paidAt: now,
  ));

  for (var i = 0; i < cleanNames.length; i++) {
    final idx = i + 1;
    result.add(SplitBillParticipant(
      id: 'p_${billId}_$i',
      name: cleanNames[i],
      shareAmount: resolveShare(idx),
      sharePercentage: resolvePct(idx),
      note: notes != null && idx < notes.length ? notes[idx] : null,
      status: SplitParticipantStatus.pending,
    ));
  }

  return result;
}
