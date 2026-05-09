-- Sophia Quiz — Datenbank-Schema
-- Wird sowohl lokal (Docker) als auch auf dem Linux-Server unverändert ausgeführt.

create table if not exists duels (
  code text primary key,
  host_id uuid not null,
  guest_id uuid,
  question_seed bigint not null,
  question_count int not null default 5,
  status text not null default 'waiting' check (status in ('waiting','playing','finished')),
  created_at timestamptz default now()
);

create table if not exists duel_answers (
  duel_code text references duels(code) on delete cascade,
  player_id uuid not null,
  question_index int not null,
  selected_index int not null,
  was_correct boolean not null,
  time_taken_ms int not null,
  points int not null,
  submitted_at timestamptz default now(),
  primary key (duel_code, player_id, question_index)
);

create table if not exists daily_scores (
  day date not null,
  player_id uuid not null,
  display_name text not null,
  score int not null,
  correct int not null,
  submitted_at timestamptz default now(),
  primary key (day, player_id)
);

-- Realtime publication (Supabase liefert die per default)
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime for table duels, duel_answers;
  else
    -- nur hinzufügen, falls noch nicht enthalten
    begin
      alter publication supabase_realtime add table duels;
    exception when duplicate_object then null; end;
    begin
      alter publication supabase_realtime add table duel_answers;
    exception when duplicate_object then null; end;
  end if;
end $$;

-- Row-Level-Security
-- Hinweis: Diese Policies sind permissiv (für Entwicklung).
-- Vor Produktivbetrieb mit echten Auth-Regeln ersetzen.

alter table duels enable row level security;
drop policy if exists "duels_read_all" on duels;
create policy "duels_read_all" on duels for select using (true);
drop policy if exists "duels_write_all" on duels;
create policy "duels_write_all" on duels for all using (true) with check (true);

alter table duel_answers enable row level security;
drop policy if exists "duel_answers_read_all" on duel_answers;
create policy "duel_answers_read_all" on duel_answers for select using (true);
drop policy if exists "duel_answers_write_all" on duel_answers;
create policy "duel_answers_write_all" on duel_answers for all using (true) with check (true);

alter table daily_scores enable row level security;
drop policy if exists "daily_scores_read_all" on daily_scores;
create policy "daily_scores_read_all" on daily_scores for select using (true);
drop policy if exists "daily_scores_write_all" on daily_scores;
create policy "daily_scores_write_all" on daily_scores for all using (true) with check (true);
