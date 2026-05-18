-- Migration 0005 — Rematch-Verkettung + Cancelled-Status.
--
-- - rematch_code: zeigt vom alten Duell auf das frisch eröffnete Revanche-
--   Duell. Der Client der das Revanche-Duell macht, befüllt diese Spalte
--   damit die Gegenspielerin via watchDuel die Einladung sieht.
-- - status erlaubt jetzt 'cancelled' (Lobby-Timeout, Host bricht ab).
--
-- Apply AFTER 0003 + 0004.

alter table duels
  add column if not exists rematch_code text references duels(code) on delete set null;

-- Status-Check erweitern.
alter table duels drop constraint if exists duels_status_check;
alter table duels add constraint duels_status_check
  check (status in ('waiting','playing','finished','cancelled'));
