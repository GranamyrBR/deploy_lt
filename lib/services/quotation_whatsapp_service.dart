import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/enhanced_quotation_model.dart';
import 'pdf_generator_simple.dart';

class QuotationWhatsAppService {
  static Future<bool> sendQuotationWhatsApp({
    required Quotation quotation,
    required String phoneNumber,
    String? recipientName,
    String? additionalMessage,
    File? attachmentFile,
  }) async {
    try {
      // Generate PDF if no attachment provided
      File? pdfFile = attachmentFile;
      if (pdfFile == null) {
        pdfFile = await PdfGeneratorSimple.generatePdf(quotation);
      }

      // Create WhatsApp message
      final message = _createWhatsAppMessage(
        quotation: quotation,
        recipientName: recipientName,
        additionalMessage: additionalMessage,
      );

      // For WhatsApp, we can either:
      // 1. Open WhatsApp with pre-filled message (URL launcher)
      // 2. Share the PDF file with WhatsApp (Share Plus)
      
      // Option 1: URL launcher for text message
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
      
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        
        // Also offer to share the PDF file
        _sharePdfFile(pdfFile, 'Cotação ${quotation.quotationNumber}');
        
        return true;
      } else {
        // Fallback to share dialog
        _shareQuotation(quotation, pdfFile);
        return true;
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp message: $e');
      return false;
    }
  }

  static String _createWhatsAppMessage({
    required Quotation quotation,
    String? recipientName,
    String? additionalMessage,
  }) {
    final buffer = StringBuffer();
    
    // Greeting
    if (recipientName != null && recipientName.isNotEmpty) {
      buffer.writeln('Olá $recipientName,');
    } else {
      buffer.writeln('Olá,');
    }
    buffer.writeln();
    
    // Main message
    buffer.writeln('Segue cotação de viagem conforme solicitado:');
    buffer.writeln();
    
    // Quotation summary
    buffer.writeln('*RESUMO DA COTAÇÃO:*');
    buffer.writeln('📋 Número: ${quotation.quotationNumber}');
    buffer.writeln('👤 Cliente: ${quotation.clientName}');
    buffer.writeln('📅 Data: ${quotation.travelDate.day}/${quotation.travelDate.month}/${quotation.travelDate.year}');
    buffer.writeln('👥 Passageiros: ${quotation.passengerCount}');
    buffer.writeln('💰 Total: ${quotation.formattedTotal}');
    buffer.writeln();
    
    // Items summary (limited for WhatsApp)
    if (quotation.items.isNotEmpty) {
      buffer.writeln('*ITENS INCLUÍDOS:*');
      final limitedItems = quotation.items.take(5).toList();
      for (final item in limitedItems) {
        buffer.writeln('• ${item.description}');
      }
      if (quotation.items.length > 5) {
        buffer.writeln('• ... e mais ${quotation.items.length - 5} itens');
      }
      buffer.writeln();
    }
    
    // Validity notice
    if (quotation.expirationDate != null) {
      buffer.writeln('⏰ *Validade:* até ${quotation.expirationDate!.day}/${quotation.expirationDate!.month}/${quotation.expirationDate!.year}');
      buffer.writeln();
    }
    
    // Additional message
    if (additionalMessage != null && additionalMessage.isNotEmpty) {
      buffer.writeln('*INFORMAÇÕES:*');
      buffer.writeln(additionalMessage);
      buffer.writeln();
    }
    
    // Terms and conditions (shortened for WhatsApp)
    if (quotation.cancellationPolicy != null || quotation.paymentTerms != null) {
      buffer.writeln('*TERMOS:*');
      if (quotation.cancellationPolicy != null) {
        buffer.writeln('🔄 Cancelamento: ${quotation.cancellationPolicy}');
      }
      if (quotation.paymentTerms != null) {
        buffer.writeln('💳 Pagamento: ${quotation.paymentTerms}');
      }
      buffer.writeln();
    }
    
    // Closing
    buffer.writeln('Para confirmar ou tirar dúvidas, estou à disposição!');
    buffer.writeln();
    buffer.writeln('Atenciosamente,');
    buffer.writeln('Equipe LeCoTour');
    buffer.writeln();
    buffer.writeln('📄 *PDF anexado com detalhes completos*');
    
    return buffer.toString();
  }

  static Future<void> _sharePdfFile(File pdfFile, String subject) async {
    try {
      final xFile = XFile(pdfFile.path);
      await Share.shareXFiles(
        [xFile],
        subject: subject,
        text: 'Cotação de Viagem - $subject',
      );
    } catch (e) {
      debugPrint('Error sharing PDF file: $e');
    }
  }

  static Future<void> _shareQuotation(Quotation quotation, File pdfFile) async {
    try {
      final xFile = XFile(pdfFile.path);
      final message = _createWhatsAppMessage(quotation: quotation);
      
      await Share.share(
        '$message\n\n📄 PDF anexado com detalhes completos',
        subject: 'Cotação ${quotation.quotationNumber}',
      );
    } catch (e) {
      debugPrint('Error sharing quotation: $e');
    }
  }

  static Future<bool> sendQuotationToClient({
    required Quotation quotation,
    String? additionalMessage,
  }) async {
    if (quotation.clientContact?.whatsapp == null) {
      debugPrint('No client WhatsApp number available');
      return false;
    }

    // Remove non-numeric characters from phone number
    final cleanPhone = quotation.clientContact!.whatsapp!.replaceAll(RegExp(r'[^0-9+]'), '');
    
    return sendQuotationWhatsApp(
      quotation: quotation,
      phoneNumber: cleanPhone,
      recipientName: quotation.clientName,
      additionalMessage: additionalMessage,
    );
  }

  static Future<bool> sendQuotationToAgency({
    required Quotation quotation,
    String? additionalMessage,
  }) async {
    if (quotation.agency == null) {
      debugPrint('No agency available');
      return false;
    }

    // Try to get agency contact phone/WhatsApp
    String? agencyPhone;
    
    // First try to find agency contact with WhatsApp
    if (quotation.agency!.contactPerson != null) {
      // In a real app, you would query contacts for agency
      // For now, we'll try a default format
      agencyPhone = '+55'; // Default country code, should be configurable
    }

    if (agencyPhone == null) {
      debugPrint('No agency WhatsApp number available');
      return false;
    }

    return sendQuotationWhatsApp(
      quotation: quotation,
      phoneNumber: agencyPhone,
      recipientName: quotation.agency!.contactPerson ?? quotation.agency!.name,
      additionalMessage: additionalMessage ?? 'Cotação enviada para aprovação do cliente.',
    );
  }

  static Future<bool> sendQuotationCopy({
    required Quotation quotation,
    required String phoneNumber,
    String? recipientName,
    String? additionalMessage,
  }) async {
    return sendQuotationWhatsApp(
      quotation: quotation,
      phoneNumber: phoneNumber,
      recipientName: recipientName,
      additionalMessage: additionalMessage ?? 'Cópia da cotação enviada ao cliente.',
    );
  }

  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters except +
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Ensure it starts with country code
    if (!cleanNumber.startsWith('+')) {
      // Default to Brazil country code, should be configurable
      cleanNumber = '+55$cleanNumber';
    }
    
    return cleanNumber;
  }
}