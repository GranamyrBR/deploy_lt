import 'package:flutter_dotenv/flutter_dotenv.dart';

// Configuração da API FlightAware
// Para obter sua chave: https://flightaware.com/aeroapi/

class ApiKeys {
  // FlightAware API Key
  // Configure sua chave real no arquivo .env
  static String get flightAwareApiKey => dotenv.env['FLIGHTAWARE_API_KEY'] ?? 'DoPXAzO86aAWofjsY3AHqSdezFvO4W24';
  
  // RapidAPI Key
  static String get rapidApiKey => dotenv.env['RAPIDAPI_KEY'] ?? '';
  
  // AviationStack API Key
  static String get aviationStackApiKey => dotenv.env['AVIATIONSTACK_API_KEY'] ?? '';
  
  // Google Calendar Client ID
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  
  // Google Calendar Client Secret
  static String get googleClientSecret => dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
  
  // Nova York APIs
  static String get tripadvisorApiKey => dotenv.env['TRIPADVISOR_API_KEY'] ?? '';
  static String get openweatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? 'e37152e1f87d3a504485bcc619c20173';
  // DESABILITADO: Google Places API (causa cobranças)
  static String get googlePlacesApiKey => ''; // SEMPRE VAZIO para evitar cobranças
  // DESABILITADO: Viator API (causa loop infinito)
  static String get viatorApiKey => ''; // SEMPRE VAZIO para evitar loop infinito
  
  // =====================================================
  // GOOGLE MAPS APIs GRATUITAS (FASE 1)
  // =====================================================
  
  // Google Maps API Key (para Geocoding, Directions, Maps JavaScript)
  // Configure sua chave no arquivo .env
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'AIzaSyAKhlxvUnKDY853Y3-mpWIk66Moh-aCpQM';
  
  // Firebase Project ID
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? 'lecotour-dashboard';
  
  // Firebase API Key
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
}

// INSTRUÇÕES PARA CONFIGURAR:
//
// 1. Acesse: https://flightaware.com/aeroapi/
// 2. Crie uma conta gratuita
// 3. Gere sua chave de API
// 4. Configure de uma das formas:
//
// Opção A - Variável de ambiente:
//   export FLIGHTAWARE_API_KEY=sua_chave_aqui
//   flutter run --dart-define=FLIGHTAWARE_API_KEY=sua_chave_aqui
//
// Opção B - Editar diretamente:
//   Substitua 'DoPXAzO86aAWofjsY3AHqSdezFvO4W24' pela sua chave real
//
// Opção C - Arquivo .env (recomendado para produção):
//   Crie um arquivo .env na raiz do projeto com:
//   FLIGHTAWARE_API_KEY=sua_chave_aqui
//
// =====================================================
// CONFIGURAÇÃO GOOGLE MAPS APIs (FASE 1)
// =====================================================
//
// 1. Acesse: https://console.cloud.google.com/
// 2. Crie um projeto ou use um existente
// 3. Ative as seguintes APIs:
//    - Geocoding API
//    - Directions API
//    - Maps JavaScript API
// 4. Crie uma chave de API em "APIs & Services > Credentials"
// 5. Configure restrições de domínio para segurança
// 6. Adicione no arquivo .env:
//    GOOGLE_MAPS_API_KEY=sua_chave_aqui
//
// LIMITES GRATUITOS:
// - Geocoding: 2.500 requisições/dia
// - Directions: 2.500 requisições/dia
// - Maps JavaScript: 28.500 carregamentos/mês 
