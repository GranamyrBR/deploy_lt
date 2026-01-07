import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../models/department.dart';
import '../services/auth_service.dart';
import '../providers/error_handling_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthStateNotifier, AppAuthState>((ref) {
  return AuthStateNotifier(ref.read(authServiceProvider));
});

// Provider seguro para buscar todos os usuários
final allUsersProvider = safeListProvider<app_user.User>(() async {
  final authService = AuthService();
  return await authService.getAllUsers();
});

// Provider seguro para buscar departamentos
final departmentsProvider = safeListProvider<Department>(() async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('department')
      .select('*')
      .eq('is_active', true)
      .order('name');
  
  return (response as List)
      .map((json) => Department.fromJson(json as Map<String, dynamic>))
      .toList();
});

// Provider para usuário atual
final currentUserProvider = StateProvider<app_user.User?>((ref) => null);

// Provider para estado de autenticação
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

// Providers de permissões (mantidos para compatibilidade)
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.permissions.contains('admin') ?? false;
});

final isDBAProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.permissions.contains('dba') ?? false;
});

final canExecuteCriticalDBOperationProvider = Provider.family<bool, String>((ref, operation) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  
  // Verificar se o usuário tem permissão para a operação
  return user.permissions.contains('admin') || 
         user.permissions.contains('dba') ||
         user.permissions.contains('critical_operations');
});

class AppAuthState {
  final bool isAuthenticated;
  final app_user.User? user;
  final String? error;
  final bool isLoading;

  AppAuthState({
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AppAuthState copyWith({
    bool? isAuthenticated,
    app_user.User? user,
    String? error,
    bool? isLoading,
  }) {
    return AppAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Getters para compatibilidade
  String? get errorMessage => error;
  bool get hasError => error != null;
}

class AuthStateNotifier extends StateNotifier<AppAuthState> {
  final AuthService _authService;
  RealtimeChannel? _userChannel;

  AuthStateNotifier(this._authService) : super(AppAuthState());

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(error: null, isLoading: true);
      final user = await _authService.login(email, password);
      
      if (user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          error: null,
          isLoading: false,
        );
        _subscribeToUserChanges(user.id);
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          user: null,
          error: 'Falha na autenticação',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        user: null,
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _unsubscribeUserChanges();
      state = AppAuthState();
    } catch (e) {
      // Mesmo com erro no logout, limpar o estado
      _unsubscribeUserChanges();
      state = AppAuthState();
    }
  }

  Future<void> setCurrentUser(app_user.User user) async {
    state = state.copyWith(
      isAuthenticated: true,
      user: user,
      error: null,
    );
    _subscribeToUserChanges(user.id);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void _subscribeToUserChanges(String userId) {
    try {
      _unsubscribeUserChanges();
      _userChannel = Supabase.instance.client
          .channel('user_changes_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'user',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: userId,
            ),
            callback: (payload) async {
              try {
                final newRec = payload.newRecord as Map<String, dynamic>?;
                Map<String, dynamic>? record = newRec;
                if (record == null || (record['id'] != userId)) {
                  try {
                    record = await Supabase.instance.client
                        .from('user')
                        .select('*, department(name)')
                        .eq('id', userId)
                        .maybeSingle();
                  } catch (_) {
                    record = null;
                  }
                }
                if (record != null) {
                  if (record['department'] != null) {
                    record['department_name'] = record['department']['name'];
                  }
                  final updated = app_user.User.fromJson(record);
                  state = state.copyWith(user: updated);
                }
              } catch (_) {}
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void _unsubscribeUserChanges() {
    try {
      _userChannel?.unsubscribe();
    } catch (_) {}
    _userChannel = null;
  }
}
