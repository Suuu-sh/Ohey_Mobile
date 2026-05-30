-- Rich seed data for the dev-ohey Supabase project only.
-- Do not run this against production.
--
-- Usage in Supabase SQL editor or psql:
--   select set_config('app.seed_password', '<local-dev-password>', false);
--   \i supabase/dev/seed_dev_rich_data.sql

create extension if not exists pgcrypto;

do $$
begin
  if nullif(current_setting('app.seed_password', true), '') is null then
    raise exception 'Set app.seed_password before running dev rich seed';
  end if;
end;
$$;

-- Confirmed dev auth users. Fixed UUIDs make this seed idempotent.
with seed_password(value) as (
  select nullif(current_setting('app.seed_password', true), '')
), seed(id, email, password, display_name, user_id, character_key, avatar_url, is_plus) as (
  values
    ('00000000-0000-4000-8000-000000000101'::uuid, 'dev-yuta@ohey.app',   (select value from seed_password), 'ユウタ', 'dev_yuta',   'avatar', 'ohey_avatar:v1:0:1:2:0:0:3', true),
    ('00000000-0000-4000-8000-000000000102'::uuid, 'dev-ken@ohey.app',    (select value from seed_password), 'ケン',   'dev_ken',    'avatar', 'ohey_avatar:v1:5:2:5:2:1:0', false),
    ('00000000-0000-4000-8000-000000000103'::uuid, 'dev-ryo@ohey.app',    (select value from seed_password), 'リョウ', 'dev_ryo',    'avatar', 'ohey_avatar:v1:2:6:0:3:0:1', false),
    ('00000000-0000-4000-8000-000000000104'::uuid, 'dev-haru@ohey.app',   (select value from seed_password), 'ハル',   'dev_haru',   'avatar', 'ohey_avatar:v1:1:4:3:1:2:3', false),
    ('00000000-0000-4000-8000-000000000105'::uuid, 'dev-takumi@ohey.app', (select value from seed_password), 'タクミ', 'dev_takumi', 'avatar', 'ohey_avatar:v1:3:5:6:0:1:0', false),
    ('00000000-0000-4000-8000-000000000106'::uuid, 'dev-mika@ohey.app',   (select value from seed_password), 'ミカ',   'dev_mika',   'avatar', 'ohey_avatar:v1:4:3:1:4:2:2', false),
    ('00000000-0000-4000-8000-000000000107'::uuid, 'dev-ren@ohey.app',    (select value from seed_password), 'レン',   'dev_ren',    'avatar', 'ohey_avatar:v1:6:0:4:5:3:1', false),
    ('00000000-0000-4000-8000-000000000108'::uuid, 'dev-saki@ohey.app',   (select value from seed_password), 'サキ',   'dev_saki',   'avatar', 'ohey_avatar:v1:7:7:3:6:4:0', false),
    ('00000000-0000-4000-8000-000000000109'::uuid, 'dev-ana@ohey.app',    (select value from seed_password), 'Ana',    'dev_ana',    'avatar', 'ohey_avatar:v1:8:8:7:1:1:3', false),
    ('00000000-0000-4000-8000-000000000110'::uuid, 'dev-kai@ohey.app',    (select value from seed_password), 'Kai',    'dev_kai',    'avatar', 'ohey_avatar:v1:9:9:8:2:2:2', false)
)
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  is_sso_user, is_anonymous
)
select
  '00000000-0000-0000-0000-000000000000'::uuid,
  id,
  'authenticated',
  'authenticated',
  email,
  crypt(password, gen_salt('bf')),
  now(),
  jsonb_build_object('provider', 'email', 'providers', array['email']),
  '{}'::jsonb,
  now(),
  now(),
  '',
  '',
  '',
  '',
  false,
  false
from seed
on conflict (id) do update set
  email = excluded.email,
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = excluded.email_confirmed_at,
  updated_at = now();

with seed(id, email) as (
  values
    ('00000000-0000-4000-8000-000000000101'::uuid, 'dev-yuta@ohey.app'),
    ('00000000-0000-4000-8000-000000000102'::uuid, 'dev-ken@ohey.app'),
    ('00000000-0000-4000-8000-000000000103'::uuid, 'dev-ryo@ohey.app'),
    ('00000000-0000-4000-8000-000000000104'::uuid, 'dev-haru@ohey.app'),
    ('00000000-0000-4000-8000-000000000105'::uuid, 'dev-takumi@ohey.app'),
    ('00000000-0000-4000-8000-000000000106'::uuid, 'dev-mika@ohey.app'),
    ('00000000-0000-4000-8000-000000000107'::uuid, 'dev-ren@ohey.app'),
    ('00000000-0000-4000-8000-000000000108'::uuid, 'dev-saki@ohey.app'),
    ('00000000-0000-4000-8000-000000000109'::uuid, 'dev-ana@ohey.app'),
    ('00000000-0000-4000-8000-000000000110'::uuid, 'dev-kai@ohey.app')
)
insert into auth.identities (
  id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
)
select
  id,
  id::text,
  id,
  jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true, 'phone_verified', false),
  'email',
  now(),
  now(),
  now()
from seed
on conflict (provider, provider_id) do update set
  identity_data = excluded.identity_data,
  updated_at = now();

insert into public.profiles (id, display_name, user_id, gender, character_key, avatar_url, is_plus)
values
  ('00000000-0000-4000-8000-000000000101', 'ユウタ', 'dev_yuta',   'male', 'avatar', 'ohey_avatar:v1:0:1:2:0:0:3', true),
  ('00000000-0000-4000-8000-000000000102', 'ケン',   'dev_ken',    'male', 'avatar', 'ohey_avatar:v1:5:2:5:2:1:0', false),
  ('00000000-0000-4000-8000-000000000103', 'リョウ', 'dev_ryo',    'male', 'avatar', 'ohey_avatar:v1:2:6:0:3:0:1', false),
  ('00000000-0000-4000-8000-000000000104', 'ハル',   'dev_haru',   'female', 'avatar', 'ohey_avatar:v1:1:4:3:1:2:3', false),
  ('00000000-0000-4000-8000-000000000105', 'タクミ', 'dev_takumi', 'male', 'avatar', 'ohey_avatar:v1:3:5:6:0:1:0', false),
  ('00000000-0000-4000-8000-000000000106', 'ミカ',   'dev_mika',   'female', 'avatar', 'ohey_avatar:v1:4:3:1:4:2:2', false),
  ('00000000-0000-4000-8000-000000000107', 'レン',   'dev_ren',    'male', 'avatar', 'ohey_avatar:v1:6:0:4:5:3:1', false),
  ('00000000-0000-4000-8000-000000000108', 'サキ',   'dev_saki',   'female', 'avatar', 'ohey_avatar:v1:7:7:3:6:4:0', false),
  ('00000000-0000-4000-8000-000000000109', 'Ana',    'dev_ana',    'female', 'avatar', 'ohey_avatar:v1:8:8:7:1:1:3', false),
  ('00000000-0000-4000-8000-000000000110', 'Kai',    'dev_kai',    'male', 'avatar', 'ohey_avatar:v1:9:9:8:2:2:2', false)
on conflict (id) do update set
  display_name = excluded.display_name,
  user_id = excluded.user_id,
  character_key = excluded.character_key,
  avatar_url = excluded.avatar_url,
  gender = excluded.gender,
  is_plus = excluded.is_plus,
  updated_at = now();

-- Reset deterministic seed-only social data without touching real dev users.
delete from public.memory_reports
where memory_id in (select id from public.memories where owner_user_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110');

delete from public.memory_likes
where memory_id in (select id from public.memories where owner_user_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110');

delete from public.memory_tagged_users
where memory_id in (select id from public.memories where owner_user_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110');

delete from public.memories
where owner_user_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110';

delete from public.daily_statuses
where user_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110';

delete from public.friend_requests
where from_user_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110'
   or to_user_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110';

-- Friend graph: ユウタ can see many patterns; others have a few cross-links.
insert into public.friendships (user_a_id, user_b_id, created_at)
values
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000102', now() - interval '28 days'),
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000103', now() - interval '23 days'),
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000104', now() - interval '20 days'),
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000105', now() - interval '17 days'),
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000106', now() - interval '15 days'),
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000107', now() - interval '12 days'),
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000108', now() - interval '10 days'),
  ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000103', now() - interval '9 days'),
  ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000104', now() - interval '7 days'),
  ('00000000-0000-4000-8000-000000000103', '00000000-0000-4000-8000-000000000106', now() - interval '6 days'),
  ('00000000-0000-4000-8000-000000000104', '00000000-0000-4000-8000-000000000107', now() - interval '5 days'),
  ('00000000-0000-4000-8000-000000000105', '00000000-0000-4000-8000-000000000108', now() - interval '4 days')
on conflict (user_a_id, user_b_id) do update set created_at = excluded.created_at;

insert into public.friend_requests (id, from_user_id, to_user_id, status, created_at, responded_at)
values
  ('20000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000109', '00000000-0000-4000-8000-000000000101', 'pending',   now() - interval '2 days', null),
  ('20000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000110', '00000000-0000-4000-8000-000000000101', 'pending',   now() - interval '1 day', null),
  ('20000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000106', '00000000-0000-4000-8000-000000000109', 'rejected',  now() - interval '9 days', now() - interval '8 days'),
  ('20000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000108', '00000000-0000-4000-8000-000000000110', 'cancelled', now() - interval '6 days', now() - interval '6 days')
on conflict (id) do update set
  from_user_id = excluded.from_user_id,
  to_user_id = excluded.to_user_id,
  status = excluded.status,
  created_at = excluded.created_at,
  responded_at = excluded.responded_at;

-- Today's statuses cover every UI filter/state.
insert into public.daily_statuses (user_id, status_date, status, updated_at)
values
  ('00000000-0000-4000-8000-000000000101', current_date, 'available', now() - interval '15 minutes'),
  ('00000000-0000-4000-8000-000000000102', current_date, 'maybe_available',      now() - interval '20 minutes'),
  ('00000000-0000-4000-8000-000000000103', current_date, 'depends_on_time',  now() - interval '35 minutes'),
  ('00000000-0000-4000-8000-000000000104', current_date, 'maybe_available',      now() - interval '50 minutes'),
  ('00000000-0000-4000-8000-000000000105', current_date, 'depends_on_time',       now() - interval '1 hour'),
  ('00000000-0000-4000-8000-000000000106', current_date, 'depends_on_time',   now() - interval '90 minutes'),
  ('00000000-0000-4000-8000-000000000107', current_date, 'has_plans',        now() - interval '2 hours'),
  ('00000000-0000-4000-8000-000000000108', current_date, 'unselected',       now() - interval '3 hours'),
  ('00000000-0000-4000-8000-000000000109', current_date, 'available', now() - interval '4 hours'),
  ('00000000-0000-4000-8000-000000000110', current_date, 'depends_on_time',      now() - interval '5 hours'),
  ('00000000-0000-4000-8000-000000000101', current_date - 1, 'has_plans',    now() - interval '1 day'),
  ('00000000-0000-4000-8000-000000000102', current_date - 1, 'depends_on_time',   now() - interval '1 day')
on conflict (user_id, status_date) do update set
  status = excluded.status,
  updated_at = excluded.updated_at;

with seed_memories(id, owner_user_id, days_ago, hour_text, place_name, memo, photo_path, place_lat, place_lng) as (
  values
    ('10000000-0000-4000-8000-000000000001'::uuid, '00000000-0000-4000-8000-000000000101'::uuid, 0,  '20:30', '渋谷・のものも横丁',   'カレンダー確認用のタグ',       'seed/feed_shibuya.png', 35.6595, 139.7005),
    ('10000000-0000-4000-8000-000000000002'::uuid, '00000000-0000-4000-8000-000000000101'::uuid, 2,  '19:45', '恵比寿・泡酒場',       '軽めに一杯だけ',               null, 35.6467, 139.7101),
    ('10000000-0000-4000-8000-000000000003'::uuid, '00000000-0000-4000-8000-000000000101'::uuid, 5,  '21:10', '新宿・きむら屋',       '急に集まれて最高だった',       null, 35.6909, 139.7003),
    ('10000000-0000-4000-8000-000000000004'::uuid, '00000000-0000-4000-8000-000000000101'::uuid, 12, '18:50', '下北沢・夜風スタンド', '軽めでも楽しい日',         null, 35.6618, 139.6661),
    ('10000000-0000-4000-8000-000000000005'::uuid, '00000000-0000-4000-8000-000000000101'::uuid, 26, '20:00', '中目黒・川沿いバル',   '今月最初の乾杯',               null, 35.6440, 139.6993),
    ('10000000-0000-4000-8000-000000000006'::uuid, '00000000-0000-4000-8000-000000000102'::uuid, 1,  '22:00', '渋谷・立ち飲み星',     '終電までなら行ける',           null, 35.6580, 139.7016),
    ('10000000-0000-4000-8000-000000000007'::uuid, '00000000-0000-4000-8000-000000000102'::uuid, 3,  '20:00', '三軒茶屋・月あかり',   'ビールがおいしかった',         null, 35.6434, 139.6690),
    ('10000000-0000-4000-8000-000000000008'::uuid, '00000000-0000-4000-8000-000000000102'::uuid, 8,  '19:30', '目黒・小さな酒場',     'よく飲むチーム集合',           null, 35.6339, 139.7156),
    ('10000000-0000-4000-8000-000000000009'::uuid, '00000000-0000-4000-8000-000000000102'::uuid, 15, '21:30', '高円寺・ネオン食堂',   'ハイテンションな夜',           null, 35.7056, 139.6497),
    ('10000000-0000-4000-8000-000000000010'::uuid, '00000000-0000-4000-8000-000000000103'::uuid, 4,  '20:20', '代々木・やさしい酒場', '誰か誘って〜！',               null, 35.6830, 139.7020),
    ('10000000-0000-4000-8000-000000000011'::uuid, '00000000-0000-4000-8000-000000000103'::uuid, 6,  '18:40', '中野・クラフト横丁',   '写真なしパターン',             null, 35.7060, 139.6657),
    ('10000000-0000-4000-8000-000000000012'::uuid, '00000000-0000-4000-8000-000000000103'::uuid, 9,  '23:00', '池袋・終電前',         '遅めスタート',                 null, 35.7295, 139.7109),
    ('10000000-0000-4000-8000-000000000013'::uuid, '00000000-0000-4000-8000-000000000104'::uuid, 7,  '19:00', '吉祥寺・森のバル',     '今日は軽めで合流',         null, 35.7038, 139.5797),
    ('10000000-0000-4000-8000-000000000014'::uuid, '00000000-0000-4000-8000-000000000105'::uuid, 10, '20:10', '神楽坂・静かな店',     'おやすみ明けの一杯',             null, 35.7009, 139.7400),
    ('10000000-0000-4000-8000-000000000015'::uuid, '00000000-0000-4000-8000-000000000106'::uuid, 14, '18:30', '品川・駅前ビア',       '予定が合って参加',           null, 35.6285, 139.7388),
    ('10000000-0000-4000-8000-000000000016'::uuid, '00000000-0000-4000-8000-000000000107'::uuid, 18, '20:45', '上野・路地裏',         '予定ありの日',                 null, 35.7138, 139.7770),
    ('10000000-0000-4000-8000-000000000017'::uuid, '00000000-0000-4000-8000-000000000108'::uuid, 33, '19:20', '浅草・ホッピー通り',   '先月の記録も表示確認',         null, 35.7148, 139.7967),
    ('10000000-0000-4000-8000-000000000018'::uuid, '00000000-0000-4000-8000-000000000101'::uuid, 42, '20:00', '銀座・ワインバー',     '前月比較用の思い出',           null, 35.6719, 139.7648)
)
insert into public.memories (id, owner_user_id, happened_at, place_name, memo, photo_path, place_lat, place_lng, created_at, updated_at)
select
  id,
  owner_user_id,
  ((current_date - days_ago)::timestamp + hour_text::time) at time zone 'Asia/Tokyo',
  place_name,
  memo,
  photo_path,
  place_lat,
  place_lng,
  now() - make_interval(days => days_ago),
  now() - make_interval(days => days_ago)
from seed_memories;

insert into public.memory_tagged_users (memory_id, tagged_user_id)
values
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000102'),
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000103'),
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000104'),
  ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000104'),
  ('10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000105'),
  ('10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000106'),
  ('10000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000107'),
  ('10000000-0000-4000-8000-000000000005', '00000000-0000-4000-8000-000000000108'),
  ('10000000-0000-4000-8000-000000000006', '00000000-0000-4000-8000-000000000101'),
  ('10000000-0000-4000-8000-000000000006', '00000000-0000-4000-8000-000000000103'),
  ('10000000-0000-4000-8000-000000000007', '00000000-0000-4000-8000-000000000101'),
  ('10000000-0000-4000-8000-000000000008', '00000000-0000-4000-8000-000000000104'),
  ('10000000-0000-4000-8000-000000000009', '00000000-0000-4000-8000-000000000105'),
  ('10000000-0000-4000-8000-000000000010', '00000000-0000-4000-8000-000000000101'),
  ('10000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000106'),
  ('10000000-0000-4000-8000-000000000012', '00000000-0000-4000-8000-000000000107'),
  ('10000000-0000-4000-8000-000000000013', '00000000-0000-4000-8000-000000000101'),
  ('10000000-0000-4000-8000-000000000014', '00000000-0000-4000-8000-000000000108'),
  ('10000000-0000-4000-8000-000000000015', '00000000-0000-4000-8000-000000000103'),
  ('10000000-0000-4000-8000-000000000016', '00000000-0000-4000-8000-000000000104'),
  ('10000000-0000-4000-8000-000000000017', '00000000-0000-4000-8000-000000000105'),
  ('10000000-0000-4000-8000-000000000018', '00000000-0000-4000-8000-000000000102')
on conflict (memory_id, tagged_user_id) do nothing;

insert into public.memory_likes (memory_id, user_id)
values
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000102'),
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000103'),
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000104'),
  ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000101'),
  ('10000000-0000-4000-8000-000000000006', '00000000-0000-4000-8000-000000000101'),
  ('10000000-0000-4000-8000-000000000010', '00000000-0000-4000-8000-000000000101'),
  ('10000000-0000-4000-8000-000000000013', '00000000-0000-4000-8000-000000000102')
on conflict (memory_id, user_id) do nothing;

insert into public.memory_reports (id, memory_id, reporter_user_id, reason, created_at)
values
  ('30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000017', '00000000-0000-4000-8000-000000000101', 'other', now() - interval '1 day')
on conflict (memory_id, reporter_user_id) do update set reason = excluded.reason;

select
  (select count(*) from public.profiles where user_id like 'dev_%') as dev_profiles,
  (select count(*) from public.friendships where user_a_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110') as dev_friendships,
  (select count(*) from public.daily_statuses where user_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110') as dev_statuses,
  (select count(*) from public.memories where owner_user_id between '00000000-0000-4000-8000-000000000101' and '00000000-0000-4000-8000-000000000110') as dev_memories,
  (select count(*) from public.memory_tagged_users where memory_id between '10000000-0000-4000-8000-000000000001' and '10000000-0000-4000-8000-000000000018') as dev_memory_tagged_users,
  (select count(*) from public.memory_likes where memory_id between '10000000-0000-4000-8000-000000000001' and '10000000-0000-4000-8000-000000000018') as dev_likes;
