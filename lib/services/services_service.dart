import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';

class ServicesService {
  SupabaseClient get _client => Supabase.instance.client;

  // Buscar todos os serviços
  Future<List<Service>> getServices() async {
    try {
      final response = await _client
          .from('service')
          .select('*, service_category!servicetype_id(name)')
          .order('name');
      
      return response.map((json) {
        // Extrair o nome da categoria do JOIN  
        final categoryData = json['service_category'] as Map<String, dynamic>?;
        final categoryName = categoryData?['name'] as String?;
        
        // Criar um JSON modificado com a categoria
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['category'] = categoryName;
        
        return Service.fromJson(modifiedJson);
      }).toList();
    } catch (e) {
      print('Erro ao buscar serviços: $e');
      rethrow;
    }
  }

  // Buscar serviço por ID
  Future<Service?> getServiceById(int id) async {
    try {
      final response = await _client
          .from('service')
          .select('*, service_category!servicetype_id(name)')
          .eq('id', id)
          .single();
      
      // Extrair o nome da categoria do JOIN  
      final categoryData = response['service_category'] as Map<String, dynamic>?;
      final categoryName = categoryData?['name'] as String?;
      
      // Criar um JSON modificado com a categoria
      final modifiedJson = Map<String, dynamic>.from(response);
      modifiedJson['category'] = categoryName;
      
      return Service.fromJson(modifiedJson);
    } catch (e) {
      print('Erro ao buscar serviço por ID: $e');
      return null;
    }
  }

  // Criar novo serviço
  Future<Service> createService(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('service')
          .insert(data)
          .select('*, service_category!servicetype_id(name)')
          .single();
      
      // Extrair o nome da categoria do JOIN  
      final categoryData = response['service_category'] as Map<String, dynamic>?;
      final categoryName = categoryData?['name'] as String?;
      
      // Criar um JSON modificado com a categoria
      final modifiedJson = Map<String, dynamic>.from(response);
      modifiedJson['category'] = categoryName;
      
      return Service.fromJson(modifiedJson);
    } catch (e) {
      print('Erro ao criar serviço: $e');
      rethrow;
    }
  }

  // Atualizar serviço
  Future<Service> updateService(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('service')
          .update(data)
          .eq('id', id)
          .select('*, service_category!servicetype_id(name)')
          .single();
      
      // Extrair o nome da categoria do JOIN  
      final categoryData = response['service_category'] as Map<String, dynamic>?;
      final categoryName = categoryData?['name'] as String?;
      
      // Criar um JSON modificado com a categoria
      final modifiedJson = Map<String, dynamic>.from(response);
      modifiedJson['category'] = categoryName;
      
      return Service.fromJson(modifiedJson);
    } catch (e) {
      print('Erro ao atualizar serviço: $e');
      rethrow;
    }
  }

  // Deletar serviço
  Future<void> deleteService(int id) async {
    try {
      await _client
          .from('service')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erro ao deletar serviço: $e');
      rethrow;
    }
  }

  // Buscar serviços por categoria
  Future<List<Service>> getServicesByCategory(String category) async {
    try {
      final response = await _client
          .from('service')
          .select('*, service_category!servicetype_id(name)')
          .eq('category', category)
          .eq('is_active', true)
          .order('name');
      
      return response.map((json) {
        // Extrair o nome da categoria do JOIN  
        final categoryData = json['service_category'] as Map<String, dynamic>?;
        final categoryName = categoryData?['name'] as String?;
        
        // Criar um JSON modificado com a categoria
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['category'] = categoryName;
        
        return Service.fromJson(modifiedJson);
      }).toList();
    } catch (e) {
      print('Erro ao buscar serviços por categoria: $e');
      rethrow;
    }
  }

  // Buscar serviços por nome (busca parcial)
  Future<List<Service>> searchServicesByName(String name) async {
    try {
      final response = await _client
          .from('service')
          .select('*, service_category!servicetype_id(name)')
          .ilike('name', '%$name%')
          .eq('is_active', true)
          .order('name');
      
      return response.map((json) {
        // Extrair o nome da categoria do JOIN  
        final categoryData = json['service_category'] as Map<String, dynamic>?;
        final categoryName = categoryData?['name'] as String?;
        
        // Criar um JSON modificado com a categoria
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['category'] = categoryName;
        
        return Service.fromJson(modifiedJson);
      }).toList();
    } catch (e) {
      print('Erro ao buscar serviços por nome: $e');
      rethrow;
    }
  }

  // Buscar estatísticas de serviços
  Future<Map<String, dynamic>> getServiceStats() async {
    try {
      final response = await _client
          .from('service')
          .select('is_active, servicetype_id, service_category!servicetype_id(name)');
      
      int totalServices = response.length;
      int activeServices = response.where((service) => service['is_active'] == true).length;
      int inactiveServices = totalServices - activeServices;
      
      // Contar por categoria
      Map<String, int> categoryCount = {};
      for (final service in response) {
        final categoryData = service['service_category'] as Map<String, dynamic>?;
        final categoryName = categoryData?['name'] as String? ?? 'Sem categoria';
        categoryCount[categoryName] = (categoryCount[categoryName] ?? 0) + 1;
      }
      
      return {
        'totalServices': totalServices,
        'activeServices': activeServices,
        'inactiveServices': inactiveServices,
        'activePercentage': totalServices > 0 ? (activeServices / totalServices) * 100 : 0.0,
        'categoryCount': categoryCount,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas de serviços: $e');
      rethrow;
    }
  }
}
