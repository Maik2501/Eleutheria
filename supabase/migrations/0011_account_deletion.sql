-- Migration 0011 — In-App-Account-Löschung (Apple 5.1.1(v), DSGVO Art. 17)
-- + Drop der Legacy-Tabelle daily_scores (Audit B7).
--
-- WICHTIG: Als postgres/Superuser anwenden (wie die bisherigen Migrationen) —
-- der Funktions-Owner braucht DELETE-Rechte auf auth.users.
--
-- Lösch-Semantik:
--   profiles, scores, duel_ratings  → FK on delete cascade über auth.users
--   feedback                        → bleibt anonymisiert erhalten
--                                     (profile_id -> null via FK), die optionale
--                                     Kontakt-E-Mail wird vorab entfernt
--   duels / duel_answers            → KEINE FK auf auth.users, werden hier
--                                     explizit gelöscht (Antworten cascaden
--                                     über duels.code)
--   auth.sessions / refresh_tokens  → Standard-GoTrue-Schema cascadet

-- ---------------------------------------------------------------------------
-- B7: daily_scores ist seit der scores-Tabelle von keinem Code-Pfad genutzt,
-- weltlesbar und mit freiem display_name beschreibbar — weg damit. Das nimmt
-- der Account-Löschung gleichzeitig eine Tabelle ohne FK-Cascade ab.
-- ---------------------------------------------------------------------------
drop table if exists daily_scores;

-- ---------------------------------------------------------------------------
-- delete_account(): löscht das Konto des Callers vollständig.
-- ---------------------------------------------------------------------------
create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public
as $func$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  -- Feedback-Inhalte bleiben (anonymisiert), aber die Kontakt-E-Mail ist
  -- personenbezogen und muss mit dem Konto verschwinden.
  update feedback set contact_email = null where profile_id = uid;

  -- Duelle ohne FK-Netz: alles entfernen, woran der Nutzer beteiligt war.
  -- duel_answers (auch die des Gegners in diesen Duellen) cascaden über
  -- duels.code; eigene Antworten existieren nur in eigenen Duellen, da
  -- submit_duel_answer Teilnehmerschaft erzwingt.
  delete from duels where host_id = uid or guest_id = uid;

  -- Cascadet profiles, scores, duel_ratings; feedback.profile_id -> null;
  -- gibt den display_name wieder frei.
  delete from auth.users where id = uid;
end;
$func$;

revoke all on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;
