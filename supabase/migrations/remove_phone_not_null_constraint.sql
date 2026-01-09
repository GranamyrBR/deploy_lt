-- ============================================
-- Remove constraint conflitante que exige phone NOT NULL
-- ============================================

ALTER TABLE leadstintim 
DROP CONSTRAINT leadstintim_phone_not_empty;
