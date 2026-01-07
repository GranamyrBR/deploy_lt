import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/enhanced_quotation_model.dart';

/// Gerador PDF Profissional para Cotações
class PdfGeneratorSimple {
  static Future<File> generatePdf(Quotation q) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
      final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'USD ', decimalDigits: 2);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // HEADER COM LOGO E TÍTULO
            _buildHeader(q, dateFormat),
            
            pw.SizedBox(height: 30),
            
            // INFORMAÇÕES DO CLIENTE
            _buildClientSection(q),
            
            pw.SizedBox(height: 20),
            
            // INFORMAÇÕES DA VIAGEM
            _buildTripSection(q, dateFormat),
            
            pw.SizedBox(height: 20),
            
            // SERVIÇOS COTADOS
            if (q.items.isNotEmpty) ...[
              _buildServicesSection(q, currencyFormat),
              pw.SizedBox(height: 20),
            ],
            
            // RESUMO FINANCEIRO
            _buildFinancialSummary(q, currencyFormat),
            
            pw.SizedBox(height: 30),
            
            // CONDIÇÕES E SERVIÇOS INCLUSOS
            _buildServicesIncludedSection(),
            
            pw.SizedBox(height: 20),
            
            // OBSERVAÇÕES
            if (q.notes != null && q.notes!.isNotEmpty) ...[
              _buildNotesSection(q),
              pw.SizedBox(height: 20),
            ],
            
            // FOOTER
            _buildFooter(),
          ],
        ),
      );

      final bytes = await pdf.save();
      
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'Cotacao_${q.quotationNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        return File('');
      } else {
        final file = File('${Directory.systemTemp.path}/Cotacao_${q.quotationNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e, stack) {
      print('Erro ao gerar PDF: $e\n$stack');
      rethrow;
    }
  }

  // HEADER PROFISSIONAL
  static pw.Widget _buildHeader(Quotation q, DateFormat dateFormat) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.blue900, PdfColors.blue700],
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LECOTOUR',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Receptivos em Nova York',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'COTACAO',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'No ${q.quotationNumber}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                dateFormat.format(q.quotationDate),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SEÇÃO DO CLIENTE
  static pw.Widget _buildClientSection(Quotation q) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Center(
                  child: pw.Text(
                    q.clientName.isNotEmpty ? q.clientName[0].toUpperCase() : 'C',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DADOS DO CLIENTE',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    q.clientName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(height: 20, color: PdfColors.grey300),
          _buildInfoRow('Email:', q.clientEmail),
          if (q.clientPhone != null) _buildInfoRow('Telefone:', q.clientPhone!),
        ],
      ),
    );
  }

  // SEÇÃO DA VIAGEM
  static pw.Widget _buildTripSection(Quotation q, DateFormat dateFormat) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DETALHES DA VIAGEM',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Destino:', q.destination ?? 'Nova York'),
                    _buildInfoRow('Data de Ida:', dateFormat.format(q.travelDate)),
                    if (q.returnDate != null)
                      _buildInfoRow('Data de Volta:', dateFormat.format(q.returnDate!)),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Passageiros:', '${q.passengerCount} pessoa(s)'),
                    if (q.hotel != null && q.hotel!.isNotEmpty)
                      _buildInfoRow('Hotel:', q.hotel!),
                    if (q.roomType != null && q.roomType!.isNotEmpty)
                      _buildInfoRow('Tipo de Quarto:', q.roomType!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SEÇÃO DE SERVIÇOS
  static pw.Widget _buildServicesSection(Quotation q, NumberFormat currencyFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SERVICOS INCLUSOS',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue900),
              children: [
                _buildTableHeader('Descricao'),
                _buildTableHeader('Qtd'),
                _buildTableHeader('Valor Unit.'),
                _buildTableHeader('Total'),
              ],
            ),
            // Items
            ...q.items.map((item) {
              final unitPrice = item.value / item.quantity;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: q.items.indexOf(item) % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                ),
                children: [
                  _buildTableCell(item.description),
                  _buildTableCell('${item.quantity}'),
                  _buildTableCell(currencyFormat.format(unitPrice)),
                  _buildTableCell(currencyFormat.format(item.value)),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // RESUMO FINANCEIRO
  static pw.Widget _buildFinancialSummary(Quotation q, NumberFormat currencyFormat) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.grey100, PdfColors.grey50],
        ),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        children: [
          _buildSummaryRow('Subtotal:', currencyFormat.format(q.subtotal)),
          if (q.discountAmount > 0)
            _buildSummaryRow(
              'Desconto:',
              '- ${currencyFormat.format(q.discountAmount)}',
              color: PdfColors.green700,
            ),
          if (q.taxAmount > 0)
            _buildSummaryRow('Impostos:', currencyFormat.format(q.taxAmount)),
          pw.Divider(height: 16, thickness: 2, color: PdfColors.grey400),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'VALOR TOTAL:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                currencyFormat.format(q.total),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CONDIÇÕES E SERVIÇOS INCLUSOS
  static pw.Widget _buildServicesIncludedSection() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green700,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'SERVICOS INCLUSOS',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          
          // Serviços inclusos
          _buildBulletPoint('Wi-Fi gratuito a bordo em todos os veiculos'),
          _buildBulletPoint('Agua em garrafa pequena em todos os veiculos'),
          _buildBulletPoint('45 minutos de periodo de tolerancia para voos domesticos, sem custo adicional'),
          _buildBulletPoint('60 minutos de periodo de tolerancia para voos internacionais, sem custo adicional'),
          _buildBulletPoint('SUVs: Suburban Black ou Similares'),
          
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.green300),
          pw.SizedBox(height: 8),
          
          // Taxas adicionais
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TAXAS ADICIONAIS',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber900,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildBulletPoint('Taxa noturna: +USD 30 (voos de chegada entre 23h e 5h)', small: true),
                _buildBulletPoint('Taxa noturna: +USD 30 (saida do hotel entre 00h e 5h)', small: true),
                _buildBulletPoint('Hora extra: USD 80/hora', small: true),
              ],
            ),
          ),
          
          pw.SizedBox(height: 8),
          pw.Text(
            'Outros carros disponiveis mediante cotacao especifica',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBulletPoint(String text, {bool small = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            width: 4,
            height: 4,
            decoration: pw.BoxDecoration(
              color: small ? PdfColors.amber700 : PdfColors.green700,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: small ? 8 : 9,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // OBSERVAÇÕES
  static pw.Widget _buildNotesSection(Quotation q) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.amber200),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'OBSERVACOES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            q.notes!,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // FOOTER
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'LECOTOUR - Receptivos em Nova York',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'www.lecotour.com | contato@lecotour.com | +1 (555) 123-4567',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Cotacao valida por 15 dias a partir da data de emissao',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // HELPERS
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: color ?? PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color ?? PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}
