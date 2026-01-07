import 'package:flutter/foundation.dart';

enum ExpenseType {
  FIXED,    // Despesas Fixas
  VARIABLE, // Despesas Variáveis
}

@immutable
class CostCenter {
  final String id;
  final String name;
  final String description;
  final String code;
  final double budget;
  final double utilized;
  final String responsible;
  final String department;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Expense> expenses;
  final bool isActive;

  const CostCenter({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    required this.budget,
    required this.utilized,
    required this.responsible,
    required this.department,
    required this.createdAt,
    required this.updatedAt,
    this.expenses = const [],
    this.isActive = true,
  });

  double get utilizationPercentage => (utilized / budget) * 100;
  double get utilizationRate => utilizationPercentage; // Alias for enhanced charts
  double get remainingBudget => budget - utilized;
  bool get isOverBudget => utilized > budget;
  int get expenseCount => expenses.length;
  double get spent => utilized;
  double get available => remainingBudget;

  // KPIs Financeiros
  double get fixedExpenses => expenses
      .where((e) => e.type == ExpenseType.FIXED)
      .fold(0.0, (sum, e) => sum + e.amount);
  
  double get variableExpenses => expenses
      .where((e) => e.type == ExpenseType.VARIABLE)
      .fold(0.0, (sum, e) => sum + e.amount);
  
  double get fixedExpensePercentage => 
      expenses.isEmpty ? 0.0 : (fixedExpenses / utilized) * 100;
  
  double get variableExpensePercentage => 
      expenses.isEmpty ? 0.0 : (variableExpenses / utilized) * 100;
  
  double get roiPercentage => 
      budget == 0.0 ? 0.0 : ((budget - utilized) / budget) * 100;
  
  double get costPerExpense => 
      expenses.isEmpty ? 0.0 : utilized / expenses.length;
  
  Map<String, double> get expensesByCategory {
    final Map<String, double> categories = {};
    for (final expense in expenses) {
      categories.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return categories;
  }

  Map<ExpenseType, double> get expensesByType {
    return {
      ExpenseType.FIXED: fixedExpenses,
      ExpenseType.VARIABLE: variableExpenses,
    };
  }

  factory CostCenter.fromJson(Map<String, dynamic> json) {
    return CostCenter(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      code: json['code'],
      budget: json['budget'].toDouble(),
      utilized: json['utilized'].toDouble(),
      responsible: json['responsible'],
      department: json['department'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      expenses: (json['expenses'] as List<dynamic>?)
          ?.map((e) => Expense.fromJson(e))
          .toList() ?? [],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'budget': budget,
      'utilized': utilized,
      'responsible': responsible,
      'department': department,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'isActive': isActive,
    };
  }

  CostCenter copyWith({
    String? id,
    String? name,
    String? description,
    String? code,
    double? budget,
    double? utilized,
    String? responsible,
    String? department,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Expense>? expenses,
    bool? isActive,
  }) {
    return CostCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      budget: budget ?? this.budget,
      utilized: utilized ?? this.utilized,
      responsible: responsible ?? this.responsible,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expenses: expenses ?? this.expenses,
      isActive: isActive ?? this.isActive,
    );
  }
}

@immutable
class CostCenterCategory {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const CostCenterCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  factory CostCenterCategory.fromJson(Map<String, dynamic> json) {
    return CostCenterCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

@immutable
class CostCenterExpense {
  final int id;
  final int costCenterId;
  final int? categoryId;
  final String description;
  final double amount;
  final int currencyId;
  final double exchangeRate;
  final double amountInBrl;
  final double amountInUsd;
  final DateTime expenseDate;
  final String createdBy;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? receiptUrl;
  final DateTime createdAt;
  final ExpenseType type;

  const CostCenterExpense({
    required this.id,
    required this.costCenterId,
    this.categoryId,
    required this.description,
    required this.amount,
    required this.currencyId,
    required this.exchangeRate,
    required this.amountInBrl,
    required this.amountInUsd,
    required this.expenseDate,
    required this.createdBy,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.receiptUrl,
    required this.createdAt,
    required this.type,
  });

  factory CostCenterExpense.fromJson(Map<String, dynamic> json) {
    return CostCenterExpense(
      id: json['id'],
      costCenterId: json['cost_center_id'],
      categoryId: json['category_id'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      currencyId: json['currency_id'],
      exchangeRate: json['exchange_rate'].toDouble(),
      amountInBrl: json['amount_in_brl'].toDouble(),
      amountInUsd: json['amount_in_usd'].toDouble(),
      expenseDate: DateTime.parse(json['expense_date']),
      createdBy: json['created_by'],
      status: json['status'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      receiptUrl: json['receipt_url'],
      createdAt: DateTime.parse(json['created_at']),
      type: ExpenseType.values.firstWhere(
        (e) => e.toString() == 'ExpenseType.${json['type']}',
        orElse: () => ExpenseType.VARIABLE,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cost_center_id': costCenterId,
      'category_id': categoryId,
      'description': description,
      'amount': amount,
      'currency_id': currencyId,
      'exchange_rate': exchangeRate,
      'amount_in_brl': amountInBrl,
      'amount_in_usd': amountInUsd,
      'expense_date': expenseDate.toIso8601String(),
      'created_by': createdBy,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'receipt_url': receiptUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

@immutable
class Expense {
  final String id;
  final String costCenterId;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final ExpenseType type; // FIXED or VARIABLE
  final String? vendor;
  final String? notes;
  final String? receiptUrl;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.costCenterId,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.vendor,
    this.notes,
    this.receiptUrl,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      costCenterId: json['costCenterId'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      category: json['category'],
      type: ExpenseType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ExpenseType.VARIABLE,
      ),
      vendor: json['vendor'],
      notes: json['notes'],
      receiptUrl: json['receiptUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'costCenterId': costCenterId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'type': type.toString().split('.').last,
      'vendor': vendor,
      'notes': notes,
      'receiptUrl': receiptUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}