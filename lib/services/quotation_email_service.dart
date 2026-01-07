import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../models/enhanced_quotation_model.dart';
import 'pdf_generator_simple.dart';

class QuotationEmailService {
  static Future<bool> sendQuotationEmail({
    required Quotation quotation,
    required String recipientEmail,
    String? recipientName,
    String? additionalMessage,
    File? attachmentFile,
  }) async {
    try {
      // Generate PDF if no attachment provided
      File? pdfFile = attachmentFile;
      pdfFile ??= await PdfGeneratorSimple.generatePdf(quotation);

      // Create email subject
      final subject = 'Cotação de Viagem - ${quotation.quotationNumber}';

      // Create email body
      final body = _createEmailBody(
        quotation: quotation,
        recipientName: recipientName,
        additionalMessage: additionalMessage,
      );

      // Create email
      final email = Email(
        subject: subject,
        body: body,
        recipients: [recipientEmail],
        attachmentPaths: [pdfFile.path],
        isHTML: false,
      );

      // Send email
      await FlutterEmailSender.send(email);
      return true;
    } catch (e) {
      debugPrint('Error sending quotation email: $e');
      return false;
    }
  }

  static String _createEmailBody({
    required Quotation quotation,
    String? recipientName,
    String? additionalMessage,
  }) {
    final buffer = StringBuffer();
    
    // Greeting
    if (recipientName != null && recipientName.isNotEmpty) {
      buffer.writeln('Prezado(a) $recipientName,');
    } else {
      buffer.writeln('Prezado(a),');
    }
    buffer.writeln();
    
    // Main message
    buffer.writeln('Segue em anexo a cotação de viagem conforme solicitado.');
    buffer.writeln();
    
    // Quotation summary
    buffer.writeln('RESUMO DA COTAÇÃO:');
    buffer.writeln('Número: ${quotation.quotationNumber}');
    buffer.writeln('Cliente: ${quotation.clientName}');
    buffer.writeln('Data da Viagem: ${quotation.travelDate.day}/${quotation.travelDate.month}/${quotation.travelDate.year}');
    buffer.writeln('Número de Passageiros: ${quotation.passengerCount}');
    buffer.writeln('Valor Total: ${quotation.formattedTotal}');
    buffer.writeln();
    
    // Items summary
    if (quotation.items.isNotEmpty) {
      buffer.writeln('ITENS INCLUÍDOS:');
      for (final item in quotation.items) {
        buffer.writeln('• ${item.description} - ${quotation.currency} ${item.totalValue.toStringAsFixed(2)}');
      }
      buffer.writeln();
    }
    
    // Validity notice
    if (quotation.expirationDate != null) {
      buffer.writeln('Esta cotação é válida até ${quotation.expirationDate!.day}/${quotation.expirationDate!.month}/${quotation.expirationDate!.year}.');
      buffer.writeln();
    }
    
    // Additional message
    if (additionalMessage != null && additionalMessage.isNotEmpty) {
      buffer.writeln('OBSERVAÇÕES:');
      buffer.writeln(additionalMessage);
      buffer.writeln();
    }
    
    // Terms and conditions
    if (quotation.cancellationPolicy != null || quotation.paymentTerms != null) {
      buffer.writeln('TERMOS E CONDIÇÕES:');
      if (quotation.cancellationPolicy != null) {
        buffer.writeln('Cancelamento: ${quotation.cancellationPolicy}');
      }
      if (quotation.paymentTerms != null) {
        buffer.writeln('Pagamento: ${quotation.paymentTerms}');
      }
      buffer.writeln();
    }
    
    // Closing
    buffer.writeln('Para confirmar esta cotação ou tirar dúvidas, favor entrar em contato.');
    buffer.writeln();
    buffer.writeln('Atenciosamente,');
    buffer.writeln('Equipe LeCoTour');
    
    return buffer.toString();
  }

  static Future<bool> sendQuotationToClient({
    required Quotation quotation,
    String? additionalMessage,
  }) async {
    return sendQuotationEmail(
      quotation: quotation,
      recipientEmail: quotation.clientEmail,
      recipientName: quotation.clientName,
      additionalMessage: additionalMessage,
    );
  }

  static Future<bool> sendQuotationToAgency({
    required Quotation quotation,
    String? additionalMessage,
  }) async {
    if (quotation.agency?.email == null) {
      debugPrint('No agency email available');
      return false;
    }

    return sendQuotationEmail(
      quotation: quotation,
      recipientEmail: quotation.agency!.email!,
      recipientName: quotation.agency!.contactPerson ?? quotation.agency!.name,
      additionalMessage: additionalMessage ?? 'Cotação enviada para aprovação do cliente.',
    );
  }

  static Future<bool> sendQuotationCopy({
    required Quotation quotation,
    required String copyEmail,
    String? copyName,
    String? additionalMessage,
  }) async {
    return sendQuotationEmail(
      quotation: quotation,
      recipientEmail: copyEmail,
      recipientName: copyName,
      additionalMessage: additionalMessage ?? 'Cópia da cotação enviada ao cliente.',
    );
  }
}