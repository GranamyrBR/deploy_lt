import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/firebase_account.dart';

class FirebaseAccountService {
  static const String _storageKey = 'firebase_accounts';
  static const String _activeAccountKey = 'active_firebase_account_id';
  
  static FirebaseAccountService? _instance;
  static FirebaseAccountService get instance {
    _instance ??= FirebaseAccountService._internal();
    return _instance!;
  }
  
  FirebaseAccountService._internal();
  
  List<FirebaseAccount> _accounts = [];
  FirebaseAccount? _activeAccount;
  
  // Getters
  List<FirebaseAccount> get accounts => List.unmodifiable(_accounts);
  FirebaseAccount? get activeAccount {
    try {
      return _accounts.firstWhere((account) => account.isActive);
    } catch (e) {
      return _accounts.isNotEmpty ? _accounts.first : null;
    }
  }
  
  // Inicializar o serviço carregando as contas salvas
  Future<void> initialize() async {
    await _loadAccounts();
    await _loadActiveAccount();
    
    // Se não há conta ativa, criar uma conta padrão
    if (_activeAccount == null && _accounts.isEmpty) {
      await _createDefaultAccount();
    }
  }
  
  // Carregar contas do SharedPreferences
  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_storageKey);
      
      if (accountsJson != null) {
        final List<dynamic> accountsList = json.decode(accountsJson);
        _accounts = accountsList
            .map((json) => FirebaseAccount.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Erro ao carregar contas Firebase: $e');
      _accounts = [];
    }
  }
  
  // Carregar conta ativa
  Future<void> _loadActiveAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeAccountId = prefs.getString(_activeAccountKey);
      
      if (activeAccountId != null) {
        try {
          _activeAccount = _accounts.firstWhere(
            (account) => account.id == activeAccountId,
          );
        } catch (e) {
          _activeAccount = _accounts.isNotEmpty ? _accounts.first : null;
        }
      } else if (_accounts.isNotEmpty) {
        _activeAccount = _accounts.first;
      }
    } catch (e) {
      print('Erro ao carregar conta ativa: $e');
      _activeAccount = _accounts.isNotEmpty ? _accounts.first : null;
    }
  }
  
  // Salvar contas no SharedPreferences
  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = json.encode(
        _accounts.map((account) => account.toJson()).toList(),
      );
      await prefs.setString(_storageKey, accountsJson);
    } catch (e) {
      print('Erro ao salvar contas Firebase: $e');
    }
  }
  
  // Salvar conta ativa
  Future<void> _saveActiveAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeAccount != null) {
        await prefs.setString(_activeAccountKey, _activeAccount!.id);
      } else {
        await prefs.remove(_activeAccountKey);
      }
    } catch (e) {
      print('Erro ao salvar conta ativa: $e');
    }
  }
  
  // Criar conta padrão
  Future<void> _createDefaultAccount() async {
    final defaultAccount = FirebaseAccount(
      id: 'default',
      name: 'lecotour-dashboard',
      displayName: 'Lecotour Dashboard (Padrão)',
      projectId: 'lecotour-dashboard',
      apiKey: 'YOUR_FIREBASE_KEY_HERE',
      description: 'Conta Firebase padrão do projeto Lecotour Dashboard',
      isDefault: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      testConnectionUrl: 'https://testconnection-6jqkhayvia-uc.a.run.app',
      searchFlightUrl: 'https://searchflight-6jqkhayvia-uc.a.run.app',
      getAirportFlightsUrl: 'https://getairportflights-6jqkhayvia-uc.a.run.app',
      getBrazilUsaFlightsUrl: 'https://getbrazilusaflights-6jqkhayvia-uc.a.run.app',
    );
    
    await addAccount(defaultAccount);
    await setActiveAccount(defaultAccount.id);
  }
  
  // Adicionar nova conta
  Future<void> addAccount(FirebaseAccount account) async {
    // Verificar se já existe uma conta com o mesmo ID
    final existingIndex = _accounts.indexWhere((a) => a.id == account.id);
    
    if (existingIndex >= 0) {
      // Atualizar conta existente
      _accounts[existingIndex] = account.copyWith(updatedAt: DateTime.now());
    } else {
      // Adicionar nova conta
      _accounts.add(account);
    }
    
    await _saveAccounts();
  }
  
  // Remover conta
  Future<bool> removeAccount(String accountId) async {
    if (accountId == 'default') {
      return false; // Não permitir remover a conta padrão
    }
    
    final removedIndex = _accounts.indexWhere((a) => a.id == accountId);
    if (removedIndex >= 0) {
      _accounts.removeAt(removedIndex);
      
      // Se a conta removida era a ativa, definir outra como ativa
      if (_activeAccount?.id == accountId) {
        _activeAccount = _accounts.isNotEmpty ? _accounts.first : null;
        await _saveActiveAccount();
      }
      
      await _saveAccounts();
      return true;
    }
    
    return false;
  }
  
  // Definir conta ativa
  Future<bool> setActiveAccount(String accountId) async {
    FirebaseAccount? account;
    try {
      account = _accounts.firstWhere((a) => a.id == accountId);
    } catch (e) {
      account = null;
    }
    
    if (account != null && account.isActive) {
      _activeAccount = account;
      await _saveActiveAccount();
      return true;
    }
    
    return false;
  }
  
  // Atualizar conta
  Future<bool> updateAccount(FirebaseAccount updatedAccount) async {
    final index = _accounts.indexWhere((a) => a.id == updatedAccount.id);
    
    if (index >= 0) {
      _accounts[index] = updatedAccount.copyWith(updatedAt: DateTime.now());
      
      // Se a conta atualizada é a ativa, atualizar a referência
      if (_activeAccount?.id == updatedAccount.id) {
        _activeAccount = _accounts[index];
      }
      
      await _saveAccounts();
      return true;
    }
    
    return false;
  }
  
  // Obter conta por ID
  FirebaseAccount? getAccountById(String accountId) {
    try {
      return _accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }
  
  // Verificar se uma conta existe
  bool accountExists(String accountId) {
    return _accounts.any((a) => a.id == accountId);
  }
  
  // Limpar todas as contas (usar com cuidado)
  Future<void> clearAllAccounts() async {
    _accounts.clear();
    _activeAccount = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_activeAccountKey);
  }
  
  // Testar conexão de uma conta específica
  Future<bool> testAccountConnection(FirebaseAccount account) async {
    try {
      // Usar a URL de teste de conexão da conta ou a padrão
      final testUrl = account.testConnectionUrl ?? 
          'https://testconnection-6jqkhayvia-uc.a.run.app';
      
      final response = await http.get(
        Uri.parse(testUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao testar conexão da conta ${account.name}: $e');
      return false;
    }
  }
  
  // Testar conexão da conta ativa
  Future<bool> testActiveAccountConnection() async {
    if (_activeAccount == null) {
      return false;
    }
    return await testAccountConnection(_activeAccount!);
  }
  
  // Validar configuração de uma conta
  bool validateAccount(FirebaseAccount account) {
    // Validações básicas
    if (account.name.trim().isEmpty) return false;
    if (account.projectId.trim().isEmpty) return false;
    if (account.apiKey.trim().isEmpty) return false;
    
    // Validar formato do Project ID (deve seguir padrão do Firebase)
    final projectIdRegex = RegExp(r'^[a-z0-9-]+$');
    if (!projectIdRegex.hasMatch(account.projectId)) return false;
    
    // Validar se as URLs são válidas (se fornecidas)
    final urls = [
      account.testConnectionUrl,
      account.searchFlightUrl,
      account.getAirportFlightsUrl,
      account.getBrazilUsaFlightsUrl,
    ];
    
    for (final url in urls) {
      if (url != null && url.isNotEmpty) {
        try {
          Uri.parse(url);
        } catch (e) {
          return false; // URL inválida
        }
      }
    }
    
    return true;
  }
}
