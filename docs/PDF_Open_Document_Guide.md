# Guia: Abrir PDFs Automaticamente

## 📦 Bibliotecas Adicionadas

```yaml
dependencies:
  pdf: ^3.11.3              # Gera PDFs
  printing: ^5.13.2         # Imprime PDFs
  path_provider: ^2.1.4     # Localiza diretórios do sistema
  open_file: ^3.5.8         # Abre arquivos automaticamente ✨
```

---

## 🎯 Como Usar

### Opção 1: Gerar e Salvar (sem abrir)

```dart
import 'package:lecotour_dashboard/services/quotation_pdf_with_fonts.dart';

// Apenas gera e salva o PDF
final file = await QuotationPdfWithFonts.generateQuotationPdf(quotation);
print('PDF salvo em: ${file.path}');

// Você pode fazer algo com o arquivo depois
// Ex: enviar por email, WhatsApp, etc
```

### Opção 2: Gerar, Salvar E Abrir ⭐

```dart
import 'package:lecotour_dashboard/services/quotation_pdf_with_fonts.dart';

// Gera, salva E abre automaticamente
final file = await QuotationPdfWithFonts.generateAndOpenQuotationPdf(quotation);
print('PDF gerado e aberto!');
```

---

## 💡 Exemplo: Botão no Widget

```dart
import 'package:flutter/material.dart';
import 'package:lecotour_dashboard/services/quotation_pdf_with_fonts.dart';

class QuotationActions extends StatelessWidget {
  final Quotation quotation;

  const QuotationActions({required this.quotation});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Botão 1: Gerar e ABRIR automaticamente
        ElevatedButton.icon(
          onPressed: () async {
            try {
              // Mostra loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Gera e abre o PDF
              await QuotationPdfWithFonts.generateAndOpenQuotationPdf(quotation);

              // Fecha loading
              Navigator.pop(context);

              // Mostra sucesso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ PDF gerado e aberto com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Erro ao gerar PDF: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Ver PDF'),
        ),

        const SizedBox(width: 8),

        // Botão 2: Gerar e COMPARTILHAR (sem abrir)
        ElevatedButton.icon(
          onPressed: () async {
            try {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Apenas gera (sem abrir)
              final file = await QuotationPdfWithFonts.generateQuotationPdf(quotation);

              Navigator.pop(context);

              // Compartilhar via WhatsApp, Email, etc
              await _shareFile(file);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ PDF gerado!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Erro: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.share),
          label: const Text('Compartilhar'),
        ),
      ],
    );
  }

  Future<void> _shareFile(File file) async {
    // Implementar compartilhamento (WhatsApp, Email, etc)
  }
}
```

---

## 🔧 Comportamento da Biblioteca `open_file`

### Plataformas Suportadas

| Plataforma | Comportamento |
|------------|---------------|
| **Android** | Abre com o visualizador padrão de PDFs |
| **iOS** | Abre com o visualizador nativo |
| **Windows** | Abre com o app padrão (Adobe, Edge, etc) |
| **macOS** | Abre com Preview ou app padrão |
| **Linux** | Abre com o visualizador configurado |
| **Web** | Download do arquivo |

### Códigos de Retorno

```dart
final result = await OpenFile.open(file.path);

switch (result.type) {
  case ResultType.done:
    print('✅ Arquivo aberto com sucesso');
    break;
  
  case ResultType.noAppToOpen:
    print('⚠️ Nenhum app disponível para abrir PDFs');
    // Sugestão: mostrar dialog para usuário instalar leitor de PDF
    break;
  
  case ResultType.fileNotFound:
    print('❌ Arquivo não encontrado');
    break;
  
  case ResultType.permissionDenied:
    print('❌ Permissão negada');
    // Sugestão: solicitar permissões
    break;
  
  case ResultType.error:
    print('❌ Erro: ${result.message}');
    break;
}
```

---

## 📂 Onde os PDFs São Salvos

### Android
```
/storage/emulated/0/Android/data/com.lecotour.dashboard/files/
cotacao_COT-2025-001_1234567890.pdf
```

### iOS
```
/var/mobile/Containers/Data/Application/.../Documents/
cotacao_COT-2025-001_1234567890.pdf
```

### Windows
```
C:\Users\<Username>\Documents\lecotour_dashboard\
cotacao_COT-2025-001_1234567890.pdf
```

### Web
```
Downloads/
cotacao_COT-2025-001_1234567890.pdf
```

---

## 🎨 Exemplo: Menu de Contexto

```dart
PopupMenuButton<String>(
  onSelected: (value) async {
    switch (value) {
      case 'view':
        // Abrir para visualizar
        await QuotationPdfWithFonts.generateAndOpenQuotationPdf(quotation);
        break;
      
      case 'download':
        // Apenas salvar
        final file = await QuotationPdfWithFonts.generateQuotationPdf(quotation);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salvo em: ${file.path}')),
        );
        break;
      
      case 'print':
        // Imprimir
        final file = await QuotationPdfWithFonts.generateQuotationPdf(quotation);
        await Printing.layoutPdf(
          onLayout: (format) => file.readAsBytes(),
        );
        break;
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'view',
      child: Row(
        children: [
          Icon(Icons.visibility),
          SizedBox(width: 8),
          Text('Visualizar'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'download',
      child: Row(
        children: [
          Icon(Icons.download),
          SizedBox(width: 8),
          Text('Baixar'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'print',
      child: Row(
        children: [
          Icon(Icons.print),
          SizedBox(width: 8),
          Text('Imprimir'),
        ],
      ),
    ),
  ],
)
```

---

## ⚠️ Tratamento de Erros

```dart
Future<void> openPdfSafely(Quotation quotation, BuildContext context) async {
  try {
    final result = await QuotationPdfWithFonts.generateAndOpenQuotationPdf(quotation);
    
    // Verificar se abriu com sucesso
    final openResult = await OpenFile.open(result.path);
    
    if (openResult.type == ResultType.noAppToOpen) {
      // Nenhum app para abrir PDFs
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('App não encontrado'),
          content: const Text(
            'Nenhum aplicativo disponível para abrir PDFs. '
            'Instale um leitor de PDF (Adobe Reader, Google PDF Viewer, etc.)'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } on FileSystemException catch (e) {
    // Erro ao salvar arquivo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao salvar PDF: ${e.message}'),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    // Outros erros
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro inesperado: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 📱 Permissões

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<!-- Para salvar arquivos -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Android 11+ -->
<application
  android:requestLegacyExternalStorage="true">
</application>
```

### iOS (ios/Runner/Info.plist)

```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

---

## ✅ Checklist de Implementação

- [x] Adicionar `path_provider` ao pubspec.yaml
- [x] Adicionar `open_file` ao pubspec.yaml
- [x] Criar método `generateAndOpenQuotationPdf()`
- [x] Atualizar widgets para usar novo método
- [ ] Testar em Android
- [ ] Testar em iOS
- [ ] Testar em Windows
- [ ] Adicionar tratamento de erros
- [ ] Adicionar permissões necessárias

---

## 🎯 Resumo

**Antes:**
```dart
// Apenas gerava e salvava
final file = await generateQuotationPdf(quotation);
// Usuário precisa procurar o arquivo manualmente
```

**Depois:**
```dart
// Gera, salva E abre automaticamente! ✨
await generateAndOpenQuotationPdf(quotation);
// PDF já aparece na tela para o usuário!
```

**Resultado:** Melhor experiência do usuário! 🎉


