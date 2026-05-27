-- ============================================================
-- 0010 — questions + crossword_puzzles
-- ============================================================
-- Inhalte werden weiter lokal kuratiert (cms/ + scripts/), aber
-- zusätzlich nach Supabase gespiegelt, damit Frage- und Puzzle-
-- Erweiterungen ohne neuen App-Release live gehen können.
--
-- Read: für alle erlaubt (auch unauthenticated, falls die App
-- mal anonyme Reads erlauben würde — aktuell läuft sie ja immer
-- mit anonymous session).
-- Write: client-seitig verboten (keine Policies), nur über
-- service_role / Studio / Push-Skript.
--
-- Schema spiegelt das Dart-Modell (siehe lib/data/models/question.dart
-- und lib/features/crossword/models/crossword_puzzle.dart). Bei
-- Schema-Drift gilt: neue Spalten immer NULLABLE oder mit Default,
-- damit ältere Clients nicht brechen.

-- ============================================================
-- questions
-- ============================================================
create table if not exists questions (
  id              text primary key,
  category        text not null check (category in (
    'quoteToPhilosopher',
    'workToAuthor',
    'philosopherToEra',
    'conceptToSchool',
    'completeQuote',
    'whoCriticizedWhom'
  )),
  prompt          text not null,
  options         jsonb not null,
  correct_index   int  not null check (correct_index >= 0),
  difficulty      int  not null check (difficulty between 1 and 5),
  attribution     text,
  explanation     text,
  philosopher_id  text,
  topic_key       text,
  updated_at      timestamptz not null default now(),
  -- jsonb-Sanity: options muss ein Array mit mindestens 2 Einträgen sein.
  constraint questions_options_array
    check (jsonb_typeof(options) = 'array' and jsonb_array_length(options) >= 2)
);

create index if not exists questions_category_difficulty_idx
  on questions (category, difficulty);
create index if not exists questions_updated_at_idx
  on questions (updated_at desc);

alter table questions enable row level security;

drop policy if exists questions_read_all on questions;
create policy questions_read_all on questions
  for select using (true);

-- ============================================================
-- crossword_puzzles
-- ============================================================
-- Words als jsonb-Liste statt eigener Tabelle: das Modell hat genug
-- Felder (row, col, direction, clue, …), dass eine relationale
-- Zerlegung mehr Aufwand wäre als sie wert. Außerdem laden wir Puzzles
-- immer als Ganzes — kein Query-Pattern, das eine Sub-Tabelle bräuchte.
create table if not exists crossword_puzzles (
  id                text primary key,
  title             text not null,
  theme             text not null,
  grid_rows         int  not null check (grid_rows between 1 and 64),
  grid_cols         int  not null check (grid_cols between 1 and 64),
  difficulty        text not null default 'Mittel',
  estimated_minutes int  not null default 8 check (estimated_minutes > 0),
  source_label      text not null default 'Eleutheria',
  words             jsonb not null,
  updated_at        timestamptz not null default now(),
  constraint crossword_words_array
    check (jsonb_typeof(words) = 'array' and jsonb_array_length(words) >= 1)
);

create index if not exists crossword_updated_at_idx
  on crossword_puzzles (updated_at desc);

alter table crossword_puzzles enable row level security;

drop policy if exists crossword_read_all on crossword_puzzles;
create policy crossword_read_all on crossword_puzzles
  for select using (true);

-- Trigger: updated_at bei UPDATE automatisch hochziehen.
-- (Funktion set_updated_at() existiert bereits aus Migration 0002.)
drop trigger if exists questions_set_updated_at on questions;
create trigger questions_set_updated_at
  before update on questions
  for each row execute function public.set_updated_at();

drop trigger if exists crossword_puzzles_set_updated_at on crossword_puzzles;
create trigger crossword_puzzles_set_updated_at
  before update on crossword_puzzles
  for each row execute function public.set_updated_at();
