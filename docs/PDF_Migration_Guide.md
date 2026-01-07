# Guia de Migração: Suporte Unicode em PDFs

## 🎯 Objetivo

Eliminar os avisos:
```
Helvetica-Bold has no Unicode support
Helvetica has no Unicode support
```

E habilitar **suporte completo a caracteres acentuados** nos PDFs.

---

## ✅ Mudanças Implementadas

### 1. Novo Gerador com Suporte Unicode

**Criado:** `lib/services/quotation_pdf_with_fonts.dart`

Este gerador usa as fontes **Noto Sans** que já estão no projeto e oferece:
- ✅ Suporte total a acentos (á, é, í, ó, ú, ã, õ, ç)
- ✅ Símbolos de moeda (R$, €, £)
- ✅ Cache de fontes para performance
- ✅ Mesma interface dos geradores antigos

### 2. Arquivos Atualizados

| Arquivo | Mudança | Status |
|---------|---------|--------|
| `lib/widgets/quotation_management_dialog.dart` | ✅ Substituído por `QuotationPdfWithFonts` | Completo |
| `lib/services/quotation_whatsapp_service.dart` | ✅ Substituído por `QuotationPdfWithFonts` | Completo |
| `lib/services/quotation_email_service.dart` | ✅ Substituído por `QuotationPdfWithFonts` | Completo |

### 3. Geradores Antigos

Os geradores antigos foram **mantidos** para referência/debug:
- `lib/services/quotation_pdf_generator.dart` (com sanitização ASCII)
- `lib/services/professional_quotation_pdf_generator.dart` (com sanitização ASCII)

---

## 🧪 Como Testar

### 1. Executar Testes Automatizados

```bash
# Testar o novo gerador
flutter test test/services/quotation_pdf_with_fonts_test.dart

# Ver output detalhado
flutter test test/services/quotation_pdf_with_fonts_test.dart --reporter expanded
```

### 2. Testar no App

```bash
# Executar o app
flutter run

# Passos:
# 1. Abra uma cotação com dados acentuados:
#    - Cliente: "José da Silva"
#    - Destino: "São Paulo"
#    - Notas: "Observação importante"
#
# 2. Clique em "Gerar PDF"
#
# 3. Verifique o console - NÃO DEVE haver avisos de Unicode
#
# 4. Abra o PDF gerado e verifique se os acentos aparecem corretamente
```

### 3. Verificar Console

**ANTES (com avisos):**
```
Helvetica-Bold has no Unicode support see https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
Helvetica has no Unicode support see https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
```

**DEPOIS (sem avisos):**
```
✅ Fontes carregadas com sucesso!
✅ PDF gerado: /tmp/cotacao_COT-2025-001_1234567890.pdf
```

---

## 📊 Comparação: Antes vs Depois

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Acentos** | José → Jose ❌ | José → José ✅ |
| **Cedilha** | Cotacao ❌ | Cotação ✅ |
| **Til** | Sao Paulo ❌ | São Paulo ✅ |
| **Moeda** | BRL 1,500.00 ❌ | R$ 1.500,00 ✅ |
| **Avisos** | 2 warnings ⚠️ | Nenhum ✅ |
| **Performance** | Rápido ⚡ | Rápido ⚡ (com cache) |

---

## 🔧 Troubleshooting

### Problema: Ainda vejo avisos de Unicode

**Causa:** Ainda há código usando os geradores antigos.

**Solução:**
```bash
# Buscar usos dos geradores antigos
grep -r "QuotationPdfGenerator\|ProfessionalQuotationPdfGenerator" lib/

# Substituir por:
import 'package:lecotour_dashboard/services/quotation_pdf_with_fonts.dart';

final pdf = await QuotationPdfWithFonts.generateQuotationPdf(quotation);
```

### Problema: Erro "unable to find head table"

**Causa:** Fontes corrompidas ou caminho incorreto.

**Solução:**
1. Verificar que as fontes existem:
   ```bash
   ls fonts/NotoSans-*.ttf
   ```

2. Verificar `pubspec.yaml`:
   ```yaml
   flutter:
     fonts:
       - family: NotoSans
         fonts:
           - asset: fonts/NotoSans-Regular.ttf
           - asset: fonts/NotoSans-Bold.ttf
           - asset: fonts/NotoSans-Italic.ttf
   ```

3. Limpar e reconstruir:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Problema: PDF gerado mas sem acentos

**Causa:** Usando gerador antigo em vez do novo.

**Solução:**
Certifique-se de usar `QuotationPdfWithFonts` e não os antigos.

---

## 📚 Documentação Adicional

- **Guia Completo:** `docs/PDF_Unicode_Guide.md`
- **Código-fonte:** `lib/services/quotation_pdf_with_fonts.dart`
- **Testes:** `test/services/quotation_pdf_with_fonts_test.dart`
- **Wiki dart_pdf:** https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management

---

## ✨ Próximos Passos

1. ✅ **Testar:** Execute os testes e valide no app
2. ✅ **Commit:** Commit das mudanças
3. ⏭️ **Deploy:** Deploy para produção
4. 🗑️ **Limpar:** (Opcional) Remover geradores antigos após validação completa

---

## 📝 Checklist de Validação

- [ ] Testes automatizados passando
- [ ] App gera PDF sem warnings no console
- [ ] Acentos aparecem corretamente no PDF
- [ ] Símbolos (R$, ç, etc) funcionam
- [ ] Performance aceitável (< 2s para gerar PDF)
- [ ] WhatsApp envia PDF corretamente
- [ ] Email envia PDF corretamente

---

## 🎉 Status Final

✅ **Migração Completa**

Todos os usos dos geradores antigos foram substituídos pelo novo gerador com suporte Unicode.

**Data:** 5 de dezembro de 2025  
**Desenvolvedor:** AI Assistant  
**Referência:** [pdf_invoice_generator_flutter](https://github.com/md-weber/pdf_invoice_generator_flutter)


