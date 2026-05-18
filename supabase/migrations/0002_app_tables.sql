-- Migration 0002 — Eleutheria-spezifische Tabellen und gehärtete RLS-Policies.
-- Wird NACH 0001_init.sql angewendet.
--
-- Was hier passiert:
--   1. profiles  — anonymer User + unique display_name
--   2. scores    — moderner Leaderboard mit Pure/Casual-Trennung via is_pure
--   3. duel_ratings — Elo-Tabelle (jetzt nur Schema, befüllt später Auto-Pairing)
--   4. RLS-Policies aus 0001 werden gegen "anyone can write" gehärtet
--   5. daily_scores (aus 0001) wird vorerst behalten, aber Insert-Policy
--      auf player_id = auth.uid() eingeschränkt

create extension if not exists citext;

-- ============================================================
-- profiles
-- ============================================================
create table if not exists profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name citext unique not null,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now(),
  constraint display_name_len   check (char_length(display_name::text) between 2 and 24),
  constraint display_name_chars check (display_name::text ~* '^[a-z0-9 _.-]+$')
);

alter table profiles enable row level security;

drop policy if exists profiles_read_all on profiles;
create policy profiles_read_all on profiles
  for select using (true);

drop policy if exists profiles_insert_own on profiles;
create policy profiles_insert_own on profiles
  for insert with check (id = auth.uid());

drop policy if exists profiles_update_own on profiles;
create policy profiles_update_own on profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- Trigger: updated_at automatisch aktualisieren bei UPDATE
create or replace function public.set_updated_at() returns trigger
  language plpgsql as $func$
begin
  new.updated_at = now();
  return new;
end;
$func$;

drop trigger if exists profiles_set_updated_at on profiles;
create trigger profiles_set_updated_at
  before update on profiles
  for each row execute function public.set_updated_at();

-- ============================================================
-- scores — Leaderboard (Pure ohne Joker, Casual mit Joker-Abzug)
-- ============================================================
-- Score-Logik (Reminder, wird in der App umgesetzt):
--   raw_score      = Summe der Frage-Punkte ohne Abzug
--   score          = raw_score minus 50 % der Punkte von Fragen,
--                    in denen mindestens ein Joker eingesetzt wurde
--   jokers_used    = Anzahl Fragen mit Joker (nicht einzelne Klicks)
--   is_pure        = jokers_used == 0  (generierte Spalte)
-- Leaderboard:
--   Pure-Tab  → WHERE is_pure = true
--   Casual-Tab → alle, sortiert nach score

create table if not exists scores (
  id              uuid primary key default gen_random_uuid(),
  player_id       uuid not null references auth.users(id) on delete cascade,
  display_name    text not null,
  mode            text not null check (mode in (
    'classic','quizRush','suddenDeath','daily','letterbox','category','practice'
  )),
  variant         text,  -- '1min' | '3min' | '5min' | 'endless' | null
  difficulty_band text not null check (difficulty_band in (
    'einstieg','salon','meisterpruefung'
  )),
  raw_score       int  not null check (raw_score >= 0),
  score           int  not null check (score >= 0),
  correct         int  not null check (correct >= 0),
  answered        int  not null check (answered >= 0),
  jokers_used     int  not null default 0 check (jokers_used >= 0),
  joker_setting   text not null check (joker_setting in ('off','one','three','always')),
  is_pure         boolean generated always as (jokers_used = 0) stored,
  session_id      text not null,
  played_at       timestamptz default now(),
  unique (player_id, session_id)
);

create index if not exists scores_mode_band_score_idx
  on scores (mode, difficulty_band, score desc);

create index if not exists scores_pure_mode_band_score_idx
  on scores (is_pure, mode, difficulty_band, score desc);

create index if not exists scores_played_at_idx
  on scores (played_at desc);

alter table scores enable row level security;

drop policy if exists scores_read_all on scores;
create policy scores_read_all on scores
  for select using (true);

drop policy if exists scores_insert_own on scores;
create policy scores_insert_own on scores
  for insert with check (player_id = auth.uid());

-- UPDATE/DELETE implizit verboten (keine Policy = RLS lehnt ab)

-- ============================================================
-- duel_ratings — Elo (Schema jetzt, befüllt später)
-- ============================================================
create table if not exists duel_ratings (
  player_id    uuid primary key references auth.users(id) on delete cascade,
  rating       int not null default 1000 check (rating between 0 and 4000),
  games        int not null default 0 check (games >= 0),
  wins         int not null default 0 check (wins >= 0),
  losses       int not null default 0 check (losses >= 0),
  draws        int not null default 0 check (draws >= 0),
  last_played  timestamptz,
  updated_at   timestamptz default now()
);

alter table duel_ratings enable row level security;

drop policy if exists duel_ratings_read_all on duel_ratings;
create policy duel_ratings_read_all on duel_ratings
  for select using (true);

-- INSERT/UPDATE/DELETE für Clients implizit verboten.
-- Schreiben passiert per service_role (Server-Funktion nach Match-Ende).

-- ============================================================
-- Bestehende RLS-Policies aus 0001 verschärfen
-- ============================================================

-- duels
drop policy if exists "duels_read_all" on duels;
drop policy if exists "duels_write_all" on duels;

create policy duels_read_all on duels
  for select using (true);

create policy duels_insert_own on duels
  for insert with check (host_id = auth.uid());

create policy duels_update_participants on duels
  for update
  using       (host_id = auth.uid() or guest_id = auth.uid())
  with check  (host_id = auth.uid() or guest_id = auth.uid());

-- duel_answers
drop policy if exists "duel_answers_read_all" on duel_answers;
drop policy if exists "duel_answers_write_all" on duel_answers;

create policy duel_answers_read_all on duel_answers
  for select using (true);

create policy duel_answers_insert_own on duel_answers
  for insert with check (player_id = auth.uid());

-- daily_scores: legacy, wird später durch scores (mode='daily') ersetzt;
-- bis dahin Insert auf eigene player_id einschränken
drop policy if exists "daily_scores_read_all" on daily_scores;
drop policy if exists "daily_scores_write_all" on daily_scores;

create policy daily_scores_read_all on daily_scores
  for select using (true);

create policy daily_scores_insert_own on daily_scores
  for insert with check (player_id = auth.uid());
