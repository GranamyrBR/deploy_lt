# TODO: Sistema de Datas Rápidas - Continuação

## ✅ Já Implementado:
1. Modal QuickDatesDialog (lib/widgets/quick_dates_dialog.dart)
2. Chip verde de datas no card do contato
3. Método _abrirDatasRapidas e _salvarCotacaoRapida

## ❌ Falta Implementar:

### 1. Badge Visual de Datas no Card
**Localização**: lib/screens/contacts_screen.dart (linha ~2730)

**Adicionar após os chips**, antes da categoria:
```dart
// Badge de datas de viagem (se existir)
if (c['travel_date'] != null)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(Icons.flight_takeoff, size: 12, color: Colors.blue.shade700),
        SizedBox(width: 4),
        Text(
          'Ida: ${_formatDate(DateTime.parse(c['travel_date']))}',
          style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
        ),
        if (c['return_date'] != null) ...[
          SizedBox(width: 8),
          Icon(Icons.flight_land, size: 12, color: Colors.green.shade700),
          SizedBox(width: 4),
          Text(
            'Volta: ${_formatDate(DateTime.parse(c['return_date']))}',
            style: TextStyle(fontSize: 10, color: Colors.green.shade700),
          ),
        ],
        SizedBox(width: 8),
        _buildDaysUntilBadge(DateTime.parse(c['travel_date'])),
      ],
    ),
  ),
```

**Adicionar método helper**:
```dart
Widget _buildDaysUntilBadge(DateTime travelDate) {
  final daysUntil = travelDate.difference(DateTime.now()).inDays;
  final color = daysUntil <= 7 ? Colors.red : daysUntil <= 30 ? Colors.orange : Colors.green;
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      'em $daysUntil dias',
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.shade700),
    ),
  );
}
```

### 2. Modificar Query para Buscar Cotações
**Localização**: linha 220-225

**ANTES**:
```dart
response = await _client.from('contact').select('''
  *,
  source(name),
  account(name),
  contact_category(name)
''')
```

**DEPOIS**:
```dart
response = await _client.from('contact').select('''
  *,
  source(name),
  account(name),
  contact_category(name),
  quotation!quotation_client_phone_fkey(
    travel_date,
    return_date,
    status
  )
''')
```

### 3. Processar Cotação Mais Recente
**Localização**: Após linha 232

```dart
// Adicionar travel_date e return_date ao contato se houver cotação
for (final c in contactsList) {
  if (c['quotation'] != null && (c['quotation'] as List).isNotEmpty) {
    final quotations = (c['quotation'] as List);
    // Pegar a mais recente com travel_date
    final withDate = quotations.where((q) => q['travel_date'] != null).toList();
    if (withDate.isNotEmpty) {
      withDate.sort((a, b) => DateTime.parse(b['travel_date']).compareTo(DateTime.parse(a['travel_date'])));
      c['travel_date'] = withDate.first['travel_date'];
      c['return_date'] = withDate.first['return_date'];
    }
  }
}
```

### 4. Adicionar Filtros
**Localização**: Adicionar no AppBar ou sidebar

- Filtro por data de ida (DateRangePicker)
- Filtro por data de volta (DateRangePicker)
- Filtro "Viagens próximas" (7, 15, 30 dias)
- Filtro por data de criação da cotação

## Migrations Pendentes:
1. `supabase/migrations/2025-01-13_quotation_optional_fields.sql`
2. Criar índice: `CREATE INDEX idx_quotation_client_phone_travel_date ON quotation(client_phone, travel_date DESC);`

