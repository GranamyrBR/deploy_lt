import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecotour_dashboard/screens/ai_assistant_screen.dart';
import 'package:lecotour_dashboard/providers/ai_assistant_provider.dart';

class MockAIAssistantNotifier extends AIAssistantNotifier {
  @override
  Future<void> sendMessage(String message) async {
    // Mock implementation that adds a test response
    state = state.copyWith(
      messages: [
        ...state.messages,
        AIMessage(
          id: 'test-1',
          role: 'user',
          content: message,
          timestamp: DateTime.now(),
        ),
        AIMessage(
          id: 'test-2',
          role: 'assistant',
          content: 'Esta é uma resposta de teste para: $message',
          timestamp: DateTime.now().add(Duration(seconds: 1)),
        ),
      ],
      isLoading: false,
    );
  }

  @override
  Future<void> sendQuickAction(String action) async {
    // Mock implementation for quick actions
    String response;
    switch (action) {
      case 'recent_sales':
        response = 'As vendas recentes mostram um total de R$ 15.230,50 nas últimas 24 horas.';
        break;
      case 'popular_products':
        response = 'Os produtos mais populares são: Passeio de Barco (45 vendas), City Tour (38 vendas), e Ecoturismo (32 vendas).';
        break;
      case 'active_customers':
        response = 'Você tem 127 clientes ativos este mês, com 23 novos clientes registrados.';
        break;
      case 'month_metrics':
        response = 'As métricas do mês: Total de vendas: R$ 125.430,80 | Número de vendas: 234 | Ticket médio: R$ 536,02';
        break;
      default:
        response = 'Ação não reconhecida: $action';
    }

    state = state.copyWith(
      messages: [
        ...state.messages,
        AIMessage(
          id: 'quick-action-1',
          role: 'assistant',
          content: response,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }
}

void main() {
  group('AIAssistantScreen Widget Tests', () {
    testWidgets('should render AI assistant screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('Assistente de IA'), findsOneWidget);
      
      // Verify message input field
      expect(find.byType(TextField), findsOneWidget);
      
      // Verify send button
      expect(find.byIcon(Icons.send), findsOneWidget);
      
      // Verify analytics button
      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });

    testWidgets('should display quick action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Verify quick action buttons
      expect(find.text('Vendas Recentes'), findsOneWidget);
      expect(find.text('Produtos Populares'), findsOneWidget);
      expect(find.text('Clientes Ativos'), findsOneWidget);
      expect(find.text('Métricas do Mês'), findsOneWidget);
    });

    testWidgets('should send message when send button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Enter a message
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify message is being sent (loading state)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for response
      await tester.pump(Duration(seconds: 1));
      
      // Verify both user message and AI response are displayed
      expect(find.text('Test message'), findsOneWidget);
      expect(find.textContaining('Esta é uma resposta de teste'), findsOneWidget);
    });

    testWidgets('should not send empty message', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Try to send empty message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify no loading indicator (message not sent)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should handle quick action button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Tap on quick action
      await tester.tap(find.text('Vendas Recentes'));
      await tester.pump();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for response
      await tester.pump(Duration(seconds: 1));
      
      // Verify response is displayed
      expect(find.textContaining('vendas recentes'), findsOneWidget);
    });

    testWidgets('should show usage metrics dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Tap analytics button
      await tester.tap(find.byIcon(Icons.analytics));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Métricas de Uso'), findsOneWidget);
      expect(find.text('Total de Requisições'), findsOneWidget);
      expect(find.text('Tokens Utilizados'), findsOneWidget);
      expect(find.text('Tempo Médio de Resposta'), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      
      // Verify dialog is closed
      expect(find.text('Métricas de Uso'), findsNothing);
    });

    testWidgets('should display conversation history', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Send multiple messages
      for (int i = 0; i < 3; i++) {
        await tester.enterText(find.byType(TextField), 'Message $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump(Duration(seconds: 1));
      }

      // Verify all messages are displayed
      expect(find.text('Message 0'), findsOneWidget);
      expect(find.text('Message 1'), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
      
      // Verify AI responses are displayed
      expect(find.textContaining('Esta é uma resposta de teste'), findsWidgets);
    });

    testWidgets('should scroll to show latest messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Send many messages to trigger scrolling
      for (int i = 0; i < 10; i++) {
        await tester.enterText(find.byType(TextField), 'Message $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump(Duration(milliseconds: 500));
      }

      // Verify latest message is visible
      expect(find.text('Message 9'), findsOneWidget);
    });

    testWidgets('should show loading indicator during AI processing', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Send message
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(Duration(milliseconds: 100));

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for completion
      await tester.pump(Duration(seconds: 1));
      
      // Verify loading indicator is gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should handle different screen sizes', (WidgetTester tester) async {
      // Test on small screen
      tester.binding.window.physicalSizeTestValue = Size(320, 568);
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Verify UI adapts to small screen
      expect(find.byType(AIAssistantScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      
      // Reset screen size
      tester.binding.window.clearPhysicalSizeTestValue();
    });

    testWidgets('should show conversation history viewer', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantProvider.overrideWith((ref) => MockAIAssistantNotifier()),
          ],
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      // Send some messages first
      await tester.enterText(find.byType(TextField), 'First message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(Duration(seconds: 1));

      // Open conversation history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Verify history dialog is shown
      expect(find.text('Histórico de Conversas'), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      
      // Verify dialog is closed
      expect(find.text('Histórico de Conversas'), findsNothing);
    });
  });
}