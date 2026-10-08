import 'package:flutter/material.dart';

enum ExpenseCategory {
  food(Icons.restaurant, Colors.orange),
  study(Icons.menu_book, Colors.blue),
  travel(Icons.flight, Colors.green),
  gear(Icons.computer, Colors.purple),
  entertainment(Icons.movie, Colors.red);

  final IconData icon;
  final Color color;

  const ExpenseCategory(this.icon, this.color);

  String get name => toString().split('.').last;
}

