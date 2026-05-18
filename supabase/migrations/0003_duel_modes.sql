-- Migration 0003 — Duel-Mode-Erweiterung.
-- Erweitert duels um Modus (race | parallel), Zeit-/Leben-Konfig,
-- Eingabeart, Schwierigkeitsband und einen Start-Zeitstempel.
--
-- NULL semantics:
--   time_limit_seconds NULL = ohne Zeitlimit
--   lives_per_player   NULL = unbegrenzte Leben
--
-- Apply AFTER 0001 + 0002.

alter table duels
  add column if not exists mode text not null default 'race'
    check (mode in ('race', 'parallel'));

alter table duels
  add column if not exists time_limit_seconds int
    check (time_limit_seconds is null or time_limit_seconds between 30 and 7200);

alter table duels
  add column if not exists lives_per_player int
    check (lives_per_player is null or lives_per_player between 1 and 50);

alter table duels
  add column if not exists input_style text not null default 'multipleChoice'
    check (input_style in ('multipleChoice', 'letterbox'));

alter table duels
  add column if not exists difficulty_band text not null default 'salon'
    check (difficulty_band in ('einstieg', 'salon', 'meisterpruefung'));

alter table duels
  add column if not exists started_at timestamptz;

-- question_count default hochziehen, damit zeit-basierte Duelle nicht
-- nach 5 Fragen verhungern. Bestehende Zeilen bleiben unverändert.
alter table duels
  alter column question_count set default 100;
