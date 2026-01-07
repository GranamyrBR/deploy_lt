import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/operational_route.dart';

class DatabaseFlightService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Buscar todas as rotas operacionais do banco
  Future<List<OperationalRoute>> getOperationalRoutes() async {
    try {
      print('=== BUSCANDO ROTAS OPERACIONAIS NO BANCO ===');
      
      // Primeiro, verificar se a view existe
      print('🔍 Verificando se a view brasil_eua_operacional existe...');
      
      final response = await _supabase
          .from('brasil_eua_operacional')
          .select('*')
          .order('origem')
          .order('saida');

      print('📊 Resposta do banco: ${response.length} registros encontrados');
      
      if (response.isEmpty) {
        print('⚠️ Nenhuma rota encontrada na tabela brasil_eua_operacional');
        print('🔍 Verificando se a tabela rotas_operacionais tem dados...');
        
        // Tentar buscar diretamente da tabela base
        final baseResponse = await _supabase
            .from('rotas_operacionais')
            .select('*')
            .order('id', ascending: false).limit(5);
            
        print('📊 Tabela rotas_operacionais: ${baseResponse.length} registros');
        
        if (baseResponse.isNotEmpty) {
          print('📋 Primeiro registro da tabela base:');
          print(baseResponse[0]);
        }
        
        return [];
      }

      print('📋 Primeiro registro da view:');
      print(response[0]);

      final routes = (response as List)
          .map((json) {
            try {
              return OperationalRoute.fromJson(json);
            } catch (e) {
              print('❌ Erro ao converter registro: $e');
              print('📋 JSON problemático: $json');
              return null;
            }
          })
          .where((route) => route != null)
          .cast<OperationalRoute>()
          .toList();

      print('✅ ${routes.length} rotas convertidas com sucesso');
      
      if (routes.isNotEmpty) {
        print('📋 Exemplo de rota convertida:');
        print('Voo: ${routes[0].voo}');
        print('Companhia: ${routes[0].nomeCia}');
        print('Origem: ${routes[0].origem}');
        print('Destino: ${routes[0].destino}');
        print('Operação: ${routes[0].operacao}');
      }
      
      return routes;
    } catch (e) {
      print('❌ Erro ao buscar rotas operacionais: $e');
      print('🔍 Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Buscar rotas por filtros
  Future<List<OperationalRoute>> getOperationalRoutesByFilters({
    String? operacao,
    String? companhia,
    String? aeroportoOrigem,
    String? aeroportoDestino,
    String? searchQuery,
  }) async {
    try {
      print('=== BUSCANDO ROTAS COM FILTROS ===');
      print('Operação: $operacao');
      print('Companhia: $companhia');
      print('Origem: $aeroportoOrigem');
      print('Destino: $aeroportoDestino');
      print('Busca: $searchQuery');

      var query = _supabase
          .from('brasil_eua_operacional')
          .select('*');

      // Aplicar filtros
      if (operacao != null && operacao.isNotEmpty) {
        query = query.eq('operacao', operacao);
      }

      if (companhia != null && companhia.isNotEmpty) {
        query = query.eq('cia', companhia);
      }

      if (aeroportoOrigem != null && aeroportoOrigem.isNotEmpty) {
        query = query.eq('origem', aeroportoOrigem);
      }

      if (aeroportoDestino != null && aeroportoDestino.isNotEmpty) {
        query = query.eq('destino', aeroportoDestino);
      }

      // Busca por texto (se implementado no banco)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Nota: Busca por texto pode precisar ser implementada no backend
        // Por enquanto, vamos filtrar no cliente
      }

      final response = await query.order('origem').order('saida');

      print('Resposta filtrada: ${response.length} registros');

      if (response.isEmpty) {
        return [];
      }

      final routes = (response as List)
          .map((json) => OperationalRoute.fromJson(json))
          .toList();

      // Aplicar filtro de texto no cliente se necessário
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        routes.removeWhere((route) {
          return !route.voo.toLowerCase().contains(query) &&
                 !route.nomeCia.toLowerCase().contains(query) &&
                 !route.origem.toLowerCase().contains(query) &&
                 !route.destino.toLowerCase().contains(query) &&
                 !(route.observacoes?.toLowerCase().contains(query) ?? false);
        });
      }

      print('✅ ${routes.length} rotas filtradas com sucesso');
      return routes;
    } catch (e) {
      print('❌ Erro ao buscar rotas com filtros: $e');
      return [];
    }
  }

  // Buscar voo específico por número
  Future<OperationalRoute?> getOperationalRouteByFlightNumber(String flightNumber) async {
    try {
      print('=== BUSCANDO VOO ESPECÍFICO ===');
      print('Voo: $flightNumber');

      final response = await _supabase
          .from('brasil_eua_operacional')
          .select('*')
          .eq('voo', flightNumber)
          .single();

      final route = OperationalRoute.fromJson(response);
      print('✅ Voo encontrado: ${route.voo}');
      return route;
    } catch (e) {
      print('❌ Erro ao buscar voo específico: $e');
      return null;
    }
  }

  // Buscar estatísticas das rotas
  Future<Map<String, dynamic>> getRouteStats() async {
    try {
      print('=== BUSCANDO ESTATÍSTICAS ===');

      final response = await _supabase
          .from('brasil_eua_operacional')
          .select('*');

      if (response.isEmpty) {
        return {
          'total_routes': 0,
          'saida_brasil': 0,
          'chegada_brasil': 0,
          'total_companies': 0,
          'companies': [],
          'aeroportos_brasil': [],
          'aeroportos_eua': [],
        };
      }

      final routes = (response as List)
          .map((json) => OperationalRoute.fromJson(json))
          .toList();

      final stats = <String, dynamic>{};
      
      // Total de rotas
      stats['total_routes'] = routes.length;
      
      // Rotas por operação
      stats['saida_brasil'] = routes.where((r) => r.operacao == 'SAÍDA DO BRASIL').length;
      stats['chegada_brasil'] = routes.where((r) => r.operacao == 'CHEGADA AO BRASIL').length;
      
      // Companhias únicas
      final companhias = routes.map((r) => r.cia).toSet().toList();
      stats['total_companies'] = companhias.length;
      stats['companies'] = companhias;
      
      // Aeroportos brasileiros
      final aeroportosBr = routes.where((r) => r.operacao == 'SAÍDA DO BRASIL').map((r) => r.origem).toSet().toList();
      stats['aeroportos_brasil'] = aeroportosBr;
      
      // Aeroportos americanos
      final aeroportosEua = routes.where((r) => r.operacao == 'SAÍDA DO BRASIL').map((r) => r.destino).toSet().toList();
      stats['aeroportos_eua'] = aeroportosEua;

      print('✅ Estatísticas calculadas: ${stats['total_routes']} rotas');
      return stats;
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      return {
        'total_routes': 0,
        'saida_brasil': 0,
        'chegada_brasil': 0,
        'total_companies': 0,
        'companies': [],
        'aeroportos_brasil': [],
        'aeroportos_eua': [],
      };
    }
  }

  // Testar conexão com o banco
  Future<bool> testConnection() async {
    try {
      print('=== TESTANDO CONEXÃO COM BANCO ===');
      
      final response = await _supabase
          .from('brasil_eua_operacional')
          .select('count')
          .order('id', ascending: false).limit(1);

      print('✅ Conexão com banco estabelecida');
      return true;
    } catch (e) {
      print('❌ Erro na conexão com banco: $e');
      return false;
    }
  }

  // Verificar estrutura da tabela
  Future<Map<String, dynamic>> checkTableStructure() async {
    try {
      print('=== VERIFICANDO ESTRUTURA DA TABELA ===');
      
      final response = await _supabase
          .from('brasil_eua_operacional')
          .select('*')
          .order('id', ascending: false).limit(1);

      if (response.isEmpty) {
        return {
          'table_exists': true,
          'has_data': false,
          'columns': [],
          'error': 'Tabela vazia',
        };
      }

      final sample = response[0];
      final columns = sample.keys.toList();

      return {
        'table_exists': true,
        'has_data': true,
        'columns': columns,
        'sample_data': sample,
      };
    } catch (e) {
      return {
        'table_exists': false,
        'has_data': false,
        'columns': [],
        'error': e.toString(),
      };
    }
  }
} 
