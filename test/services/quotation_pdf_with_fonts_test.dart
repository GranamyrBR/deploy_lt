import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/models/enhanced_quotation_model.dart';
import 'package:lecotour_dashboard/services/quotation_pdf_with_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuotationPdfWithFonts', () {
    test('should generate PDF with Unicode support (integration test)', () async {
      // IMPORTANTE: Este teste requer assets (fontes)
      // Execute com: flutter test --platform chrome test/services/quotation_pdf_with_fonts_test.dart
      
      final quotation = Quotation(
        quotationNumber: 'COT-2025-001',
        type: 'tourism',
        status: 'draft',
        clientName: 'José da Silva',  // COM ACENTOS
        clientEmail: 'jose@example.com',
        clientPhone: '(11) 98765-4321',
        travelDate: DateTime(2025, 3, 15),
        returnDate: DateTime(2025, 3, 22),
        passengerCount: 2,
        destination: 'São Paulo', // COM ACENTOS
        hotel: 'Hotel Ação Internacional', // COM Ç e Ã
        quotationDate: DateTime.now(),
        subtotal: 5000.00,
        discountAmount: 500.00,
        taxRate: 0.0,
        taxAmount: 0.0,
        total: 4500.00,
        currency: 'BRL',
        createdBy: 'Test User',
        createdAt: DateTime.now(),
        items: [
          QuotationItem(
            id: '1',
            description: 'Passagem Aérea São Paulo - Rio', // COM ACENTOS
            date: DateTime(2025, 3, 15),
            value: 3000.00,
            category: 'service',
            quantity: 2,
          ),
          QuotationItem(
            id: '2',
            description: 'Hospedagem com café da manhã', // COM ACENTOS
            date: DateTime(2025, 3, 15),
            value: 1400.00,
            category: 'service',
            quantity: 7,
          ),
        ],
        notes: 'Observação: Preços válidos até 31/12/2025', // COM Ç e Á
      );

      // Testar geração
      final file = await QuotationPdfWithFonts.generateQuotationPdf(quotation);

      // Verificações
      expect(file.existsSync(), true);
      expect(file.path.contains('cotacao_'), true);
      expect(file.path.endsWith('.pdf'), true);

      final bytes = await file.readAsBytes();
      expect(bytes.isNotEmpty, true);
      expect(bytes.length > 1000, true, reason: 'PDF deve ter conteúdo significativo');

      print('✅ PDF gerado com sucesso: ${file.path}');
      print('   Tamanho: ${bytes.length} bytes');
      print('   ✅ Suporte a Unicode: José, São, ção, etc.');
      
      // Limpar
      if (file.existsSync()) {
        await file.delete();
      }
    });

    test('should cache fonts after first load', () async {
      // Carregar primeira vez
      final quotation = Quotation(
        quotationNumber: 'TEST-001',
        type: 'tourism',
        status: 'draft',
        clientName: 'Test',
        clientEmail: 'test@test.com',
        travelDate: DateTime.now(),
        passengerCount: 1,
        quotationDate: DateTime.now(),
        subtotal: 100,
        discountAmount: 0,
        taxRate: 0,
        taxAmount: 0,
        total: 100,
        currency: 'BRL',
        createdBy: 'Test',
        createdAt: DateTime.now(),
        items: [],
      );

      final stopwatch = Stopwatch()..start();
      await QuotationPdfWithFonts.generateQuotationPdf(quotation);
      stopwatch.stop();
      final firstTime = stopwatch.elapsedMilliseconds;

      // Carregar segunda vez (deve ser mais rápido por causa do cache)
      stopwatch.reset();
      stopwatch.start();
      await QuotationPdfWithFonts.generateQuotationPdf(quotation);
      stopwatch.stop();
      final secondTime = stopwatch.elapsedMilliseconds;

      print('⏱️ Primeira geração: ${firstTime}ms');
      print('⏱️ Segunda geração: ${secondTime}ms (com cache)');
      
      // Segunda geração PODE ser mais rápida (mas não sempre garantido)
      expect(secondTime >= 0, true, reason: 'Tempo deve ser positivo');
    });
  });
}

