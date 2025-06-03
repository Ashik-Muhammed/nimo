import 'dart:io';

void main() {
  // Create expense.g.dart
  final expenseContent = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a generated file.
part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 1;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      category: fields[4] as String,
      notes: fields[5] as String?,
      userId: fields[6] as String,
      frequency: fields[7] as ExpenseFrequency? ?? ExpenseFrequency.oneTime,
      isRecurring: fields[8] as bool? ?? false,
      endDate: fields[9] as DateTime?,
      attachmentUrl: fields[10] as String?,
      currencyCode: fields[11] as String? ?? 'INR',
      splitWith: (fields[12] as Map?)?.cast<String, SplitExpense>(),
      isSynced: fields[13] as bool? ?? false,
      isDeleted: fields[14] as bool? ?? false,
      lastSyncedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.frequency)
      ..writeByte(8)
      ..write(obj.isRecurring)
      ..writeByte(9)
      ..write(obj.endDate)
      ..writeByte(10)
      ..write(obj.attachmentUrl)
      ..writeByte(11)
      ..write(obj.currencyCode)
      ..writeByte(12)
      ..write(obj.splitWith)
      ..writeByte(13)
      ..write(obj.isSynced)
      ..writeByte(14)
      ..write(obj.isDeleted)
      ..writeByte(15)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
''';

  // Create expense_frequency.g.dart
  final expenseFrequencyContent = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a generated file.
part of 'expense_frequency.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseFrequencyAdapter extends TypeAdapter<ExpenseFrequency> {
  @override
  final int typeId = 0;

  @override
  ExpenseFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseFrequency.oneTime;
      case 1:
        return ExpenseFrequency.daily;
      case 2:
        return ExpenseFrequency.weekly;
      case 3:
        return ExpenseFrequency.monthly;
      case 4:
        return ExpenseFrequency.yearly;
      default:
        return ExpenseFrequency.oneTime;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseFrequency obj) {
    switch (obj) {
      case ExpenseFrequency.oneTime:
        writer.writeByte(0);
        break;
      case ExpenseFrequency.daily:
        writer.writeByte(1);
        break;
      case ExpenseFrequency.weekly:
        writer.writeByte(2);
        break;
      case ExpenseFrequency.monthly:
        writer.writeByte(3);
        break;
      case ExpenseFrequency.yearly:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
''';

  // Create split_expense.g.dart
  final splitExpenseContent = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a generated file.
part of 'split_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitExpenseAdapter extends TypeAdapter<SplitExpense> {
  @override
  final int typeId = 2;

  @override
  SplitExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitExpense(
      userId: fields[0] as String,
      amount: fields[1] as double,
      isPaid: fields[2] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SplitExpense obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.isPaid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
''';

  // Create directories if they don't exist
  Directory('lib/models').createSync(recursive: true);

  // Write the files
  File('lib/models/expense.g.dart').writeAsStringSync(expenseContent);
  File('lib/models/expense_frequency.g.dart')
      .writeAsStringSync(expenseFrequencyContent);
  File('lib/models/split_expense.g.dart')
      .writeAsStringSync(splitExpenseContent);

  print('Hive adapters generated successfully!');
}
