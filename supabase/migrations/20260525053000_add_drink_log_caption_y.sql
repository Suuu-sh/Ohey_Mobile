alter table public.drink_logs
  add column if not exists caption_y double precision not null default 0.5;

alter table public.drink_logs
  drop constraint if exists drink_logs_caption_y_check;

alter table public.drink_logs
  add constraint drink_logs_caption_y_check
  check (caption_y >= 0 and caption_y <= 1);
