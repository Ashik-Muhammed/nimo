enum AccountType {
  // Banking
  savings('Savings Account'),
  current('Current Account'),
  cashWallet('Cash Wallet'),
  
  // Debt
  loan('Loan'),
  creditCard('Credit Card'),
  bnpl('BNPL'),
  personalDebt('Personal Debt'),
  
  // Investments
  stocks('Stocks'),
  mutualFunds('Mutual Funds'),
  crypto('Crypto'),
  gold('Gold'),
  fixedDeposit('Fixed Deposit'),
  
  // Assets
  vehicle('Vehicle'),
  property('Property'),
  electronics('Electronics'),
  businessAsset('Business Asset');
  
  final String displayName;
  const AccountType(this.displayName);
  
  @override
  String toString() => displayName;
  
  bool get isAsset => [
    AccountType.stocks,
    AccountType.mutualFunds,
    AccountType.crypto,
    AccountType.gold,
    AccountType.fixedDeposit,
    AccountType.vehicle,
    AccountType.property,
    AccountType.electronics,
    AccountType.businessAsset,
  ].contains(this);
  
  bool get isLiability => [
    AccountType.loan,
    AccountType.creditCard,
    AccountType.bnpl,
    AccountType.personalDebt,
  ].contains(this);
  
  bool get isBanking => [
    AccountType.savings,
    AccountType.current,
    AccountType.cashWallet,
  ].contains(this);
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String currencyCode;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? accountNumber;
  final String? institution;
  final String? notes;
  final bool isActive;
  final double? creditLimit; // For credit cards
  final DateTime? dueDate; // For debts/credit cards
  final double? interestRate; // For debts/investments
  final DateTime? maturityDate; // For investments
  
  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currencyCode = 'USD',
    required this.userId,
    DateTime? createdAt,
    this.updatedAt,
    this.accountNumber,
    this.institution,
    this.notes,
    this.isActive = true,
    this.creditLimit,
    this.dueDate,
    this.interestRate,
    this.maturityDate,
  }) : createdAt = createdAt ?? DateTime.now();
  
  factory Account.fromMap(Map<String, dynamic> map, [String? id]) {
    AccountType parseAccountType(String? type) {
      if (type == null) return AccountType.savings;
      try {
        return AccountType.values.firstWhere(
          (e) => e.toString() == 'AccountType.$type' || 
                e.displayName.toLowerCase() == type.toLowerCase(),
          orElse: () => AccountType.savings,
        );
      } catch (e) {
        return AccountType.savings;
      }
    }
    
    return Account(
      id: id ?? map['id'] as String,
      name: map['name'] as String,
      type: parseAccountType(map['type'] as String?),
      balance: (map['balance'] as num).toDouble(),
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      userId: map['userId'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
      accountNumber: map['accountNumber'] as String?,
      institution: map['institution'] as String?,
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      creditLimit: (map['creditLimit'] as num?)?.toDouble(),
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      interestRate: (map['interestRate'] as num?)?.toDouble(),
      maturityDate: map['maturityDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['maturityDate'] as int)
          : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'balance': balance,
      'currencyCode': currencyCode,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'accountNumber': accountNumber,
      'institution': institution,
      'notes': notes,
      'isActive': isActive,
      'creditLimit': creditLimit,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'interestRate': interestRate,
      'maturityDate': maturityDate?.millisecondsSinceEpoch,
    };
  }
  
  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currencyCode,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountNumber,
    String? institution,
    String? notes,
    bool? isActive,
    double? creditLimit,
    DateTime? dueDate,
    double? interestRate,
    DateTime? maturityDate,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountNumber: accountNumber ?? this.accountNumber,
      institution: institution ?? this.institution,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      creditLimit: creditLimit ?? this.creditLimit,
      dueDate: dueDate ?? this.dueDate,
      interestRate: interestRate ?? this.interestRate,
      maturityDate: maturityDate ?? this.maturityDate,
    );
  }
  
  // Calculate available credit for credit cards
  double get availableCredit {
    if (type == AccountType.creditCard && creditLimit != null) {
      return creditLimit! - balance.abs();
    }
    return 0;
  }
  
  // Calculate credit utilization for credit cards
  double get creditUtilization {
    if (type == AccountType.creditCard && creditLimit != null && creditLimit! > 0) {
      return (balance.abs() / creditLimit!) * 100;
    }
    return 0;
  }
  
  // Check if account is overdue (for debts/credit cards)
  bool get isOverdue {
    if (dueDate != null && type.isLiability) {
      return !isActive && DateTime.now().isAfter(dueDate!);
    }
    return false;
  }
}
