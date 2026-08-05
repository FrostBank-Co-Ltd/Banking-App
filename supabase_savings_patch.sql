-- ====================================================================
-- Incremental Patch for Existing Supabase Databases
-- Run this snippet in your Supabase SQL Editor to add the Savings Goal feature.
-- ====================================================================

-- 1. Create goal_saves table
CREATE TABLE IF NOT EXISTS public.goal_saves (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  emoji TEXT NOT NULL,
  target_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  currency_code TEXT NOT NULL DEFAULT 'USD',
  daily_rate_percent NUMERIC(10,6) NOT NULL DEFAULT 0.011918,
  interest_earned NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL CHECK (status IN ('active', 'closed')) DEFAULT 'active'
);

-- 2. Create goal_transactions table
CREATE TABLE IF NOT EXISTS public.goal_transactions (
  id TEXT PRIMARY KEY,
  goal_id TEXT NOT NULL REFERENCES public.goal_saves(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('transferIn', 'transferOut', 'interest')),
  amount NUMERIC(12,2) NOT NULL,
  running_balance NUMERIC(12,2) NOT NULL,
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  note TEXT
);

-- 3. Enable RLS & Security Policies
ALTER TABLE public.goal_saves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read goal_saves" ON public.goal_saves FOR SELECT USING (true);
CREATE POLICY "Allow write goal_saves" ON public.goal_saves FOR ALL USING (true);
CREATE POLICY "Allow read goal_transactions" ON public.goal_transactions FOR SELECT USING (true);
CREATE POLICY "Allow write goal_transactions" ON public.goal_transactions FOR ALL USING (true);

-- 4. Seed Goal Saves Data
INSERT INTO public.goal_saves (id, name, emoji, target_amount, balance, currency_code, daily_rate_percent, interest_earned, created_at, status)
VALUES
  ('goal_emergency', 'Emergency Fund', 'shield', 10000.00, 6420.50, 'USD', 0.011918, 28.14, NOW() - INTERVAL '198 days', 'active'),
  ('goal_europe', 'Europe Trip', 'flight', 5000.00, 1875.30, 'USD', 0.011918, 4.82, NOW() - INTERVAL '47 days', 'active'),
  ('goal_gadget', 'New Laptop', 'laptop', 2200.00, 2200.00, 'USD', 0.011918, 9.36, NOW() - INTERVAL '120 days', 'active')
ON CONFLICT (id) DO UPDATE SET
  balance = EXCLUDED.balance,
  interest_earned = EXCLUDED.interest_earned;

-- 5. Seed Goal Transactions Data
INSERT INTO public.goal_transactions (id, goal_id, kind, amount, running_balance, date, note)
VALUES
  ('gtxn_001', 'goal_emergency', 'transferIn', 5000.00, 5000.00, NOW() - INTERVAL '198 days', 'Initial deposit'),
  ('gtxn_002', 'goal_emergency', 'interest', 0.60, 5000.60, NOW() - INTERVAL '197 days', NULL),
  ('gtxn_003', 'goal_emergency', 'transferIn', 1400.00, 6400.60, NOW() - INTERVAL '90 days', 'Top up'),
  ('gtxn_004', 'goal_emergency', 'interest', 19.90, 6420.50, NOW() - INTERVAL '1 day', 'Daily interest'),
  ('gtxn_005', 'goal_europe', 'transferIn', 1000.00, 1000.00, NOW() - INTERVAL '47 days', 'Initial deposit'),
  ('gtxn_006', 'goal_europe', 'interest', 0.12, 1000.12, NOW() - INTERVAL '46 days', NULL),
  ('gtxn_007', 'goal_europe', 'transferIn', 875.00, 1875.12, NOW() - INTERVAL '20 days', 'Monthly save'),
  ('gtxn_008', 'goal_europe', 'interest', 0.18, 1875.30, NOW() - INTERVAL '1 day', 'Daily interest'),
  ('gtxn_009', 'goal_gadget', 'transferIn', 1000.00, 1000.00, NOW() - INTERVAL '120 days', 'Initial deposit'),
  ('gtxn_010', 'goal_gadget', 'transferIn', 1200.00, 2200.00, NOW() - INTERVAL '60 days', 'Goal top up'),
  ('gtxn_011', 'goal_gadget', 'interest', 9.36, 2200.00, NOW() - INTERVAL '1 day', 'Daily interest')
ON CONFLICT (id) DO UPDATE SET
  amount = EXCLUDED.amount,
  running_balance = EXCLUDED.running_balance;
