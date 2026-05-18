-- Migration 0006 — Harden duel state transitions, race scoring and score names.
--
-- This keeps the friend-duel protocol client-driven, but moves the critical
-- arbitration points into Postgres:
--   - joining is only possible for waiting lobbies
--   - duel rows can only move through the intended state transitions
--   - race answers are serialized per duel, so only the first correct answer
--     for a question receives points
--   - leaderboard rows must use the caller's reserved profile display_name

-- ---------------------------------------------------------------------------
-- scores: clients may only submit under their reserved remote display name.
-- ---------------------------------------------------------------------------
drop policy if exists scores_insert_own on scores;
create policy scores_insert_own on scores
  for insert with check (
    player_id = auth.uid()
    and exists (
      select 1
      from profiles p
      where p.id = auth.uid()
        and p.display_name::text = scores.display_name
    )
  );

-- ---------------------------------------------------------------------------
-- duels: allow broad update visibility, but validate every actual transition
-- in a trigger below. This is needed because the guest is not yet a participant
-- before joining a waiting lobby.
-- ---------------------------------------------------------------------------
drop policy if exists duels_update_participants on duels;
drop policy if exists duels_join_open_lobby on duels;
drop policy if exists duels_update_allowed on duels;

create policy duels_update_allowed on duels
  for update
  using (
    host_id = auth.uid()
    or guest_id = auth.uid()
    or (status = 'waiting' and guest_id is null)
  )
  with check (
    host_id = auth.uid()
    or guest_id = auth.uid()
  );

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
  if uid is null then
    raise exception 'authentication required' using errcode = '42501';
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
     and new.rematch_code is not distinct from old.rematch_code then
    new.started_at := now();
    return new;
  end if;

  -- Host cancels an unjoined lobby.
  if old.status = 'waiting'
     and old.host_id = uid
     and new.status = 'cancelled'
     and new.guest_id is not distinct from old.guest_id
     and new.started_at is not distinct from old.started_at
     and new.rematch_code is not distinct from old.rematch_code then
    return new;
  end if;

  -- Either participant can finish an active duel.
  if old.status = 'playing'
     and (old.host_id = uid or old.guest_id = uid)
     and new.status = 'finished'
     and new.guest_id is not distinct from old.guest_id
     and new.started_at is not distinct from old.started_at
     and new.rematch_code is not distinct from old.rematch_code then
    return new;
  end if;

  -- Either participant may attach exactly one rematch code after the duel ended.
  if old.status = 'finished'
     and (old.host_id = uid or old.guest_id = uid)
     and old.rematch_code is null
     and new.rematch_code is not null
     and new.status = old.status
     and new.guest_id is not distinct from old.guest_id
     and new.started_at is not distinct from old.started_at then
    return new;
  end if;

  raise exception 'duel update not allowed from % to %', old.status, new.status
    using errcode = '42501';
end;
$func$;

drop trigger if exists duels_validate_update on duels;
create trigger duels_validate_update
  before update on duels
  for each row execute function public.validate_duel_update();

-- ---------------------------------------------------------------------------
-- duel_answers: route writes through an RPC that serializes race submissions.
-- ---------------------------------------------------------------------------
drop policy if exists duel_answers_insert_own on duel_answers;

create or replace function public.submit_duel_answer(
  p_duel_code text,
  p_player_id uuid,
  p_question_index int,
  p_selected_index int,
  p_was_correct boolean,
  p_time_taken_ms int,
  p_points int
)
returns void
language plpgsql
security definer
set search_path = public
as $func$
declare
  uid uuid := auth.uid();
  duel_row duels%rowtype;
  effective_points int := greatest(p_points, 0);
begin
  if uid is null or p_player_id <> uid then
    raise exception 'cannot submit answer for another user' using errcode = '42501';
  end if;

  if p_question_index < 0
     or p_selected_index < -1
     or p_time_taken_ms < 0 then
    raise exception 'invalid answer payload' using errcode = '22023';
  end if;

  select *
  into duel_row
  from duels
  where code = upper(p_duel_code)
  for update;

  if not found then
    raise exception 'duel not found' using errcode = 'P0002';
  end if;

  if duel_row.status <> 'playing' then
    raise exception 'duel is not active' using errcode = '22023';
  end if;

  if p_player_id <> duel_row.host_id
     and p_player_id <> duel_row.guest_id then
    raise exception 'player is not part of duel' using errcode = '42501';
  end if;

  if p_question_index >= duel_row.question_count then
    raise exception 'question index out of range' using errcode = '22023';
  end if;

  -- Race arbitration: the duel row lock serializes both clients. Once a correct
  -- answer exists for this question, later correct answers can still be recorded
  -- but receive no points.
  if duel_row.mode = 'race'
     and p_was_correct
     and exists (
       select 1
       from duel_answers
       where duel_code = duel_row.code
         and question_index = p_question_index
         and was_correct = true
     ) then
    effective_points := 0;
  end if;

  insert into duel_answers (
    duel_code,
    player_id,
    question_index,
    selected_index,
    was_correct,
    time_taken_ms,
    points
  ) values (
    duel_row.code,
    p_player_id,
    p_question_index,
    p_selected_index,
    p_was_correct,
    p_time_taken_ms,
    effective_points
  )
  on conflict (duel_code, player_id, question_index) do nothing;
end;
$func$;

revoke all on function public.submit_duel_answer(
  text, uuid, int, int, boolean, int, int
) from public;
grant execute on function public.submit_duel_answer(
  text, uuid, int, int, boolean, int, int
) to authenticated;
