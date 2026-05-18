-- Migration 0004 — Erlaube Beitritt zu offenen Duell-Lobbies.
--
-- Problem: die Policy aus 0002 (duels_update_participants) lässt nur
-- bestehende Teilnehmer:innen UPDATEn. Eine neu joinende Gast-Spielerin
-- ist aber noch keine Teilnehmerin und sieht die Zeile dadurch nicht
-- als update-able -> PGRST116 (0 rows).
--
-- Fix: zweite, eigenständige Policy, die `guest_id IS NULL`-Rows als
-- update-bar markiert, aber per WITH CHECK sicherstellt, dass nach dem
-- Update der aufrufende User exakt als Gast eingetragen wurde. Damit ist
-- das 6-stellige Lobby-Code "Wer-den-Code-kennt"-Token effektiv die
-- Zugangskontrolle.
--
-- Apply AFTER 0003.

drop policy if exists duels_join_open_lobby on duels;

create policy duels_join_open_lobby on duels
  for update
  using       (guest_id is null)
  with check  (guest_id = auth.uid());
