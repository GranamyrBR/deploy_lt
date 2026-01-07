# 🤝 Guia de Contribuição - Lecotour Dashboard

Obrigado por considerar contribuir com o Lecotour Dashboard! Este documento fornece diretrizes para contribuições ao projeto.

## 📋 Sumário

- [Código de Conduta](#código-de-conduta)
- [Como Posso Contribuir?](#como-posso-contribuir)
- [Processo de Desenvolvimento](#processo-de-desenvolvimento)
- [Padrões de Código](#padrões-de-código)
- [Commits e Pull Requests](#commits-e-pull-requests)
- [Testes](#testes)

## 📜 Código de Conduta

- Seja respeitoso e profissional
- Aceite críticas construtivas
- Foque no que é melhor para o projeto
- Mostre empatia com outros membros da comunidade

## 🚀 Como Posso Contribuir?

### Reportando Bugs

Antes de criar um issue:
1. Verifique se o bug já não foi reportado
2. Colete informações sobre o ambiente (SO, navegador, versão do Flutter)
3. Descreva os passos para reproduzir o problema

Template para issues:
```markdown
**Descrição do Bug**
Descrição clara e concisa do problema.

**Passos para Reproduzir**
1. Vá para '...'
2. Clique em '...'
3. Role até '...'
4. Veja o erro

**Comportamento Esperado**
O que deveria acontecer.

**Screenshots**
Se aplicável, adicione screenshots.

**Ambiente:**
 - OS: [ex: Windows 10]
 - Browser: [ex: Chrome 120]
 - Flutter: [ex: 3.16.0]
```

### Sugerindo Melhorias

Melhorias são bem-vindas! Ao sugerir:
- Explique claramente o problema que resolve
- Descreva a solução proposta
- Liste alternativas consideradas
- Adicione mockups se aplicável

### Pull Requests

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/MinhaFeature`)
3. Faça suas alterações
4. Commit suas mudanças seguindo nossos padrões
5. Push para a branch (`git push origin feature/MinhaFeature`)
6. Abra um Pull Request

## 🔧 Processo de Desenvolvimento

### Setup do Ambiente

```bash
# Clone seu fork
git clone https://github.com/seu-usuario/lecotour_dashboard.git
cd lecotour_dashboard

# Adicione o repositório original como upstream
git remote add upstream https://github.com/lecotour/lecotour_dashboard.git

# Instale dependências
flutter pub get
cd functions && npm install && cd ..

# Configure .env
cp .env.example .env
# Edite .env com suas credenciais
```

### Workflow de Desenvolvimento

1. **Sincronize com upstream**
```bash
git checkout main
git pull upstream main
```

2. **Crie uma branch**
```bash
git checkout -b feature/nome-da-feature
# ou
git checkout -b fix/nome-do-bug
```

3. **Desenvolva e teste**
```bash
# Durante desenvolvimento
flutter run -d chrome

# Execute testes
flutter test

# Verifique análise estática
flutter analyze
```

4. **Commit e Push**
```bash
git add .
git commit -m "feat: adiciona nova funcionalidade"
git push origin feature/nome-da-feature
```

## 📝 Padrões de Código

### Dart/Flutter

- Siga o [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` antes de commitar
- Máximo de 80-100 caracteres por linha
- Use trailing commas para melhor formatação

### Estrutura de Arquivos

```dart
// lib/screens/exemplo_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports relativos por último
import '../models/exemplo_model.dart';
import '../providers/exemplo_provider.dart';

class ExemploScreen extends ConsumerWidget {
  const ExemploScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Implementação
  }
}
```

### Nomenclatura

- **Classes**: `PascalCase` (ex: `CustomerProfileScreen`)
- **Variáveis/Funções**: `camelCase` (ex: `getUserData`)
- **Constantes**: `lowerCamelCase` (ex: `defaultTimeout`)
- **Arquivos**: `snake_case` (ex: `customer_profile_screen.dart`)
- **Providers**: termine com `Provider` (ex: `authProvider`)

### Comentários

```dart
/// Documentação pública (3 barras)
/// Usado para classes, métodos e propriedades públicas
class MinhaClasse {
  /// Obtém os dados do usuário
  /// 
  /// Retorna `null` se o usuário não for encontrado.
  Future<User?> getUserData(String id) async {
    // Comentário de implementação (2 barras)
    final response = await supabase.from('users').select();
    return User.fromJson(response);
  }
}
```

### Estado e Providers

Use Riverpod para gerenciamento de estado:

```dart
// Provider simples
final counterProvider = StateProvider<int>((ref) => 0);

// Provider assíncrono
final userProvider = FutureProvider.autoDispose<User>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});

// StateNotifier para lógica complexa
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
```

## 💬 Commits e Pull Requests

### Mensagens de Commit

Seguimos o padrão [Conventional Commits](https://www.conventionalcommits.org/):

```
<tipo>(<escopo>): <descrição curta>

[corpo opcional]

[rodapé opcional]
```

**Tipos:**
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Documentação
- `style`: Formatação, ponto e vírgula, etc
- `refactor`: Refatoração de código
- `test`: Adição ou correção de testes
- `chore`: Manutenção, dependências, etc

**Exemplos:**
```bash
feat(auth): adiciona login com Google

fix(sales): corrige cálculo de comissão para vendas múltiplas

docs(readme): atualiza instruções de instalação

refactor(dashboard): extrai widget de métrica para componente reutilizável

test(quotations): adiciona testes para geração de PDF
```

### Pull Request

Template:
```markdown
## Descrição
Descrição clara das mudanças

## Tipo de Mudança
- [ ] Bug fix
- [ ] Nova feature
- [ ] Breaking change
- [ ] Documentação

## Checklist
- [ ] Código segue os padrões do projeto
- [ ] Comentários adicionados em código complexo
- [ ] Documentação atualizada
- [ ] Testes adicionados/atualizados
- [ ] Testes passando (`flutter test`)
- [ ] Análise estática passando (`flutter analyze`)
- [ ] Build web funciona (`flutter build web`)

## Screenshots (se aplicável)
Adicione screenshots das mudanças visuais

## Issues Relacionadas
Closes #123
Related to #456
```

## 🧪 Testes

### Executando Testes

```bash
# Todos os testes
flutter test

# Teste específico
flutter test test/services/auth_service_test.dart

# Com cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Escrevendo Testes

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      authService = AuthService(mockSupabase);
    });

    test('login deve retornar usuário quando credenciais válidas', () async {
      // Arrange
      when(() => mockSupabase.auth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => MockAuthResponse());

      // Act
      final result = await authService.login('test@example.com', 'password');

      // Assert
      expect(result, isNotNull);
    });
  });
}
```

### Cobertura de Testes

Mantemos pelo menos 70% de cobertura:
- Serviços: 80%+
- Providers: 70%+
- Widgets complexos: 60%+

## 📚 Recursos Adicionais

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Supabase Documentation](https://supabase.io/docs)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## ❓ Dúvidas?

- Abra uma issue com a label `question`
- Entre em contato com a equipe
- Consulte a documentação em `docs/`

---

Obrigado por contribuir! 🎉
