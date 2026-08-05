/// Domain models. Plain immutable value types with no data source knowledge.
library;

enum AccountKind { wallet, savings, crypto }

extension AccountKindLabel on AccountKind {
  String get label => switch (this) {
    AccountKind.wallet => 'Wallet',
    AccountKind.savings => 'Savings account',
    AccountKind.crypto => 'Crypto wallet',
  };
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.kind,
    required this.maskedNumber,
    required this.currencyCode,
    required this.totalBalance,
    required this.availableBalance,
    this.cryptoQuantity,
    this.cryptoUnit,
  });

  final String id;
  final String name;

  /// Chip label, for example `WALLET` or `BTC`.
  final String shortCode;
  final AccountKind kind;
  final String maskedNumber;
  final String currencyCode;
  final double totalBalance;
  final double availableBalance;
  final double? cryptoQuantity;
  final String? cryptoUnit;

  bool get isCrypto => kind == AccountKind.crypto;
}

enum CardNetwork { visa, mastercard }

extension CardNetworkLabel on CardNetwork {
  String get label => switch (this) {
    CardNetwork.visa => 'Visa',
    CardNetwork.mastercard => 'Mastercard',
  };
}

enum CardStatus { active, frozen }

extension CardStatusLabel on CardStatus {
  String get label => switch (this) {
    CardStatus.active => 'Active',
    CardStatus.frozen => 'Frozen',
  };
}

/// How the card settles. Printed on the card face, the way a real card carries
/// its scheme product name.
enum CardKind { debit, credit }

extension CardKindLabel on CardKind {
  String get label => switch (this) {
    CardKind.debit => 'Debit',
    CardKind.credit => 'Credit',
  };
}

class BankCard {
  const BankCard({
    required this.id,
    required this.accountId,
    required this.label,
    required this.holderName,
    required this.number,
    required this.cvc,
    required this.expiry,
    required this.network,
    required this.kind,
    required this.status,
    required this.balance,
    required this.currencyCode,
    required this.spendingLimit,
  });

  final String id;
  final String accountId;
  final String label;
  final String holderName;

  /// Full digits, grouped in fours. Only the last group is shown until the
  /// holder asks to reveal it.
  final String number;

  /// Three or four digit security code.
  final String cvc;
  final String expiry;
  final CardNetwork network;
  final CardKind kind;
  final CardStatus status;
  final double balance;
  final String currencyCode;
  final double spendingLimit;

  String get last4 => number.replaceAll(' ', '').substring(number.replaceAll(' ', '').length - 4);

  String get maskedNumber => '\u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 $last4';
}

enum TxnType { deposit, transfer, qrPayment, cardPurchase }

extension TxnTypeLabel on TxnType {
  String get label => switch (this) {
    TxnType.deposit => 'Deposit',
    TxnType.transfer => 'Transfer',
    TxnType.qrPayment => 'QR payment',
    TxnType.cardPurchase => 'Card purchase',
  };
}

enum TxnStatus { completed, pending, failed }

extension TxnStatusLabel on TxnStatus {
  String get label => switch (this) {
    TxnStatus.completed => 'Completed',
    TxnStatus.pending => 'Pending',
    TxnStatus.failed => 'Failed',
  };
}

enum TxnDirection { inflow, outflow }

class Txn {
  const Txn({
    required this.id,
    required this.accountId,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.currencyCode,
    required this.direction,
    required this.type,
    required this.status,
    required this.date,
    required this.reference,
    this.note,
  });

  final String id;
  final String accountId;
  final String merchant;
  final String category;

  /// Always positive. [direction] carries the sign.
  final double amount;
  final String currencyCode;
  final TxnDirection direction;
  final TxnType type;
  final TxnStatus status;
  final DateTime date;
  final String reference;
  final String? note;

  bool get isInflow => direction == TxnDirection.inflow;

  double get signedAmount => isInflow ? amount : -amount;

  String get monogram {
    final parts = merchant
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class Promo {
  const Promo({
    required this.id,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.accentIndex,
  });

  final String id;
  final String title;
  final String body;
  final String actionLabel;

  /// Selects which brand gradient the card uses.
  final int accentIndex;
}

// ---------------------------------------------------------------------------
// Goal Saves
// ---------------------------------------------------------------------------

enum GoalSaveStatus { active, closed }

extension GoalSaveStatusLabel on GoalSaveStatus {
  String get label => switch (this) {
    GoalSaveStatus.active => 'Active',
    GoalSaveStatus.closed => 'Closed',
  };
}

/// A named savings pocket the user opens inside their Savings account.
///
/// Interest accrues daily at [dailyRatePercent] on the current [balance].
class GoalSave {
  const GoalSave({
    required this.id,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    required this.balance,
    required this.currencyCode,
    required this.dailyRatePercent,
    required this.interestEarned,
    required this.createdAt,
    required this.status,
  });

  final String id;

  /// User-defined goal name, e.g. "Europe Trip".
  final String name;

  /// Single emoji picked when the goal was opened, e.g. "✈️".
  final String emoji;

  /// Optional savings target. Zero means no explicit target.
  final double targetAmount;

  final double balance;
  final String currencyCode;

  /// Daily interest rate as a percentage, e.g. 0.011918 for ~4.35% APY.
  final double dailyRatePercent;

  /// Cumulative interest credited to this goal since it was opened.
  final double interestEarned;

  final DateTime createdAt;
  final GoalSaveStatus status;

  bool get hasTarget => targetAmount > 0;

  /// Progress toward the target. Clamped to [0, 1]. Returns 0 if no target.
  double get progress =>
      hasTarget ? (balance / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Amount that would be earned today based on the current balance.
  double get dailyInterestAmount => balance * (dailyRatePercent / 100);

  /// Annual Percentage Yield inferred from the daily rate: (1 + d/100)^365 − 1.
  double get apy =>
      (1 + dailyRatePercent / 100) * 365 - 1; // simple approximation

  GoalSave copyWith({
    double? balance,
    double? interestEarned,
    GoalSaveStatus? status,
    String? name,
    String? emoji,
    double? targetAmount,
  }) => GoalSave(
    id: id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    targetAmount: targetAmount ?? this.targetAmount,
    balance: balance ?? this.balance,
    currencyCode: currencyCode,
    dailyRatePercent: dailyRatePercent,
    interestEarned: interestEarned ?? this.interestEarned,
    createdAt: createdAt,
    status: status ?? this.status,
  );
}

// ---------------------------------------------------------------------------
// Goal Save Transactions
// ---------------------------------------------------------------------------

enum GoalTxnKind { transferIn, transferOut, interest }

extension GoalTxnKindLabel on GoalTxnKind {
  String get label => switch (this) {
    GoalTxnKind.transferIn => 'Added funds',
    GoalTxnKind.transferOut => 'Withdrawn',
    GoalTxnKind.interest => 'Interest earned',
  };

  bool get isCredit =>
      this == GoalTxnKind.transferIn || this == GoalTxnKind.interest;
}

/// An entry in a goal save's transaction history.
class GoalTxn {
  const GoalTxn({
    required this.id,
    required this.goalId,
    required this.kind,
    required this.amount,
    required this.runningBalance,
    required this.date,
    this.note,
  });

  final String id;
  final String goalId;
  final GoalTxnKind kind;

  /// Always positive.
  final double amount;
  final double runningBalance;
  final DateTime date;
  final String? note;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.memberSince,
  });

  final String id;
  final String fullName;
  final String email;
  final String mobile;
  final DateTime memberSince;

  String get initials {
    final parts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get maskedEmail {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    final visible = email.substring(0, 2);
    return '$visible${'\u2022' * (at - 2)}${email.substring(at)}';
  }

  String get maskedMobile {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return mobile;
    final tail = digits.substring(digits.length - 4);
    return '\u2022\u2022\u2022 \u2022\u2022\u2022 $tail';
  }
}
