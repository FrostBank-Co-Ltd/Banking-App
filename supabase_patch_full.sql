-- ====================================================================
-- Comprehensive Supabase Patch with IVE Members, Ava Mercado & Auth Users
-- Valid UUIDs formatted for Supabase Auth auth.users table
-- ====================================================================

-- 1. ENABLE PGCRYPTO FOR BCRYPT PASSWORD HASHING
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. ADD USER_ID COLUMNS TO EXISTING TABLES
ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.cards ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.goal_saves ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.goal_transactions ADD COLUMN IF NOT EXISTS user_id TEXT;

-- 3. BACKFILL EXISTING SEEDED DATA WITH USER_ID
UPDATE public.accounts SET user_id = '00000000-0000-0000-0000-000000000001' WHERE user_id IS NULL OR user_id = 'usr_01';
UPDATE public.cards SET user_id = '00000000-0000-0000-0000-000000000001' WHERE user_id IS NULL OR user_id = 'usr_01';
UPDATE public.transactions SET user_id = '00000000-0000-0000-0000-000000000001' WHERE user_id IS NULL OR user_id = 'usr_01';
UPDATE public.goal_saves SET user_id = '00000000-0000-0000-0000-000000000001' WHERE user_id IS NULL OR user_id = 'usr_01';
UPDATE public.goal_transactions SET user_id = '00000000-0000-0000-0000-000000000001' WHERE user_id IS NULL OR user_id = 'usr_01';

-- 4. CREATE SPLIT BILLS TABLES
CREATE TABLE IF NOT EXISTS public.split_bills (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  title TEXT NOT NULL,
  total_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  category TEXT NOT NULL DEFAULT 'General',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by TEXT NOT NULL DEFAULT 'You (Host)'
);

CREATE TABLE IF NOT EXISTS public.split_bill_participants (
  id TEXT PRIMARY KEY,
  bill_id TEXT NOT NULL REFERENCES public.split_bills(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  share_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  status TEXT NOT NULL CHECK (status IN ('paid', 'pending')) DEFAULT 'pending',
  paid_at TIMESTAMPTZ
);

-- 5. ENABLE RLS FOR SPLIT BILL TABLES & DROP EXISTING POLICIES FOR CLEAN RE-RUNS
ALTER TABLE public.split_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.split_bill_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow read split_bills" ON public.split_bills;
DROP POLICY IF EXISTS "Allow write split_bills" ON public.split_bills;
DROP POLICY IF EXISTS "Allow read split_bill_participants" ON public.split_bill_participants;
DROP POLICY IF EXISTS "Allow write split_bill_participants" ON public.split_bill_participants;

CREATE POLICY "Allow read split_bills" ON public.split_bills FOR SELECT USING (true);
CREATE POLICY "Allow write split_bills" ON public.split_bills FOR ALL USING (true);
CREATE POLICY "Allow read split_bill_participants" ON public.split_bill_participants FOR SELECT USING (true);
CREATE POLICY "Allow write split_bill_participants" ON public.split_bill_participants FOR ALL USING (true);

-- ====================================================================
-- SEED DATA FOR IVE MEMBERS & AVA MERCADO
-- ====================================================================

-- 6. PROFILES (Ava Mercado + IVE Members)
INSERT INTO public.profiles (id, full_name, email, mobile, member_since)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'Ava Mercado', 'ava.mercado@frostbank.app', '+1 (312) 847-1928', '2019-04-17T00:00:00Z'),
  ('00000000-0000-0000-0000-000000000002', 'An Yujin', 'yujin.an@frostbank.app', '+82 10-1001-0901', '2021-12-01T00:00:00Z'),
  ('00000000-0000-0000-0000-000000000003', 'Jang Wonyoung', 'wonyoung.jang@frostbank.app', '+82 10-2002-0831', '2021-12-01T00:00:00Z'),
  ('00000000-0000-0000-0000-000000000004', 'Gaeul (Kim Gaeul)', 'gaeul.kim@frostbank.app', '+82 10-3003-0924', '2021-12-01T00:00:00Z'),
  ('00000000-0000-0000-0000-000000000005', 'Rei (Naoi Rei)', 'rei.naoi@frostbank.app', '+82 10-4004-0203', '2021-12-01T00:00:00Z'),
  ('00000000-0000-0000-0000-000000000006', 'Liz (Kim Jiwon)', 'liz.kim@frostbank.app', '+82 10-5005-1121', '2021-12-01T00:00:00Z'),
  ('00000000-0000-0000-0000-000000000007', 'Leeseo (Lee Hyunseo)', 'hyunseo.lee@frostbank.app', '+82 10-6006-0221', '2021-12-01T00:00:00Z')
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  mobile = EXCLUDED.mobile;

-- 7. ACCOUNTS
INSERT INTO public.accounts (id, user_id, name, short_code, kind, masked_number, currency_code, total_balance, available_balance, crypto_quantity, crypto_unit)
VALUES 
  ('acc_wallet', '00000000-0000-0000-0000-000000000001', 'Everyday Wallet', 'WALLET', 'wallet', '•••• 4182', 'USD', 12480.55, 12106.20, NULL, NULL),
  ('acc_savings', '00000000-0000-0000-0000-000000000001', 'Horizon Savings', 'SAVINGS', 'savings', '•••• 7735', 'USD', 38214.83, 38214.83, NULL, NULL),
  ('acc_crypto', '00000000-0000-0000-0000-000000000001', 'Crypto Wallet', 'BTC', 'crypto', 'bc1q •••• 9d3f', 'USD', 9142.67, 9142.67, 0.14382, 'BTC'),
  ('acc_yujin_wallet', '00000000-0000-0000-0000-000000000002', 'Yujin''s Leader Vault', 'WALLET', 'wallet', '•••• 1001', 'USD', 24500.00, 24180.00, NULL, NULL),
  ('acc_yujin_savings', '00000000-0000-0000-0000-000000000002', 'Horizon Leader Fund', 'SAVINGS', 'savings', '•••• 1002', 'USD', 85000.00, 85000.00, NULL, NULL),
  ('acc_wonyoung_wallet', '00000000-0000-0000-0000-000000000003', 'Wonyoung''s Style Vault', 'WALLET', 'wallet', '•••• 2001', 'USD', 42800.00, 39650.00, NULL, NULL),
  ('acc_wonyoung_savings', '00000000-0000-0000-0000-000000000003', 'Luxury & Beauty Savings', 'SAVINGS', 'savings', '•••• 2002', 'USD', 120000.00, 120000.00, NULL, NULL),
  ('acc_gaeul_wallet', '00000000-0000-0000-0000-000000000004', 'Gaeul''s Autumn Wallet', 'WALLET', 'wallet', '•••• 3001', 'USD', 18300.00, 17850.00, NULL, NULL),
  ('acc_gaeul_savings', '00000000-0000-0000-0000-000000000004', 'Choreography Studio Savings', 'SAVINGS', 'savings', '•••• 3002', 'USD', 55000.00, 55000.00, NULL, NULL),
  ('acc_rei_wallet', '00000000-0000-0000-0000-000000000005', 'Rei''s Creative Stash', 'WALLET', 'wallet', '•••• 4001', 'USD', 21100.00, 19560.00, NULL, NULL),
  ('acc_rei_savings', '00000000-0000-0000-0000-000000000005', 'Art & Manga Vault', 'SAVINGS', 'savings', '•••• 4002', 'USD', 48000.00, 48000.00, NULL, NULL),
  ('acc_liz_wallet', '00000000-0000-0000-0000-000000000006', 'Liz''s Vocal Vault', 'WALLET', 'wallet', '•••• 5001', 'USD', 19500.00, 17635.00, NULL, NULL),
  ('acc_liz_savings', '00000000-0000-0000-0000-000000000006', 'Acoustic & Studio Savings', 'SAVINGS', 'savings', '•••• 5002', 'USD', 52000.00, 52000.00, NULL, NULL),
  ('acc_leeseo_wallet', '00000000-0000-0000-0000-000000000007', 'Leeseo''s Youth Wallet', 'WALLET', 'wallet', '•••• 6001', 'USD', 12900.00, 12652.50, NULL, NULL),
  ('acc_leeseo_savings', '00000000-0000-0000-0000-000000000007', 'Future Education Fund', 'SAVINGS', 'savings', '•••• 6002', 'USD', 35000.00, 35000.00, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET
  total_balance = EXCLUDED.total_balance,
  available_balance = EXCLUDED.available_balance;

-- 8. CARDS
INSERT INTO public.cards (id, user_id, account_id, label, holder_name, number, cvc, expiry, network, kind, status, balance, currency_code, spending_limit)
VALUES 
  ('card_visa', '00000000-0000-0000-0000-000000000001', 'acc_wallet', 'FrostBank Signature', 'Ava Mercado', '4137 8947 1175 1879', '678', '09/29', 'visa', 'credit', 'active', 12106.20, 'USD', 4000.00),
  ('card_mc', '00000000-0000-0000-0000-000000000001', 'acc_savings', 'Horizon Everyday', 'Ava Mercado', '5204 7401 4290 1028', '412', '02/28', 'mastercard', 'debit', 'frozen', 1875.40, 'USD', 1500.00),
  ('card_yujin_black', '00000000-0000-0000-0000-000000000002', 'acc_yujin_wallet', 'FrostBank Black Leader Edition', 'An Yujin', '4532 9811 7402 1001', '901', '12/30', 'visa', 'credit', 'active', 24180.00, 'USD', 15000.00),
  ('card_wonyoung_luxe', '00000000-0000-0000-0000-000000000003', 'acc_wonyoung_wallet', 'FrostBank Platinum Luxe', 'Jang Wonyoung', '4000 8821 9904 2001', '831', '08/30', 'visa', 'credit', 'active', 39650.00, 'USD', 25000.00),
  ('card_gaeul_mc', '00000000-0000-0000-0000-000000000004', 'acc_gaeul_wallet', 'Horizon Autumn Everyday', 'Gaeul', '5412 7734 6100 3001', '924', '09/29', 'mastercard', 'debit', 'active', 17850.00, 'USD', 8000.00),
  ('card_rei_visa', '00000000-0000-0000-0000-000000000005', 'acc_rei_wallet', 'FrostBank Signature Creative', 'Rei', '4123 6549 8812 4001', '203', '02/29', 'visa', 'credit', 'active', 19560.00, 'USD', 10000.00),
  ('card_liz_mc', '00000000-0000-0000-0000-000000000006', 'acc_liz_wallet', 'Horizon Vocal Edition', 'Liz', '5233 4410 9021 5001', '121', '11/29', 'mastercard', 'debit', 'active', 17635.00, 'USD', 8000.00),
  ('card_leeseo_visa', '00000000-0000-0000-0000-000000000007', 'acc_leeseo_wallet', 'FrostBank Youth Signature', 'Leeseo', '4916 2200 3104 6001', '221', '02/31', 'visa', 'debit', 'active', 12652.50, 'USD', 5000.00)
ON CONFLICT (id) DO UPDATE SET
  balance = EXCLUDED.balance,
  status = EXCLUDED.status;

-- 9. TRANSACTIONS
INSERT INTO public.transactions (id, user_id, account_id, merchant, category, amount, currency_code, direction, type, status, date, reference, note)
VALUES 
  ('txn_001', '00000000-0000-0000-0000-000000000001', 'acc_wallet', 'Ludlow Coffee House', 'Dining', 6.85, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '1 hour', 'NM-748219', NULL),
  ('txn_002', '00000000-0000-0000-0000-000000000001', 'acc_wallet', 'Verdant Grocers', 'Groceries', 84.37, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '4 hours', 'NM-748356', NULL),
  ('txn_yj_01', '00000000-0000-0000-0000-000000000002', 'acc_yujin_wallet', 'Pilates & Fitness Studio', 'Health', 180.00, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '3 hours', 'NM-YJ9901', 'Monthly Pilates'),
  ('txn_wy_01', '00000000-0000-0000-0000-000000000003', 'acc_wonyoung_wallet', 'Miu Miu Flagship Boutique', 'Shopping', 2450.00, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '2 hours', 'NM-WY8801', 'Fashion week wardrobe'),
  ('txn_gl_01', '00000000-0000-0000-0000-000000000004', 'acc_gaeul_wallet', '1MILLION Dance Studio Rental', 'Entertainment', 250.00, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '5 hours', 'NM-GL7701', 'Choreography practice'),
  ('txn_rei_01', '00000000-0000-0000-0000-000000000005', 'acc_rei_wallet', 'Tokyo Character Goods & Manga', 'Shopping', 340.00, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '4 hours', 'NM-REI6601', 'Limited edition merch'),
  ('txn_lz_01', '00000000-0000-0000-0000-000000000006', 'acc_liz_wallet', 'Ultimate Ears Custom In-Ears', 'Equipment', 1850.00, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '6 hours', 'NM-LZ5501', 'Stage monitors'),
  ('txn_ls_01', '00000000-0000-0000-0000-000000000007', 'acc_leeseo_wallet', 'High School Stationery & Books', 'Education', 85.00, 'USD', 'outflow', 'cardPurchase', 'completed', NOW() - INTERVAL '8 hours', 'NM-LS4401', 'Textbooks')
ON CONFLICT (id) DO UPDATE SET
  amount = EXCLUDED.amount,
  status = EXCLUDED.status;

-- 10. GOAL SAVES
INSERT INTO public.goal_saves (id, user_id, name, emoji, target_amount, balance, currency_code, daily_rate_percent, interest_earned, created_at, status)
VALUES
  ('goal_emergency', '00000000-0000-0000-0000-000000000001', 'Emergency Fund', 'shield', 10000.00, 6420.50, 'USD', 0.011918, 28.14, NOW() - INTERVAL '198 days', 'active'),
  ('goal_yujin_tour', '00000000-0000-0000-0000-000000000002', 'World Tour Savings', '🎤', 50000.00, 35000.00, 'USD', 0.011918, 142.50, NOW() - INTERVAL '90 days', 'active'),
  ('goal_wonyoung_fashion', '00000000-0000-0000-0000-000000000003', 'Paris Fashion Week', '💄', 30000.00, 22500.00, 'USD', 0.011918, 98.10, NOW() - INTERVAL '60 days', 'active'),
  ('goal_gaeul_studio', '00000000-0000-0000-0000-000000000004', 'Private Dance Studio', '💃', 40000.00, 19000.00, 'USD', 0.011918, 76.20, NOW() - INTERVAL '110 days', 'active'),
  ('goal_rei_art', '00000000-0000-0000-0000-000000000005', 'Art & Manga Exhibition', '🎨', 20000.00, 14200.00, 'USD', 0.011918, 54.80, NOW() - INTERVAL '80 days', 'active'),
  ('goal_liz_piano', '00000000-0000-0000-0000-000000000006', 'Grand Piano Savings', '🎹', 25000.00, 18400.00, 'USD', 0.011918, 68.40, NOW() - INTERVAL '100 days', 'active'),
  ('goal_leeseo_trip', '00000000-0000-0000-0000-000000000007', 'Graduation Vacation', '✈️', 10000.00, 7800.00, 'USD', 0.011918, 29.10, NOW() - INTERVAL '50 days', 'active')
ON CONFLICT (id) DO UPDATE SET
  balance = EXCLUDED.balance,
  interest_earned = EXCLUDED.interest_earned;

-- 11. GOAL TRANSACTIONS
INSERT INTO public.goal_transactions (id, user_id, goal_id, kind, amount, running_balance, date, note)
VALUES
  ('gtxn_001', '00000000-0000-0000-0000-000000000001', 'goal_emergency', 'transferIn', 5000.00, 5000.00, NOW() - INTERVAL '198 days', 'Initial deposit'),
  ('gtxn_yj_01', '00000000-0000-0000-0000-000000000002', 'goal_yujin_tour', 'transferIn', 35000.00, 35000.00, NOW() - INTERVAL '90 days', 'Tour budget deposit')
ON CONFLICT (id) DO UPDATE SET
  amount = EXCLUDED.amount,
  running_balance = EXCLUDED.running_balance;

-- 12. SPLIT BILLS
INSERT INTO public.split_bills (id, user_id, title, total_amount, category, created_at, created_by)
VALUES
  ('bill_ive_afterlike', '00000000-0000-0000-0000-000000000002', 'IVE ''AFTER LIKE'' Comeback Celebration Dinner', 600.00, 'Food & Dining', NOW() - INTERVAL '3 days', 'An Yujin (Host)')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  total_amount = EXCLUDED.total_amount;

-- 13. SPLIT BILL PARTICIPANTS
INSERT INTO public.split_bill_participants (id, bill_id, name, share_amount, status, paid_at)
VALUES
  ('p_ive_yujin', 'bill_ive_afterlike', 'An Yujin (Host)', 100.00, 'paid', NOW() - INTERVAL '3 days'),
  ('p_ive_wonyoung', 'bill_ive_afterlike', 'Jang Wonyoung', 100.00, 'paid', NOW() - INTERVAL '2 days'),
  ('p_ive_gaeul', 'bill_ive_afterlike', 'Gaeul', 100.00, 'paid', NOW() - INTERVAL '2 days'),
  ('p_ive_rei', 'bill_ive_afterlike', 'Rei', 100.00, 'paid', NOW() - INTERVAL '1 day'),
  ('p_ive_liz', 'bill_ive_afterlike', 'Liz', 100.00, 'pending', NULL),
  ('p_ive_leeseo', 'bill_ive_afterlike', 'Leeseo', 100.00, 'pending', NULL)
ON CONFLICT (id) DO UPDATE SET
  status = EXCLUDED.status,
  paid_at = EXCLUDED.paid_at;

-- ====================================================================
-- 14. BATCH SEED AUTH USERS & PASSWORDS INTO SUPABASE AUTH (VALID UUIDs)
-- ====================================================================

INSERT INTO auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at, 
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud
)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'ava.mercado@frostbank.app', extensions.crypt('frost2026', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Ava Mercado"}'::jsonb, NOW(), NOW(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000002'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'yujin.an@frostbank.app', extensions.crypt('ive2026', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"An Yujin"}'::jsonb, NOW(), NOW(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000003'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'wonyoung.jang@frostbank.app', extensions.crypt('ive2026', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Jang Wonyoung"}'::jsonb, NOW(), NOW(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000004'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'gaeul.kim@frostbank.app', extensions.crypt('ive2026', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Gaeul (Kim Gaeul)"}'::jsonb, NOW(), NOW(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000005'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'rei.naoi@frostbank.app', extensions.crypt('ive2026', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Rei (Naoi Rei)"}'::jsonb, NOW(), NOW(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000006'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'liz.kim@frostbank.app', extensions.crypt('ive2026', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Liz (Kim Jiwon)"}'::jsonb, NOW(), NOW(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000007'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'hyunseo.lee@frostbank.app', extensions.crypt('ive2026', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Leeseo (Lee Hyunseo)"}'::jsonb, NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO UPDATE SET
  encrypted_password = EXCLUDED.encrypted_password,
  email_confirmed_at = EXCLUDED.email_confirmed_at,
  updated_at = NOW();

INSERT INTO auth.identities (
  id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
)
VALUES
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'::uuid, '{"sub":"00000000-0000-0000-0000-000000000001","email":"ava.mercado@frostbank.app"}'::jsonb, 'email', NOW(), NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002'::uuid, '{"sub":"00000000-0000-0000-0000-000000000002","email":"yujin.an@frostbank.app"}'::jsonb, 'email', NOW(), NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003'::uuid, '{"sub":"00000000-0000-0000-0000-000000000003","email":"wonyoung.jang@frostbank.app"}'::jsonb, 'email', NOW(), NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004'::uuid, '{"sub":"00000000-0000-0000-0000-000000000004","email":"gaeul.kim@frostbank.app"}'::jsonb, 'email', NOW(), NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005'::uuid, '{"sub":"00000000-0000-0000-0000-000000000005","email":"rei.naoi@frostbank.app"}'::jsonb, 'email', NOW(), NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006'::uuid, '{"sub":"00000000-0000-0000-0000-000000000006","email":"liz.kim@frostbank.app"}'::jsonb, 'email', NOW(), NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000007'::uuid, '{"sub":"00000000-0000-0000-0000-000000000007","email":"hyunseo.lee@frostbank.app"}'::jsonb, 'email', NOW(), NOW(), NOW())
ON CONFLICT DO NOTHING;
