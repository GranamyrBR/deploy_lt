# Análise Crítica do Schema de Vendas e Proposta de Reestruturação

## 🔍 PROBLEMAS IDENTIFICADOS NO SCHEMA ATUAL

### 1. **PROBLEMA CONCEITUAL FUNDAMENTAL**

**Tabela `sale`:**
- `exchange_rate_to_usd` é um campo único por venda
- Não suporta múltiplas cotações para diferentes transações da mesma venda
- Viola o princípio de que cada pagamento pode ter cotação diferente

**Tabela `sale_payment`:**
- `exchange_rate_to_usd` permite cotação por pagamento ✅
- MAS não há garantia de consistência com a cotação da venda
- Campos `amount_in_brl` e `amount_in_usd` podem estar inconsistentes

### 2. **INCONSISTÊNCIAS DE DADOS**

```sql
-- PROBLEMA: Venda com cotação fixa
CREATE TABLE public.sale (
  exchange_rate_to_usd numeric DEFAULT 1.0, -- ❌ COTAÇÃO FIXA POR VENDA
  total_amount_brl numeric,
  total_amount_usd numeric
);

-- PROBLEMA: Pagamento com cotação independente
CREATE TABLE public.sale_payment (
  exchange_rate_to_usd numeric, -- ❌ PODE SER DIFERENTE DA VENDA
  amount_in_brl numeric,
  amount_in_usd numeric
);
```

### 3. **REGRAS DE NEGÓCIO NÃO IMPLEMENTADAS**

- ❌ Não há controle de que a soma dos pagamentos deve igualar o total da venda
- ❌ Não há histórico de cotações por data
- ❌ Não há validação de consistência entre moedas
- ❌ Não há suporte a pagamentos parciais com cotações diferentes

## 🏗️ PROPOSTA DE REESTRUTURAÇÃO CONCEITUAL

### **PRINCÍPIOS DA NOVA ARQUITETURA:**

1. **Empresa Americana**: Todos os preços base em USD
2. **Cotação por Transação**: Cada pagamento trava sua própria cotação
3. **Histórico de Cotações**: Rastreabilidade completa
4. **Consistência de Dados**: Validações automáticas
5. **Flexibilidade**: Suporte a cenários complexos

### **NOVA ESTRUTURA PROPOSTA:**

```sql
-- 1. TABELA DE COTAÇÕES HISTÓRICAS
CREATE TABLE exchange_rate_history (
  id BIGSERIAL PRIMARY KEY,
  currency_from VARCHAR(3) NOT NULL, -- 'BRL'
  currency_to VARCHAR(3) NOT NULL,   -- 'USD'
  rate NUMERIC(10,6) NOT NULL,       -- 5.890000
  rate_date DATE NOT NULL,
  source VARCHAR(50) NOT NULL,       -- 'banco_central_brasil'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(currency_from, currency_to, rate_date)
);

-- 2. VENDA REFORMULADA (APENAS USD)
CREATE TABLE sale_v2 (
  id BIGSERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  user_id UUID NOT NULL,
  
  -- VALORES SEMPRE EM USD (EMPRESA AMERICANA)
  total_amount_usd NUMERIC(12,2) NOT NULL,
  
  -- STATUS E CONTROLE
  status VARCHAR(20) DEFAULT 'draft',
  payment_status VARCHAR(20) DEFAULT 'pending',
  
  -- DATAS
  sale_date TIMESTAMPTZ DEFAULT NOW(),
  due_date TIMESTAMPTZ,
  
  -- AUDITORIA
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id) REFERENCES contact(id),
  CONSTRAINT fk_sale_user FOREIGN KEY (user_id) REFERENCES "user"(id)
);

-- 3. TRANSAÇÕES DE PAGAMENTO (COM COTAÇÃO TRAVADA)
CREATE TABLE payment_transaction (
  id BIGSERIAL PRIMARY KEY,
  sale_id BIGINT NOT NULL,
  
  -- VALOR ORIGINAL DO PAGAMENTO
  amount_original NUMERIC(12,2) NOT NULL,
  currency_original VARCHAR(3) NOT NULL, -- 'BRL' ou 'USD'
  
  -- COTAÇÃO TRAVADA NO MOMENTO DO PAGAMENTO
  exchange_rate_id BIGINT, -- NULL se pagamento em USD
  exchange_rate_value NUMERIC(10,6), -- Cotação travada
  
  -- VALOR CONVERTIDO PARA USD (SEMPRE CALCULADO)
  amount_usd NUMERIC(12,2) NOT NULL,
  
  -- DADOS DO PAGAMENTO
  payment_method_id INTEGER NOT NULL,
  payment_date TIMESTAMPTZ NOT NULL,
  transaction_id VARCHAR(100),
  
  -- TIPO DE PAGAMENTO
  is_advance_payment BOOLEAN DEFAULT FALSE,
  
  -- AUDITORIA
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT fk_payment_sale FOREIGN KEY (sale_id) REFERENCES sale_v2(id),
  CONSTRAINT fk_payment_exchange_rate FOREIGN KEY (exchange_rate_id) REFERENCES exchange_rate_history(id),
  CONSTRAINT fk_payment_method FOREIGN KEY (payment_method_id) REFERENCES payment_method(id),
  
  -- VALIDAÇÕES
  CONSTRAINT chk_currency_and_rate CHECK (
    (currency_original = 'USD' AND exchange_rate_id IS NULL) OR
    (currency_original != 'USD' AND exchange_rate_id IS NOT NULL)
  )
);

-- 4. ITENS DA VENDA (SEMPRE EM USD)
CREATE TABLE sale_item_v2 (
  id BIGSERIAL PRIMARY KEY,
  sale_id BIGINT NOT NULL,
  service_id INTEGER,
  product_id INTEGER,
  
  -- PREÇOS EM USD
  unit_price_usd NUMERIC(10,2) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  
  -- DESCONTOS E TAXAS
  discount_percentage NUMERIC(5,2) DEFAULT 0,
  discount_amount_usd NUMERIC(10,2) DEFAULT 0,
  tax_percentage NUMERIC(5,2) DEFAULT 0,
  tax_amount_usd NUMERIC(10,2) DEFAULT 0,
  
  -- TOTAL DO ITEM
  subtotal_usd NUMERIC(10,2) NOT NULL,
  total_usd NUMERIC(10,2) NOT NULL,
  
  -- DADOS ADICIONAIS
  pax INTEGER DEFAULT 1,
  
  -- AUDITORIA
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT fk_sale_item_sale FOREIGN KEY (sale_id) REFERENCES sale_v2(id),
  CONSTRAINT fk_sale_item_service FOREIGN KEY (service_id) REFERENCES service(id),
  CONSTRAINT fk_sale_item_product FOREIGN KEY (product_id) REFERENCES product(product_id)
);
```

## 🔧 TRIGGERS E VALIDAÇÕES AUTOMÁTICAS

```sql
-- TRIGGER: Atualizar total da venda quando itens mudarem
CREATE OR REPLACE FUNCTION update_sale_total()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE sale_v2 
  SET total_amount_usd = (
    SELECT COALESCE(SUM(total_usd), 0)
    FROM sale_item_v2 
    WHERE sale_id = COALESCE(NEW.sale_id, OLD.sale_id)
  ),
  updated_at = NOW()
  WHERE id = COALESCE(NEW.sale_id, OLD.sale_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_sale_total
  AFTER INSERT OR UPDATE OR DELETE ON sale_item_v2
  FOR EACH ROW EXECUTE FUNCTION update_sale_total();

-- TRIGGER: Atualizar status de pagamento da venda
CREATE OR REPLACE FUNCTION update_payment_status()
RETURNS TRIGGER AS $$
DECLARE
  sale_total NUMERIC;
  paid_total NUMERIC;
BEGIN
  SELECT total_amount_usd INTO sale_total
  FROM sale_v2 
  WHERE id = COALESCE(NEW.sale_id, OLD.sale_id);
  
  SELECT COALESCE(SUM(amount_usd), 0) INTO paid_total
  FROM payment_transaction 
  WHERE sale_id = COALESCE(NEW.sale_id, OLD.sale_id);
  
  UPDATE sale_v2 
  SET payment_status = CASE
    WHEN paid_total = 0 THEN 'pending'
    WHEN paid_total < sale_total THEN 'partial'
    WHEN paid_total >= sale_total THEN 'completed'
  END,
  updated_at = NOW()
  WHERE id = COALESCE(NEW.sale_id, OLD.sale_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_payment_status
  AFTER INSERT OR UPDATE OR DELETE ON payment_transaction
  FOR EACH ROW EXECUTE FUNCTION update_payment_status();
```

## 📊 VIEWS PARA RELATÓRIOS

```sql
-- VIEW: Resumo completo de vendas com conversões
CREATE VIEW sale_summary AS
SELECT 
  s.id,
  s.customer_id,
  c.name as customer_name,
  s.total_amount_usd,
  
  -- TOTAL PAGO POR MOEDA
  COALESCE(SUM(CASE WHEN pt.currency_original = 'USD' THEN pt.amount_original END), 0) as paid_usd,
  COALESCE(SUM(CASE WHEN pt.currency_original = 'BRL' THEN pt.amount_original END), 0) as paid_brl,
  
  -- TOTAL PAGO CONVERTIDO PARA USD
  COALESCE(SUM(pt.amount_usd), 0) as total_paid_usd,
  
  -- SALDO RESTANTE
  s.total_amount_usd - COALESCE(SUM(pt.amount_usd), 0) as remaining_usd,
  
  -- STATUS
  s.payment_status,
  s.status,
  
  -- DATAS
  s.sale_date,
  s.due_date
  
FROM sale_v2 s
LEFT JOIN contact c ON s.customer_id = c.id
LEFT JOIN payment_transaction pt ON s.id = pt.sale_id
GROUP BY s.id, c.name;

-- VIEW: Histórico detalhado de pagamentos
CREATE VIEW payment_history AS
SELECT 
  pt.id,
  pt.sale_id,
  pt.amount_original,
  pt.currency_original,
  pt.exchange_rate_value,
  pt.amount_usd,
  pt.payment_date,
  pt.transaction_id,
  
  -- DADOS DA COTAÇÃO
  erh.rate_date,
  erh.source as exchange_rate_source,
  
  -- DADOS DO MÉTODO DE PAGAMENTO
  pm.name as payment_method_name
  
FROM payment_transaction pt
LEFT JOIN exchange_rate_history erh ON pt.exchange_rate_id = erh.id
LEFT JOIN payment_method pm ON pt.payment_method_id = pm.id
ORDER BY pt.payment_date DESC;
```

## 🚀 MIGRAÇÃO DOS DADOS EXISTENTES

```sql
-- SCRIPT DE MIGRAÇÃO (EXECUTAR COM CUIDADO)

-- 1. Migrar cotações históricas
INSERT INTO exchange_rate_history (currency_from, currency_to, rate, rate_date, source)
SELECT DISTINCT 
  'BRL', 'USD', 
  sp.exchange_rate_to_usd,
  sp.payment_date::DATE,
  'legacy_migration'
FROM sale_payment sp
WHERE sp.exchange_rate_to_usd IS NOT NULL
  AND sp.exchange_rate_to_usd > 0
ON CONFLICT (currency_from, currency_to, rate_date) DO NOTHING;

-- 2. Migrar vendas
INSERT INTO sale_v2 (id, customer_id, user_id, total_amount_usd, status, payment_status, sale_date, due_date, created_at, updated_at)
SELECT 
  id,
  customer_id,
  user_id,
  COALESCE(total_amount_usd, total_amount / COALESCE(exchange_rate_to_usd, 1.0)),
  status,
  payment_status,
  sale_date,
  due_date,
  created_at,
  updated_at
FROM sale;

-- 3. Migrar itens (simplificado)
INSERT INTO sale_item_v2 (sale_id, service_id, product_id, unit_price_usd, quantity, total_usd, created_at, updated_at)
SELECT 
  sales_id,
  service_id,
  product_id,
  COALESCE(unit_price_in_usd, unit_price_at_sale / COALESCE(exchange_rate_to_usd, 1.0)),
  quantity,
  COALESCE(item_total_in_usd, item_total / COALESCE(exchange_rate_to_usd, 1.0)),
  created_at,
  updated_at
FROM sale_item;

-- 4. Migrar pagamentos
INSERT INTO payment_transaction (sale_id, amount_original, currency_original, exchange_rate_id, exchange_rate_value, amount_usd, payment_method_id, payment_date, transaction_id, is_advance_payment, created_at, updated_at)
SELECT 
  sp.sales_id,
  sp.amount,
  CASE WHEN sp.currency_id = 1 THEN 'USD' ELSE 'BRL' END,
  erh.id,
  sp.exchange_rate_to_usd,
  COALESCE(sp.amount_in_usd, sp.amount / COALESCE(sp.exchange_rate_to_usd, 1.0)),
  sp.payment_method_id,
  sp.payment_date,
  sp.transaction_id,
  sp.is_advance_payment,
  sp.created_at,
  sp.updated_at
FROM sale_payment sp
LEFT JOIN exchange_rate_history erh ON erh.rate = sp.exchange_rate_to_usd 
  AND erh.rate_date = sp.payment_date::DATE;
```

## ✅ VANTAGENS DA NOVA ESTRUTURA

1. **✅ Cotação por Transação**: Cada pagamento trava sua cotação independentemente
2. **✅ Consistência de Dados**: Triggers garantem integridade
3. **✅ Histórico Completo**: Rastreabilidade de todas as cotações
4. **✅ Flexibilidade**: Suporte a cenários complexos de pagamento
5. **✅ Performance**: Views otimizadas para relatórios
6. **✅ Auditoria**: Controle completo de mudanças
7. **✅ Escalabilidade**: Estrutura preparada para crescimento

## 🎯 PRÓXIMOS PASSOS

1. **Validar** a proposta com a equipe de negócios
2. **Testar** a migração em ambiente de desenvolvimento
3. **Implementar** as novas tabelas
4. **Migrar** os dados existentes
5. **Atualizar** o código da aplicação
6. **Validar** os cálculos no frontend

---

**Esta reestruturação resolve completamente o problema de múltiplas cotações e garante a integridade dos dados financeiros da empresa.**
# Análise Crítica do Schema de Vendas e Proposta de Reestruturação
