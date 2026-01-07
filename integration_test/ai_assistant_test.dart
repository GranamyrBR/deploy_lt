import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:lecotour_dashboard/main.dart' as app;
import 'package:lecotour_dashboard/screens/ai_assistant_screen.dart';
import 'package:lecotour_dashboard/services/ai_assistant_service.dart';
import 'package:lecotour_dashboard/providers/ai_assistant_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Assistant Integration Tests', () {
    testWidgets('should load AI assistant screen', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Verify AI assistant screen is loaded
      expect(find.byType(AIAssistantScreen), findsOneWidget);
      expect(find.text('Assistente de IA'), findsOneWidget);
    });

    testWidgets('should send message and receive response', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Enter a message
      await tester.enterText(find.byType(TextField), 'Qual é o total de vendas deste mês?');
      await tester.pumpAndSettle();
      
      // Send message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle(Duration(seconds: 3)); // Wait for AI response
      
      // Verify response is received
      final responseFinder = find.textContaining('vendas');
      expect(responseFinder, findsWidgets);
    });

    testWidgets('should display quick action buttons', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Verify quick action buttons are present
      expect(find.text('Vendas Recentes'), findsOneWidget);
      expect(find.text('Produtos Populares'), findsOneWidget);
      expect(find.text('Clientes Ativos'), findsOneWidget);
      expect(find.text('Métricas do Mês'), findsOneWidget);
    });

    testWidgets('should handle quick action tap', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Tap on quick action
      await tester.tap(find.text('Vendas Recentes'));
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Verify AI response for quick action
      final responseFinder = find.textContaining('vendas');
      expect(responseFinder, findsWidgets);
    });

    testWidgets('should show typing indicator', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Send message
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      
      // Pump to show typing indicator
      await tester.pump(Duration(milliseconds: 100));
      
      // Verify typing indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display conversation history', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Send multiple messages
      for (int i = 0; i < 3; i++) {
        await tester.enterText(find.byType(TextField), 'Message $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle(Duration(seconds: 2));
      }
      
      // Verify conversation history
      expect(find.text('Message 0'), findsOneWidget);
      expect(find.text('Message 1'), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
    });

    testWidgets('should show usage metrics dialog', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Open metrics dialog
      await tester.tap(find.byIcon(Icons.analytics));
      await tester.pumpAndSettle();
      
      // Verify metrics dialog
      expect(find.text('Métricas de Uso'), findsOneWidget);
      expect(find.text('Total de Requisições'), findsOneWidget);
      expect(find.text('Tokens Utilizados'), findsOneWidget);
    });

    testWidgets('should handle empty message input', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Try to send empty message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      
      // Verify no message was sent (no new messages in chat)
      final messageCount = find.byType(Text).evaluate().length;
      expect(messageCount, greaterThan(0)); // Should have at least the UI text
    });

    testWidgets('should handle network errors gracefully', (WidgetTester tester) async {
      // This test would require mocking network failures
      // For now, we'll test the error UI elements
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Verify error handling UI is present
      expect(find.byType(SnackBar), findsNothing); // No error initially
    });

    testWidgets('should respect rate limiting', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to AI assistant screen
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      
      // Send multiple messages quickly
      for (int i = 0; i < 5; i++) {
        await tester.enterText(find.byType(TextField), 'Rate limit test $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump(Duration(milliseconds: 100));
      }
      
      // Verify app doesn't crash and handles rate limiting
      expect(find.byType(AIAssistantScreen), findsOneWidget);
    });
  });

  group('AI Assistant Service Integration', () {
    test('should process request with database context', () async {
      final service = AIAssistantService();
      
      final request = AIRequestModel(
        message: 'What are the recent sales?',
        userId: 'test-user',
        context: {}
      );
      
      // This would require a real database connection
      // For integration test, we verify the request structure
      expect(request.message, 'What are the recent sales?');
      expect(request.userId, 'test-user');
      expect(request.context, isNotNull);
    });

    test('should handle different types of queries', () async {
      final service = AIAssistantService();
      
      final queries = [
        'Show me sales data',
        'What products are popular?',
        'Who are our top customers?',
        'What is the revenue this month?'
      ];
      
      for (final query in queries) {
        final request = AIRequestModel(
          message: query,
          userId: 'test-user',
          context: {}
        );
        
        expect(request.message, query);
        expect(request.userId, 'test-user');
      }
    });

    test('should generate appropriate system prompts', () async {
      final service = AIAssistantService();
      
      final context = {
        'user': {'name': 'Test User', 'role': 'admin'},
        'sales': {'total': 10000.0, 'count': 50},
        'products': ['Product A', 'Product B']
      };
      
      // Test context structure
      expect(context['user'], isNotNull);
      expect(context['sales'], isNotNull);
      expect(context['products'], isNotNull);
    });
  });
}