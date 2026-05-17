import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/debt_service.dart';
import 'package:expense_tracker/models/account.dart';
import 'package:expense_tracker/models/debt.dart';

class NetWorthService {
  final AccountService _accountService;
  final DebtService _debtService;

  NetWorthService({
    required AccountService accountService,
    required DebtService debtService,
  })  : _accountService = accountService,
        _debtService = debtService;

  // Calculate complete net worth including accounts and debts
  Future<NetWorthSnapshot> calculateNetWorth(String userId) async {
    // Get assets from accounts
    final assets = await _accountService.getAssetAccounts(userId).first;
    double totalAssets = 0;
    final Map<AccountType, double> assetBreakdown = {};

    for (var account in assets) {
      totalAssets += account.balance;
      assetBreakdown[account.type] = 
          (assetBreakdown[account.type] ?? 0) + account.balance;
    }

    // Get liabilities from accounts (credit cards, BNPL, etc.)
    final liabilityAccounts = await _accountService.getLiabilityAccounts(userId).first;
    double totalLiabilities = 0;
    final Map<AccountType, double> liabilityBreakdown = {};

    for (var account in liabilityAccounts) {
      totalLiabilities += account.balance.abs();
      liabilityBreakdown[account.type] = 
          (liabilityBreakdown[account.type] ?? 0) + account.balance.abs();
    }

    // Get debts
    final debts = await _debtService.getActiveDebts(userId).first;
    double totalDebt = 0;
    final Map<DebtType, double> debtBreakdown = {};

    for (var debt in debts) {
      final remaining = debt.amount - debt.paidAmount;
      // Only count debts where user owes money (not lent)
      if (!debt.type.toString().contains('lent')) {
        totalDebt += remaining;
        debtBreakdown[debt.type] = (debtBreakdown[debt.type] ?? 0) + remaining;
      }
    }

    final totalLiabilitiesIncludingDebt = totalLiabilities + totalDebt;
    final netWorth = totalAssets - totalLiabilitiesIncludingDebt;

    return NetWorthSnapshot(
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilitiesIncludingDebt,
      netWorth: netWorth,
      assetBreakdown: assetBreakdown,
      liabilityBreakdown: liabilityBreakdown,
      debtBreakdown: debtBreakdown,
      accountAssets: assets,
      accountLiabilities: liabilityAccounts,
      debts: debts,
    );
  }

  // Get net worth trend over months
  Future<List<NetWorthDataPoint>> getNetWorthTrend(
    String userId, {
    int months = 6,
  }) async {
    final List<NetWorthDataPoint> trend = [];
    final now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final snapshot = await calculateNetWorth(userId);
      
      trend.add(NetWorthDataPoint(
        date: month,
        netWorth: snapshot.netWorth,
        assets: snapshot.totalAssets,
        liabilities: snapshot.totalLiabilities,
      ));
    }

    return trend;
  }

  // Calculate monthly growth rate
  double calculateMonthlyGrowthRate(List<NetWorthDataPoint> trend) {
    if (trend.length < 2) return 0;

    final first = trend.first;
    final last = trend.last;

    if (first.netWorth == 0) return 0;

    return ((last.netWorth - first.netWorth) / first.netWorth) * 100;
  }

  // Get asset allocation percentages
  Map<AccountType, double> getAssetAllocation(NetWorthSnapshot snapshot) {
    final Map<AccountType, double> allocation = {};
    
    if (snapshot.totalAssets == 0) return allocation;

    snapshot.assetBreakdown.forEach((type, amount) {
      allocation[type] = (amount / snapshot.totalAssets) * 100;
    });

    return allocation;
  }
}

class NetWorthSnapshot {
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final Map<AccountType, double> assetBreakdown;
  final Map<AccountType, double> liabilityBreakdown;
  final Map<DebtType, double> debtBreakdown;
  final List<Account> accountAssets;
  final List<Account> accountLiabilities;
  final List<Debt> debts;

  NetWorthSnapshot({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.assetBreakdown,
    required this.liabilityBreakdown,
    required this.debtBreakdown,
    required this.accountAssets,
    required this.accountLiabilities,
    required this.debts,
  });

  // Get debt-to-asset ratio
  double get debtToAssetRatio {
    if (totalAssets == 0) return 0;
    return totalLiabilities / totalAssets;
  }

  // Get savings rate (assets / (assets + liabilities))
  double get savingsRate {
    final total = totalAssets + totalLiabilities;
    if (total == 0) return 0;
    return (totalAssets / total) * 100;
  }
}

class NetWorthDataPoint {
  final DateTime date;
  final double netWorth;
  final double assets;
  final double liabilities;

  NetWorthDataPoint({
    required this.date,
    required this.netWorth,
    required this.assets,
    required this.liabilities,
  });
}
