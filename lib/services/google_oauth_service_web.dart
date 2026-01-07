import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lecotour_dashboard/models/api_configuration.dart';

class GoogleOAuthService {
  static const String _authUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const String _tokenUrl = 'https://oauth2.googleapis.com/token';
  
  static String _generateState() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  static Future<String?> authenticate(ApiConfiguration config) async {
    try {
      final configData = config.configData;
      if (configData == null) {
        throw Exception('Configuração OAuth2 não encontrada');
      }

      final clientId = configData['client_id'] as String?;
      final clientSecret = configData['client_secret'] as String?;
      final scopes = (configData['scopes'] as List<dynamic>?)?.cast<String>() ?? [];

      if (clientId == null || clientSecret == null) {
        throw Exception('Client ID ou Client Secret não configurados');
      }

      final state = _generateState();
      const redirectUri = 'http://localhost:8081/oauth_callback.html';
      final authParams = {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scopes.join(' '),
        'state': state,
        'access_type': 'offline',
        'prompt': 'consent',
      };

      final uri = Uri.parse(_authUrl).replace(queryParameters: authParams);
      debugPrint('URL de autorização: $uri');
      final popup = html.window.open(
        uri.toString(),
        'google_oauth',
        'width=500,height=600,scrollbars=yes,resizable=yes,location=yes'
      );
      final code = await _waitForAuthorizationCodeViaPostMessage(popup, state);
      if (code != null) {
        final token = await _exchangeCodeForToken(code, clientId, clientSecret, redirectUri);
        return token;
      }
      return null;
    } catch (e) {
      debugPrint('Erro na autenticação OAuth2: $e');
      rethrow;
    }
  }

  static Future<String?> _waitForAuthorizationCodeViaPostMessage(dynamic popup, String state) async {
    final completer = Completer<String?>();
    void messageListener(html.Event event) {
      if (event is html.MessageEvent && event.data is Map) {
        final data = event.data as Map;
        if (data['type'] == 'oauth_success') {
          final code = data['code'] as String?;
          final returnedState = data['state'] as String?;
          if (code != null && returnedState == state) {
            html.window.removeEventListener('message', messageListener);
            popup.close();
            completer.complete(code);
          }
        } else if (data['type'] == 'oauth_error') {
          final error = data['error'] as String?;
          html.window.removeEventListener('message', messageListener);
          popup.close();
          completer.completeError(Exception(error ?? 'Erro de autorização'));
        }
      }
    }
    html.window.addEventListener('message', messageListener);
    Timer(const Duration(minutes: 5), () {
      if (!completer.isCompleted) {
        html.window.removeEventListener('message', messageListener);
        popup.close();
        completer.completeError(Exception('Timeout na autorização'));
      }
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (popup.closed == true && !completer.isCompleted) {
        html.window.removeEventListener('message', messageListener);
        timer.cancel();
        completer.completeError(Exception('Autorização cancelada pelo usuário'));
      }
    });
    return completer.future;
  }

  static Future<String> _exchangeCodeForToken(String code, String clientId, String clientSecret, String redirectUri) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          debugPrint('Token obtido com sucesso');
          return accessToken;
        } else {
          throw Exception('Token não encontrado na resposta');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception('Erro ao trocar código por token: ${error['error_description'] ?? error['error']}');
      }
    } catch (e) {
      debugPrint('Erro ao trocar código por token: $e');
      rethrow;
    }
  }
} 
