-- Migration 0013 — Duell-Finish-Härtung (Audit F10, F21, F23-Server).
--
-- 1. winner_id/finish_reason: Der Ausgang wird beim Finish einmalig
--    persistiert — beide Clients rendern denselben Sieger, statt ihn
--    lokal (und ggf. widersprüchlich) zu berechnen.
-- 2. validate_duel_update: erlaubt die neuen Spalten nur in der
--    playing→finished-Transition; Requests ohne JWT-Kontext
--    (service_role/postgres/Cron) passieren den Trigger ungeprüft.
-- 3. server_now(): RPC für den Client-Clock-Offset (F21).
-- 4. pg_cron: räumt verwaiste Lobbys/Duelle ab (F23) — best effort,
--    Migration läuft auch ohne pg_cron durch.

alter table duels add column if not exists winner_id uuid;
alter table duels add column if not exists finish_reason text;

alter table duels drop constraint if exists duels_finish_reason_check;
alter table duels add constraint duels_finish_reason_check check (
  finish_reason is null
  or finish_reason in ('completed','timeout','surrender','disconnect')
);

-- ---------------------------------------------------------------------------
-- Trigger-Update: identisch zu 0006 plus winner/reason-Regeln und
-- Admin-Bypass (uid is null = kein Client-Request).
-- ---------------------------------------------------------------------------
create or replace function public.validate_duel_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $func$
declare
  uid uuid := auth.uid();
  immutable_unchanged boolean;
begin
  -- Kein JWT-Kontext: service_role, Studio oder Cron — voller Zugriff.
  -- Jeder Client-Request (auch anonym) trägt eine auth.uid().
  if uid is null then
    return new;
  end if;

  immutable_unchanged :=
    new.code is not distinct from old.code
    and new.host_id is not distinct from old.host_id
    and new.question_seed is not distinct from old.question_seed
    and new.question_count is not distinct from old.question_count
    and new.created_at is not distinct from old.created_at
    and new.mode is not distinct from old.mode
    and new.time_limit_seconds is not distinct from old.time_limit_seconds
    and new.lives_per_player is not distinct from old.lives_per_player
    and new.input_style is not distinct from old.input_style
    and new.difficulty_band is not distinct from old.difficulty_band;

  if not immutable_unchanged then
    raise exception 'immutable duel fields cannot be changed' using errcode = '42501';
  end if;

  -- Guest joins an open lobby. The shared clock is stamped server-side.
  if old.status = 'waiting'
     and old.guest_id is null
     and old.host_id <> uid
     and new.guest_id = uid
     and new.status = 'playing'
     and new.rematch_code is not distinct from old.rematch_code
     and new.winner_id is null
     and new.finish_reason is null then
    new.started_at := now();
    return new;
  end if;

  -- Host cancels an unjoined lobby.
  if old.status = 'waiting'
     and old.host_id = uid
     and new.status = 'cancelled'
     and new.guest_id is not distinct from old.guest_id
     and new.started_at is not distinct from old.started_at
     and new.rematch_code is not distinct from old.rematch_code
     and new.winner_id is null
     and new.finish_reason is null then
    return new;
  end if;

  -- Either participant finishes an active duel. winner_id/finish_reason
  -- werden hier genau einmal gesetzt (F10) — winner muss Teilnehmer sein,
  -- null heißt Unentschieden.
  if old.status = 'playing'
     and (old.host_id = uid or old.guest_id = uid)
     and new.status = 'finished'
     and new.guest_id is not distinct from old.guest_id
     and new.started_at is not distinct from old.started_at
     and new.rematch_code is not distinct from old.rematch_code
     and (new.winner_id is null
          or new.winner_id = old.host_id
          or new.winner_id = old.guest_id) then
    return new;
  end if;

  -- Either participant may attach exactly one rematch code after the duel
  -- ended; Ausgangs-Felder bleiben dabei unangetastet.
  if old.status = 'finished'
     and (old.host_id = uid or old.guest_id = uid)
     and old.rematch_code is null
     and new.rematch_code is not null
     and new.status = old.status
     and new.guest_id is not distinct from old.guest_id
     and new.started_at is not distinct from old.started_at
     and new.winner_id is not distinct from old.winner_id
     and new.finish_reason is not distinct from old.finish_reason then
    return new;
  end if;

  raise exception 'duel update not allowed from % to %', old.status, new.status
    using errcode = '42501';
end;
$func$;

-- ---------------------------------------------------------------------------
-- server_now(): Client bestimmt damit einmalig seinen Clock-Offset (F21).
-- ---------------------------------------------------------------------------
create or replace function public.server_now()
returns timestamptz
language sql
stable
as $$ select now() $$;

revoke all on function public.server_now() from public;
grant execute on function public.server_now() to authenticated;

-- ---------------------------------------------------------------------------
-- Cleanup verwaister Duelle (F23): Lobbys ohne Join nach 1 h canceln,
-- hängende playing-Duelle nach 6 h beenden. Läuft als postgres → passiert
-- den Trigger über den uid-null-Bypass.
-- ---------------------------------------------------------------------------
do $do$
begin
  create extension if not exists pg_cron;
  perform cron.unschedule(jobid)
    from cron.job where jobname = 'griphos-expire-stale-duels';
  perform cron.schedule(
    'griphos-expire-stale-duels',
    '*/30 * * * *',
    $job$
      update duels set status = 'cancelled'
        where status = 'waiting' and created_at < now() - interval '1 hour';
      update duels set status = 'finished', finish_reason = 'timeout'
        where status = 'playing' and started_at < now() - interval '6 hours';
    $job$
  );
exception when others then
  raise notice 'pg_cron nicht verfuegbar (%) — Cleanup-Job uebersprungen', sqlerrm;
end
$do$;
