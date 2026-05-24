alter table public.drink_logs
  add column if not exists marker_rarity text not null default 'normal';

alter table public.drink_logs
  drop constraint if exists drink_logs_marker_rarity_check;

alter table public.drink_logs
  add constraint drink_logs_marker_rarity_check
  check (marker_rarity in ('normal', 'uncommon', 'rare', 'super_rare', 'ultra_rare', 'secret'));
