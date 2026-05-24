-- ============================================================
-- 0008 — feedback
-- ============================================================
-- Strukturierter Rückkanal in die App:
--   * question_report     — aus dem Reveal-Panel (eine konkrete Frage melden)
--   * general_feedback    — aus den Einstellungen (Idee/Bug/Lob)
--   * question_suggestion — aus den Einstellungen (Zitat + Quelle + Begründung)
--
-- Anonymous-Auth-kompatibel: profile_id darf NULL sein (z. B. wenn der
-- Client gerade keine Session hat), Insert ist aber nur möglich, wenn
-- der Caller authentifiziert ist (auch Anonymous-Sessions reichen).
-- Lesen darf niemand außer service_role / Studio.

create table if not exists feedback (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),
  profile_id    uuid references auth.users(id) on delete set null,
  type          text not null check (type in (
    'question_report','general_feedback','question_suggestion'
  )),
  category      text,
  question_id   text,
  -- Leerstring erlaubt: Bei Frage-Reports reicht oft die Kategorie als
  -- Signal (z. B. "Tippfehler") ohne weiteren Freitext. Pflichttext-Logik
  -- lebt im Client (FeedbackSheet), nicht in der DB.
  message       text not null check (char_length(message) <= 4000),
  contact_email text check (
    contact_email is null
    or contact_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  ),
  app_version   text,
  platform      text check (
    platform is null
    or platform in ('ios','android','web','macos','windows','linux','unknown')
  )
);

create index if not exists feedback_type_created_idx
  on feedback (type, created_at desc);

create index if not exists feedback_question_id_idx
  on feedback (question_id)
  where question_id is not null;

alter table feedback enable row level security;

-- Insert nur für eingeloggte (auch Anonymous-) User. Wenn profile_id
-- gesetzt wird, muss sie zur eigenen UID passen.
drop policy if exists feedback_insert_authenticated on feedback;
create policy feedback_insert_authenticated on feedback
  for insert
  with check (
    auth.uid() is not null
    and (profile_id is null or profile_id = auth.uid())
  );

-- Bewusst KEINE select/update/delete-Policy: Clients dürfen Feedback
-- nur einreichen, nicht zurücklesen. Auswertung über Studio/service_role.
