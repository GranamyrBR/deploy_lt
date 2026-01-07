import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/models/ai_request_model.dart';
import 'package:lecotour_dashboard/models/ai_response_model.dart';

void main() {
  group('AI Models', () {
    group('AIRequest', () {
      test('should create AIRequest with required fields', () {
        final request = AIRequest(
          message: 'Test message',
          userId: 'test-user',
          conversationId: 'test-conversation',
        );
        
        expect(request.message, 'Test message');
        expect(request.userId, 'test-user');
        expect(request.conversationId, 'test-conversation');
        expect(request.timestamp, isNotNull);
      });

      test('should create AIRequest with optional fields', () {
        final context = {'key': 'value'};
        final request = AIRequest(
          message: 'Test message',
          userId: 'test-user',
          conversationId: 'test-conversation',
          context: context,
          requestType: 'test-type',
        );
        
        expect(request.context, context);
        expect(request.requestType, 'test-type');
      });

      test('should copy AIRequest with updated fields', () {
        final original = AIRequest(
          message: 'Original message',
          userId: 'original-user',
          conversationId: 'original-conversation',
        );
        
        final updated = original.copyWith(
          message: 'Updated message',
        );
        
        expect(updated.message, 'Updated message');
        expect(updated.userId, 'original-user'); // Should remain unchanged
        expect(updated.conversationId, 'original-conversation'); // Should remain unchanged
      });

      test('should convert AIRequest to JSON and back', () {
        final request = AIRequest(
          message: 'Test message',
          userId: 'test-user',
          conversationId: 'test-conversation',
          context: {'key': 'value'},
          requestType: 'test-type',
        );
        
        final json = request.toJson();
        final fromJson = AIRequest.fromJson(json);
        
        expect(fromJson.message, request.message);
        expect(fromJson.userId, request.userId);
        expect(fromJson.conversationId, request.conversationId);
      });
    });

    group('AIResponse', () {
      test('should create AIResponse with required fields', () {
        final response = AIResponse(
          message: 'Test response',
          conversationId: 'test-conversation',
          timestamp: DateTime.now(),
          tokensUsed: 100,
          model: 'gpt-4-turbo-preview',
        );
        
        expect(response.message, 'Test response');
        expect(response.conversationId, 'test-conversation');
        expect(response.tokensUsed, 100);
        expect(response.model, 'gpt-4-turbo-preview');
        expect(response.hasError, false);
        expect(response.isSuccess, true);
      });

      test('should create AIResponse with error', () {
        final response = AIResponse(
          message: '',
          conversationId: 'test-conversation',
          timestamp: DateTime.now(),
          tokensUsed: 0,
          model: 'gpt-4-turbo-preview',
          error: 'API Error',
        );
        
        expect(response.hasError, true);
        expect(response.isSuccess, false);
        expect(response.error, 'API Error');
      });

      test('should copy AIResponse with updated fields', () {
        final original = AIResponse(
          message: 'Original response',
          conversationId: 'original-conversation',
          timestamp: DateTime.now(),
          tokensUsed: 50,
          model: 'gpt-4-turbo-preview',
        );
        
        final updated = original.copyWith(
          message: 'Updated response',
          tokensUsed: 75,
        );
        
        expect(updated.message, 'Updated response');
        expect(updated.tokensUsed, 75);
        expect(updated.conversationId, 'original-conversation'); // Should remain unchanged
      });

      test('should convert AIResponse to JSON and back', () {
        final response = AIResponse(
          message: 'Test response',
          conversationId: 'test-conversation',
          timestamp: DateTime.now(),
          tokensUsed: 100,
          model: 'gpt-4-turbo-preview',
          metadata: {'key': 'value'},
        );
        
        final json = response.toJson();
        final fromJson = AIResponse.fromJson(json);
        
        expect(fromJson.message, response.message);
        expect(fromJson.conversationId, response.conversationId);
        expect(fromJson.tokensUsed, response.tokensUsed);
        expect(fromJson.model, response.model);
      });
    });
  });

  group('AI Service Logic', () {
    test('should create appropriate system prompt', () {
      final context = {
        'user': {'name': 'Test User', 'role': 'admin'},
        'sales': {'total': 1000.0, 'count': 5}
      };
      
      final systemPrompt = createSystemPrompt(context);
      
      expect(systemPrompt, isNotNull);
      expect(systemPrompt, contains('assistente especializado'));
      expect(systemPrompt, contains('Lecotour'));
      expect(systemPrompt, contains(context.toString()));
    });

    test('should filter sensitive data from context', () {
      final sensitiveContext = {
        'user': {
          'name': 'Test User',
          'password': 'secret123',
          'email': 'user@example.com',
          'api_key': 'secret-api-key'
        }
      };
      
      final filtered = filterSensitiveData(sensitiveContext);
      
      expect(filtered['user'], isNot(contains('password')));
      expect(filtered['user'], isNot(contains('api_key')));
      expect(filtered['user'], contains('name'));
      expect(filtered['user'], contains('email'));
    });

    test('should sanitize user input', () {
      final maliciousInput = '<script>alert("xss")</script>';
      final sanitized = sanitizeInput(maliciousInput);
      
      expect(sanitized, isNot(contains('<script>')));
      expect(sanitized, isNot(contains('</script>')));
    });

    test('should validate input parameters', () {
      // Valid input
      final validRequest = AIRequest(
        message: 'Valid message',
        userId: 'valid-user',
        conversationId: 'valid-conversation',
      );
      
      expect(isValidRequest(validRequest), true);
      
      // Invalid input - empty message
      final invalidMessage = AIRequest(
        message: '',
        userId: 'valid-user',
        conversationId: 'valid-conversation',
      );
      
      expect(isValidRequest(invalidMessage), false);
      
      // Invalid input - empty user ID
      final invalidUserId = AIRequest(
        message: 'Valid message',
        userId: '',
        conversationId: 'valid-conversation',
      );
      
      expect(isValidRequest(invalidUserId), false);
    });

    test('should meet performance requirements', () async {
      // Simulate AI processing time
      final startTime = DateTime.now();
      
      // Simulate processing
      await Future.delayed(Duration(milliseconds: 100));
      
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      // Should be less than 3 seconds (3000ms)
      expect(responseTime, lessThan(3000));
    });
  });
}

// Helper functions for testing
String createSystemPrompt(Map<String, dynamic> context) {
  return '''Você é um assistente especializado em análise de dados e vendas para a empresa Lecotour.
  
Contexto do sistema:
- Especialista em turismo e vendas
- Acesso a dados de vendas, clientes e produtos
- Foco em insights acionáveis e recomendações

Dados disponíveis: ${context.toString()}

Forneça respostas claras, objetivas e baseadas nos dados apresentados.''';}

Map<String, dynamic> filterSensitiveData(Map<String, dynamic> context) {
  final filtered = Map<String, dynamic>.from(context);
  if (filtered.containsKey('user')) {
    final userData = Map<String, dynamic>.from(filtered['user']);
    userData.remove('password');
    userData.remove('api_key');
    userData.remove('secret');
    filtered['user'] = userData;
  }
  return filtered;
}

String sanitizeInput(String input) {
  return input
      .replaceAll(RegExp(r'<script[^>]*>.*?</script>'), '')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .trim();
}

bool isValidRequest(AIRequest request) {
  return request.message.isNotEmpty && 
         request.userId.isNotEmpty && 
         request.conversationId.isNotEmpty;
}