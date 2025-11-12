import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

class Expense extends HiveObject {
  String id;
  String title;
  double amount;
  String category;
  DateTime date;
  String iconName;
  int colorValue;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.iconName,
    required this.colorValue,
  });

  // Getters for icon and color
  IconData get icon {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'local_hospital':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }

  Color get color => Color(colorValue);

  // Convert to/from Map for easier handling
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'iconName': iconName,
      'colorValue': colorValue,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      iconName: map['iconName'] as String,
      colorValue: map['colorValue'] as int,
    );
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? iconName,
    int? colorValue,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

