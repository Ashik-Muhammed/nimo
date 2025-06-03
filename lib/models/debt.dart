enum DebtType {
  // Money you owe to others
  borrowed('Borrowed (I owe)'),
  loan('Loan (I owe)'),
  creditCard('Credit Card (I owe)'),
  
  // Money others owe to you
  lent('Lent (Owed to me)');
  
  final String displayName;
  const DebtType(this.displayName);
  
  @override
  String toString() => displayName;
}

class Debt {
  final String id;
  final String title;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final String? notes;
  final String userId;
  final DebtType type;
  final double? interestRate;
  final String? lender;
  final DateTime createdAt;
  final bool isPaid;
  final DateTime? paidDate;
  final String currencyCode;

  // Remove const constructor to allow non-const values
  Debt({
    required this.id,
    required this.title,
    required this.amount,
    this.paidAmount = 0,
    required this.dueDate,
    this.notes,
    required this.userId,
    this.type = DebtType.borrowed,
    this.interestRate,
    this.lender,
    DateTime? createdAt,
    this.isPaid = false,
    this.paidDate,
    this.currencyCode = 'USD',
  }) : createdAt = createdAt ?? DateTime.now();

  // Single fromMap constructor
  factory Debt.fromMap(Map<String, dynamic> map, [String? id]) {
    // Handle legacy or unknown types by defaulting to borrowed
    DebtType parseDebtType(String? type) {
      if (type == null) return DebtType.borrowed;
      try {
        return DebtType.values.firstWhere(
          (e) => e.toString() == 'DebtType.${type.toLowerCase()}' || 
                e.displayName.toLowerCase() == type.toLowerCase(),
          orElse: () => DebtType.borrowed,
        );
      } catch (e) {
        return DebtType.borrowed;
      }
    }

    return Debt(
      id: id ?? map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      notes: map['notes'] as String?,
      userId: map['userId'] as String,
      type: parseDebtType(map['type'] as String?),
      interestRate: (map['interestRate'] as num?)?.toDouble(),
      lender: map['lender'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      isPaid: map['isPaid'] as bool? ?? false,
      paidDate: map['paidDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paidDate'] as int)
          : null,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'notes': notes,
      'userId': userId,
      'type': type.toString().split('.').last,
      'interestRate': interestRate,
      'lender': lender,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isPaid': isPaid,
      'paidDate': paidDate?.millisecondsSinceEpoch,
      'currencyCode': currencyCode,
    };
  }

  // Create a copy of Debt with updated fields
  Debt copyWith({
    String? id,
    String? title,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    String? notes,
    String? userId,
    DebtType? type,
    double? interestRate,
    String? lender,
    DateTime? createdAt,
    bool? isPaid,
    DateTime? paidDate,
    String? currencyCode,
  }) {
    return Debt(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      interestRate: interestRate ?? this.interestRate,
      lender: lender ?? this.lender,
      createdAt: createdAt ?? this.createdAt,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  // Calculate remaining amount
  double get remainingAmount => amount - paidAmount;

  // Check if debt is overdue
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);

  // Get progress percentage
  double get progress => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;
}
