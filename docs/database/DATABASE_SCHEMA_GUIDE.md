# LeCotour Dashboard - Database Schema Guide

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Database Architecture](#database-architecture)
3. [Core Business Modules](#core-business-modules)
4. [Entity Relationship Summary](#entity-relationship-summary)
5. [Key Tables Reference](#key-tables-reference)
6. [Business Logic & Workflows](#business-logic--workflows)

---

## 🎯 Project Overview

**LeCotour Dashboard** is a comprehensive travel/tourism operations management system built with Flutter and Supabase (PostgreSQL). The system manages:

- **B2B & B2C Travel Operations** (agencies, clients, services)
- **Sales & Quotation Management** (proposals, invoicing, payments)
- **Operational Logistics** (drivers, vehicles, scheduling)
- **Customer Relationship Management** (contacts, interactions, rankings)
- **Financial Tracking** (multi-currency, commissions, cost centers)
- **AI-Powered Assistant** (conversation history, analytics)
- **Integration Hub** (WhatsApp, Google Calendar, Flight APIs)

---

## 🏗️ Database Architecture

### Database Stats
- **Total Tables**: ~80+ tables
- **Database Type**: PostgreSQL (via Supabase)
- **Key Features**: Row Level Security (RLS), Triggers, JSON support, Spatial data (PostGIS)

### Table Categories

#### 1. **Core Business Entities** (16 tables)
- `account`, `contact`, `user`, `sale`, `operation`, `product`, `service`

#### 2. **CRM & Account Management** (10 tables)
- `account_*` prefixed tables for client ranking, interactions, opportunities

#### 3. **Financial & Payment** (8 tables)
- `sale_payment`, `invoice`, `currency`, `exchange_rate_history`, `cost_center`

#### 4. **Operations & Logistics** (10 tables)
- `driver`, `car`, `operation_history`, `flight_data`, `driver_commission`

#### 5. **AI Assistant** (5 tables)
- `ai_interactions`, `ai_conversation_history`, `ai_usage_metrics`, `ai_errors`

#### 6. **Integration & API** (6 tables)
- `api_configuration`, `api_log`, `api_integration`, `flight_cache`

#### 7. **Audit & Compliance** (3 tables)
- `audit_log`, `quotation_audit_log`, `operation_history`

#### 8. **Supporting Data** (20+ tables)
- Reference data, backups, caches, and helper tables

---

## 🎯 Core Business Modules

### Module 1: Contact & Account Management

#### **contact** (Primary Customer/Lead Table)
```sql
PRIMARY KEY: phone (character varying)
UNIQUE: id (integer, auto-generated)
```

**Key Fields:**
- `name`, `email`, `phone` (PK), `address`, `city`, `state`, `country`
- `user_type` (enum): 'normal', 'agency', 'driver', etc.
- `is_vip` (boolean): VIP client flag
- `source_id` → links to lead source
- `account_id` → links to B2B account
- `contact_category_id` → customer segmentation

**Special Notes:**
- Uses **phone as primary key** (unique identifier across system)
- Supports multiple contact types via `user_type` enum
- Integration with `leadstintim` (WhatsApp leads) and `monday` (CRM)

#### **account** (B2B Corporate Accounts)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `name`, `domain`, `email`, `phone`, `logo_url`
- `chave_id` → links to `account_category`
- `is_active`: soft delete flag

**Related Tables:**
- `account_employee`: Contact persons within account
- `account_client_ranking`: Client scoring & categorization (bronze → diamond)
- `account_opportunity`: Sales pipeline tracking
- `account_interaction_log`: CRM activity log
- `account_task`: Follow-up tasks
- `account_document`: Contract/proposal storage
- `account_communication_preferences`: Communication settings
- `account_performance_metrics`: KPI tracking

---

### Module 2: Sales & Quotation Management

#### **sale** (Sales Transactions)
```sql
PRIMARY KEY: id (integer)
```

**Key Fields:**
- `customer_id` → contact(id)
- `seller_id` → user(id)
- `total_value_usd`, `total_value_brl`
- `currency_id` → currency table
- `sale_status`: 'pending', 'confirmed', 'completed', 'cancelled'
- `payment_status`: 'pending', 'partial', 'paid', 'refunded'
- `discount_percentage`, `discount_amount_usd`
- `payment_date`, `notes`

**Related Tables:**
- `sale_item`: Line items (products/services)
- `sale_payment`: Payment transactions
- `sale_item_detail`: Additional item metadata

#### **quotation** (Price Proposals)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `quotation_number`: Auto-generated unique ID (e.g., "QT-2025-56356")
- `contact_phone` → contact(phone)
- `total_usd`, `total_brl`
- `status`: 'draft', 'sent', 'accepted', 'rejected', 'expired'
- `valid_until`: Expiration date
- `pdf_url`: Generated proposal document
- `whatsapp_sent`: Integration flag

**Related Tables:**
- `quotation_item`: Services/products in quote
- `quotation_audit_log`: Version history & changes
- `pre_trip_action`: Scheduled follow-ups

#### **invoice** (Billing Documents)
```sql
PRIMARY KEY: id (integer)
```

**Key Fields:**
- `sale_id` → sale(id)
- `invoice_number`: Unique invoice ID
- `total_amount`, `due_date`
- `status`: 'pending', 'paid', 'overdue', 'cancelled'

---

### Module 3: Operations & Logistics

#### **operation** (Service Execution)
```sql
PRIMARY KEY: id (bigint)
```

**Core Concept**: Each sale item becomes an operation (e.g., airport transfer, tour)

**Key Fields:**
- `sale_id`, `sale_item_id`, `customer_id`
- `service_id`, `product_id` (what's being delivered)
- `driver_id`, `car_id` (resources assigned)
- `scheduled_date`, `actual_start_time`, `actual_end_time`
- `pickup_location`, `dropoff_location` (text + coordinates)
- `pickup_location_id`, `dropoff_location_id` → `locations` table
- `status`: 'pending', 'assigned', 'in_progress', 'completed', 'cancelled'
- `service_value_usd`: Operation revenue
- `driver_commission_usd`: Driver payout

**Integration Fields:**
- `whatsapp_message_id`: Notification tracking
- `google_calendar_event_id`: Calendar sync
- `customer_rating`, `driver_rating`: Feedback (1-5)

**Related Tables:**
- `operation_history`: Complete audit trail
- `flight_data`: Flight details for airport transfers
- `driver_commission`: Commission payments
- `api_integration`: External API calls (Uber, Lyft, etc.)

#### **driver** (Service Providers)
```sql
PRIMARY KEY: id (integer)
```

**Key Fields:**
- `name`, `email`, `phone`, `city_name`
- `photo_url`, `is_active`

**Related Tables:**
- `driver_car`: Vehicle assignments
- `driver_service`: Qualified services
- `driver_commission`: Earnings tracking

#### **car** (Fleet Management)
```sql
PRIMARY KEY: id (integer)
```

**Key Fields:**
- `make`, `model`, `year`, `color`, `license_plate` (unique)
- `capacity`, `price_usd`
- `photo_url`, `has_wifi`
- `price_source`, `price_status`: Dynamic pricing metadata

---

### Module 4: Product & Service Catalog

#### **service** (Service Offerings)
```sql
PRIMARY KEY: id (integer)
```

**Key Fields:**
- `service_name`, `description`
- `service_type_id` → `service_type` (categorization)
- `price_usd`, `max_pax` (passenger capacity)
- `is_active`, `created_by_user_id`

#### **product** (Ticketed Products)
```sql
PRIMARY KEY: product_id (integer)
```

**Key Fields:**
- `product_name`, `description`
- `price_per_unit`, `currency_id`
- `product_category_id` → `product_category`
- `stock_quantity`, `site_url`
- `is_active`

#### **service_configuration** (Business Rules)
```sql
PRIMARY KEY: id (bigint)
```

**Dynamic Pricing Rules:**
- `service_id`, `vehicle_type`, `route_type`
- `base_price_usd`, `additional_passenger_fee`
- `peak_hour_multiplier`, `weekend_multiplier`
- `min_price_usd`, `max_price_usd`
- `commission_percentage`

---

### Module 5: Financial Management

#### **currency** (Multi-Currency Support)
```sql
PRIMARY KEY: currency_id (integer)
```

**Key Fields:**
- `currency_code`: 'USD', 'BRL', 'EUR', etc.
- `currency_name`: Full name
- `exchange_rate_to_usd`: Conversion rate
- `is_active`

#### **exchange_rate_history** (Rate Tracking)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `currency_code`, `rate_to_usd`, `rate_date`
- `source`: 'banco_central_brasil', etc.

#### **cost_center** (Budget Management)
```sql
PRIMARY KEY: id (text, UUID)
```

**Key Fields:**
- `code`, `name`, `department`, `responsible`
- `budget`, `utilized`: Budget tracking
- `is_active`

**Related Tables:**
- `cost_center_expense`: Expense transactions
- `cost_center_category`: Expense classification

#### **sale_payment** (Payment Transactions)
```sql
PRIMARY KEY: sales_payments_id (integer)
```

**Key Fields:**
- `sale_id` → sale(id)
- `payment_amount`, `currency_id`
- `payment_method_id` → payment_method
- `payment_date`, `payment_status`
- `transaction_reference`

---

### Module 6: AI Assistant

#### **ai_interactions** (AI Chat Sessions)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `user_id` → user(id)
- `conversation_id`: Session identifier
- `request_message`, `response_message`
- `model`: AI model used
- `tokens_used`, `response_time_ms`

**Related Tables:**
- `ai_conversation_history`: Full message log
- `ai_usage_metrics`: Daily aggregates
- `ai_errors`: Error tracking
- `ai_rate_limit_tracking`: Usage throttling

---

### Module 7: Integration & APIs

#### **api_configuration** (External APIs)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `api_name`: Unique identifier
- `base_url`, `api_key_encrypted`
- `auth_type`: 'api_key', 'oauth2', 'bearer', 'basic'
- `requests_per_minute`, `requests_per_hour`, `requests_per_day`
- `is_active`, `is_test_mode`

#### **api_log** (API Call History)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `api_configuration_id`, `endpoint`, `method`
- `request_headers`, `request_body` (jsonb)
- `response_status`, `response_body` (jsonb)
- `response_time_ms`, `error_message`
- `status`: 'pending', 'success', 'failed', 'timeout', 'rate_limited'

#### **flight_data** (Flight Tracking)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `operation_id` → operation(id)
- `flight_number`, `airline_code`
- `departure_airport_code`, `arrival_airport_code`
- `scheduled_departure_time`, `actual_departure_time`
- `flight_status`: 'scheduled', 'boarding', 'departed', 'arrived', 'delayed', 'cancelled'
- `flightaware_flight_id`, `flightaware_data` (jsonb)

#### **flight_cache** (Flight Data Cache)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `cache_key`, `flight_data` (jsonb)
- `expires_at`, `is_valid`

---

### Module 8: Reference Data

#### **source** (Lead Sources)
```sql
PRIMARY KEY: id (integer)
```

**Key Fields:**
- `name`: 'WhatsApp', 'Website', 'Referral', 'Agency', etc.
- `description`, `is_active`

#### **airport** (Airport Database)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `iata_code`, `icao_code`, `name`
- `city`, `state`, `country`
- `latitude`, `longitude`, `timezone`
- `is_major_airport`

#### **airline** (Airline Database)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `iata_code`, `icao_code`, `name`
- `country`, `is_active`

#### **locations** (Geocoded Addresses)
```sql
PRIMARY KEY: id (uuid)
```

**Key Fields:**
- `address`, `coordinates` (PostGIS point)
- `city`, `state`, `country`, `postcode`
- `display_name`, `establishment_name`

---

### Module 9: Audit & Compliance

#### **audit_log** (System-Wide Audit Trail)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `table_name`, `record_id`
- `operation_type`: 'INSERT', 'UPDATE', 'DELETE', 'SOFT_DELETE'
- `user_id`, `user_name`, `user_email`
- `old_values`, `new_values` (jsonb)
- `changed_fields`: Array of modified columns
- `ip_address`, `user_agent`
- `operation_timestamp`

#### **quotation_audit_log** (Quotation Versioning)
```sql
PRIMARY KEY: id (bigint)
```

**Key Fields:**
- `quotation_id` → quotation(id)
- `action_type`: 'created', 'updated', 'sent', 'accepted', 'rejected'
- `changed_by_user_id`, `changed_by_name`
- `changes` (jsonb): Detailed change log

---

## 🔗 Entity Relationship Summary

### Primary Relationships

```
USER (auth)
  └─> CONTACT (customers/leads)
       ├─> SALE (transactions)
       │    ├─> SALE_ITEM (line items)
       │    │    └─> OPERATION (service execution)
       │    │         ├─> DRIVER (assigned provider)
       │    │         ├─> CAR (assigned vehicle)
       │    │         ├─> FLIGHT_DATA (flight info)
       │    │         └─> OPERATION_HISTORY (audit trail)
       │    └─> SALE_PAYMENT (payments)
       └─> QUOTATION (price proposals)
            └─> QUOTATION_ITEM (quoted items)

ACCOUNT (B2B clients)
  ├─> ACCOUNT_EMPLOYEE (contact persons)
  ├─> ACCOUNT_OPPORTUNITY (sales pipeline)
  ├─> ACCOUNT_INTERACTION_LOG (CRM activities)
  └─> ACCOUNT_CLIENT_RANKING (scoring)

SERVICE (catalog)
  ├─> SERVICE_TYPE (categorization)
  └─> SERVICE_CONFIGURATION (pricing rules)

PRODUCT (catalog)
  └─> PRODUCT_CATEGORY (categorization)
```

### Key Foreign Key Chains

1. **Sales to Operations Flow:**
   ```
   CONTACT → SALE → SALE_ITEM → OPERATION → DRIVER_COMMISSION
   ```

2. **B2B Account Flow:**
   ```
   ACCOUNT → ACCOUNT_EMPLOYEE → ACCOUNT_OPPORTUNITY → SALE
   ```

3. **Financial Flow:**
   ```
   SALE → SALE_PAYMENT → PAYMENT_METHOD
   SALE → INVOICE
   OPERATION → DRIVER_COMMISSION
   ```

4. **Integration Flow:**
   ```
   OPERATION → FLIGHT_DATA → FLIGHT_CACHE
   OPERATION → API_INTEGRATION → API_LOG
   ```

---

## 📊 Key Tables Reference

### Contact Classification

**user_type Enum Values:**
- `normal`: Regular customer
- `agency`: B2B travel agency
- `driver`: Service provider
- `employee`: Internal staff
- `vip`: VIP client

### Status Enums

**Sale Status:**
- `pending`, `confirmed`, `completed`, `cancelled`

**Payment Status:**
- `pending`, `partial`, `paid`, `refunded`, `overdue`

**Operation Status:**
- `pending`, `assigned`, `in_progress`, `completed`, `cancelled`, `failed`

**Quotation Status:**
- `draft`, `sent`, `accepted`, `rejected`, `expired`

**Flight Status:**
- `scheduled`, `boarding`, `departed`, `arrived`, `delayed`, `cancelled`, `diverted`

### Ranking Categories (B2B Clients)

**account_client_ranking.ranking_category:**
- `bronze`, `silver`, `gold`, `platinum`, `diamond`

Based on:
- Total revenue (USD/BRL)
- Total operations count
- Average ticket value
- Customer satisfaction score
- Payment reliability score
- Relationship duration

---

## 💼 Business Logic & Workflows

### Workflow 1: Lead to Sale Conversion

1. **Lead Capture**: `leadstintim` (WhatsApp) or `monday` (CRM) → `contact`
2. **Quotation**: Create `quotation` + `quotation_item`
3. **Approval**: Update `quotation.status` → 'accepted'
4. **Sale Creation**: Convert to `sale` + `sale_item`
5. **Operation Creation**: Each `sale_item` → `operation`
6. **Execution**: Assign `driver`, update `operation.status`
7. **Payment**: Record `sale_payment`
8. **Completion**: Update `sale.sale_status` → 'completed'

### Workflow 2: Operation Execution

1. **Creation**: `operation` created from `sale_item`
2. **Assignment**: 
   - Assign `driver_id`, `car_id`
   - Create `google_calendar_event_id`
   - Send `whatsapp_message_id`
3. **Tracking**:
   - Update `operation.status` → 'assigned' → 'in_progress' → 'completed'
   - Log changes in `operation_history`
4. **Flight Integration** (if applicable):
   - Create `flight_data` record
   - Cache data in `flight_cache`
   - Update via `api_integration`
5. **Completion**:
   - Record `customer_rating`, `driver_rating`
   - Calculate `driver_commission`
   - Create `driver_commission` record

### Workflow 3: B2B Account Management

1. **Account Creation**: `account` + `account_category`
2. **Contact Management**: `account_employee` (multiple contacts)
3. **Opportunity Tracking**: `account_opportunity` (sales pipeline)
4. **Interaction Logging**: `account_interaction_log` (calls, emails, meetings)
5. **Task Management**: `account_task` (follow-ups)
6. **Performance Tracking**: 
   - `account_client_ranking` (scoring)
   - `account_performance_metrics` (KPIs)

### Workflow 4: Multi-Currency Sales

1. **Configuration**: `currency` table with `exchange_rate_to_usd`
2. **Historical Tracking**: `exchange_rate_history` (daily rates)
3. **Sale Creation**: 
   - Record in primary currency (`currency_id`)
   - Store `total_value_usd` AND `total_value_brl`
4. **Payment**: 
   - `sale_payment.currency_id`
   - Convert to USD for reporting
5. **Commission Calculation**:
   - `driver_commission_usd`, `driver_commission_brl`
   - Use `exchange_rate_to_usd` at payment time

---

## 🔍 Special Features

### 1. Phone-Based Primary Key
- `contact` table uses `phone` as PRIMARY KEY
- Ensures unique customer identification
- Simplifies WhatsApp integration
- Indexed for performance

### 2. JSONB Support
- `api_log.request_body`, `api_log.response_body`
- `flight_data.flightaware_data`
- `audit_log.old_values`, `audit_log.new_values`
- Flexible schema for integrations

### 3. PostGIS Spatial Data
- `locations.coordinates` (point type)
- `operation.pickup_coordinates`, `operation.dropoff_coordinates`
- Enables distance calculations, mapping

### 4. Soft Deletes
- Most tables have `is_active` boolean
- `audit_log` tracks 'SOFT_DELETE' operations
- Data preservation for compliance

### 5. Audit Trails
- `audit_log`: System-wide change tracking
- `operation_history`: Operation-specific timeline
- `quotation_audit_log`: Quotation versioning
- Complete accountability

### 6. Rate Limiting
- `api_configuration`: Requests per minute/hour/day
- `ai_rate_limit_tracking`: AI usage throttling
- Protects external API quotas

### 7. Caching Strategy
- `flight_cache`: Flight data caching with TTL
- `contact_user_type_cache`: Performance optimization
- `airline_favicons`: Logo/icon storage

---

## 📈 Performance Optimizations

### Indexes (Implied by Schema)

**Primary Keys** (automatic indexes):
- All `id` columns
- `contact.phone`
- `airline.iata_code`
- `airport.iata_code`

**Unique Constraints** (automatic indexes):
- `contact.id`, `car.license_plate`
- `invoice.invoice_number`
- `quotation.quotation_number`
- `flight_cache.cache_key`

**Foreign Keys** (recommend manual indexes):
- `sale.customer_id`, `sale.seller_id`
- `operation.sale_id`, `operation.driver_id`
- `sale_item.sale_id`, `sale_item.service_id`

### Query Optimization Tips

1. **Use phone lookups for contacts**:
   ```sql
   SELECT * FROM contact WHERE phone = '+1234567890';
   ```

2. **Filter by date ranges**:
   ```sql
   SELECT * FROM sale WHERE created_at >= '2025-01-01';
   ```

3. **Use JSONB operators for API logs**:
   ```sql
   SELECT * FROM api_log WHERE response_body->>'status' = 'success';
   ```

4. **Leverage materialized views for metrics** (not in schema, but recommended):
   ```sql
   CREATE MATERIALIZED VIEW daily_sales_summary AS ...
   ```

---

## 🚀 Integration Points

### External Systems

1. **WhatsApp (Tintim)**:
   - `leadstintim` table: Lead capture
   - `operation.whatsapp_message_id`: Notifications
   - `quotation.whatsapp_sent`: Proposal delivery

2. **Google Calendar**:
   - `operation.google_calendar_event_id`: Event sync
   - `google_calendar_event` table: Event metadata

3. **FlightAware**:
   - `flight_data.flightaware_flight_id`: Flight tracking
   - `flight_cache`: Caching layer
   - `api_integration`: API call logs

4. **Monday.com (CRM)**:
   - `monday` table: CRM data sync
   - `monday_backup`: Historical data

5. **Payment Gateways** (implied):
   - `sale_payment.transaction_reference`
   - `payment_method` table

---

## 🛠️ Development Guidelines

### Adding New Features

1. **New Table**: Follow naming conventions (`snake_case`)
2. **Foreign Keys**: Always add constraints
3. **Audit Trail**: Consider adding to `audit_log`
4. **Timestamps**: Include `created_at`, `updated_at`
5. **Soft Deletes**: Use `is_active` boolean
6. **User Tracking**: Add `created_by_user_id`, `updated_by_user_id`

### Migration Best Practices

1. **Backup First**: Create backup tables (`backup_*` prefix)
2. **Add Columns**: Use `ALTER TABLE ... ADD COLUMN ... DEFAULT ...`
3. **Data Migration**: Use `UPDATE` statements with `WHERE` clauses
4. **Constraints**: Add constraints AFTER data is clean
5. **Test Queries**: Run `SELECT` before `UPDATE`
6. **Rollback Plan**: Document reverse migration

### Common Queries

**Get customer sales history:**
```sql
SELECT s.*, si.* 
FROM sale s
JOIN sale_item si ON si.sale_id = s.id
WHERE s.customer_id = (SELECT id FROM contact WHERE phone = '+1234567890')
ORDER BY s.created_at DESC;
```

**Get active operations for a driver:**
```sql
SELECT o.*, c.name as customer_name, s.service_name
FROM operation o
JOIN contact c ON c.id = o.customer_id
JOIN service s ON s.id = o.service_id
WHERE o.driver_id = 123 
  AND o.status IN ('assigned', 'in_progress')
ORDER BY o.scheduled_date;
```

**Calculate monthly revenue:**
```sql
SELECT 
  DATE_TRUNC('month', created_at) as month,
  SUM(total_value_usd) as revenue_usd,
  COUNT(*) as sale_count
FROM sale
WHERE sale_status = 'completed'
GROUP BY month
ORDER BY month DESC;
```

**Get pending driver commissions:**
```sql
SELECT dc.*, d.name as driver_name, o.scheduled_date
FROM driver_commission dc
JOIN driver d ON d.id = dc.driver_id
JOIN operation o ON o.id = dc.operation_id
WHERE dc.payment_status = 'pending'
ORDER BY o.scheduled_date;
```

---

## 📝 Notes & Observations

### Schema Strengths
✅ Comprehensive audit trails  
✅ Multi-currency support  
✅ Flexible JSONB for integrations  
✅ Clear separation of concerns  
✅ B2B and B2C support  
✅ Strong referential integrity  

### Potential Improvements
⚠️ Consider adding composite indexes for common queries  
⚠️ Add database-level triggers for `updated_at` columns  
⚠️ Implement row-level security (RLS) policies  
⚠️ Add check constraints for email format, phone format  
⚠️ Consider partitioning large tables (audit_log, api_log) by date  
⚠️ Add full-text search indexes on `name`, `description` fields  

### Backup Tables (Present in Schema)
- `backup_country_fix_20250127`
- `backup_country_normalization`
- `backup_drivers_contact_removal`
- `contact_backup_*` (multiple versions)

These indicate active development and careful data migration practices.

---

## 📚 Additional Resources

- **Supabase Documentation**: For RLS, triggers, and realtime features
- **PostGIS Documentation**: For spatial queries
- **Flutter Supabase Client**: For realtime subscriptions
- **Migration Files**: See `/supabase/migrations/` for schema evolution

---

**Document Version**: 1.0  
**Generated**: 2025  
**Maintainer**: Development Team  
**Last Updated**: Based on current DB schema

---

## Quick Reference Tables

### Most Important Tables (Top 10)

| Table | Purpose | Key Relationships |
|-------|---------|-------------------|
| `contact` | Customer/Lead master | → sale, quotation, operation |
| `sale` | Sales transactions | ← contact, → sale_item, sale_payment |
| `operation` | Service execution | ← sale_item, → driver, car, flight_data |
| `account` | B2B corporate clients | → account_employee, account_opportunity |
| `quotation` | Price proposals | ← contact, → quotation_item |
| `driver` | Service providers | ← operation, driver_commission |
| `service` | Service catalog | ← sale_item, operation |
| `product` | Product catalog | ← sale_item, operation |
| `user` | System users | → sale, operation, account_task |
| `audit_log` | Change tracking | All tables |

---

*For questions or updates to this documentation, please contact the development team.*
