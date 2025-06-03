import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/split_expense.dart';
import 'package:expense_tracker/models/expense_frequency.dart';
import 'package:uuid/uuid.dart';

// Helper extension to convert between DateTime and Timestamp
extension DateTimeExtension on DateTime {
  Timestamp toTimestamp() => Timestamp.fromDate(this); // Convert DateTime to Firestore Timestamp
}

// Helper extension for Timestamp
extension TimestampExtension on Timestamp {
  DateTime toDateTime() => toDate(); // Return DateTime directly
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? notes;
  final String userId;
  final ExpenseFrequency frequency;
  final bool isRecurring;
  final DateTime? endDate;
  final String? attachmentUrl;
  final String currencyCode;
  final Map<String, SplitExpense>? splitWith;
  final bool isSynced;
  final bool isDeleted;
  final DateTime? lastSyncedAt;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    required this.userId,
    required this.frequency,
    this.isRecurring = false,
    this.endDate,
    this.attachmentUrl,
    this.currencyCode = 'INR',
    this.splitWith,
    this.isSynced = false,
    this.isDeleted = false,
    this.lastSyncedAt,
  }) : id = id ?? const Uuid().v4();

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDateTime(),
      category: map['category'] as String,
      notes: map['notes'] as String?,
      userId: map['userId'] as String,
      frequency: ExpenseFrequency.fromString(map['frequency'] as String),
      isRecurring: map['isRecurring'] as bool,
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDateTime() : null,
      attachmentUrl: map['attachmentUrl'] as String?,
      currencyCode: map['currencyCode'] as String? ?? 'INR',
      splitWith: map['splitWith'] != null
          ? Map<String, SplitExpense>.from(
              (map['splitWith'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, SplitExpense.fromMap(value as Map<String, dynamic>)),
              ),
            )
          : null,
      isSynced: map['isSynced'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      lastSyncedAt: map['lastSyncedAt'] != null ? (map['lastSyncedAt'] as Timestamp).toDateTime() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toTimestamp(),
      'category': category,
      'notes': notes,
      'userId': userId,
      'frequency': frequency.toString(),
      'isRecurring': isRecurring,
      'endDate': endDate?.toTimestamp(),
      'attachmentUrl': attachmentUrl,
      'currencyCode': currencyCode,
      'splitWith': splitWith?.map((key, value) => MapEntry(key, value.toMap())),
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'lastSyncedAt': lastSyncedAt?.toTimestamp(),
    };
  }

  // Copy with method
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
    String? userId,
    ExpenseFrequency? frequency,
    bool? isRecurring,
    DateTime? endDate,
    String? attachmentUrl,
    String? currencyCode,
    Map<String, SplitExpense>? splitWith,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastSyncedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      frequency: frequency ?? this.frequency,
      isRecurring: isRecurring ?? this.isRecurring,
      endDate: endDate ?? this.endDate,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      currencyCode: currencyCode ?? this.currencyCode,
      splitWith: splitWith ?? this.splitWith,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }


}
