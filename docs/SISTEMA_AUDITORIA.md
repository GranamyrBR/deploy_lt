## 🔍 **SISTEMA COMPLETO DE AUDITORIA E RASTREAMENTO**

### 📋 **ÍNDICE**
1. [Visão Geral](#visão-geral)
2. [Logs de Atividades](#logs-de-atividades)
3. [Sistema de Follow-ups](#sistema-de-follow-ups)
4. [Rastreamento de Usuários](#rastreamento-de-usuários)
5. [Comissões de Vendedores](#comissões-de-vendedores)
6. [Como Usar](#como-usar)

---

## 🎯 **VISÃO GERAL**

Este sistema resolve **3 problemas críticos**:

### **1. "Quem fez o quê?"** 
✅ Registro completo de todas as ações

### **2. "Quem é responsável?"** 
✅ Atribuição clara de cotações e follow-ups

### **3. "Quanto cada um vendeu?"** 
✅ Comissões transparentes e sem disputas

---

## 📝 **LOGS DE ATIVIDADES**

### **O que é registrado:**

```
┌─────────────────────────────────────────────┐
│ TODAS AS AÇÕES NO SISTEMA:                 │
├─────────────────────────────────────────────┤
│ ✅ Criação de cotações                      │
│ ✅ Modificações (quem mudou o quê)          │
│ ✅ Mudanças de status                       │
│ ✅ Envios de email/WhatsApp                 │
│ ✅ Geração de PDF                           │
│ ✅ Adição/remoção de serviços               │
│ ✅ Alterações de valores                    │
│ ✅ Visualizações                            │
│ ✅ Follow-ups realizados                    │
└─────────────────────────────────────────────┘
```

### **Informações Registradas:**

```json
{
  "user_id": "uuid-do-usuario",
  "user_name": "João Silva",
  "user_email": "joao@email.com",
  "action_type": "status_change",
  "entity_type": "quotation",
  "entity_id": "123",
  "entity_name": "QT-2025-001",
  "action_description": "Status alterado de enviado para aceito",
  "old_value": {"status": "sent"},
  "new_value": {"status": "accepted"},
  "metadata": {
    "ip": "192.168.1.1",
    "device": "Chrome/Windows"
  },
  "created_at": "2025-12-06T10:30:00Z"
}
```

### **Exemplo Visual no Sistema:**

```
┌────────────────────────────────────────────────┐
│  📊 Histórico de Atividades                   │
├────────────────────────────────────────────────┤
│                                                │
│  ● João Silva                                  │
│  │ Há 2 minutos • 🔄 Mudou Status              │
│  │                                             │
│  └─ Status alterado de 'Enviado' para 'Aceito'│
│                                                │
│  ○ Maria Santos                                │
│  │ Há 15 minutos • 📧 Enviou Email             │
│  │                                             │
│  └─ Email enviado para cliente@email.com      │
│                                                │
│  ○ Pedro Costa                                 │
│  │ Há 1 hora • ➕ Criou                        │
│  │                                             │
│  └─ Cotação QT-2025-001 criada                │
│                                                │
└────────────────────────────────────────────────┘
```

---

## 📞 **SISTEMA DE FOLLOW-UPS**

### **Por que é importante:**

```
┌──────────────────────────────────────────┐
│  PROBLEMA:                               │
│  Cliente não responde cotação            │
│                                          │
│  SOLUÇÃO:                                │
│  Follow-ups agendados com alertas        │
│                                          │
│  RESULTADO:                              │
│  +30% conversão de vendas! 📈            │
└──────────────────────────────────────────┘
```

### **Tipos de Follow-up:**

| Tipo | Ícone | Quando Usar |
|------|-------|-------------|
| 📞 Ligação | Call | Contato direto urgente |
| 📧 Email | Email | Follow-up formal |
| 💬 WhatsApp | WhatsApp | Mensagem rápida |
| 🤝 Reunião | Meeting | Apresentação presencial |
| 📝 Nota | Note | Lembrete interno |

### **Prioridades:**

```
🟢 BAIXA (LOW)     → Sem pressa
🟠 MÉDIA (MEDIUM)  → Importante
🔴 ALTA (HIGH)     → Urgente
🟣 URGENTE (URGENT) → Faça AGORA!
```

### **Fluxo de Follow-up:**

```
1️⃣ CRIAR FOLLOW-UP
   ↓
   📅 Agendar data/hora
   👤 Atribuir responsável
   ⚡ Definir prioridade
   ↓

2️⃣ ALERTA AUTOMÁTICO
   ↓
   🔔 Sistema notifica quando chegar a hora
   🚨 Alerta de atraso se não concluir
   ↓

3️⃣ EXECUTAR
   ↓
   📞 Fazer contato
   📝 Registrar resultado
   ✅ Marcar como concluído
   ↓

4️⃣ PRÓXIMA AÇÃO
   ↓
   🔄 Agendar novo follow-up se necessário
```

### **Exemplo de Follow-up Atrasado:**

```
┌────────────────────────────────────────────┐
│ ⚠️ FOLLOW-UP ATRASADO!                     │
├────────────────────────────────────────────┤
│ Cliente: João Silva                        │
│ Cotação: QT-2025-001                       │
│ Tipo: 📞 Ligação                           │
│ Prioridade: 🔴 ALTA                        │
│ Agendado: 05/12 14:00                      │
│ Atrasado há: 2 dias                        │
│                                            │
│ [🚨 Executar Agora] [📅 Reagendar]         │
└────────────────────────────────────────────┘
```

---

## 👥 **RASTREAMENTO DE USUÁRIOS**

### **Campos Adicionados na Cotação:**

```sql
-- Quem criou a cotação
created_by_user_id       (UUID do usuário)
created_by_user_name     (Nome para exibição)

-- Quem modificou por último
modified_by_user_id      (UUID do usuário)
modified_by_user_name    (Nome para exibição)

-- Vendedor responsável (para comissão)
assigned_to_user_id      (UUID do vendedor)
assigned_to_user_name    (Nome do vendedor)
```

### **Visualização na Cotação:**

```
┌────────────────────────────────────────────┐
│ Cotação QT-2025-001                        │
├────────────────────────────────────────────┤
│                                            │
│ 👤 Criado por:  João Silva                 │
│    📅 Em: 05/12/2025 10:30                 │
│                                            │
│ ✏️ Modificado por: Maria Santos            │
│    📅 Em: 06/12/2025 14:15                 │
│                                            │
│ 💼 Vendedor: João Silva (5% comissão)      │
│                                            │
└────────────────────────────────────────────┘
```

---

## 💰 **COMISSÕES DE VENDEDORES**

### **Como Funciona:**

```
1. Cotação criada
   ↓
2. Vendedor atribuído (assigned_to)
   ↓
3. Taxa de comissão definida (%)
   ↓
4. Cliente aceita
   ↓
5. Comissão calculada automaticamente
   ↓
6. Relatório gerado
```

### **Cálculo Automático:**

```
Valor da Cotação:    R$ 5.000,00
Taxa de Comissão:    5%
─────────────────────────────
Comissão do Vendedor: R$ 250,00
```

### **Relatório de Comissões:**

```
┌────────────────────────────────────────────────────┐
│  RELATÓRIO DE COMISSÕES - DEZEMBRO/2025           │
├────────────────────────────────────────────────────┤
│                                                    │
│  João Silva                                        │
│  ├─ Cotações Aceitas: 15                          │
│  ├─ Valor Total: R$ 75.000,00                     │
│  ├─ Taxa Média: 5%                                │
│  └─ Comissão Total: R$ 3.750,00 💰                │
│                                                    │
│  Maria Santos                                      │
│  ├─ Cotações Aceitas: 12                          │
│  ├─ Valor Total: R$ 60.000,00                     │
│  ├─ Taxa Média: 5%                                │
│  └─ Comissão Total: R$ 3.000,00 💰                │
│                                                    │
│  Pedro Costa                                       │
│  ├─ Cotações Aceitas: 8                           │
│  ├─ Valor Total: R$ 40.000,00                     │
│  ├─ Taxa Média: 5%                                │
│  └─ Comissão Total: R$ 2.000,00 💰                │
│                                                    │
└────────────────────────────────────────────────────┘

📊 TOTAL GERAL: R$ 175.000,00
💰 COMISSÕES: R$ 8.750,00
```

### **Estatísticas por Vendedor:**

```sql
-- Chamada da função
SELECT * FROM get_seller_stats('user-id');

-- Retorna:
{
  "total_quotations": 25,
  "accepted_quotations": 15,
  "pending_quotations": 8,
  "rejected_quotations": 2,
  "total_value": 125000.00,
  "accepted_value": 75000.00,
  "total_commission": 3750.00,
  "conversion_rate": 60.00,  -- 60% de conversão!
  "avg_quotation_value": 5000.00,
  "follow_ups_completed": 45,
  "follow_ups_pending": 5
}
```

---

## 🚀 **COMO USAR**

### **1. Executar Migration:**

```bash
# Conectar ao Supabase e executar
supabase/migrations/2025-12-06_audit_system.sql
```

### **2. No Código Flutter:**

```dart
// Registrar uma atividade
final auditService = AuditService();

await auditService.logActivity(
  userId: currentUser.id,
  userName: currentUser.name,
  actionType: 'status_change',
  entityType: 'quotation',
  entityId: quotation.id.toString(),
  entityName: quotation.quotationNumber,
  actionDescription: 'Status alterado para aceito',
  oldValue: {'status': 'sent'},
  newValue: {'status': 'accepted'},
);

// Buscar logs de uma cotação
final logs = await auditService.getQuotationActivityLogs(
  quotation.id.toString(),
);

// Criar follow-up
await auditService.createFollowUp(
  quotationId: quotation.id,
  assignedTo: vendedor.id,
  assignedName: vendedor.name,
  type: 'call',
  priority: 'high',
  scheduledDate: DateTime.now().add(Duration(days: 2)),
  title: 'Ligar para cliente',
  description: 'Confirmar interesse na viagem',
  createdBy: currentUser.id,
);

// Buscar estatísticas
final stats = await auditService.getSellerStats(vendedor.id);
print('Taxa de conversão: ${stats.conversionRate}%');
print('Comissão total: R\$ ${stats.totalCommission}');
```

### **3. Exibir Timeline:**

```dart
QuotationActivityTimeline(
  activities: logs,
  followUps: followUps,
)
```

---

## ✅ **BENEFÍCIOS**

### **Para Gestores:**
- ✅ Visibilidade completa das ações
- ✅ Auditoria para resolver disputas
- ✅ Métricas de performance por vendedor
- ✅ Comissões calculadas automaticamente

### **Para Vendedores:**
- ✅ Follow-ups organizados
- ✅ Alertas para não perder vendas
- ✅ Transparência nas comissões
- ✅ Histórico de suas ações

### **Para a Empresa:**
- ✅ Compliance e auditoria
- ✅ Aumento de conversão (follow-ups)
- ✅ Redução de conflitos
- ✅ Dados para decisões estratégicas

---

## 📊 **RELATÓRIOS DISPONÍVEIS**

### **1. Atividades por Usuário:**
```sql
SELECT * FROM get_user_activity_logs('user-id', 100);
```

### **2. Comissões:**
```sql
SELECT * FROM quotation_commissions
WHERE assigned_to_user_id = 'user-id'
  AND status = 'accepted'
ORDER BY accepted_date DESC;
```

### **3. Follow-ups Pendentes:**
```sql
SELECT * FROM quotation_follow_up
WHERE assigned_to = 'user-id'
  AND status = 'pending'
ORDER BY scheduled_date;
```

### **4. Follow-ups Atrasados:**
```sql
SELECT * FROM quotation_follow_up
WHERE assigned_to = 'user-id'
  AND status = 'pending'
  AND scheduled_date < NOW()
ORDER BY scheduled_date;
```

---

## 🎯 **PRÓXIMOS PASSOS**

1. ✅ Executar migration no Supabase
2. ✅ Integrar `AuditService` nas ações
3. ✅ Adicionar timeline no modal de cotação
4. ✅ Criar dashboard de comissões
5. ✅ Implementar notificações de follow-up
6. ✅ Criar relatório gerencial

---

**Sistema completo de auditoria profissional!** 🚀

