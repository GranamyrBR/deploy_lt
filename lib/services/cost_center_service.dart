import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cost_center.dart';
import '../models/user_roles.dart';

class CostCenterService {
  SupabaseClient get _client => Supabase.instance.client;

  // Get all cost centers
  Future<List<CostCenter>> getCostCenters({bool? isActive}) async {
    try {
      var query = _client.from('cost_center').select('*');

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('name');

      return (response as List)
          .map((json) => CostCenter.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching cost centers: $e');
      // Return mock data if Supabase is not available
      return _getMockCostCenters();
    }
  }

  // Get cost center by ID
  Future<CostCenter?> getCostCenterById(int id) async {
    try {
      final response =
          await _client.from('cost_center').select('*').eq('id', id).single();

      return CostCenter.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching cost center by ID: $e');
      return null;
    }
  }

  // Create cost center
  Future<CostCenter?> createCostCenter({
    required String name,
    String? description,
    required double budget,
    String? responsibleUserId,
  }) async {
    try {
      final data = {
        'name': name,
        'description': description,
        'budget': budget,
        'spent': 0.0,
        'responsible_user_id': responsibleUserId,
        'is_active': true,
      };

      final response =
          await _client.from('cost_center').insert(data).select().single();

      return CostCenter.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating cost center: $e');
      return null;
    }
  }

  // Update cost center
  Future<CostCenter?> updateCostCenter({
    required int id,
    String? name,
    String? description,
    double? budget,
    String? responsibleUserId,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (budget != null) data['budget'] = budget;
      if (responsibleUserId != null)
        data['responsible_user_id'] = responsibleUserId;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _client
          .from('cost_center')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return CostCenter.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating cost center: $e');
      return null;
    }
  }

  // Get cost center categories
  Future<List<CostCenterCategory>> getCostCenterCategories(
      {bool? isActive}) async {
    try {
      var query = _client.from('cost_center_category').select('*');

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('name');

      return (response as List)
          .map((json) =>
              CostCenterCategory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching cost center categories: $e');
      return [];
    }
  }

  // Get expenses for a cost center
  Future<List<CostCenterExpense>> getCostCenterExpenses({
    required int costCenterId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('cost_center_expense')
          .select('*')
          .eq('cost_center_id', costCenterId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('expense_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('expense_date', endDate.toIso8601String());
      }

      final response = await query.order('expense_date', ascending: false);

      return (response as List)
          .map((json) =>
              CostCenterExpense.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching cost center expenses: $e');
      return [];
    }
  }

  // Create expense
  Future<CostCenterExpense?> createExpense({
    required int costCenterId,
    int? categoryId,
    required String description,
    required double amount,
    required int currencyId,
    required DateTime expenseDate,
    required String createdBy,
    String? receiptUrl,
  }) async {
    try {
      // Get exchange rates
      final exchangeRateToUsd = await _getExchangeRate(currencyId);

      // Calculate amounts in different currencies
      final amountInUsd = currencyId == 1 ? amount : amount / exchangeRateToUsd;
      final amountInBrl = currencyId == 2 ? amount : amount * exchangeRateToUsd;

      final data = {
        'cost_center_id': costCenterId,
        'category_id': categoryId,
        'description': description,
        'amount': amount,
        'currency_id': currencyId,
        'exchange_rate': exchangeRateToUsd,
        'amount_in_brl': amountInBrl,
        'amount_in_usd': amountInUsd,
        'expense_date': expenseDate.toIso8601String(),
        'created_by': createdBy,
        'status': 'pending',
        'receipt_url': receiptUrl,
      };

      final response = await _client
          .from('cost_center_expense')
          .insert(data)
          .select()
          .single();

      // Update cost center spent amount
      await _updateCostCenterSpent(costCenterId);

      return CostCenterExpense.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating expense: $e');
      return null;
    }
  }

  // Approve expense
  Future<bool> approveExpense({
    required int expenseId,
    required String approvedBy,
  }) async {
    try {
      final data = {
        'status': 'approved',
        'approved_by': approvedBy,
        'approved_at': DateTime.now().toUtc().toIso8601String(),
      };

      await _client
          .from('cost_center_expense')
          .update(data)
          .eq('id', expenseId);

      // Get the expense to update the cost center spent amount
      final expense = await _client
          .from('cost_center_expense')
          .select('cost_center_id')
          .eq('id', expenseId)
          .single();

      await _updateCostCenterSpent(expense['cost_center_id']);

      return true;
    } catch (e) {
      print('Error approving expense: $e');
      return false;
    }
  }

  // Reject expense
  Future<bool> rejectExpense({
    required int expenseId,
    required String rejectedBy,
  }) async {
    try {
      final data = {
        'status': 'rejected',
        'approved_by': rejectedBy, // Using the same field for rejection
        'approved_at': DateTime.now().toUtc().toIso8601String(),
      };

      await _client
          .from('cost_center_expense')
          .update(data)
          .eq('id', expenseId);

      // Get the expense to update the cost center spent amount
      final expense = await _client
          .from('cost_center_expense')
          .select('cost_center_id')
          .eq('id', expenseId)
          .single();

      await _updateCostCenterSpent(expense['cost_center_id']);

      return true;
    } catch (e) {
      print('Error rejecting expense: $e');
      return false;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(int costCenterId, int expenseId) async {
    try {
      await _client
          .from('cost_center_expense')
          .delete()
          .eq('id', expenseId)
          .eq('cost_center_id', costCenterId);

      // Update cost center spent amount
      await _updateCostCenterSpent(costCenterId);

      return true;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // Add expense (compatibility method for old Expense model)
  Future<Expense?> addExpense(String costCenterId, Expense expense) async {
    try {
      final newExpense = await createExpense(
        costCenterId: int.parse(costCenterId),
        description: expense.description,
        amount: expense.amount,
        currencyId: 2, // Default to BRL
        expenseDate: expense.date,
        createdBy: 'system', // Default user
      );

      if (newExpense != null) {
        // Convert CostCenterExpense to Expense
        return Expense(
          id: newExpense.id.toString(),
          costCenterId: costCenterId,
          description: newExpense.description,
          amount: newExpense.amount,
          date: newExpense.expenseDate,
          category: 'general', // Default category
          type: ExpenseType.VARIABLE, // Default type
          createdAt: newExpense.createdAt,
        );
      }
      return null;
    } catch (e) {
      print('Error adding expense: $e');
      return null;
    }
  }

  // Update expense (compatibility method for old Expense model)
  Future<Expense?> updateExpense(String costCenterId, Expense expense) async {
    try {
      // For compatibility, we'll create a new expense and delete the old one
      final newExpense = await createExpense(
        costCenterId: int.parse(costCenterId),
        description: expense.description,
        amount: expense.amount,
        currencyId: 2, // Default to BRL
        expenseDate: expense.date,
        createdBy: 'system', // Default user
      );

      if (newExpense != null && expense.id != null) {
        // Delete the old expense
        await deleteExpense(int.parse(costCenterId), int.parse(expense.id!));

        // Convert CostCenterExpense to Expense
        return Expense(
          id: newExpense.id.toString(),
          costCenterId: costCenterId,
          description: newExpense.description,
          amount: newExpense.amount,
          date: newExpense.expenseDate,
          category: expense.category,
          type: newExpense.type,
          createdAt: newExpense.createdAt,
        );
      }
      return null;
    } catch (e) {
      print('Error updating expense: $e');
      return null;
    }
  }

  // Helper method to get exchange rate
  Future<double> _getExchangeRate(int currencyId) async {
    try {
      // Default exchange rate (USD to BRL)
      double defaultRate = 5.50;

      // If currency is USD, return 1.0
      if (currencyId == 1) return 1.0;

      // If currency is BRL, try to get the current rate
      if (currencyId == 2) {
        try {
          final response = await _client
              .from('exchange_rate')
              .select('rate')
              .eq('from_currency_id', 1)
              .eq('to_currency_id', 2)
              .order('created_at', ascending: false)
              .order('id', ascending: false).limit(1)
              .single();

          return response['rate'] as double;
        } catch (e) {
          print('Error getting exchange rate, using default: $e');
          return defaultRate;
        }
      }

      // For other currencies, try to get the rate to USD
      try {
        final response = await _client
            .from('exchange_rate')
            .select('rate')
            .eq('from_currency_id', currencyId)
            .eq('to_currency_id', 1)
            .order('created_at', ascending: false)
            .order('id', ascending: false).limit(1)
            .single();

        return response['rate'] as double;
      } catch (e) {
        print('Error getting exchange rate, using default: $e');
        return defaultRate;
      }
    } catch (e) {
      print('Error in _getExchangeRate: $e');
      return 5.50; // Default fallback
    }
  }

  // Helper method to update cost center spent amount
  Future<void> _updateCostCenterSpent(int costCenterId) async {
    try {
      // Get all approved expenses for this cost center
      final expenses = await _client
          .from('cost_center_expense')
          .select('amount_in_usd')
          .eq('cost_center_id', costCenterId)
          .eq('status', 'approved');

      // Calculate total spent
      double totalSpent = 0.0;
      for (final expense in expenses) {
        totalSpent += expense['amount_in_usd'] as double;
      }

      // Update cost center
      await _client
          .from('cost_center')
          .update({'spent': totalSpent}).eq('id', costCenterId);
    } catch (e) {
      print('Error updating cost center spent: $e');
    }
  }

  // Check if user has access to cost center
  bool userHasCostCenterAccess(List<String> userPermissions) {
    return userPermissions.contains(UserRoles.VIEW_COST_CENTER) ||
        userPermissions.contains(UserRoles.MANAGE_COST_CENTER) ||
        userPermissions.contains(UserRoles.ADMIN);
  }

  // Mock data for development - Exemplos baseados em pesquisa de melhores práticas
  List<CostCenter> _getMockCostCenters() {
    return [
      // Centro de Custo: Marketing Digital (Baseado em pesquisa)
      CostCenter(
        id: 'cc001',
        name: 'Marketing Digital',
        description:
            'Campanhas de marketing digital, redes sociais, Google Ads, Facebook Ads',
        code: 'MKT-DIG-001',
        budget: 50000.00,
        utilized: 32500.00,
        responsible: 'Ana Silva',
        department: 'Marketing',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        expenses: _getMarketingExpenses('cc001'),
      ),
      // Centro de Custo: Desenvolvimento de Software (Baseado em pesquisa)
      CostCenter(
        id: 'cc002',
        name: 'Desenvolvimento de Software',
        description:
            'Desenvolvimento, manutenção, licenças de software, cloud computing',
        code: 'DEV-SFT-001',
        budget: 120000.00,
        utilized: 87500.00,
        responsible: 'Carlos Oliveira',
        department: 'Tecnologia',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        expenses: _getDevelopmentExpenses('cc002'),
      ),
      // Centro de Custo: Vendas e Comercial (Baseado em pesquisa)
      CostCenter(
        id: 'cc003',
        name: 'Vendas e Comercial',
        description:
            'Salários de vendedores, comissões, promoções, viagens comerciais',
        code: 'VND-COM-001',
        budget: 80000.00,
        utilized: 42000.00,
        responsible: 'Marina Santos',
        department: 'Vendas',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
        expenses: _getSalesExpenses('cc003'),
      ),
      // Centro de Custo: Frota de Veículos (Exemplo de pesquisa - despesas fixas/variáveis)
      CostCenter(
        id: 'cc004',
        name: 'Frota de Veículos',
        description:
            'Seguro de carro, prestação, manutenção, combustível, IPVA',
        code: 'FLT-001',
        budget: 45000.00,
        utilized: 28000.00,
        responsible: 'Pedro Costa',
        department: 'Operações',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 80)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        expenses: _getFleetExpenses('cc004'),
      ),
      // Centro de Custo: Recursos Humanos (Baseado em pesquisa)
      CostCenter(
        id: 'cc005',
        name: 'Recursos Humanos',
        description:
            'Salários administrativos, treinamentos, benefícios, recrutamento',
        code: 'RH-ADM-001',
        budget: 65000.00,
        utilized: 48000.00,
        responsible: 'Julia Ferreira',
        department: 'RH',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 110)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        expenses: _getHRExpenses('cc005'),
      ),
      // Centro de Custo: Retirada de Sócios (Baseado em pesquisa)
      CostCenter(
        id: 'cc006',
        name: 'Retirada de Sócios',
        description: 'Distribuição de lucros, retiradas de sócios, dividendos',
        code: 'SOC-001',
        budget: 30000.00,
        utilized: 15000.00,
        responsible: 'Sócios',
        department: 'Financeiro',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        expenses: _getPartnerWithdrawalExpenses('cc006'),
      ),
    ];
  }

  // Despesas de Marketing Digital (Exemplos da pesquisa)
  List<Expense> _getMarketingExpenses(String costCenterId) {
    return [
      Expense(
        id: 'exp001',
        costCenterId: costCenterId,
        description: 'Google Ads - Campanha Search',
        amount: 5000.00,
        date: DateTime.now().subtract(const Duration(days: 15)),
        category: 'Publicidade Online',
        type: ExpenseType.VARIABLE,
        vendor: 'Google',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Expense(
        id: 'exp002',
        costCenterId: costCenterId,
        description: 'Facebook Ads - Campanha Display',
        amount: 3500.00,
        date: DateTime.now().subtract(const Duration(days: 10)),
        category: 'Publicidade Online',
        type: ExpenseType.VARIABLE,
        vendor: 'Meta',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Expense(
        id: 'exp003',
        costCenterId: costCenterId,
        description: 'Licença HubSpot - Mensalidade',
        amount: 1200.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
        category: 'Ferramentas',
        type: ExpenseType.FIXED,
        vendor: 'HubSpot',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Expense(
        id: 'exp004',
        costCenterId: costCenterId,
        description: 'Consultoria SEO',
        amount: 8000.00,
        date: DateTime.now().subtract(const Duration(days: 20)),
        category: 'Consultoria',
        type: ExpenseType.VARIABLE,
        vendor: 'Agência SEO',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Expense(
        id: 'exp005',
        costCenterId: costCenterId,
        description: 'Criação de Conteúdo',
        amount: 4500.00,
        date: DateTime.now().subtract(const Duration(days: 25)),
        category: 'Produção de Conteúdo',
        type: ExpenseType.VARIABLE,
        vendor: 'Redator Freelancer',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
    ];
  }

  // Despesas de Desenvolvimento (Exemplos da pesquisa)
  List<Expense> _getDevelopmentExpenses(String costCenterId) {
    return [
      Expense(
        id: 'exp006',
        costCenterId: costCenterId,
        description: 'AWS - Hospedagem Cloud',
        amount: 8500.00,
        date: DateTime.now().subtract(const Duration(days: 8)),
        category: 'Infraestrutura',
        type: ExpenseType.VARIABLE,
        vendor: 'Amazon Web Services',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Expense(
        id: 'exp007',
        costCenterId: costCenterId,
        description: 'Licença JetBrains - Equipe',
        amount: 2500.00,
        date: DateTime.now().subtract(const Duration(days: 12)),
        category: 'Ferramentas',
        type: ExpenseType.FIXED,
        vendor: 'JetBrains',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Expense(
        id: 'exp008',
        costCenterId: costCenterId,
        description: 'GitHub - Plano Enterprise',
        amount: 1800.00,
        date: DateTime.now().subtract(const Duration(days: 6)),
        category: 'Ferramentas',
        type: ExpenseType.FIXED,
        vendor: 'GitHub',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      Expense(
        id: 'exp009',
        costCenterId: costCenterId,
        description: 'Consultoria de Arquitetura',
        amount: 12000.00,
        date: DateTime.now().subtract(const Duration(days: 18)),
        category: 'Consultoria',
        type: ExpenseType.VARIABLE,
        vendor: 'Arquiteto Cloud',
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
      Expense(
        id: 'exp010',
        costCenterId: costCenterId,
        description: 'Curso de Certificação AWS',
        amount: 3500.00,
        date: DateTime.now().subtract(const Duration(days: 22)),
        category: 'Treinamento',
        type: ExpenseType.VARIABLE,
        vendor: 'AWS Training',
        createdAt: DateTime.now().subtract(const Duration(days: 22)),
      ),
    ];
  }

  // Despesas de Vendas (Exemplos da pesquisa)
  List<Expense> _getSalesExpenses(String costCenterId) {
    return [
      Expense(
        id: 'exp011',
        costCenterId: costCenterId,
        description: 'Comissões de Vendas - Março',
        amount: 15000.00,
        date: DateTime.now().subtract(const Duration(days: 10)),
        category: 'Comissões',
        type: ExpenseType.VARIABLE,
        vendor: 'Equipe de Vendas',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Expense(
        id: 'exp012',
        costCenterId: costCenterId,
        description: 'Viagem Comercial - São Paulo',
        amount: 4200.00,
        date: DateTime.now().subtract(const Duration(days: 15)),
        category: 'Viagens',
        type: ExpenseType.VARIABLE,
        vendor: 'CVC Viagens',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Expense(
        id: 'exp013',
        costCenterId: costCenterId,
        description: 'Promoção de Lançamento',
        amount: 8000.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
        category: 'Promoções',
        type: ExpenseType.VARIABLE,
        vendor: 'Agência de Eventos',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Expense(
        id: 'exp014',
        costCenterId: costCenterId,
        description: 'Salário Base Equipe Vendas',
        amount: 12000.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Salários',
        type: ExpenseType.FIXED,
        vendor: 'Funcionários',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Despesas de Frota (Exemplos da pesquisa - Fixas vs Variáveis)
  List<Expense> _getFleetExpenses(String costCenterId) {
    return [
      // DESPESAS FIXAS
      Expense(
        id: 'exp015',
        costCenterId: costCenterId,
        description: 'Seguro Veicular - Mensalidade',
        amount: 1800.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
        category: 'Seguros',
        type: ExpenseType.FIXED,
        vendor: 'Porto Seguro',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Expense(
        id: 'exp016',
        costCenterId: costCenterId,
        description: 'Prestação do Carro - Mensal',
        amount: 3500.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Financiamento',
        type: ExpenseType.FIXED,
        vendor: 'Banco Santander',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 'exp017',
        costCenterId: costCenterId,
        description: 'IPVA - Parcela',
        amount: 450.00,
        date: DateTime.now().subtract(const Duration(days: 20)),
        category: 'Impostos',
        type: ExpenseType.FIXED,
        vendor: 'Detran',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      // DESPESAS VARIÁVEIS
      Expense(
        id: 'exp018',
        costCenterId: costCenterId,
        description: 'Combustível - Abastecimento',
        amount: 2500.00,
        date: DateTime.now().subtract(const Duration(days: 3)),
        category: 'Combustível',
        type: ExpenseType.VARIABLE,
        vendor: 'Posto Shell',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Expense(
        id: 'exp019',
        costCenterId: costCenterId,
        description: 'Manutenção Preventiva',
        amount: 800.00,
        date: DateTime.now().subtract(const Duration(days: 15)),
        category: 'Manutenção',
        type: ExpenseType.VARIABLE,
        vendor: 'Mecânica Silva',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Expense(
        id: 'exp020',
        costCenterId: costCenterId,
        description: 'Lavagem e Higienização',
        amount: 150.00,
        date: DateTime.now().subtract(const Duration(days: 7)),
        category: 'Limpeza',
        type: ExpenseType.VARIABLE,
        vendor: 'Lava Rápido',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  // Despesas de RH (Baseado em pesquisa)
  List<Expense> _getHRExpenses(String costCenterId) {
    return [
      Expense(
        id: 'exp021',
        costCenterId: costCenterId,
        description: 'Salário Equipe Administrativa',
        amount: 25000.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Salários',
        type: ExpenseType.FIXED,
        vendor: 'Funcionários',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 'exp022',
        costCenterId: costCenterId,
        description: 'Benefícios - Vale Refeição',
        amount: 4200.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
        category: 'Benefícios',
        type: ExpenseType.FIXED,
        vendor: 'Ticket',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Expense(
        id: 'exp023',
        costCenterId: costCenterId,
        description: 'Treinamento de Liderança',
        amount: 3500.00,
        date: DateTime.now().subtract(const Duration(days: 12)),
        category: 'Treinamento',
        type: ExpenseType.VARIABLE,
        vendor: 'Consultoria RH',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Expense(
        id: 'exp024',
        costCenterId: costCenterId,
        description: 'Recrutamento e Seleção',
        amount: 2800.00,
        date: DateTime.now().subtract(const Duration(days: 18)),
        category: 'Recrutamento',
        type: ExpenseType.VARIABLE,
        vendor: 'Headhunter',
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
    ];
  }

  // Despesas de Retirada de Sócios (Baseado em pesquisa)
  List<Expense> _getPartnerWithdrawalExpenses(String costCenterId) {
    return [
      Expense(
        id: 'exp025',
        costCenterId: costCenterId,
        description: 'Distribuição de Lucros - Sócio A',
        amount: 8000.00,
        date: DateTime.now().subtract(const Duration(days: 10)),
        category: 'Distribuição de Lucros',
        type: ExpenseType.VARIABLE,
        vendor: 'Sócio A',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Expense(
        id: 'exp026',
        costCenterId: costCenterId,
        description: 'Distribuição de Lucros - Sócio B',
        amount: 7000.00,
        date: DateTime.now().subtract(const Duration(days: 10)),
        category: 'Distribuição de Lucros',
        type: ExpenseType.VARIABLE,
        vendor: 'Sócio B',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Expense(
        id: 'exp027',
        costCenterId: costCenterId,
        description: 'Pró-Labore - Sócio A',
        amount: 5000.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Pró-Labore',
        type: ExpenseType.FIXED,
        vendor: 'Sócio A',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 'exp028',
        costCenterId: costCenterId,
        description: 'Pró-Labore - Sócio B',
        amount: 4500.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Pró-Labore',
        type: ExpenseType.FIXED,
        vendor: 'Sócio B',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Delete cost center
  Future<bool> deleteCostCenter(String id) async {
    try {
      await _client.from('cost_center').delete().eq('id', id);

      return true;
    } catch (e) {
      print('Error deleting cost center: $e');
      return false;
    }
  }
}
