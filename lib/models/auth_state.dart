import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_state.g.dart';

@JsonSerializable()
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastActivity;

  AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.lastActivity,
  });

  factory AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);
  Map<String, dynamic> toJson() => _$AuthStateToJson(this);

  // Método para verificar se o usuário tem acesso a uma página
  bool canAccessPage(String pageName) {
    if (!isAuthenticated || user == null) return false;
    return user!.canAccessPage(pageName);
  }

  // Método para verificar se o usuário tem uma permissão específica
  bool hasPermission(String permission) {
    if (!isAuthenticated || user == null) return false;
    return user!.hasPermission(permission);
  }

  // Método para verificar se o usuário é administrador
  bool get isAdmin {
    if (!isAuthenticated || user == null) return false;
    return user!.isAdmin;
  }

  // Método para verificar se o usuário é DBA
  bool get isDBA {
    if (!isAuthenticated || user == null) return false;
    return user!.isDBA;
  }

  // Método para verificar se o usuário pode executar operações críticas
  bool canExecuteCriticalDBOperation(String operation) {
    if (!isAuthenticated || user == null) return false;
    return user!.canExecuteCriticalDBOperation(operation);
  }

  // Método para verificar se o usuário pode modificar dados críticos
  bool canModifyCriticalData(String dataType) {
    if (!isAuthenticated || user == null) return false;
    return user!.canModifyCriticalData(dataType);
  }

  // Método para criar uma cópia com novos valores
  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastActivity,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  // Método para criar estado de loading
  AuthState loading() {
    return copyWith(isLoading: true, errorMessage: null);
  }

  // Método para criar estado de erro
  AuthState error(String errorMessage) {
    return copyWith(isLoading: false, errorMessage: errorMessage);
  }

  // Método para criar estado de sucesso
  AuthState success(User user) {
    return copyWith(
      user: user,
      isAuthenticated: true,
      isLoading: false,
      errorMessage: null,
      lastActivity: DateTime.now(),
    );
  }

  // Método para logout
  AuthState logout() {
    return AuthState();
  }
} 
