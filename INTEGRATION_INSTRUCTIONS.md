# 🔧 Instruções de Integração dos Filtros Avançados

## ✅ O que JÁ FOI FEITO:

1. ✅ Variáveis de estado adicionadas (linhas 45-53)
2. ✅ Função `_aplicarFiltrosAvancados()` criada (linhas 55-108)
3. ✅ Função `_limparFiltrosAvancados()` criada (linhas 110-122)
4. ✅ Widget `ContactsAdvancedFilters` criado (lib/widgets/contacts_advanced_filters.dart)
5. ✅ Import adicionado (linha 21)

## 🔨 O que FALTA FAZER:

### 1. Adicionar o widget de filtros na UI

Procure pela linha ~2430 onde está o `@override Widget build` ou onde tem o `return Scaffold`.

Logo **APÓS** a barra de pesquisa/botões de visualização, adicione:

```dart
// Filtros Avançados
ContactsAdvancedFilters(
  filtroDataIda: _filtroDataIda,
  filtroDataIdaInicio: _filtroDataIdaInicio,
  filtroDataIdaFim: _filtroDataIdaFim,
  filtroOrigem: _filtroOrigem,
  filtroCategoria: _filtroCategoria,
  filtroAgencia: _filtroAgencia,
  filtroPossuiCotacao: _filtroPossuiCotacao,
  filtroPossuiVenda: _filtroPossuiVenda,
  onDataIdaChanged: (valor) {
    setState(() => _filtroDataIda = valor);
  },
  onDataRangeChanged: (inicio, fim) {
    setState(() {
      _filtroDataIdaInicio = inicio;
      _filtroDataIdaFim = fim;
    });
  },
  onOrigemChanged: (valor) {
    setState(() => _filtroOrigem = valor);
  },
  onCategoriaChanged: (valor) {
    setState(() => _filtroCategoria = valor);
  },
  onAgenciaChanged: (valor) {
    setState(() => _filtroAgencia = valor);
  },
  onPossuiCotacaoChanged: (valor) {
    setState(() => _filtroPossuiCotacao = valor);
  },
  onPossuiVendaChanged: (valor) {
    setState(() => _filtroPossuiVenda = valor);
  },
  onClearFilters: _limparFiltrosAvancados,
),

const SizedBox(height: 16),
```

### 2. Aplicar filtros na lista de contatos

Procure pela linha ~2360 ou onde tem:
```dart
final contacts = allContacts.where((c) =>
```

Adicione o filtro avançado **APÓS** o filtro de search:
```dart
final contacts = allContacts.where((c) {
  // Filtro de busca existente
  final searchMatches = _searchTerm.isEmpty || 
      c['name'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
      c['phone'].toString().contains(_searchTerm) ||
      (c['email']?.toString() ?? '').toLowerCase().contains(_searchTerm.toLowerCase());
  
  // Aplicar filtros avançados
  final advancedFilterMatches = _aplicarFiltrosAvancados(c);
  
  return searchMatches && advancedFilterMatches;
}).toList();
```

## 🎯 Resultado Esperado:

- Filtros avançados aparecem abaixo da barra de busca
- Usuário pode filtrar por data de ida (7, 15, 30 dias ou range)
- Usuário pode filtrar por status (com/sem cotação, com/sem venda)
- Botão "Limpar" remove todos os filtros

## 📝 Nota:

Como o arquivo é muito grande (4398 linhas), não consegui fazer o find_and_replace direto.
Você pode fazer manualmente ou me passar as linhas exatas onde adicionar.
