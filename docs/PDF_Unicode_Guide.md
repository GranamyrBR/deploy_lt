# Guia: Unicode e Acentos em PDFs

## Problema

As fontes padrão do PDF (Helvetica, Times, Courier) **não suportam caracteres Unicode** como:
- Acentos: á, é, í, ó, ú, ã, õ, ç
- Símbolos de moeda: R$, €, £
- Emojis: 😀, 🚗, ✈️
- Caracteres especiais de outros idiomas

### Erros Comuns
```
Helvetica has no Unicode support see https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
unable to find head table
TTF is not supported
```

---

## ✅ SOLUÇÃO RECOMENDADA (Com Fontes)

### Você JÁ TEM as Fontes Instaladas!

O projeto já possui **Noto Sans** e **Roboto** no `pubspec.yaml`. Basta usar corretamente:

```dart
import 'package:lecotour_dashboard/services/quotation_pdf_with_fonts.dart';

// Gerar PDF COM suporte a Unicode
final file = await QuotationPdfWithFonts.generateQuotationPdf(quotation);

// Agora funciona:
// - José da Silva ✅
// - São Paulo ✅
// - Cotação ✅  
// - R$ 1.500,00 ✅
```

**Referência:** [pdf_invoice_generator_flutter](https://github.com/md-weber/pdf_invoice_generator_flutter) - Tutorial oficial do pacote PDF

---

## Soluções Alternativas

### ✅ Solução 1: Remover Acentos (Atual - Mais Simples)

Use `TextUtils.formatForPdf()` para remover acentos automaticamente:

```dart
import 'package:lecotour_dashboard/utils/text_utils.dart';

// Antes de colocar texto no PDF
final nomeCliente = 'José da Silva';
final nomeSemAcento = TextUtils.formatForPdf(nomeCliente); // 'Jose da Silva'

pw.Text(nomeSemAcento); // ✅ Funciona
```

**Para moedas:**
```dart
// Ao invés de 'R$' use 'BRL' ou 'USD'
final moeda = TextUtils.pdfSafeCurrencySymbol('BRL'); // 'BRL '
pw.Text('${moeda}1.500,00'); // ✅ BRL 1.500,00
```

**Vantagens:**
- ✅ Simples e rápido
- ✅ Sem dependências extras
- ✅ Funciona imediatamente

**Desvantagens:**
- ⚠️ Perde acentuação original
- ⚠️ "José" vira "Jose"

---

### ✅ Solução 2: Usar Apenas ASCII

Evite caracteres com acento no conteúdo do PDF:

```dart
// ❌ NÃO FUNCIONA
pw.Text('Cotação de Viagem');
pw.Text('R$ 1.500,00');

// ✅ FUNCIONA
pw.Text('Cotacao de Viagem');
pw.Text('USD 1,500.00');
```

---

### ✅ Solução 3: Implementar Fontes TrueType Customizadas

✅ **AGORA FUNCIONA!** Use `QuotationPdfWithFonts` que já implementa tudo corretamente.

#### Como Funciona Internamente

O código em `quotation_pdf_with_fonts.dart` faz exatamente isto:

```dart
// 1. Carregar fontes TTF (com cache para performance)
final regular = await rootBundle.load('fonts/NotoSans-Regular.ttf');
final bold = await rootBundle.load('fonts/NotoSans-Bold.ttf');
final italic = await rootBundle.load('fonts/NotoSans-Italic.ttf');

final ttfRegular = pw.Font.ttf(regular);
final ttfBold = pw.Font.ttf(bold);
final ttfItalic = pw.Font.ttf(italic);

// 2. Aplicar tema com as fontes
pdf.addPage(
  pw.MultiPage(
    theme: pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
      italic: ttfItalic,
    ),
    build: (context) {
      // Agora TODO texto terá suporte a Unicode! ✅
      return [
        pw.Text('Cotação com ç, ã, é, etc!'),
        pw.Text('R$ 1.500,00'), // Símbolo funciona!
      ];
    },
  ),
);
```

#### Fontes Disponíveis no Projeto

Você já tem estas fontes instaladas:

```yaml
# pubspec.yaml (já configurado)
flutter:
  fonts:
    - family: NotoSans       # ✅ Fonte principal (Unicode completo)
      fonts:
        - asset: fonts/NotoSans-Regular.ttf
        - asset: fonts/NotoSans-Bold.ttf
        - asset: fonts/NotoSans-Italic.ttf
        - asset: fonts/NotoSans-BoldItalic.ttf
    
    - family: Roboto         # ✅ Fallback
      fonts:
        - asset: fonts/Roboto-Regular.ttf
```

**Fontes recomendadas** (caso precise adicionar mais):
- [Google Fonts - Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans) ✅ Já instalada
- [Google Fonts - Roboto](https://fonts.google.com/specimen/Roboto) ✅ Já instalada
- [Adobe Source Sans Pro](https://fonts.adobe.com/fonts/source-sans-pro)

---

## Uso Recomendado no Projeto

### Para Cotações (`quotation_pdf_generator.dart`)

```dart
// Opção 1: Remover acentos
import '../utils/text_utils.dart';

final clientName = TextUtils.formatForPdf(quotation.clientName);
pw.Text(clientName);

// Opção 2: Usar apenas ASCII
pw.Text('QUOTATION'); // Ao invés de 'COTAÇÃO'
pw.Text('Customer'); // Ao invés de 'Cliente'
```

### Para Moedas

```dart
// ❌ Não funciona
pw.Text('R$ 1.500,00');

// ✅ Funciona
pw.Text('BRL 1,500.00'); // Ou USD, EUR
```

---

## Testando

```dart
import 'package:lecotour_dashboard/utils/text_utils.dart';

void test() {
  print(TextUtils.formatForPdf('José da Silva')); // Jose da Silva
  print(TextUtils.formatForPdf('São Paulo')); // Sao Paulo
  print(TextUtils.formatForPdf('Cotação')); // Cotacao
  print(TextUtils.pdfSafeCurrencySymbol('BRL')); // BRL 
  print(TextUtils.pdfSafeCurrencySymbol('USD')); // USD 
}
```

---

## Links Úteis

- [PDF Package Wiki - Fonts Management](https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management)
- [Google Fonts](https://fonts.google.com/)
- [Font Squirrel - Webfont Generator](https://www.fontsquirrel.com/tools/webfont-generator)

---

## Status Atual

✅ **COMPLETO - Implementado:**
- `QuotationPdfWithFonts` - Gerador com suporte TOTAL a Unicode
- Cache de fontes para performance
- `TextUtils.formatForPdf()` - Remove acentos (alternativa)
- `TextUtils.pdfSafeCurrencySymbol()` - Símbolos de moeda seguros (alternativa)
- Testes automatizados (`quotation_pdf_with_fonts_test.dart`)

## Comparação das Soluções

| Recurso | Solução 1 (Remover Acentos) | Solução 2 (ASCII Only) | Solução 3 (Com Fontes) ✅ |
|---------|----------------------------|----------------------|-------------------------|
| Suporta acentos | ❌ José → Jose | ❌ Evitar acentos | ✅ José → José |
| Suporta R$ | ❌ BRL | ❌ USD/BRL | ✅ R$ |
| Performance | ⚡ Rápida | ⚡ Rápida | ⚡ Rápida (com cache) |
| Complexidade | 🟢 Simples | 🟢 Simples | 🟡 Moderada |
| Qualidade | ⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ |
| Recomendado | Para testes | Para inglês | **SIM** ✅ |

## Recomendação Final

🎯 **Use `QuotationPdfWithFonts` para produção**

```dart
// ✅ RECOMENDADO - Produção
import 'package:lecotour_dashboard/services/quotation_pdf_with_fonts.dart';
final file = await QuotationPdfWithFonts.generateQuotationPdf(quotation);

// 🔧 ALTERNATIVA - Desenvolvimento/Testes
import 'package:lecotour_dashboard/services/quotation_pdf_generator.dart';
final file = await QuotationPdfGenerator.generateQuotationPdf(quotation);
```

