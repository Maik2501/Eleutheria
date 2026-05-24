-- ============================================================
-- 0009 — "Pure" heißt jetzt: Joker waren komplett deaktiviert
-- ============================================================
-- Bisher: is_pure = (jokers_used = 0)
--   → ein Lauf gilt schon dann als "pure", wenn der Spieler einfach
--     keinen Joker gespielt hat, obwohl welche zur Verfügung standen.
--
-- Neu:    is_pure = (joker_setting = 'off')
--   → "pure" ist nur, was bewusst mit ausgeschalteten Jokern angetreten
--     ist. Wer Joker an hat und sie zufällig nicht braucht, landet
--     trotzdem in der Casual-Liste.
--
-- Generated columns sind in Postgres nicht inplace änderbar — wir
-- droppen den abhängigen Index, droppen die Spalte, legen sie neu an
-- und stellen den Index wieder her.

drop index if exists scores_pure_mode_band_score_idx;

alter table scores drop column is_pure;

alter table scores
  add column is_pure boolean
  generated always as (joker_setting = 'off') stored;

create index if not exists scores_pure_mode_band_score_idx
  on scores (is_pure, mode, difficulty_band, score desc);
