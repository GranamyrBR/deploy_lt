# Tabelas do Banco de Dados - Sistema Lecotour

Este documento lista todas as **58 tabelas** identificadas no banco de dados do sistema Lecotour, organizadas por categorias funcionais.

## 📊 Gestão de Contas e Contatos (13 tabelas)

- `account` - Contas/empresas clientes
- `account_category` - Categorias de contas
- `account_client_ranking` - Ranking de clientes por conta
- `account_communication_preferences` - Preferências de comunicação
- `account_document` - Documentos das contas
- `account_employee` - Funcionários das contas
- `account_interaction_log` - Log de interações
- `account_opportunity` - Oportunidades de negócio
- `account_performance_metrics` - Métricas de performance
- `account_task` - Tarefas relacionadas às contas
- `contact` - Contatos/clientes
- `contact_category` - Categorias de contatos
- `contact_service` - Serviços dos contatos

## ✈️ Transporte e Logística (14 tabelas)

- `airline` - Companhias aéreas
- `airline_favicons` - Favicons das companhias aéreas
- `airport` - Aeroportos
- `car` - Veículos
- `driver` - Motoristas
- `driver_car` - Associação motorista-veículo
- `driver_commission` - Comissões dos motoristas
- `driver_service` - Serviços dos motoristas
- `flight_cache` - Cache de dados de voos
- `flight_data` - Dados detalhados de voos
- `rotas_operacionais` - Rotas operacionais
- `service_route` - Rotas de serviços
- `provider` - Fornecedores

## 🔧 Operações e Serviços (10 tabelas)

- `operation` - Operações de serviço
- `operation_backup_2025_08_06_14_51_19` - Backup de operações
- `operation_history` - Histórico de operações
- `service` - Serviços disponíveis
- `service_category` - Categorias de serviços
- `service_configuration` - Configurações de serviços
- `service_payment` - Pagamentos de serviços
- `service_price_history` - Histórico de preços de serviços

## 💰 Vendas e Faturamento (12 tabelas)

- `sale` - Vendas
- `sale_cancellation_item` - Itens de vendas canceladas
- `sale_cancellation_log` - Log de cancelamentos
- `sale_cancellation_payment` - Pagamentos de cancelamentos
- `sale_item` - Itens de venda
- `sale_payment` - Pagamentos de vendas
- `invoice` - Faturas
- `provisional_invoice` - Faturas provisórias
- `provisional_invoice_approval` - Aprovações de faturas
- `provisional_invoice_item` - Itens de faturas provisórias
- `provisional_invoice_metric` - Métricas de faturas
- `provisional_invoice_reminder` - Lembretes de faturas

## 🛍️ Produtos e Categorias (2 tabelas)

- `product` - Produtos
- `product_category` - Categorias de produtos

## ⚙️ Sistema e Configurações (13 tabelas)

- `user` - Usuários do sistema
- `role` - Funções/papéis
- `department` - Departamentos
- `position` - Cargos
- `api_configuration` - Configurações de APIs
- `api_integration` - Integrações de APIs
- `api_log` - Log de APIs
- `audit_log` - Log de auditoria
- `currency` - Moedas
- `exchange_rate_history` - Histórico de câmbio
- `payment_method` - Métodos de pagamento
- `source` - Fontes de leads
- `status` - Status do sistema

## 📋 Dados Externos e Backups (6 tabelas)

- `deleted_sales_log` - Log de vendas deletadas
- `leadstintim` - Leads do sistema Tintim
- `monday` - Dados do Monday.com
- `monday_backup` - Backup do Monday.com

---

## 📝 Notas para Desenvolvimento

### Potenciais Submenus no Sidebar:

1. **CRM & Contas**
   - Gestão de Contas
   - Contatos
   - Oportunidades
   - Interações

2. **Operações**
   - Operações Ativas
   - Histórico
   - Configurações

3. **Transporte**
   - Motoristas
   - Veículos
   - Voos
   - Rotas

4. **Vendas & Financeiro**
   - Vendas
   - Faturas
   - Pagamentos
   - Relatórios

5. **Catálogo**
   - Serviços
   - Produtos
   - Categorias

6. **Administração**
   - Usuários
   - Configurações
   - APIs
   - Auditoria

### Observações Técnicas:
- Total de 58 tabelas identificadas
- Estrutura bem organizada com relacionamentos claros
- Sistema de auditoria implementado
- Suporte a múltiplas moedas
- Integração com APIs externas
- Backup e versionamento de dados

---

*Documento gerado automaticamente em: " + DateTime.now().toString() + "*
# Tabelas do Banco de Dados - Sistema Lecotour
