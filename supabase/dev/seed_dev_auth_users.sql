create extension if not exists pgcrypto;

do $$
begin
  if nullif(current_setting('app.seed_password', true), '') is null then
    raise exception 'Set app.seed_password before running dev seed';
  end if;
end;
$$;

with seed_password(value) as (
  select nullif(current_setting('app.seed_password', true), '')
), seed(id, email, password, display_name, user_id, character_key) as (
  values
    ('00000000-0000-4000-8000-000000000101'::uuid, 'dev-yuta@nomo.app', (select value from seed_password), 'ユウタ', 'dev_yuta', 'memu'),
    ('00000000-0000-4000-8000-000000000102'::uuid, 'dev-ken@nomo.app', (select value from seed_password), 'ケン', 'dev_ken', 'saigou'),
    ('00000000-0000-4000-8000-000000000103'::uuid, 'dev-ryo@nomo.app', (select value from seed_password), 'リョウ', 'dev_ryo', 'chi'),
    ('00000000-0000-4000-8000-000000000104'::uuid, 'dev-haru@nomo.app', (select value from seed_password), 'ハル', 'dev_haru', 'uo'),
    ('00000000-0000-4000-8000-000000000105'::uuid, 'dev-takumi@nomo.app', (select value from seed_password), 'タクミ', 'dev_takumi', 'aren')
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
    ('00000000-0000-4000-8000-000000000101'::uuid, 'dev-yuta@nomo.app'),
    ('00000000-0000-4000-8000-000000000102'::uuid, 'dev-ken@nomo.app'),
    ('00000000-0000-4000-8000-000000000103'::uuid, 'dev-ryo@nomo.app'),
    ('00000000-0000-4000-8000-000000000104'::uuid, 'dev-haru@nomo.app'),
    ('00000000-0000-4000-8000-000000000105'::uuid, 'dev-takumi@nomo.app')
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
  ('00000000-0000-4000-8000-000000000101', 'ユウタ', 'dev_yuta', 'male', 'memu', 'nomo_avatar:v1:0:1:2:0:0:3', false),
  ('00000000-0000-4000-8000-000000000102', 'ケン', 'dev_ken', 'male', 'saigou', 'nomo_avatar:v1:5:2:5:2:1:0', false),
  ('00000000-0000-4000-8000-000000000103', 'リョウ', 'dev_ryo', 'male', 'chi', 'nomo_avatar:v1:2:6:0:3:0:1', false),
  ('00000000-0000-4000-8000-000000000104', 'ハル', 'dev_haru', 'female', 'uo', 'nomo_avatar:v1:1:4:3:1:2:3', false),
  ('00000000-0000-4000-8000-000000000105', 'タクミ', 'dev_takumi', 'male', 'aren', 'nomo_avatar:v1:3:5:6:0:1:0', false)
on conflict (id) do update set
  display_name = excluded.display_name,
  user_id = excluded.user_id,
  character_key = excluded.character_key,
  avatar_url = excluded.avatar_url,
  gender = excluded.gender,
  updated_at = now();

insert into public.friendships (user_a_id, user_b_id)
values
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000102'),
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000103'),
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000104'),
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000105')
on conflict (user_a_id, user_b_id) do nothing;

select p.id, p.display_name, p.user_id, p.character_key, u.email
from public.profiles p
join auth.users u on u.id = p.id
where p.user_id like 'dev_%'
order by p.user_id;
