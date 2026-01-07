import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? avatar;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  @JsonKey(name: 'department_id')
  final String departmentId;
  @JsonKey(name: 'department_name')
  final String? departmentName;
  final List<String> permissions;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'last_login_at')
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.avatar,
    required this.firstName,
    required this.lastName,
    required this.departmentId,
    this.departmentName,
    required this.permissions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle nested department data from join
    String? deptName = json['department_name'];
    if (deptName == null && json['department'] != null) {
      deptName = json['department']['name'] as String?;
    }
    
    // Convert department_id to String
    String deptId = '';
    if (json['department_id'] != null) {
      deptId = json['department_id'].toString();
    }
    
    // Handle permissions - if not present, create default based on department
    List<String> userPermissions = [];
    if (json['permissions'] != null) {
      userPermissions = List<String>.from(json['permissions']);
    } else {
      // Default permissions based on department
      final deptNameLower = deptName?.toLowerCase() ?? '';
      if (deptNameLower.contains('master')) {
        userPermissions = ['admin', 'master'];
      } else if (deptNameLower.contains('admin')) {
        userPermissions = ['admin'];
      } else {
        userPermissions = ['view_dashboard'];
      }
    }
    
    return _$UserFromJson({
      ...json,
      'department_id': deptId,
      'department_name': deptName,
      'permissions': userPermissions,
    });
  }
  
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Método para verificar se o usuário tem uma permissão específica
  bool hasPermission(String permission) {
    return permissions.contains(permission) || permissions.contains('admin') || isMaster;
  }

  // Método para verificar se o usuário tem acesso a uma página específica
  bool canAccessPage(String pageName) {
    // Mapeamento de páginas para permissões
    final pagePermissions = {
      'dashboard': ['view_dashboard'],
      'contact': ['view_contact', 'manage_contact'],
      'driver': ['view_driver', 'manage_driver'],
      'agencies': ['view_agencies', 'manage_agencies'],
      'flights': ['view_flights', 'manage_flights'],
      'whatsapp_leads': ['view_leads', 'manage_leads'],
      'reports': ['view_reports'],
      'settings': ['manage_settings'],
    };

    final requiredPermissions = pagePermissions[pageName] ?? [];
    
    if (requiredPermissions.isEmpty) return true; // Página sem restrições
    
    return requiredPermissions.any((permission) => hasPermission(permission));
  }

  // Método para verificar se o usuário é administrador
  bool get isAdmin => hasPermission('admin');

  // Método para verificar se o usuário é master (admin supremo)
  bool get isMaster => departmentName?.toLowerCase() == 'master' || 
                      username.toLowerCase().contains('master') ||
                      permissions.contains('master');

  // Método para verificar se o usuário é DBA
  bool get isDBA => hasPermission('dba') || isMaster;

  // Método para verificar se o usuário pode executar operações críticas de banco
  bool canExecuteCriticalDBOperation(String operation) {
    // Operações críticas que requerem permissão DBA
    final criticalOperations = {
      'delete_car': ['dba', 'admin'],
      'delete_driver': ['dba', 'admin'],
      'delete_agency': ['dba', 'admin'],
      'delete_contact': ['dba', 'admin'],
      'delete_user': ['dba', 'admin'],
      'modify_database_schema': ['dba'],
      'execute_raw_sql': ['dba'],
      'backup_database': ['dba'],
      'restore_database': ['dba'],
      'manage_foreign_keys': ['dba'],
      'bulk_data_operations': ['dba', 'admin'],
    };

    final requiredPermissions = criticalOperations[operation] ?? [];
    
    if (requiredPermissions.isEmpty) return true; // Operação sem restrições
    
    return requiredPermissions.any((permission) => hasPermission(permission));
  }

  // Método para verificar se o usuário pode modificar dados críticos
  bool canModifyCriticalData(String dataType) {
    // Tipos de dados críticos que requerem permissão DBA
    final criticalDataTypes = {
      'user_permissions': ['dba', 'admin'],
      'department_structure': ['dba', 'admin'],
      'system_configuration': ['dba'],
      'audit_logs': ['dba'],
      'backup_data': ['dba'],
    };

    final requiredPermissions = criticalDataTypes[dataType] ?? [];
    
    if (requiredPermissions.isEmpty) return true; // Dados sem restrições
    
    return requiredPermissions.any((permission) => hasPermission(permission));
  }

  // Método para verificar se o usuário está ativo
  bool get isUserActive => isActive;

  // Getter para nome completo (usando first_name + last_name)
  String get name => '$firstName $lastName'.trim();
} 
