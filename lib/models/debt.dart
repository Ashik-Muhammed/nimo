enum DebtType {
  // Money you owe to others
  borrowed('Borrowed (I owe)'),
  loan('Loan (I owe)'),
  creditCard('Credit Card (I owe)'),
  
  // Loan Types
  homeLoan('Home Loan'),
  personalLoan('Personal Loan'),
  vehicleLoan('Vehicle Loan'),
  educationLoan('Education Loan'),
  goldLoan('Gold Loan'),
  businessLoan('Business Loan'),
  
  // Money others owe to you
  lent('Lent (Owed to me)');
  
  final String displayName;
  const DebtType(this.displayName);
  
  @override
  String toString() => displayName;
  
  bool get isLoan => [
    DebtType.homeLoan,
    DebtType.personalLoan,
    DebtType.vehicleLoan,
    DebtType.educationLoan,
    DebtType.goldLoan,
    DebtType.businessLoan,
  ].contains(this);
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
  
  // Loan-specific fields
  final int? tenureMonths; // Loan tenure in months
  final double? emi; // Equated Monthly Installment
  final DateTime? startDate; // Loan start date
  final String? amortizationSchedule; // JSON string of amortization schedule
  final double? prepaymentAmount; // Total prepayment made
  final int? prepaymentCount; // Number of prepayments made

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
    // Loan-specific fields
    this.tenureMonths,
    this.emi,
    this.startDate,
    this.amortizationSchedule,
    this.prepaymentAmount,
    this.prepaymentCount,
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
      // Loan-specific fields
      tenureMonths: map['tenureMonths'] as int?,
      emi: (map['emi'] as num?)?.toDouble(),
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int)
          : null,
      amortizationSchedule: map['amortizationSchedule'] as String?,
      prepaymentAmount: (map['prepaymentAmount'] as num?)?.toDouble(),
      prepaymentCount: map['prepaymentCount'] as int?,
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
      // Loan-specific fields
      'tenureMonths': tenureMonths,
      'emi': emi,
      'startDate': startDate?.millisecondsSinceEpoch,
      'amortizationSchedule': amortizationSchedule,
      'prepaymentAmount': prepaymentAmount,
      'prepaymentCount': prepaymentCount,
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
    // Loan-specific fields
    int? tenureMonths,
    double? emi,
    DateTime? startDate,
    String? amortizationSchedule,
    double? prepaymentAmount,
    int? prepaymentCount,
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
      // Loan-specific fields
      tenureMonths: tenureMonths ?? this.tenureMonths,
      emi: emi ?? this.emi,
      startDate: startDate ?? this.startDate,
      amortizationSchedule: amortizationSchedule ?? this.amortizationSchedule,
      prepaymentAmount: prepaymentAmount ?? this.prepaymentAmount,
      prepaymentCount: prepaymentCount ?? this.prepaymentCount,
    );
  }

  // Calculate remaining amount
  double get remainingAmount => amount - paidAmount;

  // Check if debt is overdue
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);

  // Get progress percentage
  double get progress => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;
}
