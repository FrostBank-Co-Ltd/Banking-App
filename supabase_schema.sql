-- ====================================================================
-- FrostBank Mobile - Supabase Database Schema & Seed Script
-- Execute this script in your Supabase SQL Editor.
-- ====================================================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
  id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  mobile TEXT NOT NULL,
  member_since TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. ACCOUNTS TABLE
CREATE TABLE IF NOT EXISTS public.accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  short_code TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('wallet', 'savings', 'crypto')),
  masked_number TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'USD',
  total_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  available_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  crypto_quantity NUMERIC(12,5),
  crypto_unit TEXT
);

-- 3. CARDS TABLE
CREATE TABLE IF NOT EXISTS public.cards (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  holder_name TEXT NOT NULL,
  number TEXT NOT NULL,
  cvc TEXT NOT NULL,
  expiry TEXT NOT NULL,
  network TEXT NOT NULL CHECK (network IN ('visa', 'mastercard')),
  kind TEXT NOT NULL CHECK (kind IN ('debit', 'credit')),
  status TEXT NOT NULL CHECK (status IN ('active', 'frozen')),
  balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  currency_code TEXT NOT NULL DEFAULT 'USD',
  spending_limit NUMERIC(12,2) NOT NULL DEFAULT 0.00
);

-- 4. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.transactions (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  merchant TEXT NOT NULL,
  category TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'USD',
  direction TEXT NOT NULL CHECK (direction IN ('inflow', 'outflow')),
  type TEXT NOT NULL CHECK (type IN ('deposit', 'transfer', 'qrPayment', 'cardPurchase')),
  status TEXT NOT NULL CHECK (status IN ('completed', 'pending', 'failed')),
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reference TEXT NOT NULL,
  note TEXT
);

-- 5. PROMOS TABLE
CREATE TABLE IF NOT EXISTS public.promos (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  action_label TEXT NOT NULL,
  accent_index INT NOT NULL DEFAULT 0
);

-- Row Level Security (RLS) Configuration
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promos ENABLE ROW LEVEL SECURITY;

-- Allow read access to anon / authenticated roles
CREATE POLICY "Allow read profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow read accounts" ON public.accounts FOR SELECT USING (true);
CREATE POLICY "Allow read cards" ON public.cards FOR SELECT USING (true);
CREATE POLICY "Allow read transactions" ON public.transactions FOR SELECT USING (true);
CREATE POLICY "Allow read promos" ON public.promos FOR SELECT USING (true);

-- Allow full management for authenticated users on their own data
CREATE POLICY "Allow write profiles" ON public.profiles FOR ALL USING (true);
CREATE POLICY "Allow write accounts" ON public.accounts FOR ALL USING (true);
CREATE POLICY "Allow write cards" ON public.cards FOR ALL USING (true);
CREATE POLICY "Allow write transactions" ON public.transactions FOR ALL USING (true);

-- ====================================================================
-- SEED DATA
-- ====================================================================

-- User Profile
INSERT INTO public.profiles (id, full_name, email, mobile, member_since)
VALUES (
  'usr_01',
  'Ava Mercado',
  'ava.mercado@frostbank.app',
  '+1 (312) 847-1928',
  '2019-04-17T00:00:00Z'
) ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  mobile = EXCLUDED.mobile;

-- Accounts
INSERT INTO public.accounts (id, name, short_code, kind, masked_number, currency_code, total_balance, available_balance, crypto_quantity, crypto_unit)
VALUES 
  ('acc_wallet', 'Everyday Wallet', 'WALLET', 'wallet', '•••• 4182', 'USD', 12480.55, 12106.20, NULL, NULL),
  ('acc_savings', 'Horizon Savings', 'SAVINGS', 'savings', '•••• 7735', 'USD', 38214.83, 38214.83, NULL, NULL),
  ('acc_crypto', 'Crypto Wallet', 'BTC', 'crypto', 'bc1q •••• 9d3f', 'USD', 9142.67, 9142.67, 0.14382, 'BTC')
ON CONFLICT (id) DO UPDATE SET
  total_balance = EXCLUDED.total_balance,
  available_balance = EXCLUDED.available_balance;

-- Cards
INSERT INTO public.cards (id, account_id, label, holder_name, number, cvc, expiry, network, kind, status, balance, currency_code, spending_limit)
VALUES 
  ('card_visa', 'acc_wallet', 'FrostBank Signature', 'Ava Mercado', '4137 8947 1175 1879', '678', '09/29', 'visa', 'credit', 'active', 12106.20, 'USD', 4000.00),
  ('card_mc', 'acc_savings', 'Horizon Everyday', 'Ava Mercado', '5204 7401 4290 1028', '412', '02/28', 'mastercard', 'debit', 'frozen', 1875.40, 'USD', 1500.00)
ON CONFLICT (id) DO UPDATE SET
  balance = EXCLUDED.balance,
  status = EXCLUDED.status;

-- Promos
INSERT INTO public.promos (id, title, body, action_label, accent_index)
VALUES 
  ('promo_horizon', 'Horizon Savings at 4.35 percent', 'Move idle cash into Horizon and earn 4.35 percent on every dollar.', 'See rates', 0),
  ('promo_travel', 'No fees abroad this quarter', 'Signature cardholders pay zero conversion fees until 30 September.', 'View terms', 1),
  ('promo_split', 'Split Bills with four people', 'Share a bill and track who has paid without leaving the app.', 'Learn more', 2)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  body = EXCLUDED.body;

-- Sample Recent Transactions
INSERT INTO public.transactions (id, account_id, merchant, category, amount, currency_code, direction, type, status, date, reference, note)
VALUES 
  ('txn_001', 'acc_wallet', 'Ludlow Coffee House', 'Dining', 6.85, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '1 hour', 'NM-748219', NULL),
  ('txn_002', 'acc_wallet', 'Verdant Grocers', 'Groceries', 84.37, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '4 hours', 'NM-748356', NULL),
  ('txn_003', 'acc_wallet', 'Halden Transit Authority', 'Transport', 3.25, 'USD', 'outflow', 'qrPayment', 'pending', NOW() - INTERVAL '10 hours', 'NM-748493', NULL),
  ('txn_004', 'acc_wallet', 'Solene Bakery', 'Dining', 12.40, 'USD', 'outflow', 'qrPayment', 'completed', NOW() - INTERVAL '1 day', 'NM-748630', NULL),
  ('txn_005', 'acc_wallet', 'Priya Raman', 'Transfer', 240.00, 'USD', 'inflow', 'transfer', 'completed', NOW() - INTERVAL '1 day 5 hours', 'NM-748767', 'Shared costs'),
  ('txn_006', 'acc_wallet', 'Ludlow Coffee House', 'Dining', 5.95, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '2 days', 'NM-748904', NULL),
  ('txn_007', 'acc_wallet', 'Fable & Vine', 'Dining', 63.18, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '2 days 12 hours', 'NM-749041', NULL),
  ('txn_008', 'acc_wallet', 'Northgate Pharmacy', 'Health', 27.49, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '3 days', 'NM-749178', NULL),
  ('txn_009', 'acc_savings', 'Marlowe Books', 'Shopping', 41.72, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '3 days 5 hours', 'NM-749315', NULL),
  ('txn_010', 'acc_wallet', 'Brightwire Energy', 'Utilities', 138.66, 'USD', 'outflow', 'transfer', 'completed', NOW() - INTERVAL '4 days', 'NM-749452', NULL),
  ('txn_011', 'acc_wallet', 'Lumen Mobile', 'Utilities', 55.00, 'USD', 'outflow', 'qrPayment', 'completed', NOW() - INTERVAL '5 days', 'NM-749589', NULL),
  ('txn_012', 'acc_wallet', 'Verdant Grocers', 'Groceries', 96.03, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '5 days 10 hours', 'NM-749726', NULL),
  ('txn_013', 'acc_wallet', 'Tobias Fuentes', 'Transfer', 320.75, 'USD', 'outflow', 'transfer', 'failed', NOW() - INTERVAL '6 days', 'NM-749863', 'Shared costs'),
  ('txn_014', 'acc_wallet', 'Cedarline Studios', 'Salary', 4812.44, 'USD', 'inflow', 'deposit', 'completed', NOW() - INTERVAL '7 days', 'NM-750000', NULL)
ON CONFLICT (id) DO UPDATE SET
  amount = EXCLUDED.amount,
  status = EXCLUDED.status;
