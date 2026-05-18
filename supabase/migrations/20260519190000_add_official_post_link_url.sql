-- Optional detail links for official feed posts.
-- When link_url is empty/null, the app hides the "詳しく見る" CTA.

alter table public.drink_logs
  add column if not exists link_url text;
