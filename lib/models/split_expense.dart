class SplitExpense {
  final String userId;
  final double amount;
  final bool isPaid;

  SplitExpense({
    required this.userId,
    required this.amount,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'isPaid': isPaid,
    };
  }

  factory SplitExpense.fromMap(Map<String, dynamic> map) {
    return SplitExpense(
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      isPaid: map['isPaid'] as bool? ?? false,
    );
  }
}
