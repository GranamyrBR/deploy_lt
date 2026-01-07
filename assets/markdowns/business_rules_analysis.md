# Análise das Regras de Negócio - App vs Banco de Dados

## Resumo Executivo

Esta análise documenta as regras de negócio identificadas entre a aplicação Flutter/Dart e o banco de dados PostgreSQL, com foco especial no sistema de vendas e operações.

## Estrutura do Sistema de Vendas

### Fluxo Principal de Vendas

1. **Criação de Venda** (`sale`)
   - Cliente obrigatório (`customer_id` → `contact.id`)
   - Usuário vendedor obrigatório (`user_id` → `user.id`)
   - Moeda obrigatória (`currency_id` → `currency.currency_id`)
   - Status inicial: 'pending'
   - Conversão automática de moedas (BRL ↔ USD)

2. **Adição de Itens** (`sale_item`)
   - Vinculação à venda (`sales_id` → `sale.id`) **[FK AUSENTE]**
   - Serviço ou produto obrigatório
   - Cálculo automático de totais com impostos e descontos
   - Conversão de moedas por item

3. **Processamento de Pagamentos** (`sale_payment`)
   - Vinculação à venda (`sales_id` → `sale.id`) **[FK AUSENTE]**
   - Método de pagamento obrigatório
   - Conversão automática de moedas
   - Suporte a pagamentos antecipados

4. **Criação de Operações** (`operation`)
   - Gerada após pagamento confirmado
   - Vinculação a venda e item específico
   - Atribuição de motorista e veículo
   - Integração com APIs externas (WhatsApp, Google Calendar)

### Regras de Negócio Críticas

#### 1. Controle de Moedas
```dart
// Conversão automática BRL ↔ USD
if (currencyCode == 'BRL' && exchangeRateToUsd != null) {
  totalAmountUsd = totalAmount / exchangeRateToUsd;
  totalAmountBrl = totalAmount;
} else if (currencyCode == 'USD') {
  totalAmountBrl = totalAmount * exchangeRateToUsd;
  totalAmountUsd = totalAmount;
}
```

#### 2. Status de Pagamento
- **'Pendente'**: Sem pagamentos registrados
- **'Parcial'**: Pagamentos < valor total
- **'Pago'**: Pagamentos >= valor total
- **Regra**: Operações só podem ser criadas com pagamento registrado

#### 3. Cálculo de Totais
```dart
// Por item
subtotal = unitPrice * quantity;
discountAmount = subtotal * (discountPercentage / 100);
surchargeAmount = subtotal * (surchargePercentage / 100);
taxAmount = (subtotal - discountAmount + surchargeAmount) * (taxPercentage / 100);
itemTotal = subtotal - discountAmount + surchargeAmount + taxAmount;
```

#### 4. Comissões de Motoristas
- Calculadas por operação
- Base: percentual ou valor fixo
- Bônus e penalidades aplicáveis
- Status: pending → approved → paid

## Problemas Identificados

### 1. Integridade Referencial

#### Críticos (Quebram o Sistema)
- `sale_item.sales_id` sem FK para `sale.id`
- `sale_payment.sales_id` sem FK para `sale.id`
- `invoice.sale_id` sem FK para `sale.id`

#### Moderados (Causam Inconsistências)
- `sale.customer_id` nullable (deveria ser NOT NULL)
- `sale.user_id` nullable (deveria ser NOT NULL)
- `sale.currency_id` nullable (deveria ser NOT NULL)
- `sale_item.service_id` nullable (deveria ser NOT NULL)

### 2. Inconsistências de Nomenclatura
- `sales_id` vs `sale_id` (inconsistente)
- Algumas tabelas usam `id`, outras `*_id`

### 3. Campos de Auditoria
- Nem todas as tabelas têm `created_at`/`updated_at`
- Falta rastreamento de quem fez alterações

## Regras de Validação da Aplicação

### 1. Validações de Venda
```dart
// Verificação antes de criar operação
if (sale.totalPaidUsd == 0) {
  throw 'É necessário ter um pagamento registrado para criar uma operação';
}

// Validação de valores positivos
if (totalAmount <= 0) {
  throw 'Valor total deve ser positivo';
}
```

### 2. Validações de Pagamento
```dart
// Verificação de valor do pagamento
if (paymentAmount <= 0) {
  throw 'Valor do pagamento deve ser positivo';
}

// Verificação de moeda
if (currencyId == null) {
  throw 'Moeda é obrigatória';
}
```

### 3. Validações de Operação
```dart
// Verificação de motorista e veículo
if (requiresDriverAssignment && driverId == null) {
  throw 'Motorista é obrigatório para este serviço';
}

if (requiresCarAssignment && carId == null) {
  throw 'Veículo é obrigatório para este serviço';
}
```

## Integrações Externas

### 1. APIs de Voo (FlightAware)
- Cache de dados de voo (`flight_cache`)
- Atualização automática de status
- Integração com operações de transfer

### 2. WhatsApp Business API
- Envio automático de confirmações
- Notificações de status
- Log de mensagens enviadas

### 3. Google Calendar
- Criação automática de eventos
- Sincronização com operações
- Notificações de lembretes

## Configurações de Serviço

### Tabela `service_configuration`
```sql
-- Controla comportamento por tipo de serviço
requires_flight_data BOOLEAN DEFAULT false,
requires_driver_assignment BOOLEAN DEFAULT true,
requires_car_assignment BOOLEAN DEFAULT true,
auto_create_google_calendar_event BOOLEAN DEFAULT false,
auto_send_whatsapp_message BOOLEAN DEFAULT false,
default_driver_commission_percentage NUMERIC DEFAULT 0
```

## Recomendações de Melhoria

### 1. Imediatas (Críticas)
1. Adicionar FKs ausentes em `sale_item` e `sale_payment`
2. Tornar campos obrigatórios NOT NULL
3. Padronizar nomenclatura de colunas
4. Implementar constraints de validação no banco

### 2. Médio Prazo
1. Implementar auditoria completa (created_by, updated_by)
2. Criar views para relatórios complexos
3. Implementar soft delete para dados críticos
4. Adicionar índices para performance

### 3. Longo Prazo
1. Implementar versionamento de dados
2. Criar sistema de aprovação para alterações
3. Implementar cache distribuído
4. Adicionar monitoramento de performance

## Impacto das Correções

### Benefícios
- Garantia de integridade dos dados
- Prevenção de dados órfãos
- Melhoria na performance
- Facilita debugging e manutenção
- Relatórios mais confiáveis

### Riscos
- Possível quebra de código existente
- Necessidade de migração de dados
- Tempo de inatividade durante deploy
- Requer testes extensivos

## Conclusão

O sistema possui uma arquitetura sólida com regras de negócio bem definidas na aplicação, mas sofre de problemas de integridade referencial no banco de dados. As correções propostas são essenciais para garantir a confiabilidade dos dados antes do deploy em produção.

**Prioridade**: Executar script de limpeza → Aplicar correções de schema → Testar extensivamente → Deploy gradual
# Análise das Regras de Negócio - App vs Banco de Dados
