import '../models/flight_info.dart';
import 'firebase_flight_service.dart';
import 'flightaware_service.dart';

class HybridFlightService {
  final FirebaseFlightService _firebaseService;
  final FlightAwareService _flightAwareService;
  
  HybridFlightService() 
    : _firebaseService = FirebaseFlightService(),
      _flightAwareService = FlightAwareService() {
    print("HybridFlightService: Inicializado (Firebase + FlightAware fallback)");
  }

  // Buscar voo por número
  Future<FlightInfo?> searchFlightByNumber(String flightNumber, {String? date}) async {
    print('=== BUSCA DE VOO INICIADA ===');
    print('Voo: $flightNumber');
    print('Data: $date');
    
    try {
      // Tentar Firebase primeiro
      final firebaseResult = await _firebaseService.searchFlightByNumber(flightNumber, date: date);
      
      if (firebaseResult != null) {
        print('✅ Voo encontrado via Firebase');
        return firebaseResult;
      }
      
      // Fallback para FlightAware
      print('🔄 Tentando FlightAware como fallback...');
      final flightawareResult = await _flightAwareService.searchFlight(flightNumber, date: date);
      
      if (flightawareResult != null) {
        print('✅ Voo encontrado via FlightAware (fallback)');
        return flightawareResult;
      } else {
        print('❌ Voo não encontrado');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao buscar voo: $e');
      return null;
    }
  }

  // Buscar voos por aeroporto
  Future<List<FlightInfo>> getFlightsByAirport({
    String? arrIata,
    String? depIata,
    String? flightDate,
    String flightStatus = 'scheduled',
    int limit = 10,
  }) async {
    print('=== BUSCA DE VOOS POR AEROPORTO ===');
    print('Aeroporto: ${arrIata ?? depIata}');
    print('Data: $flightDate');
    
    try {
      // Tentar Firebase primeiro
      final firebaseResult = await _firebaseService.getFlightsByAirport(
        arrIata: arrIata,
        depIata: depIata,
        flightDate: flightDate,
        flightStatus: flightStatus,
        limit: limit,
      );
      
      if (firebaseResult.isNotEmpty) {
        print('✅ ${firebaseResult.length} voos encontrados via Firebase');
        return firebaseResult;
      }
      
      // Fallback para FlightAware
      print('🔄 Tentando FlightAware como fallback...');
      final flightawareResult = await _flightAwareService.getAirportFlights(
        arrIata: arrIata,
        depIata: depIata,
        limit: limit,
      );
      
      if (flightawareResult.isNotEmpty) {
        print('✅ ${flightawareResult.length} voos encontrados via FlightAware (fallback)');
        return flightawareResult;
      } else {
        print('❌ Nenhum voo encontrado');
        return [];
      }
    } catch (e) {
      print('❌ Erro ao buscar voos: $e');
      return [];
    }
  }

  // Buscar voos Brasil-EUA
  Future<List<FlightInfo>> getBrazilUsaFlights() async {
    print('=== BUSCA DE VOOS BRASIL-EUA ===');
    
    try {
      // Tentar Firebase primeiro
      final firebaseResult = await _firebaseService.getBrazilUsaFlights();
      
      if (firebaseResult.isNotEmpty) {
        print('✅ ${firebaseResult.length} voos Brasil-EUA encontrados via Firebase');
        return firebaseResult;
      }
      
      // Fallback para FlightAware
      print('🔄 Tentando FlightAware como fallback...');
      final flightawareResult = await _flightAwareService.getBrazilUsaFlights();
      
      if (flightawareResult.isNotEmpty) {
        print('✅ ${flightawareResult.length} voos Brasil-EUA encontrados via FlightAware (fallback)');
        return flightawareResult;
      } else {
        print('❌ Nenhum voo Brasil-EUA encontrado');
        return [];
      }
    } catch (e) {
      print('❌ Erro ao buscar voos Brasil-EUA: $e');
      return [];
    }
  }

  // Testar conexão
  Future<bool> testConnection() async {
    print('=== TESTE DE CONEXÃO ===');
    
    try {
      // Testar Firebase primeiro
      final firebaseConnected = await _firebaseService.testConnection();
      if (firebaseConnected) {
        print('✅ Firebase Cloud Functions disponível');
        return true;
      }
      
      // Fallback para FlightAware
      print('🔄 Testando FlightAware como fallback...');
      final flightawareResult = await _flightAwareService.getBrazilUsaFlights();
      if (flightawareResult.isNotEmpty) {
        print('✅ FlightAware API disponível (fallback)');
        return true;
      } else {
        print('❌ Nenhum serviço disponível');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao testar conexão: $e');
      return false;
    }
  }

  // Obter status do serviço
  String getServiceStatus() {
    return 'Firebase Cloud Functions + FlightAware Fallback';
  }

  // Verificar se o serviço está disponível
  bool isServiceAvailable() {
    return true; // Sempre disponível, mas pode falhar na requisição
  }
} 
