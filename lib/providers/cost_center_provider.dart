import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cost_center.dart';
import '../services/cost_center_service.dart';

class CostCenterProvider extends ChangeNotifier {
  List<CostCenter> _costCenters = [];
  List<CostCenter> _filteredCostCenters = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _selectedDepartment = 'all';
  String _sortBy = 'name'; // name, budget, utilization, department
  bool _sortAscending = true;

  final CostCenterService _costCenterService = CostCenterService();

  List<CostCenter> get costCenters => _filteredCostCenters;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  List<String> get departments {
    final departments = _costCenters.map((cc) => cc.department).toSet().toList();
    departments.sort();
    return departments;
  }

  double get totalBudget => _costCenters.fold(0, (sum, cc) => sum + cc.budget);
  double get totalUtilized => _costCenters.fold(0, (sum, cc) => sum + cc.utilized);
  double get totalRemaining => totalBudget - totalUtilized;
  double get overallUtilizationPercentage => totalBudget > 0 ? (totalUtilized / totalBudget) * 100 : 0;

  Future<void> loadCostCenters() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _costCenters = await _costCenterService.getCostCenters();
      _applyFilters();
    } catch (e) {
      _error = 'Erro ao carregar centros de custo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCostCenter(CostCenter costCenter) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newCostCenter = await _costCenterService.createCostCenter(
        name: costCenter.name,
        description: costCenter.description,
        budget: costCenter.budget,
        responsibleUserId: costCenter.responsible,
      );
      if (newCostCenter != null) {
        _costCenters.add(newCostCenter);
        _applyFilters();
      }
      _error = '';
    } catch (e) {
      _error = 'Erro ao adicionar centro de custo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCostCenter(CostCenter costCenter) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedCostCenter = await _costCenterService.updateCostCenter(
        id: int.parse(costCenter.id),
        name: costCenter.name,
        description: costCenter.description,
        budget: costCenter.budget,
        responsibleUserId: costCenter.responsible,
        isActive: costCenter.isActive,
      );
      if (updatedCostCenter != null) {
        final index = _costCenters.indexWhere((cc) => cc.id == costCenter.id);
        if (index != -1) {
          _costCenters[index] = updatedCostCenter;
          _applyFilters();
        }
      }
      _error = '';
    } catch (e) {
      _error = 'Erro ao atualizar centro de custo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCostCenter(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _costCenterService.deleteCostCenter(id);
      _costCenters.removeWhere((cc) => cc.id == id);
      _applyFilters();
      _error = '';
    } catch (e) {
      _error = 'Erro ao excluir centro de custo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(String costCenterId, Expense expense) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newExpense = await _costCenterService.addExpense(costCenterId, expense);
      if (newExpense != null) {
        final index = _costCenters.indexWhere((cc) => cc.id == costCenterId);
        if (index != -1) {
          final updatedExpenses = [..._costCenters[index].expenses, newExpense];
          final updatedCostCenter = _costCenters[index].copyWith(
            expenses: updatedExpenses,
            utilized: _costCenters[index].utilized + expense.amount,
            updatedAt: DateTime.now(),
          );
          _costCenters[index] = updatedCostCenter;
          _applyFilters();
        }
      }
      _error = '';
    } catch (e) {
      _error = 'Erro ao adicionar despesa: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateExpense(String costCenterId, Expense expense) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedExpense = await _costCenterService.updateExpense(costCenterId, expense);
      if (updatedExpense != null) {
        final ccIndex = _costCenters.indexWhere((cc) => cc.id == costCenterId);
        if (ccIndex != -1) {
          final expenseIndex = _costCenters[ccIndex].expenses.indexWhere((e) => e.id == expense.id);
          if (expenseIndex != -1) {
            final oldAmount = _costCenters[ccIndex].expenses[expenseIndex].amount;
            final newAmount = updatedExpense.amount;
            final amountDiff = newAmount - oldAmount;
            
            final updatedExpenses = [..._costCenters[ccIndex].expenses];
            updatedExpenses[expenseIndex] = updatedExpense;
            
            final updatedCostCenter = _costCenters[ccIndex].copyWith(
              expenses: updatedExpenses,
              utilized: _costCenters[ccIndex].utilized + amountDiff,
              updatedAt: DateTime.now(),
            );
            _costCenters[ccIndex] = updatedCostCenter;
            _applyFilters();
          }
        }
      }
      _error = '';
    } catch (e) {
      _error = 'Erro ao atualizar despesa: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String costCenterId, String expenseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _costCenterService.deleteExpense(int.parse(costCenterId), int.parse(expenseId));
      final ccIndex = _costCenters.indexWhere((cc) => cc.id == costCenterId);
      if (ccIndex != -1) {
        final expenseIndex = _costCenters[ccIndex].expenses.indexWhere((e) => e.id == expenseId);
        if (expenseIndex != -1) {
          final amountToRemove = _costCenters[ccIndex].expenses[expenseIndex].amount;
          final updatedExpenses = [..._costCenters[ccIndex].expenses];
          updatedExpenses.removeAt(expenseIndex);
          
          final updatedCostCenter = _costCenters[ccIndex].copyWith(
            expenses: updatedExpenses,
            utilized: _costCenters[ccIndex].utilized - amountToRemove,
            updatedAt: DateTime.now(),
          );
          _costCenters[ccIndex] = updatedCostCenter;
          _applyFilters();
        }
      }
      _error = '';
    } catch (e) {
      _error = 'Erro ao excluir despesa: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setDepartmentFilter(String department) {
    _selectedDepartment = department;
    _applyFilters();
  }

  void setSortBy(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    }
    _applyFilters();
  }

  void toggleSortOrder() {
    _sortAscending = !_sortAscending;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredCostCenters = _costCenters.where((costCenter) {
      final matchesSearch = _searchQuery.isEmpty ||
          costCenter.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          costCenter.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          costCenter.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          costCenter.responsible.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesDepartment = _selectedDepartment == 'all' ||
          costCenter.department == _selectedDepartment;
      
      return matchesSearch && matchesDepartment;
    }).toList();

    // Sort
    _filteredCostCenters.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'budget':
          comparison = a.budget.compareTo(b.budget);
          break;
        case 'utilization':
          comparison = a.utilizationPercentage.compareTo(b.utilizationPercentage);
          break;
        case 'department':
          comparison = a.department.compareTo(b.department);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedDepartment = 'all';
    _sortBy = 'name';
    _sortAscending = true;
    _applyFilters();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}

// Riverpod provider for CostCenterProvider
final costCenterProvider = ChangeNotifierProvider<CostCenterProvider>((ref) {
  return CostCenterProvider();
});