-- Comprehensive RLS policy fix for AI tables
-- This script removes all existing conflicting policies and creates clean ones

-- First, let's see what policies exist on all AI tables
DO $$
DECLARE
    table_name text;
    policy_record record;
BEGIN
    -- Loop through all AI tables
    FOR table_name IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename LIKE 'ai_%'
    LOOP
        RAISE NOTICE 'Policies on table %:', table_name;
        FOR policy_record IN
            SELECT polname, polcmd 
            FROM pg_policy 
            WHERE polrelid = (quote_ident(table_name))::regclass
        LOOP
            RAISE NOTICE '  Policy: % (%)', policy_record.polname, policy_record.polcmd;
        END LOOP;
    END LOOP;
END $$;

-- Drop ALL existing policies on AI tables to start fresh
DO $$
DECLARE
    table_name text;
    policy_name text;
BEGIN
    -- Loop through all AI tables
    FOR table_name IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename LIKE 'ai_%'
    LOOP
        -- Drop all policies on this table
        FOR policy_name IN
            SELECT polname
            FROM pg_policy 
            WHERE polrelid = (quote_ident(table_name))::regclass
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_name, table_name);
        END LOOP;
    END LOOP;
END $$;

-- Now create clean, simple policies for all AI tables
-- Policy: Allow authenticated users to do everything on AI tables

-- ai_usage_metrics
CREATE POLICY "Allow authenticated full access" ON ai_usage_metrics
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ai_interactions  
CREATE POLICY "Allow authenticated full access" ON ai_interactions
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ai_errors
CREATE POLICY "Allow authenticated full access" ON ai_errors
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ai_conversation_history
CREATE POLICY "Allow authenticated full access" ON ai_conversation_history
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ai_rate_limit_tracking
CREATE POLICY "Allow authenticated full access" ON ai_rate_limit_tracking
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Grant explicit permissions to ensure access
GRANT ALL ON ai_usage_metrics TO authenticated;
GRANT ALL ON ai_interactions TO authenticated;
GRANT ALL ON ai_errors TO authenticated;
GRANT ALL ON ai_conversation_history TO authenticated;
GRANT ALL ON ai_rate_limit_tracking TO authenticated;

-- Also grant basic permissions to anon for read operations
GRANT SELECT ON ai_usage_metrics TO anon;
GRANT SELECT ON ai_interactions TO anon;
GRANT SELECT ON ai_errors TO anon;
GRANT SELECT ON ai_conversation_history TO anon;
GRANT SELECT ON ai_rate_limit_tracking TO anon;

-- Verify the policies were created correctly
SELECT tablename, 
       (SELECT COUNT(*) FROM pg_policy WHERE polrelid = pg_tables.tablename::regclass) as policy_count
FROM pg_tables 
WHERE schemaname = 'public' AND tablename LIKE 'ai_%'
ORDER BY tablename;