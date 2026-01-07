# 📊 SISTEMA DE STATUS DE COTAÇÕES - GUIA COMPLETO

## 🎯 **LÓGICA DOS STATUS**

### **Fluxo Normal (Happy Path):**

```
┌──────────────┐
│ 📝 RASCUNHO  │ ← Cotação criada, editando
└──────┬───────┘
       │ [Enviar Email/WhatsApp]
       ↓
┌──────────────┐
│ 📤 ENVIADO   │ ← Cliente recebeu
└──────┬───────┘
       │ [Cliente abre]
       ↓
┌──────────────┐
│ 👀 VISUALIZADO│ ← Cliente viu
└──────┬───────┘
       │ [Cliente responde]
       ↓
┌──────────────┐
│ ✅ ACEITO    │ ← VENDA FECHADA! 🎉
└──────────────┘
```

### **Fluxo Alternativo (Cliente Recusa):**

```
┌──────────────┐
│ 👀 VISUALIZADO│
└──────┬───────┘
       │ [Cliente recusa]
       ↓
┌──────────────┐
│ ❌ REJEITADO │ ← Fazer follow-up
└──────────────┘
```

### **Status Especial:**

```
┌──────────────┐
│ ⏰ EXPIRADO  │ ← Data de validade passou
└──────────────┘
```

---

## 🎨 **COMO MUDAR O STATUS (Interface Visual)**

### **1. No Modal de Gerenciamento:**

Quando você abre uma cotação, verá esta seção:

```
╔═══════════════════════════════════════════════════╗
║  📊 Status da Cotação                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ║
║                                                   ║
║  Status Atual: 📝 Rascunho                       ║
║                                                   ║
║  ℹ️ Cotação em edição. Quando terminar de        ║
║     editar, envie para o cliente.                ║
║                                                   ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ║
║                                                   ║
║  TIMELINE VISUAL:                                 ║
║                                                   ║
║  ● 📝 Rascunho          ← Status Atual           ║
║  │                                                ║
║  ○ 📤 Enviado                                     ║
║  │                                                ║
║  ○ 👀 Visualizado                                 ║
║  │                                                ║
║  ○ ✅ Aceito                                      ║
║                                                   ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ║
║                                                   ║
║  Ações Disponíveis:                              ║
║                                                   ║
║  [📤 Marcar como Enviado]                        ║
║  [❌ Rejeitar]                                    ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
```

### **2. Ao Clicar em um Botão de Ação:**

Aparece confirmação:

```
╔═══════════════════════════════════════╗
║  Confirmar Mudança de Status          ║
║  ───────────────────────────────────  ║
║                                       ║
║  [📝] ──→ [📤]                        ║
║                                       ║
║  De: 📝 Rascunho                      ║
║  Para: 📤 Enviado                     ║
║                                       ║
║  Cliente recebeu a cotação por        ║
║  email/WhatsApp                       ║
║                                       ║
║        [Cancelar]  [✅ Confirmar]     ║
╚═══════════════════════════════════════╝
```

---

## 🔄 **TRANSIÇÕES PERMITIDAS**

### **Do RASCUNHO você pode:**
- ✅ Marcar como **ENVIADO** (quando enviar ao cliente)
- ❌ Marcar como **REJEITADO** (se desistir)

### **Do ENVIADO você pode:**
- ✅ Marcar como **VISUALIZADO** (quando cliente abrir)
- ✅ Marcar como **ACEITO** (atalho se cliente aceitar direto)
- ❌ Marcar como **REJEITADO**

### **Do VISUALIZADO você pode:**
- ✅ Marcar como **ACEITO** ← VENDA!
- ❌ Marcar como **REJEITADO**

### **Do ACEITO/REJEITADO você pode:**
- 📝 Voltar para **RASCUNHO** (editar novamente)

---

## 📅 **DATAS AUTOMÁTICAS**

O sistema registra **automaticamente** as datas:

| Status | Campo no Banco | Quando |
|--------|----------------|--------|
| 📤 Enviado | `sent_date` | Ao marcar como enviado |
| 👀 Visualizado | `viewed_date` | Ao marcar como visualizado |
| ✅ Aceito | `accepted_date` | Ao marcar como aceito |
| ❌ Rejeitado | `rejected_date` | Ao marcar como rejeitado |

---

## 💡 **CASOS DE USO REAIS**

### **Caso 1: Fluxo Completo**
```
1. Cria cotação → Status: RASCUNHO
2. Envia por email → Clica "Marcar como Enviado" → Status: ENVIADO
3. Cliente abre email → Clica "Marcar como Visualizado" → Status: VISUALIZADO
4. Cliente responde "Ok!" → Clica "Marcar como Aceito" → Status: ACEITO ✅
```

### **Caso 2: Cliente Recusa**
```
1. Cria cotação → Status: RASCUNHO
2. Envia WhatsApp → Clica "Marcar como Enviado" → Status: ENVIADO
3. Cliente vê → Clica "Marcar como Visualizado" → Status: VISUALIZADO
4. Cliente: "Muito caro" → Clica "Marcar como Rejeitado" → Status: REJEITADO ❌
5. Ajusta valores → Clica "Voltar para Rascunho" → Status: RASCUNHO
6. Reenvia → Repete o processo
```

### **Caso 3: Envio e Aceitação Rápida**
```
1. Cria cotação → Status: RASCUNHO
2. Envia WhatsApp → Clica "Marcar como Enviado" → Status: ENVIADO
3. Cliente: "Fechado!" → Clica "Aceitar Diretamente" → Status: ACEITO ✅
   (pula o status VISUALIZADO)
```

---

## 🎨 **VISUAL NO SISTEMA**

### **Cards na Listagem de Cotações:**

```
┌─────────────────────────────────────────┐
│ QT-2025-001 • João Silva                │
│ Miami • $1,500                          │
│ [📝 Rascunho]                           │ ← Cinza
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ QT-2025-002 • Maria Souza               │
│ Paris • $3,200                          │
│ [📤 Enviado]                            │ ← Azul
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ QT-2025-003 • Pedro Lima                │
│ Orlando • $2,100                        │
│ [👀 Visualizado]                        │ ← Laranja
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ QT-2025-004 • Ana Costa                 │
│ Dubai • $5,500                          │
│ [✅ Aceito]                             │ ← Verde
└─────────────────────────────────────────┘
```

---

## 🚀 **AUTOMAÇÃO FUTURA (Sugestões)**

1. **Auto-Visualizado**: Integrar webhook quando cliente abrir link
2. **Auto-Expirado**: Cron job que muda para expirado após data de validade
3. **Notificações**: Alertar vendedor quando status mudar
4. **Follow-up**: Sugerir follow-up automaticamente em cotações visualizadas há 3 dias

---

## ✅ **IMPLEMENTAÇÃO CONCLUÍDA**

- ✅ Widget visual `QuotationStatusManager`
- ✅ Timeline com progresso
- ✅ Botões de ação contextuais
- ✅ Confirmação antes de mudar
- ✅ Registro automático de datas
- ✅ Integrado no modal de gerenciamento

---

**Ficou claro agora? 🎯**

