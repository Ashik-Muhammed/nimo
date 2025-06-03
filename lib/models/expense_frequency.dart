enum ExpenseFrequency {
  oneTime,
  daily,
  weekly,
  monthly,
  yearly;

  static ExpenseFrequency fromString(String value) {
    switch (value) {
      case 'oneTime':
        return ExpenseFrequency.oneTime;
      case 'daily':
        return ExpenseFrequency.daily;
      case 'weekly':
        return ExpenseFrequency.weekly;
      case 'monthly':
        return ExpenseFrequency.monthly;
      case 'yearly':
        return ExpenseFrequency.yearly;
      default:
        return ExpenseFrequency.oneTime;
    }
  }
}
