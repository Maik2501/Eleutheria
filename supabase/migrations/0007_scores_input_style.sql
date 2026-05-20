-- ============================================================
-- 0007 — scores.input_style
-- ============================================================
-- Bisher hat das App-seitige _resolveMode() den input style mit dem
-- GameMode kollabiert: jede Letterbox-Session landete als
-- mode='letterbox', egal ob darunter Klassisch oder Quiz-Rush gespielt
-- wurde. Das vermischt orthogonale Achsen und macht eine saubere
-- Bestenliste pro Modus unmöglich, sobald Letterbox im Spiel ist.
--
-- Diese Migration trennt die beiden Achsen:
--   * scores.mode bleibt der echte GameMode (classic/quizRush/…)
--   * scores.input_style ('multipleChoice' | 'letterbox') ist neu
--
-- Backfill: für Altzeilen mit mode='letterbox' rekonstruieren wir den
-- ursprünglichen GameMode aus der variant-Spalte.

alter table scores
  add column if not exists input_style text not null
    default 'multipleChoice'
    check (input_style in ('multipleChoice', 'letterbox'));

-- Backfill der historischen Letterbox-Zeilen.
update scores
   set input_style = 'letterbox',
       mode = case
         when variant in ('10','15','20')                    then 'classic'
         when variant in ('1min','3min','5min','endless')    then 'quizRush'
         -- Falls eine Letterbox-Zeile ohne Variant existiert: best guess
         -- ist Klassisch (das war historisch der einzige Letterbox-Pfad
         -- ohne Variant-Tracking).
         else 'classic'
       end
 where mode = 'letterbox';

-- 'letterbox' aus dem mode-Check entfernen, damit neue Inserts den
-- echten GameMode liefern müssen.
alter table scores drop constraint if exists scores_mode_check;
alter table scores
  add constraint scores_mode_check check (mode in (
    'classic','quizRush','suddenDeath','daily','category','practice'
  ));

-- Hilfsindex für input_style-Filter (kommt häufig zusammen mit mode/band).
create index if not exists scores_input_style_idx
  on scores (input_style, mode, difficulty_band, score desc);
