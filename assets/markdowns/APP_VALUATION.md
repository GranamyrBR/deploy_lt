## Valuation rápido do aplicativo Lecotour

Este documento apresenta 3 opções de valuation solicitadas: A) estimativa conservadora (replacement / custo), B) valuation por múltiplos baseado em ARR (cenários exemplo) e C) sugestão de preço de venda (mínimo / alvo / premium).

⚠️ **CORRIGIDO PARA MERCADO BRASILEIRO** — valores em BRL (não mais em USD)

Resumo dos dados conhecidos e hipóteses principais
- Projeto: Lecotour (Flutter + Supabase)
- Status: ~80–85% concluído
- Código: ~58k LOC, 95 models, 35 services, 50+ telas
- Trabalho pendente identificado: ~235 horas para produção
- **Suposições corrigidas (mercado BR)**:
  - Junior: R$40–60/h
  - Pleno: R$80–120/h (cenário base)
  - Sênior: R$150–250/h
  - Horas já gastas estimadas: faixa 1.200–2.400 h

------------------------------------------------------------------

A) Replacement cost / Custo de substituição (estimativa)

Objetivo: estimar quanto custaria reconstruir o app hoje por uma equipe externa (Brasil).

- Cenário baixo (equipa junior/pequena studio): 1.000 horas × R$50/h = R$50.000
- Cenário médio (equipa pleno/mid-level): 1.600 horas × R$100/h = R$160.000
- Cenário alto (equipe sênior/consultoria top): 1.200 horas × R$200/h = R$240.000

**Observação**: replacement cost normalmente representa o piso para negociação quando não há receita. Valores ajustados para mercado brasileiro (mais baixo que internacional, com múltiplo 3–4× menor). Pode ser ajustado para cima se há IP, integrações complexas e clientes ativos.

------------------------------------------------------------------

B) Valuation por múltiplos de receita (cenários de ARR) — exemplos

Sem dados reais de ARR/MRR, apresento 2 cenários de referência (múltiplos SaaS Brasil 2×–4× ARR, com ajuste para mercado local):

- Exemplo 1: ARR = R$50.000/ano
  - Valor (2×–4×) = R$100.000 — R$200.000

- Exemplo 2: ARR = R$500.000/ano
  - Valor (2×–4×) = R$1.000.000 — R$2.000.000

**Breve DCF simplificado** (exemplo ARR R$50k, brasileir):
- Hipóteses: crescimento 15% a.a. nos 5 anos, margem EBITDA 15%, taxa de desconto 14% (Selic + risco), múltiplo terminal 5× EBITDA.
- Projeção (resumo rápido):
  - Year1 ARR: 50k → EBITDA Year1 = 7.5k
  - Year5 ARR ≈ 101.1k → EBITDA5 ≈ 15.2k → Terminal Value ≈ 76k (5×)
  - Valor presente líquido aproximado (PV dos fluxos + terminal) ≈ R$90k — R$130k (dependendo de premissas)

**Observação**: DCF é sensível a taxa de desconto (Brasil tem Selic maior), margem e múltiplo terminal. Forneça ARR, crescimento esperado e margens para um DCF rigoroso.

------------------------------------------------------------------

C) Preço sugerido de venda (mínimo / alvo / premium) — Brasil

Sem receita, usamos replacement médio para referência.

- **Cenário conservador** (liquidação / venda rápida): 40–50% do replacement médio
  - Replacement médio = R$160k → mínimo ≈ R$64k — R$80k

- **Preço alvo** (negociação padrão): 70–90% do replacement ou replacement médio
  - Alvo ≈ R$115k — R$160k (justificado por trabalho já feito + documentação e scripts de deploy)

- **Premium** (comprador estratégico ou com ARR): valor baseado em múltiplo de receita
  - Se houver ARR relevante, veja a seção B (pode subir para R$200k+ conforme ARR)

**Recomendações comerciais**:
- Se vender sem receita e com necessidade rápida de caixa: aceitar algo perto do mínimo (≈ R$70k) apenas se a venda for imediata.
- Se puder esperar e apresentar roadmap, testes e pipeline (aumentar readiness), negociar pelo menos replacement médio (R$160k) ou acima.
- Para venda estratégica (com clientes), alinhar valuation por múltiplos de ARR.

------------------------------------------------------------------

Custos para finalizar o produto (colocar em produção pronto para venda)
- Horas restantes: 235 h
  - Junior (R$50/h) → R$11.750
  - Pleno (R$100/h) → R$23.500 (cenário base)
  - Sênior (R$200/h) → R$47.000

------------------------------------------------------------------

Conversões rápidas (tudo já em BRL, mercado Brasil)
- Finalizar (cenário base R$23.500)
- Replacement médio R$160.000

**RESUMO FINAL** — Intervalos realistas (mercado Brasil)
- Custo para terminar: R$11.750 — R$47.000 (dependendo do seniority)
- Replacement cost (reconstruir): R$50.000 — R$240.000 (cenários baixo→alto)
- **Valor de mercado SEM receita (estimativa conservadora)**: R$64.000 — R$160.000 (provavelmente no entorno do cenário médio)
- Valor de mercado COM receita: depende do ARR (me passe ARR/MRR para calcular).

------------------------------------------------------------------

O que eu preciso para um valuation preciso (porte institucional/Due Diligence)
- ARR/MRR (receita anual recorrente e receita mensal)
- Nº de clientes pagantes, ARPU
- Churn (mensal/annum)
- Margem operacional ou EBITDA atual (ou estimada)
- Usuários ativos, contratos/contratos recorrentes, pipeline de vendas
- Expectativa de crescimento (CAGR) e custos fixos/variáveis

Próximos passos sugeridos
1) Se quer um relatório formal com DCF, múltiplos e replacement cost com números precisos, me forneça ARR/MRR + margens; eu gero um documento detalhado com tabelas.
2) Se quer preparar o app para venda e aumentar preço alvo: priorizar cobertura de testes, CI/CD, documentação e hardening de segurança (lista de 235h já identificada).

Contato e nota final
Este é um valuation rápido e indicativo. Para um valuation formal (usado em LOI/negociação), recomenda-se Due Diligence financeira e legal.

----
Gerado em 2025-11-12 — Resumo automático criado a partir da análise técnica existente no repositório.
## Valuation rápido do aplicativo Lecotour
