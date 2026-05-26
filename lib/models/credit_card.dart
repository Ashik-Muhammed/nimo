class CreditCard {
  final String id;
  final String userId;
  final String bankName;
  final String cardName;
  final String lastFourDigits;
  final double creditLimit;
  final double currentBalance;
  final double minimumDue;
  final DateTime dueDate;
  final double interestRate;
  final DateTime statementDate;
  final DateTime createdAt;
  final String currencyCode;
  final List<Statement> statements;

  CreditCard({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.cardName,
    required this.lastFourDigits,
    required this.creditLimit,
    this.currentBalance = 0,
    this.minimumDue = 0,
    required this.dueDate,
    required this.interestRate,
    required this.statementDate,
    DateTime? createdAt,
    this.currencyCode = 'USD',
    this.statements = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate credit utilization percentage
  double get utilizationRate {
    if (creditLimit == 0) return 0;
    return (currentBalance / creditLimit) * 100;
  }

  // Calculate available credit
  double get availableCredit => creditLimit - currentBalance;

  // Check if payment is overdue
  bool get isOverdue => DateTime.now().isAfter(dueDate) && currentBalance > 0;

  // Get days until due
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  // Check if utilization is high (>30%)
  bool get isHighUtilization => utilizationRate > 30;

  // Check if utilization is critical (>70%)
  bool get isCriticalUtilization => utilizationRate > 70;

  factory CreditCard.fromMap(Map<String, dynamic> map, [String? id]) {
    return CreditCard(
      id: id ?? map['id'] as String,
      userId: map['userId'] as String,
      bankName: map['bankName'] as String,
      cardName: map['cardName'] as String,
      lastFourDigits: map['lastFourDigits'] as String,
      creditLimit: (map['creditLimit'] as num).toDouble(),
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      minimumDue: (map['minimumDue'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      interestRate: (map['interestRate'] as num).toDouble(),
      statementDate: DateTime.fromMillisecondsSinceEpoch(map['statementDate'] as int),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      statements: (map['statements'] as List<dynamic>?)
              ?.map((e) => Statement.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bankName': bankName,
      'cardName': cardName,
      'lastFourDigits': lastFourDigits,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'minimumDue': minimumDue,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'interestRate': interestRate,
      'statementDate': statementDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'currencyCode': currencyCode,
      'statements': statements.map((e) => e.toMap()).toList(),
    };
  }

  CreditCard copyWith({
    String? id,
    String? userId,
    String? bankName,
    String? cardName,
    String? lastFourDigits,
    double? creditLimit,
    double? currentBalance,
    double? minimumDue,
    DateTime? dueDate,
    double? interestRate,
    DateTime? statementDate,
    DateTime? createdAt,
    String? currencyCode,
    List<Statement>? statements,
  }) {
    return CreditCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankName: bankName ?? this.bankName,
      cardName: cardName ?? this.cardName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      minimumDue: minimumDue ?? this.minimumDue,
      dueDate: dueDate ?? this.dueDate,
      interestRate: interestRate ?? this.interestRate,
      statementDate: statementDate ?? this.statementDate,
      createdAt: createdAt ?? this.createdAt,
      currencyCode: currencyCode ?? this.currencyCode,
      statements: statements ?? this.statements,
    );
  }
}

class Statement {
  final DateTime statementDate;
  final DateTime dueDate;
  final double totalAmount;
  final double minimumDue;
  final double amountPaid;
  final List<CreditCardTransaction> transactions;

  Statement({
    required this.statementDate,
    required this.dueDate,
    required this.totalAmount,
    required this.minimumDue,
    this.amountPaid = 0,
    this.transactions = const [],
  });

  double get remainingAmount => totalAmount - amountPaid;

  factory Statement.fromMap(Map<String, dynamic> map) {
    return Statement(
      statementDate: DateTime.fromMillisecondsSinceEpoch(map['statementDate'] as int),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      minimumDue: (map['minimumDue'] as num).toDouble(),
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      transactions: (map['transactions'] as List<dynamic>?)
              ?.map((e) => CreditCardTransaction.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statementDate': statementDate.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'totalAmount': totalAmount,
      'minimumDue': minimumDue,
      'amountPaid': amountPaid,
      'transactions': transactions.map((e) => e.toMap()).toList(),
    };
  }
}

class CreditCardTransaction {
  final DateTime date;
  final String description;
  final double amount;
  final String category;

  CreditCardTransaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
  });

  factory CreditCardTransaction.fromMap(Map<String, dynamic> map) {
    return CreditCardTransaction(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'amount': amount,
      'category': category,
    };
  }
}
