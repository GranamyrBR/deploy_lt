# CRUD de Serviços - Exemplo de Uso

Este documento demonstra como usar o sistema CRUD completo para gerenciamento de serviços.

## Estrutura do Sistema

### 1. Provider de Serviços (`services_provider.dart`)

O provider gerencia todo o estado dos serviços e oferece métodos para:
- **Create**: Criar novos serviços
- **Read**: Listar, buscar e filtrar serviços
- **Update**: Atualizar serviços existentes
- **Delete**: Remover serviços

### 2. Serviço de Backend (`services_service.dart`)

Contém a lógica de comunicação com o Supabase para todas as operações CRUD.

### 3. Tela de Gerenciamento (`services_management_screen.dart`)

Interface completa para gerenciar serviços com:
- Lista de serviços em tempo real
- Busca por nome
- Formulário de criação/edição com validação
- Ações de ativar/desativar e excluir

## Como Usar o Provider

### Exemplo 1: Listar Serviços
```dart
Consumer(
  builder: (context, ref, child) {
    final servicesState = ref.watch(servicesProvider);
    
    if (servicesState.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (servicesState.error != null) {
      return Text('Erro: ${servicesState.error}');
    }
    
    return ListView.builder(
      itemCount: servicesState.services.length,
      itemBuilder: (context, index) {
        final service = servicesState.services[index];
        return ListTile(
          title: Text(service.name),
          subtitle: Text(service.description),
          trailing: Text('R\$ ${service.price.toStringAsFixed(2)}'),
        );
      },
    );
  },
)
```

### Exemplo 2: Criar Serviço
```dart
Future<void> createNewService() async {
  final success = await ref.read(servicesProvider.notifier).createService(
    name: 'Transfer Aeroporto',
    description: 'Serviço de transfer do/para aeroporto',
    price: 50.0,
    servicetypeId: 1,
    isActive: true,
  );
  
  if (success) {
    // Serviço criado com sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Serviço criado com sucesso!')),
    );
  } else {
    // Erro ao criar serviço
    final error = ref.read(servicesProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: $error')),
    );
  }
}
```

### Exemplo 3: Atualizar Serviço
```dart
Future<void> updateService(int serviceId) async {
  final success = await ref.read(servicesProvider.notifier).updateService(
    id: serviceId,
    name: 'Novo Nome',
    price: 75.0,
    isActive: false,
  );
  
  if (success) {
    // Serviço atualizado
  }
}
```

### Exemplo 4: Deletar Serviço
```dart
Future<void> deleteService(int serviceId) async {
  final success = await ref.read(servicesProvider.notifier).deleteService(serviceId);
  
  if (success) {
    // Serviço deletado
  }
}
```

### Exemplo 5: Buscar Serviços
```dart
Future<void> searchServices(String query) async {
  await ref.read(servicesProvider.notifier).searchServices(query);
  // Os resultados serão automaticamente refletidos no estado
}
```

### Exemplo 6: Filtrar por Categoria
```dart
Future<void> filterByCategory(String category) async {
  await ref.read(servicesProvider.notifier).filterByCategory(category);
}
```

## Providers Auxiliares

### Buscar Serviço por ID
```dart
Consumer(
  builder: (context, ref, child) {
    final serviceAsync = ref.watch(serviceByIdProvider(123));
    
    return serviceAsync.when(
      data: (service) => service != null 
        ? Text(service.name)
        : Text('Serviço não encontrado'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Erro: $error'),
    );
  },
)
```

### Estatísticas de Serviços
```dart
Consumer(
  builder: (context, ref, child) {
    final statsAsync = ref.watch(serviceStatsProvider);
    
    return statsAsync.when(
      data: (stats) => Column(
        children: [
          Text('Total: ${stats['total']}'),
          Text('Ativos: ${stats['active']}'),
        ],
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Erro: $error'),
    );
  },
)
```

### Apenas Serviços Ativos
```dart
Consumer(
  builder: (context, ref, child) {
    final activeServices = ref.watch(activeServicesProvider);
    
    return ListView.builder(
      itemCount: activeServices.length,
      itemBuilder: (context, index) {
        final service = activeServices[index];
        return ListTile(title: Text(service.name));
      },
    );
  },
)
```

## Tratamento de Erros

O sistema possui tratamento de erros integrado:

1. **Erros de Validação**: Validados no formulário antes do envio
2. **Erros de Rede**: Capturados e exibidos no estado
3. **Erros do Supabase**: Tratados e formatados para o usuário

## Funcionalidades Implementadas

✅ **Create**: Criar novos serviços com validação
✅ **Read**: Listar todos os serviços
✅ **Update**: Atualizar serviços existentes
✅ **Delete**: Remover serviços com confirmação
✅ **Search**: Buscar serviços por nome
✅ **Filter**: Filtrar por categoria
✅ **Status**: Ativar/desativar serviços
✅ **Validation**: Validação de formulários
✅ **Error Handling**: Tratamento de erros
✅ **Loading States**: Estados de carregamento
✅ **Real-time Updates**: Atualizações em tempo real

## Próximos Passos

1. Implementar paginação para listas grandes
2. Adicionar filtros avançados
3. Implementar cache local
4. Adicionar sincronização offline
5. Implementar auditoria de mudanças
# CRUD de Serviços - Exemplo de Uso
