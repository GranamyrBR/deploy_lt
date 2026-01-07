# Sistema de Timeline para Operações

Este sistema implementa uma funcionalidade completa de timeline (linha do tempo) para rastrear o histórico de cada operação no sistema.

## Componentes Implementados

### 1. Modelo de Dados
- **OperationHistory** (`lib/models/operation_history.dart`): Modelo que representa um evento no histórico
- **OperationHistoryProvider** (`lib/providers/operation_history_provider.dart`): Provider para gerenciar o estado do histórico

### 2. Widgets de Interface
- **OperationTimelineWidget** (`lib/widgets/operation_timeline_widget.dart`): Widget completo de timeline
- **OperationTimelineCompact** (`lib/widgets/operation_timeline_compact.dart`): Versão compacta para dashboards

### 3. Integração Automática
- **OperationsProvider**: Atualizado para registrar automaticamente eventos no histórico

## Como Usar

### Timeline Completa
```dart
OperationTimelineWidget(
  operationId: operation.id,
  showHeader: true, // Opcional, padrão: true
  maxHeight: 400,   // Opcional, altura máxima
)
```

### Timeline Compacta
```dart
OperationTimelineCompact(
  operationId: operation.id,
  maxItems: 3,                    // Máximo de itens a exibir
  showViewAllButton: true,        // Mostrar botão "Ver Todas"
  onViewAll: () => {             // Callback para ver todas
    // Navegar para timeline completa
  },
)
```

## Eventos Rastreados Automaticamente

### Operações
- ✅ **Criação**: Quando uma operação é criada
- ✅ **Mudança de Status**: Quando o status é alterado
- ✅ **Designação de Motorista**: Quando um motorista é atribuído
- ✅ **Início**: Quando a operação é iniciada
- ✅ **Conclusão**: Quando a operação é finalizada
- ✅ **Cancelamento**: Quando a operação é cancelada

### Eventos Adicionais (Métodos Disponíveis)
- **Agendamento**: `recordScheduleChange()`
- **Localização**: `recordLocationChange()`
- **Notas**: `recordNoteAdded()`
- **Informações de Voo**: `recordFlightInfoUpdate()`

## Personalização

### Cores e Ícones
Cada tipo de evento tem sua própria cor e ícone definidos no método `_getActionInfo()`:

```dart
case 'created':
  return ActionInfo(
    title: 'Operação Criada',
    icon: Icons.add_circle,
    color: Colors.blue,
  );
```

### Descrições
As descrições dos eventos são geradas dinamicamente no método `_getActionDescription()`.

## Estrutura do Banco de Dados

A tabela `operation_history` deve ter as seguintes colunas:
- `id`: Identificador único
- `operation_id`: ID da operação
- `action_type`: Tipo da ação (created, status_changed, etc.)
- `old_value`: Valor anterior (opcional)
- `new_value`: Novo valor (opcional)
- `action_data`: Dados adicionais em JSON (opcional)
- `performed_by_user_id`: ID do usuário que executou a ação
- `performed_by_user_name`: Nome do usuário
- `performed_at`: Data/hora da ação

## Exemplo de Integração

### No Modal de Detalhes da Operação
```dart
// Já integrado em operation_details_modal.dart
Widget _buildTimelineTab() {
  return OperationTimelineWidget(
    operationId: widget.operation.id,
    showHeader: false,
  );
}
```

### Em Cards de Dashboard
```dart
OperationTimelineCompact(
  operationId: operation.id,
  maxItems: 3,
  onViewAll: () {
    // Abrir modal com timeline completa
    OperationDetailsModal.show(context, operation);
  },
)
```

## Estados de Carregamento

Os widgets tratam automaticamente:
- **Loading**: Exibe indicador de carregamento
- **Erro**: Exibe mensagem de erro com botão para tentar novamente
- **Vazio**: Exibe mensagem quando não há histórico
- **Sucesso**: Exibe a timeline com os eventos

## Performance

- Os dados são carregados sob demanda
- Cache automático por operação
- Atualizações em tempo real quando novos eventos são adicionados
- Paginação automática para operações com muito histórico

## Próximos Passos

1. **Filtros**: Adicionar filtros por tipo de evento
2. **Exportação**: Permitir exportar timeline como PDF
3. **Notificações**: Notificar usuários sobre eventos importantes
4. **Métricas**: Análise de tempo entre eventos
5. **Anexos**: Permitir anexar arquivos aos eventos
# Sistema de Timeline para Operações
