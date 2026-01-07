# Sistema de Auditoria Completo - Lecotour Sales V2.0

## Visão Geral

O sistema de auditoria foi projetado para garantir que **todas as operações críticas sejam registradas**, especialmente exclusões de vendas, mantendo um histórico completo de quem fez o quê e quando.

## 🔒 Características Principais

### 1. **Auditoria Automática**
- Triggers automáticos em todas as tabelas principais
- Registro de INSERT, UPDATE, DELETE e SOFT_DELETE
- Captura de valores antes/depois das alterações
- Identificação automática de campos alterados

### 2. **Exclusão Segura (Soft Delete)**
- Função `soft_delete_sale()` para exclusões controladas
- Backup completo dos dados antes da exclusão
- Motivo obrigatório para exclusão
- Sistema de aprovação para vendas de alto valor

### 3. **Rastreabilidade Completa**
- Registro de usuário, IP, sessão
- Timestamp preciso de todas as operações
- Histórico de alterações em formato JSON
- Classificação de risco das operações

## 📋 Tabelas do Sistema de Auditoria

### `audit_log`
Registro geral de todas as operações:
```sql
- id: Identificador único
- table_name: Nome da tabela afetada
- record_id: ID do registro afetado
- operation_type: INSERT/UPDATE/DELETE/SOFT_DELETE
- user_id, user_name, user_email: Dados do usuário
- session_id, ip_address: Dados da sessão
- old_values, new_values: Valores antes/depois (JSON)
- changed_fields: Array de campos alterados
- reason: Motivo da operação
```

### `deleted_sales_log`
Registro específico de vendas excluídas:
```sql
- original_sale_id: ID da venda original
- sale_data: Backup completo da venda (JSON)
- sale_items_data: Backup dos itens (JSON)
- operations_data: Backup das operações (JSON)
- payments_data: Backup dos pagamentos (JSON)
- deletion_reason: Motivo obrigatório
- requires_approval: Se precisa aprovação
- approved_by_user_id: Quem aprovou
```

### `critical_operations_log`
Log de operações que requerem supervisão:
```sql
- operation_type: Tipo da operação crítica
- entity_type, entity_id: Entidade afetada
- business_justification: Justificativa de negócio
- requires_supervisor_approval: Se precisa aprovação
```

## 🚀 Como Implementar na Aplicação Flutter

### 1. **Configuração do Contexto do Usuário**

Antes de qualquer operação no banco, configure o usuário atual:

```dart
// No seu service de database
class DatabaseService {
  Future<void> setCurrentUser(String userId) async {
    await supabase.rpc('set_config', params: {
      'setting_name': 'app.current_user_id',
      'new_value': userId,
      'is_local': true
    });
  }
}
```

### 2. **Exclusão Segura de Vendas**

```dart
class SalesService {
  Future<bool> deleteSale({
    required int saleId,
    required String userId,
    required String reason,
    String? sessionId,
    String? ipAddress,
  }) async {
    try {
      final result = await supabase.rpc('soft_delete_sale', params: {
        'p_sale_id': saleId,
        'p_user_id': userId,
        'p_deletion_reason': reason,
        'p_session_id': sessionId,
        'p_ip_address': ipAddress,
      });
      
      return result as bool;
    } catch (e) {
      print('Erro ao excluir venda: $e');
      return false;
    }
  }
}
```

### 3. **Widget para Confirmação de Exclusão**

```dart
class DeleteSaleDialog extends StatefulWidget {
  final Sale sale;
  final Function(String reason) onConfirm;
  
  @override
  _DeleteSaleDialogState createState() => _DeleteSaleDialogState();
}

class _DeleteSaleDialogState extends State<DeleteSaleDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirmar Exclusão'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tem certeza que deseja excluir a venda ${widget.sale.saleNumber}?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Valor: USD ${widget.sale.totalAmountUsd}'),
            Text('Cliente: ${widget.sale.customerName}'),
            SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Motivo da exclusão *',
                hintText: 'Ex: Cliente cancelou o serviço',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Motivo é obrigatório';
                }
                if (value.trim().length < 10) {
                  return 'Motivo deve ter pelo menos 10 caracteres';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(_reasonController.text.trim());
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Confirmar Exclusão'),
        ),
      ],
    );
  }
}
```

### 4. **Tela de Auditoria**

```dart
class AuditLogScreen extends StatefulWidget {
  @override
  _AuditLogScreenState createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditEntry> auditEntries = [];
  String? selectedUser;
  String? selectedOperation;
  
  @override
  void initState() {
    super.initState();
    _loadAuditLog();
  }
  
  Future<void> _loadAuditLog() async {
    final response = await supabase
        .from('audit_summary')
        .select()
        .order('operation_timestamp', ascending: false)
        .limit(100);
    
    setState(() {
      auditEntries = response.map((e) => AuditEntry.fromJson(e)).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log de Auditoria'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: auditEntries.length,
        itemBuilder: (context, index) {
          final entry = auditEntries[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: _getOperationIcon(entry.operationType),
              title: Text('${entry.tableName} #${entry.recordId}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.userName} - ${entry.operationType}'),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(entry.timestamp),
                    style: TextStyle(fontSize: 12),
                  ),
                  if (entry.reason != null)
                    Text(
                      'Motivo: ${entry.reason}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                ],
              ),
              trailing: Chip(
                label: Text(entry.riskLevel),
                backgroundColor: _getRiskColor(entry.riskLevel),
              ),
              onTap: () => _showAuditDetails(entry),
            ),
          );
        },
      ),
    );
  }
  
  Widget _getOperationIcon(String operationType) {
    switch (operationType) {
      case 'INSERT':
        return Icon(Icons.add, color: Colors.green);
      case 'UPDATE':
        return Icon(Icons.edit, color: Colors.blue);
      case 'DELETE':
      case 'SOFT_DELETE':
        return Icon(Icons.delete, color: Colors.red);
      default:
        return Icon(Icons.info);
    }
  }
  
  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'HIGH':
        return Colors.red.shade100;
      case 'MEDIUM':
        return Colors.orange.shade100;
      default:
        return Colors.green.shade100;
    }
  }
}
```

## 📊 Relatórios e Consultas Úteis

### 1. **Vendas Excluídas**
```dart
Future<List<DeletedSale>> getDeletedSales() async {
  final response = await supabase
      .from('deleted_sales_summary')
      .select()
      .order('deleted_at', ascending: false);
  
  return response.map((e) => DeletedSale.fromJson(e)).toList();
}
```

### 2. **Atividade por Usuário**
```dart
Future<List<UserActivity>> getUserActivity(DateTime startDate, DateTime endDate) async {
  final response = await supabase.rpc('get_user_activity', params: {
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
  });
  
  return response.map((e) => UserActivity.fromJson(e)).toList();
}
```

### 3. **Alertas de Segurança**
```dart
Future<List<SecurityAlert>> getSecurityAlerts() async {
  final response = await supabase
      .from('security_alerts')
      .select()
      .order('severity', ascending: false);
  
  return response.map((e) => SecurityAlert.fromJson(e)).toList();
}
```

## 🔧 Configuração e Manutenção

### 1. **Permissões de Usuário**

Configure RLS (Row Level Security) para controlar acesso:

```sql
-- Apenas administradores podem ver logs de auditoria
CREATE POLICY "audit_log_admin_only" ON audit_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM "user" u 
      JOIN user_role ur ON u.id = ur.user_id
      JOIN role r ON ur.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );
```

### 2. **Limpeza Automática**

Configure um job para limpeza periódica:

```sql
-- Executar mensalmente
SELECT cron.schedule('cleanup-audit-logs', '0 2 1 * *', 'SELECT cleanup_old_audit_logs();');
```

### 3. **Monitoramento**

Crie alertas para operações suspeitas:

```dart
class AuditMonitoringService {
  Future<void> checkForSuspiciousActivity() async {
    final alerts = await getSecurityAlerts();
    
    for (final alert in alerts) {
      if (alert.severity == 'CRITICAL') {
        await _sendNotificationToAdmins(alert);
      }
    }
  }
}
```

## ✅ Checklist de Implementação

- [ ] Executar limpeza de dados (`clean_sales_now.sql`)
- [ ] Executar migração principal (`migration_sale_upgrade.sql`)
- [ ] Instalar funções Flutter (`flutter_functions_compatible.sql`)
- [ ] Validar implementação (`validation_tests.sql`)
- [ ] Configurar permissões RLS
- [ ] Implementar `setCurrentUser()` na aplicação
- [ ] Substituir exclusões diretas por `delete_sale_with_validation()`
- [ ] Criar telas de auditoria
- [ ] Configurar alertas de segurança
- [ ] Testar sistema completo
- [ ] Treinar usuários sobre novo processo

## 🚨 Pontos Importantes

1. **Motivo Obrigatório**: Toda exclusão deve ter um motivo claro
2. **Aprovação**: Vendas de alto valor precisam de aprovação
3. **Backup Completo**: Todos os dados são salvos antes da exclusão
4. **Rastreabilidade**: Impossível excluir sem deixar rastro
5. **Recuperação**: Dados podem ser restaurados se necessário

Este sistema garante que **nenhuma exclusão passe despercebida** e que sempre seja possível identificar **quem fez o quê e por quê**.
# Sistema de Auditoria Completo - Lecotour Sales V2.0
