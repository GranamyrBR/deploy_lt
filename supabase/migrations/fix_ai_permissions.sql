-- Fix RLS policies for AI tables to ensure proper permissions

-- Grant permissions for ai_errors table
GRANT ALL ON ai_errors TO authenticated;
GRANT SELECT ON ai_errors TO anon;

-- Grant permissions for ai_interactions table
GRANT ALL ON ai_interactions TO authenticated;
GRANT SELECT ON ai_interactions TO anon;

-- Grant permissions for ai_conversation_history table
GRANT ALL ON ai_conversation_history TO authenticated;
GRANT SELECT ON ai_conversation_history TO anon;

-- Grant permissions for ai_usage_metrics table
GRANT ALL ON ai_usage_metrics TO authenticated;
GRANT SELECT ON ai_usage_metrics TO anon;

-- Grant permissions for ai_rate_limit_tracking table
GRANT ALL ON ai_rate_limit_tracking TO authenticated;
GRANT SELECT ON ai_rate_limit_tracking TO anon;

-- Create a more permissive policy for ai_errors to allow error logging
ALTER TABLE ai_errors ENABLE ROW LEVEL SECURITY;

-- Policy for inserting errors (allow users to log their own errors)
CREATE POLICY "Users can insert their own AI errors" ON ai_errors
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy for viewing errors (users can view their own errors)
CREATE POLICY "Users can view their own AI errors" ON ai_errors
    FOR SELECT USING (auth.uid() = user_id);

-- Policy for all operations on ai_errors for authenticated users
CREATE POLICY "Authenticated users can manage AI errors" ON ai_errors
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Similar policies for other AI tables
ALTER TABLE ai_interactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their AI interactions" ON ai_interactions
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE ai_conversation_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their AI conversation history" ON ai_conversation_history
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE ai_usage_metrics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view AI usage metrics" ON ai_usage_metrics
    FOR SELECT TO authenticated USING (true);

ALTER TABLE ai_rate_limit_tracking ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their rate limit tracking" ON ai_rate_limit_tracking
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);