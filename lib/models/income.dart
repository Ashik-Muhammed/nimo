import 'package:cloud_firestore/cloud_firestore.dart';

class Income {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String source;  
  final String? notes;
  final String userId;
  final bool isRecurring;
  final IncomeFrequency frequency;
  final DateTime? endDate;
  final String currencyCode;
  final String? attachmentUrl;

  const Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.source,
    this.notes,
    required this.userId,
    this.isRecurring = false,
    this.frequency = IncomeFrequency.oneTime,
    this.endDate,
    this.currencyCode = 'USD',
    this.attachmentUrl,
  });

  // Convert Income to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date,
      'source': source,
      'notes': notes,
      'userId': userId,
      'isRecurring': isRecurring,
      'frequency': frequency.toString(),
      'endDate': endDate,
      'currencyCode': currencyCode,
      'attachmentUrl': attachmentUrl,
    };
  }

  // Create Income from Firestore document
  factory Income.fromMap(Map<String, dynamic> map, String documentId) {
    return Income(
      id: documentId,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      source: map['source'] as String? ?? 'Other',
      notes: map['notes'] as String?,
      userId: map['userId'] as String,
      isRecurring: map['isRecurring'] as bool? ?? false,
      frequency: IncomeFrequency.values.firstWhere(
        (e) => e.toString() == 'IncomeFrequency.${map['frequency']}',
        orElse: () => IncomeFrequency.oneTime,
      ),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      attachmentUrl: map['attachmentUrl'] as String?,
    );
  }

  // Create a copy of Income with updated fields
  Income copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? source,
    String? notes,
    String? userId,
    bool? isRecurring,
    IncomeFrequency? frequency,
    DateTime? endDate,
    String? currencyCode,
    String? attachmentUrl,
  }) {
    return Income(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      endDate: endDate ?? this.endDate,
      currencyCode: currencyCode ?? this.currencyCode,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}

enum IncomeFrequency {
  oneTime,
  daily,
  weekly,
  biWeekly,
  monthly,
  quarterly,
  yearly,
}
