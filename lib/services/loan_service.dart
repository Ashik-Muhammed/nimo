import 'dart:convert';
import 'dart:math';

class AmortizationEntry {
  final int month;
  final DateTime dueDate;
  final double emi;
  final double principal;
  final double interest;
  final double balance;
  final double totalPaid;

  AmortizationEntry({
    required this.month,
    required this.dueDate,
    required this.emi,
    required this.principal,
    required this.interest,
    required this.balance,
    required this.totalPaid,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'emi': emi,
      'principal': principal,
      'interest': interest,
      'balance': balance,
      'totalPaid': totalPaid,
    };
  }

  factory AmortizationEntry.fromMap(Map<String, dynamic> map) {
    return AmortizationEntry(
      month: map['month'] as int,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      emi: (map['emi'] as num).toDouble(),
      principal: (map['principal'] as num).toDouble(),
      interest: (map['interest'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      totalPaid: (map['totalPaid'] as num).toDouble(),
    );
  }
}

class LoanService {
  // Calculate EMI using the standard formula: EMI = P * r * (1+r)^n / ((1+r)^n - 1)
  // where P = principal, r = monthly interest rate, n = tenure in months
  static double calculateEMI({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    if (principal <= 0 || tenureMonths <= 0) return 0;
    
    final monthlyRate = annualInterestRate / 12 / 100;
    if (monthlyRate == 0) {
      return principal / tenureMonths;
    }
    
    final numerator = principal * monthlyRate * pow(1 + monthlyRate, tenureMonths);
    final denominator = pow(1 + monthlyRate, tenureMonths) - 1;
    
    return numerator / denominator;
  }

  // Generate complete amortization schedule
  static List<AmortizationEntry> generateAmortizationSchedule({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
    required DateTime startDate,
  }) {
    final List<AmortizationEntry> schedule = [];
    final monthlyRate = annualInterestRate / 12 / 100;
    final emi = calculateEMI(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );
    
    double balance = principal;
    double totalPaid = 0;
    
    for (int month = 1; month <= tenureMonths; month++) {
      final interest = balance * monthlyRate;
      final principalPayment = emi - interest;
      balance -= principalPayment;
      totalPaid += emi;
      
      // Ensure balance doesn't go negative due to rounding
      if (balance < 0) balance = 0;
      
      final dueDate = DateTime(
        startDate.year + (startDate.month + month - 1) ~/ 12,
        (startDate.month + month - 1) % 12 + 1,
        startDate.day,
      );
      
      schedule.add(AmortizationEntry(
        month: month,
        dueDate: dueDate,
        emi: emi,
        principal: principalPayment,
        interest: interest,
        balance: balance,
        totalPaid: totalPaid,
      ));
    }
    
    return schedule;
  }

  // Calculate pre-closure savings
  static PreClosureAnalysis calculatePreClosureSavings({
    required double principal,
    required double annualInterestRate,
    required int originalTenureMonths,
    required int monthsPaid,
    required DateTime startDate,
    double prepaymentAmount = 0,
  }) {
    final originalSchedule = generateAmortizationSchedule(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: originalTenureMonths,
      startDate: startDate,
    );
    
    // Calculate remaining principal after payments
    final remainingPrincipal = monthsPaid < originalSchedule.length
        ? originalSchedule[monthsPaid - 1].balance
        : 0;
    
    // Calculate total interest remaining in original schedule
    double originalInterestRemaining = 0;
    for (int i = monthsPaid; i < originalSchedule.length; i++) {
      originalInterestRemaining += originalSchedule[i].interest;
    }
    
    // New schedule with prepayment
    final newPrincipal = remainingPrincipal - prepaymentAmount;
    final remainingMonths = originalTenureMonths - monthsPaid;
    
    if (newPrincipal <= 0) {
      return PreClosureAnalysis(
        originalInterestRemaining: originalInterestRemaining,
        newInterestRemaining: 0,
        savings: originalInterestRemaining,
        newTenureMonths: 0,
        newEMI: 0,
      );
    }
    
    final newSchedule = generateAmortizationSchedule(
      principal: newPrincipal,
      annualInterestRate: annualInterestRate,
      tenureMonths: remainingMonths,
      startDate: DateTime(startDate.year, startDate.month + monthsPaid, startDate.day),
    );
    
    // Calculate total interest in new schedule
    double newInterestRemaining = 0;
    for (var entry in newSchedule) {
      newInterestRemaining += entry.interest;
    }
    
    final newEMI = calculateEMI(
      principal: newPrincipal,
      annualInterestRate: annualInterestRate,
      tenureMonths: remainingMonths,
    );
    
    return PreClosureAnalysis(
      originalInterestRemaining: originalInterestRemaining,
      newInterestRemaining: newInterestRemaining,
      savings: originalInterestRemaining - newInterestRemaining,
      newTenureMonths: remainingMonths,
      newEMI: newEMI,
    );
  }

  // Serialize amortization schedule to JSON string
  static String serializeSchedule(List<AmortizationEntry> schedule) {
    final List<Map<String, dynamic>> scheduleMaps = 
        schedule.map((e) => e.toMap()).toList();
    return jsonEncode(scheduleMaps);
  }

  // Deserialize amortization schedule from JSON string
  static List<AmortizationEntry> deserializeSchedule(String jsonString) {
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => AmortizationEntry.fromMap(e as Map<String, dynamic>)).toList();
  }

  // Calculate total interest payable over loan tenure
  static double calculateTotalInterest({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    final emi = calculateEMI(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );
    return (emi * tenureMonths) - principal;
  }

  // Calculate debt-free date based on current payments
  static DateTime calculateDebtFreeDate({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
    required DateTime startDate,
    double extraMonthlyPayment = 0,
  }) {
    if (extraMonthlyPayment <= 0) {
      return DateTime(
        startDate.year + (startDate.month + tenureMonths - 1) ~/ 12,
        (startDate.month + tenureMonths - 1) % 12 + 1,
        startDate.day,
      );
    }
    
    final emi = calculateEMI(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );
    
    final monthlyPayment = emi + extraMonthlyPayment;
    final monthlyRate = annualInterestRate / 12 / 100;
    
    double balance = principal;
    int months = 0;
    
    while (balance > 0 && months < tenureMonths * 2) {
      final interest = balance * monthlyRate;
      final principalPayment = monthlyPayment - interest;
      balance -= principalPayment;
      months++;
      
      if (balance < 0) balance = 0;
    }
    
    return DateTime(
      startDate.year + (startDate.month + months - 1) ~/ 12,
      (startDate.month + months - 1) % 12 + 1,
      startDate.day,
    );
  }
}

class PreClosureAnalysis {
  final double originalInterestRemaining;
  final double newInterestRemaining;
  final double savings;
  final int newTenureMonths;
  final double newEMI;

  PreClosureAnalysis({
    required this.originalInterestRemaining,
    required this.newInterestRemaining,
    required this.savings,
    required this.newTenureMonths,
    required this.newEMI,
  });
}
