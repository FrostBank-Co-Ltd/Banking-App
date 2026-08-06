-- ====================================================================
-- Comprehensive Supabase Patch (Full RLS Lockdown)
-- Run this script in your Supabase SQL Editor.
-- This script drops ALL insecure policies and applies strict RLS.
-- ====================================================================

-- 1. Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_saves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.split_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.split_bill_participants ENABLE ROW LEVEL SECURITY;

-- 2. Drop the old insecure policies (USING true)
DROP POLICY IF EXISTS "Allow read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow read accounts" ON public.accounts;
DROP POLICY IF EXISTS "Allow read cards" ON public.cards;
DROP POLICY IF EXISTS "Allow read transactions" ON public.transactions;
DROP POLICY IF EXISTS "Allow read promos" ON public.promos;
DROP POLICY IF EXISTS "Allow read goal_saves" ON public.goal_saves;
DROP POLICY IF EXISTS "Allow read goal_transactions" ON public.goal_transactions;
DROP POLICY IF EXISTS "Allow read split_bills" ON public.split_bills;
DROP POLICY IF EXISTS "Allow read split_bill_participants" ON public.split_bill_participants;

DROP POLICY IF EXISTS "Allow write profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow write accounts" ON public.accounts;
DROP POLICY IF EXISTS "Allow write cards" ON public.cards;
DROP POLICY IF EXISTS "Allow write transactions" ON public.transactions;
DROP POLICY IF EXISTS "Allow write goal_saves" ON public.goal_saves;
DROP POLICY IF EXISTS "Allow write goal_transactions" ON public.goal_transactions;
DROP POLICY IF EXISTS "Allow write split_bills" ON public.split_bills;
DROP POLICY IF EXISTS "Allow write split_bill_participants" ON public.split_bill_participants;

-- 3. Create new Secure Policies
CREATE POLICY "Allow read profiles" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Allow read accounts" ON public.accounts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow read cards" ON public.cards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow read transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow read promos" ON public.promos FOR SELECT USING (true);
CREATE POLICY "Allow read goal_saves" ON public.goal_saves FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow read goal_transactions" ON public.goal_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow read split_bills" ON public.split_bills FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow read split_bill_participants" ON public.split_bill_participants FOR SELECT USING (EXISTS (SELECT 1 FROM public.split_bills WHERE id = bill_id AND user_id = auth.uid()));

CREATE POLICY "Allow write profiles" ON public.profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "Allow write accounts" ON public.accounts FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Allow write cards" ON public.cards FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Allow write transactions" ON public.transactions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Allow write goal_saves" ON public.goal_saves FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Allow write goal_transactions" ON public.goal_transactions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Allow write split_bills" ON public.split_bills FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Allow write split_bill_participants" ON public.split_bill_participants FOR ALL USING (EXISTS (SELECT 1 FROM public.split_bills WHERE id = bill_id AND user_id = auth.uid()));
