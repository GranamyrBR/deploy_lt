-- Fix AI usage metrics RLS policy
-- This migration fixes the row-level security policy violation for ai_usage_metrics table

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can view own usage metrics" ON ai_usage_metrics;
DROP POLICY IF EXISTS "Users can insert own usage metrics" ON ai_usage_metrics;

-- Create proper RLS policies for ai_usage_metrics
CREATE POLICY "Users can view own usage metrics" 
    ON ai_usage_metrics FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own usage metrics" 
    ON ai_usage_metrics FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own usage metrics" 
    ON ai_usage_metrics FOR UPDATE 
    USING (auth.uid() = user_id) 
    WITH CHECK (auth.uid() = user_id);

-- Grant necessary permissions
GRANT SELECT ON ai_usage_metrics TO authenticated;
GRANT INSERT ON ai_usage_metrics TO authenticated;
GRANT UPDATE ON ai_usage_metrics TO authenticated;

-- Fix AI interactions RLS policy
DROP POLICY IF EXISTS "Users can view own interactions" ON ai_interactions;
DROP POLICY IF EXISTS "Users can insert own interactions" ON ai_interactions;

CREATE POLICY "Users can view own interactions" 
    ON ai_interactions FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own interactions" 
    ON ai_interactions FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Grant necessary permissions for AI tables
GRANT SELECT ON ai_interactions TO authenticated;
GRANT INSERT ON ai_interactions TO authenticated;

GRANT SELECT ON ai_errors TO authenticated;
GRANT INSERT ON ai_errors TO authenticated;

GRANT SELECT ON ai_conversation_history TO authenticated;
GRANT INSERT ON ai_conversation_history TO authenticated;

GRANT SELECT ON ai_rate_limit_tracking TO authenticated;
GRANT INSERT ON ai_rate_limit_tracking TO authenticated;
GRANT UPDATE ON ai_rate_limit_tracking TO authenticated;

-- Grant basic read access to anon for public tables that might be referenced
GRANT SELECT ON sale TO anon;
GRANT SELECT ON sale_item TO anon;
GRANT SELECT ON contact TO anon;
GRANT SELECT ON product_category TO anon;
GRANT SELECT ON "user" TO anon;