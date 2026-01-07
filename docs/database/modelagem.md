erDiagram

    %% ========= Núcleo CRM =========
    account {
      bigint id PK
      text name
      text contact_name
      text email
      text domain
      text phone
      text address
      boolean is_active
    }

    account_category {
      bigint account_id PK
      text account_type
    }

    contact_category {
      int id PK
      text name
      boolean is_active
    }

    source {
      int id PK
      text name
      boolean is_active
    }

    contact {
      int id
      varchar phone PK
      varchar name
      varchar email
      text address
      varchar city
      varchar state
      varchar country
      int account_id FK
      int contact_category_id FK
      int source_id FK
      boolean is_vip
    }

    sale {
      int id PK
      int customer_id FK
      int currency_id FK
      int created_by
      numeric total_amount
      varchar status
    }

    sale_item {
      int id PK
      int sale_id FK
      int service_id FK
      int product_id FK
      int currency_id FK
      numeric quantity
      numeric unit_price
    }

    invoice {
      int id PK
      int sale_id FK
      int customer_id FK
      varchar invoice_number
      numeric total_amount
      date due_date
      varchar status
    }

    sale_payment {
      int id PK
      int sale_id FK
      int payment_method_id FK
      int currency_id FK
      numeric amount
      date payment_date
      varchar status
    }

    payment_method {
      int id PK
      text name
      boolean is_active
    }

    %% ========= Serviços / Produtos =========
    service_category {
      int id PK
      text name
      boolean is_active
    }

    service {
      int id PK
      text name
      int category_id FK
      numeric base_price_usd
      boolean is_active
    }

    product_category {
      int id PK
      text name
      boolean is_active
    }

    product {
      int product_id PK
      text name
      int category_id FK
      numeric base_price_usd
      boolean is_active
    }

    %% ========= Operações / Logística =========
    driver {
      int id PK
      text name
      text email
      text phone
      text city_name
      boolean is_active
    }

    car {
      int id PK
      text make
      text model
      text color
      text license_plate
      int capacity
      boolean has_wifi
    }

    driver_car {
      int id PK
      int driver_id FK
      int car_id FK
      boolean is_active
    }

    driver_service {
      int driver_id PK
      int service_id PK
    }

    locations {
      uuid id PK
      text address
      text city
      text state
      text country
    }

    operation {
      bigint id PK
      int sale_id FK
      int sale_item_id FK
      int service_id FK
      int product_id FK
      int customer_id FK
      int driver_id FK
      int car_id FK
      uuid pickup_location_id FK
      uuid dropoff_location_id FK
      timestamp scheduled_date
      varchar status
      varchar priority
      int number_of_passengers
      numeric driver_commission_usd
    }

    operation_history {
      bigint id PK
      bigint operation_id FK
      uuid user_id
      varchar status_from
      varchar status_to
      timestamp created_at
      text notes
    }

    %% ========= Financeiro / Custos =========
    currency {
      int currency_id PK
      varchar currency_code
      varchar currency_name
    }

    exchange_rate_history {
      bigint id PK
      varchar currency_code
      numeric rate_to_usd
      date rate_date
    }

    cost_center {
      text id PK
      text code
      text name
      text department
      numeric budget
      numeric utilized
      boolean is_active
    }

    cost_center_category {
      int id PK
      text name
      boolean is_active
    }

    cost_center_expense {
      int id PK
      text cost_center_id FK
      int category_id FK
      int currency_id FK
      numeric amount
      date expense_date
      text status
    }

    driver_commission {
      bigint id PK
      bigint operation_id FK
      int driver_id FK
      numeric total_commission_usd
      numeric total_commission_brl
      varchar payment_status
    }

    %% ========= Usuário / Auditoria / IA =========
    "user" {
      uuid id PK
      varchar email
      varchar full_name
      boolean is_active
    }

    department {
      int id PK
      varchar name
      boolean is_active
    }

    position {
      int id PK
      varchar name
      int department_id FK
      boolean is_active
    }

    audit_log {
      bigint id PK
      varchar table_name
      bigint record_id
      uuid user_id FK
      timestamp operation_timestamp
    }

    ai_interactions {
      bigint id PK
      uuid user_id FK
      varchar conversation_id
      int tokens_used
      int response_time_ms
    }

    %% ========= Relacionamentos =========

    account ||--o{ contact : "tem"
    account_category ||--|| account : "classifica"
    contact_category ||--o{ contact : "classifica"
    source ||--o{ contact : "origem"

    contact ||--o{ sale : "realiza"
    sale ||--o{ sale_item : "possui"
    sale ||--o{ invoice : "fatura"
    sale ||--o{ sale_payment : "pagamento"

    payment_method ||--o{ sale_payment : "utilizada_por"
    currency ||--o{ sale : "moeda"
    currency ||--o{ sale_item : "moeda"
    currency ||--o{ invoice : "moeda"
    currency ||--o{ cost_center_expense : "moeda"

    service_category ||--o{ service : "agrupa"
    product_category ||--o{ product : "agrupa"

    service ||--o{ sale_item : "vendido_em"
    product ||--o{ sale_item : "vendido_em"

    driver ||--o{ driver_car : "dirige"
    car ||--o{ driver_car : "associado_a"
    driver ||--o{ operation : "executa"
    car ||--o{ operation : "utilizado_em"

    driver ||--o{ driver_service : "pode_executar"
    service ||--o{ driver_service : "pode_ser_executado_por"

    locations ||--o{ operation : "pickup"
    locations ||--o{ operation : "dropoff"

    contact ||--o{ operation : "atendido_em"
    service ||--o{ operation : "define_tipo"
    product ||--o{ operation : "produto_relacionado"
    sale_item ||--|| operation : "origina"

    operation ||--o{ operation_history : "historico"

    cost_center ||--o{ cost_center_expense : "tem_despesas"
    cost_center_category ||--o{ cost_center_expense : "classifica"

    operation ||--|| driver_commission : "gera"
    driver ||--o{ driver_commission : "remunerado_por"

    department ||--o{ position : "contém"
    "user" ||--o{ sale : "cria"
    "user" ||--o{ operation_history : "altera"
    "user" ||--o{ ai_interactions : "usa"
    "user" ||--o{ audit_log : "registra"
