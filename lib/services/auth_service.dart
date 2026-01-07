import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../models/department.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<app_user.User?> login(String email, String password) async {
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final authUser = res.user;
      if (authUser == null) {
        throw Exception('Falha na autenticação');
      }
      Map<String, dynamic>? record;
      try {
        record = await _client
            .from('user')
            .select('*, department(name)')
            .eq('id', authUser.id)
            .maybeSingle();
      } catch (_) {
        record = null;
      }
      if (record == null) {
        try {
          record = await _client
              .from('user')
              .select('*, department(name)')
              .eq('email', email)
              .maybeSingle();
        } catch (_) {
          record = null;
        }
      }
      if (record == null) {
        throw Exception('Perfil de usuário não encontrado');
      }
      try {
        final role = (record['role'] as String?)?.toLowerCase();
        if (role == 'vendor') {
          final perms = List<String>.from(record['permissions'] ?? const []);
          if (!perms.contains('vendor')) {
            perms.add('vendor');
          }
          record['permissions'] = perms;
        }
      } catch (_) {}
      try {
        await _client
            .from('user')
            .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', record['id']);
      } catch (_) {}
      return app_user.User.fromJson(record);
    } catch (e) {
      throw Exception('Usuário não encontrado, inativo ou senha incorreta');
    }
  }

  // Logout (apenas limpar dados locais)
  Future<void> logout() async {
    try {
      // Não precisamos fazer nada no Supabase Auth
      // Apenas limpar dados locais
    } catch (e) {
      throw Exception('Erro no logout: ${e.toString()}');
    }
  }

  // Buscar usuário atual (não implementado para esta versão)
  Future<app_user.User?> getCurrentUser() async {
    try {
      // Para esta implementação, retornamos null
      // O estado do usuário será gerenciado pelo provider local
      return null;
    } catch (e) {
      print('Erro ao buscar usuário atual: $e');
      return null;
    }
  }

  // Buscar usuário por ID
  Future<app_user.User?> getUserById(String id) async {
    try {
      final userData = await _client
          .from('user')
          .select('*, department(name)')
          .eq('id', id)
          .single();
      
      // Extrair nome do departamento se existir
      if (userData['department'] != null) {
        userData['department_name'] = userData['department']['name'];
      }
      
      return app_user.User.fromJson(userData);
    } catch (e) {
      print('Erro ao buscar usuário por ID: $e');
      return null;
    }
  }

  // Buscar usuário por email
  Future<app_user.User?> getUserByEmail(String email) async {
    try {
      final userData = await _client
          .from('user')
          .select('*, department(name)')
          .eq('email', email)
          .single();
      
      // Extrair nome do departamento se existir
      if (userData['department'] != null) {
        userData['department_name'] = userData['department']['name'];
      }
      
      return app_user.User.fromJson(userData);
    } catch (e) {
      print('Erro ao buscar usuário por email: $e');
      return null;
    }
  }

  // Listar todos os usuários (apenas para admin)
  Future<List<app_user.User>> getAllUsers() async {
    try {
      final response = await _client
          .from('user')
          .select('*, department(name)')
          .order('username');
      
      final List<app_user.User> users = [];
      
      for (final userData in response) {
        try {
          // Extrair nome do departamento se existir
          if (userData['department'] != null) {
            userData['department_name'] = userData['department']['name'];
          }
          
          users.add(app_user.User.fromJson(userData));
        } catch (e) {
          print('Erro ao processar usuário ${userData['id']}: $e');
          // Continuar com o próximo usuário
          continue;
        }
      }
      
      return users;
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      
      // Se o erro for relacionado ao JOIN, tentar sem JOIN
      if (e.toString().contains('relationship') || e.toString().contains('foreign key')) {
        print('Tentando buscar usuários sem JOIN...');
        try {
          final response = await _client
              .from('user')
              .select('*')
              .order('username');
          
          final List<app_user.User> users = [];
          
          for (final userData in response) {
            try {
              // Buscar departamento separadamente se department_id existir
              if (userData['department_id'] != null) {
                try {
                  final departmentData = await _client
                      .from('department')
                      .select('name')
                      .eq('id', userData['department_id'])
                      .single();
                  
                  userData['department_name'] = departmentData['name'];
                } catch (deptError) {
                  print('Erro ao buscar departamento para usuário ${userData['id']}: $deptError');
                  userData['department_name'] = null;
                }
              }
              
              users.add(app_user.User.fromJson(userData));
            } catch (userError) {
              print('Erro ao processar usuário ${userData['id']}: $userError');
              continue;
            }
          }
          
          return users;
        } catch (fallbackError) {
          print('Erro no fallback: $fallbackError');
          throw Exception('Erro ao buscar usuários: ${e.toString()}');
        }
      }
      
      throw Exception('Erro ao buscar usuários: ${e.toString()}');
    }
  }

  // Criar novo usuário (apenas para admin)
  Future<app_user.User> createUser({
    required String username,
    required String email,
    required String password,
    required String departmentId,
    String? phone,
    List<String>? permissions,
  }) async {
    try {
      // Verificar se email já existe
      final existingUser = await _client
          .from('user')
          .select('id')
          .eq('email', email)
          .order('id', ascending: false).limit(1);
      
      if (existingUser.isNotEmpty) {
        throw Exception('Email já cadastrado');
      }
      
      // Criar registro na tabela users
      final userData = {
        'username': username,
        'email': email,
        'password': password,
        'department_id': departmentId,
        'phone': phone,
        'permissions': permissions ?? ['view_dashboard'],
        'is_active': true,
      };
      
      final response = await _client
          .from('user')
          .insert(userData)
          .select('*')
          .single();
      try {
        await _client.rpc('app_set_password', params: {
          'p_user_id': response['id'],
          'p_password': password,
        });
      } catch (_) {}
      
      // Buscar dados do departamento separadamente
      if (response['department_id'] != null) {
        try {
          final departmentData = await _client
              .from('department')
              .select('name')
              .eq('id', response['department_id'])
              .single();
          
          response['department_name'] = departmentData['name'];
        } catch (e) {
          print('Erro ao buscar departamento: $e');
          response['department_name'] = null;
        }
      }
      
      return app_user.User.fromJson(response);
    } catch (e) {
      print('Erro ao criar usuário: $e');
      throw Exception('Erro ao criar usuário: ${e.toString()}');
    }
  }

  // Atualizar usuário
  Future<app_user.User> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('user')
          .update(data)
          .eq('id', id)
          .select('*')
          .single();
      
      // Buscar dados do departamento separadamente
      if (response['department_id'] != null) {
        try {
          final departmentData = await _client
              .from('department')
              .select('name')
              .eq('id', response['department_id'])
              .single();
          
          response['department_name'] = departmentData['name'];
        } catch (e) {
          print('Erro ao buscar departamento: $e');
          response['department_name'] = null;
        }
      }
      
      return app_user.User.fromJson(response);
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      throw Exception('Erro ao atualizar usuário: ${e.toString()}');
    }
  }

  // Deletar usuário
  Future<void> deleteUser(String id) async {
    try {
      // Deletar da tabela user
      await _client
          .from('user')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erro ao deletar usuário: $e');
      throw Exception('Erro ao deletar usuário: ${e.toString()}');
    }
  }

  // Verificar se email já existe
  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await _client
          .from('user')
          .select('id')
          .eq('email', email)
          .order('id', ascending: false).limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar email: $e');
      return false;
    }
  }

  // Reset de senha (não implementado para esta versão)
  Future<void> resetPassword(String email) async {
    try {
      // TODO: Implementar reset de senha
      throw Exception('Reset de senha não implementado ainda');
    } catch (e) {
      throw Exception('Erro ao resetar senha: ${e.toString()}');
    }
  }

  // Listar departamentos
  Future<List<Department>> getAllDepartment() async {
    try {
      final response = await _client
          .from('department')
          .select('*')
          .order('name');
      return response.map<Department>((data) => Department.fromJson(data)).toList();
    } catch (e) {
      print('Erro ao buscar departamentos: $e');
      throw Exception('Erro ao buscar departamentos: ${e.toString()}');
    }
  }
}
