-- ====================================================================
-- FrostBank Mobile - Supabase Auth Batch Password Seeding Script
-- Valid UUIDs & Safe ON CONFLICT DO NOTHING for auth.identities
-- ====================================================================

-- 1. Enable pgcrypto extension for bcrypt password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. Seed Auth Users into auth.users
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  role,
  aud
)
VALUES
  -- 1. Ava Mercado (Password: frost2026)
  (
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'ava.mercado@frostbank.app',
    extensions.crypt('frost2026', extensions.gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Ava Mercado"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),

  -- 2. An Yujin (Password: ive2026)
  (
    '00000000-0000-0000-0000-000000000002'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'yujin.an@frostbank.app',
    extensions.crypt('ive2026', extensions.gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"An Yujin"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),

  -- 3. Jang Wonyoung (Password: ive2026)
  (
    '00000000-0000-0000-0000-000000000003'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'wonyoung.jang@frostbank.app',
    extensions.crypt('ive2026', extensions.gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Jang Wonyoung"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),

  -- 4. Gaeul (Password: ive2026)
  (
    '00000000-0000-0000-0000-000000000004'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'gaeul.kim@frostbank.app',
    extensions.crypt('ive2026', extensions.gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Gaeul (Kim Gaeul)"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),

  -- 5. Rei (Password: ive2026)
  (
    '00000000-0000-0000-0000-000000000005'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'rei.naoi@frostbank.app',
    extensions.crypt('ive2026', extensions.gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Rei (Naoi Rei)"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),

  -- 6. Liz (Password: ive2026)
  (
    '00000000-0000-0000-0000-000000000006'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'liz.kim@frostbank.app',
    extensions.crypt('ive2026', extensions.gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Liz (Kim Jiwon)"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  ),

  -- 7. Leeseo (Password: ive2026)
  (
    '00000000-0000-0000-0000-000000000007'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'hyunseo.lee@frostbank.app',
    extensions.crypt('ive2026', extensions.gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Leeseo (Lee Hyunseo)"}'::jsonb,
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  )
ON CONFLICT (id) DO UPDATE SET
  encrypted_password = EXCLUDED.encrypted_password,
  email_confirmed_at = EXCLUDED.email_confirmed_at,
  updated_at = NOW();

-- 3. Seed Email Identities into auth.identities
INSERT INTO auth.identities (
  id,
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
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
