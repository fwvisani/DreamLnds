-- Drop all existing tables in the public schema
-- This will permanently delete all data

DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.privacy_settings CASCADE;
DROP TABLE IF EXISTS public.user_consents CASCADE;
DROP TABLE IF EXISTS public.trend_classifications CASCADE;
DROP TABLE IF EXISTS public.agent_communications CASCADE;
DROP TABLE IF EXISTS public.trend_sources CASCADE;
DROP TABLE IF EXISTS public.agent_types CASCADE;
DROP TABLE IF EXISTS public.data_sources CASCADE;
DROP TABLE IF EXISTS public.trend_scores CASCADE;
DROP TABLE IF EXISTS public.subscriptions CASCADE;
DROP TABLE IF EXISTS public.trends CASCADE;
DROP TABLE IF EXISTS public.agents CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
