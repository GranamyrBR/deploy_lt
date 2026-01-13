import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_task.dart';

class ContactTaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Buscar tarefas de um contato específico
  Future<List<ContactTask>> getContactTasks(int contactId, {
    String? status,
    int? limit,
  }) async {
    try {
      var query = _supabase
          .from('contact_task')
          .select('''
            *,
            user:assigned_to_user_id (
              name
            )
          ''')
          .eq('contact_id', contactId);

      if (status != null) {
        query = query.eq('status', status);
      }

      var orderedQuery = query.order('due_date', ascending: true);

      if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      
      return (response as List).map((json) {
        // Adicionar nome do usuário ao JSON
        if (json['user'] != null && json['user']['name'] != null) {
          json['assigned_to_user_name'] = json['user']['name'];
        }
        return ContactTask.fromJson(json);
      }).toList();
    } catch (e) {
      print('Erro ao buscar tarefas do contato: $e');
      return [];
    }
  }

  /// Buscar tarefas pendentes de um contato
  Future<List<ContactTask>> getPendingTasks(int contactId) async {
    return getContactTasks(contactId, status: 'pending');
  }

  /// Buscar próximas tarefas (próximos 7 dias)
  Future<List<ContactTask>> getUpcomingTasks(int contactId) async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final response = await _supabase
          .from('contact_task')
          .select('''
            *,
            user:assigned_to_user_id (
              name
            )
          ''')
          .eq('contact_id', contactId)
          .eq('status', 'pending')
          .gte('due_date', now.toIso8601String())
          .lte('due_date', nextWeek.toIso8601String())
          .order('due_date', ascending: true);

      return (response as List).map((json) {
        if (json['user'] != null && json['user']['name'] != null) {
          json['assigned_to_user_name'] = json['user']['name'];
        }
        return ContactTask.fromJson(json);
      }).toList();
    } catch (e) {
      print('Erro ao buscar tarefas próximas: $e');
      return [];
    }
  }

  /// Buscar tarefas atrasadas de um contato
  Future<List<ContactTask>> getOverdueTasks(int contactId) async {
    try {
      final now = DateTime.now();

      final response = await _supabase
          .from('contact_task')
          .select('''
            *,
            user:assigned_to_user_id (
              name
            )
          ''')
          .eq('contact_id', contactId)
          .eq('status', 'pending')
          .lt('due_date', now.toIso8601String())
          .order('due_date', ascending: true);

      return (response as List).map((json) {
        if (json['user'] != null && json['user']['name'] != null) {
          json['assigned_to_user_name'] = json['user']['name'];
        }
        return ContactTask.fromJson(json);
      }).toList();
    } catch (e) {
      print('Erro ao buscar tarefas atrasadas: $e');
      return [];
    }
  }

  /// Criar nova tarefa
  Future<ContactTask?> createTask({
    required int contactId,
    required String taskType,
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'normal',
    String? assignedToUserId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      final response = await _supabase
          .from('contact_task')
          .insert({
            'contact_id': contactId,
            'task_type': taskType,
            'title': title,
            'description': description,
            'due_date': dueDate?.toIso8601String(),
            'priority': priority,
            'assigned_to_user_id': assignedToUserId ?? userId,
            'created_by': userId,
            'status': 'pending',
          })
          .select('''
            *,
            user:assigned_to_user_id (
              name
            )
          ''')
          .single();

      if (response['user'] != null && response['user']['name'] != null) {
        response['assigned_to_user_name'] = response['user']['name'];
      }

      return ContactTask.fromJson(response);
    } catch (e) {
      print('Erro ao criar tarefa: $e');
      return null;
    }
  }

  /// Atualizar tarefa
  Future<bool> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('contact_task')
          .update(updates)
          .eq('id', taskId);
      return true;
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
      return false;
    }
  }

  /// Marcar tarefa como concluída
  Future<bool> completeTask(int taskId, {String? completionNotes}) async {
    try {
      await _supabase
          .from('contact_task')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'completion_notes': completionNotes,
          })
          .eq('id', taskId);
      return true;
    } catch (e) {
      print('Erro ao completar tarefa: $e');
      return false;
    }
  }

  /// Cancelar tarefa
  Future<bool> cancelTask(int taskId) async {
    try {
      await _supabase
          .from('contact_task')
          .update({
            'status': 'cancelled',
          })
          .eq('id', taskId);
      return true;
    } catch (e) {
      print('Erro ao cancelar tarefa: $e');
      return false;
    }
  }

  /// Deletar tarefa
  Future<bool> deleteTask(int taskId) async {
    try {
      await _supabase
          .from('contact_task')
          .delete()
          .eq('id', taskId);
      return true;
    } catch (e) {
      print('Erro ao deletar tarefa: $e');
      return false;
    }
  }

  /// Contar tarefas por status
  Future<Map<String, int>> getTaskCountsByStatus(int contactId) async {
    try {
      final response = await _supabase
          .from('contact_task')
          .select('status')
          .eq('contact_id', contactId);

      final counts = <String, int>{
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (final task in response as List) {
        final status = task['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Erro ao contar tarefas: $e');
      return {};
    }
  }
}
