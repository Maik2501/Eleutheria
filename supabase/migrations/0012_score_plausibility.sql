-- Migration 0012 — Leaderboard-Plausibilität (Audit B1).
--
-- Clients senden fertig berechnete Scores; bisher prüfte der Server nur
-- `>= 0` und Enum-Zugehörigkeit — `score = 2147483647` per curl landete
-- ungebremst auf dem Pure-Board. Diese Checks deckeln den groben Betrug;
-- ein serverseitiges Nachrechnen (SECURITY-DEFINER-RPC) kann später folgen.
--
-- Punktemodell des Clients (game_session_controller._scoreFor):
--   Basis 100 + (difficulty-1)*25 ≤ 200, Speed-Bonus ≤ 50
--   → maximal 250 Punkte pro beantworteter Frage.
--
-- Modus-Kapazitäten (GameConfig, Stand 2026-06): classic/letterbox/
-- category/practice 10 Fragen, daily 5, suddenDeath 50, quizRush 200.
-- ACHTUNG: Der Mode-Cap-Check enumeriert alle Modi — ein neuer Modus in
-- 0002s Enum braucht hier einen neuen Zweig, sonst failen seine Inserts.

alter table scores
  add constraint scores_correct_le_answered check (correct <= answered);

alter table scores
  add constraint scores_score_le_raw check (score <= raw_score);

alter table scores
  add constraint scores_raw_per_question_cap check (raw_score <= answered * 250);

alter table scores
  add constraint scores_jokers_le_answered check (jokers_used <= answered);

alter table scores
  add constraint scores_mode_answered_cap check (
    (mode in ('classic','letterbox','category','practice') and answered <= 30)
    or (mode = 'daily'       and answered <= 10)
    or (mode = 'quizRush'    and answered <= 200)
    or (mode = 'suddenDeath' and answered <= 50)
  );

-- ---------------------------------------------------------------------------
-- Insert-Rate-Limit: anonyme Sessions sind gratis, aber pro Spieler-UID sind
-- mehr als 40 Score-Inserts/Stunde kein menschliches Spielverhalten
-- (schnellste legitime Session ist die 1-Minuten-Rush).
-- ---------------------------------------------------------------------------
create or replace function public.scores_rate_limit()
returns trigger
language plpgsql
set search_path = public
as $func$
declare
  recent int;
begin
  select count(*) into recent
  from scores
  where player_id = new.player_id
    and played_at > now() - interval '1 hour';
  if recent >= 40 then
    raise exception 'score rate limit exceeded' using errcode = '54000';
  end if;
  return new;
end;
$func$;

drop trigger if exists scores_rate_limit on scores;
create trigger scores_rate_limit
  before insert on scores
  for each row execute function public.scores_rate_limit();
