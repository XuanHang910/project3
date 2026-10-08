import 'expense_category.dart';

class TransactionModel {
  final int? id;
  final String merchant;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? imagePath;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.date,
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      merchant: map['merchant'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.food,
      ),
      date: DateTime.parse(map['date'] as String),
      imagePath: map['imagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

