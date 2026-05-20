# Sophia -- lokales Supabase via Docker starten + Schema migrieren.
# Nutzung:  .\scripts\supabase-up.ps1
#
# Idempotent: jede *.sql in supabase/migrations/ wird lexikographisch
# durchgespielt. Erfolgreich angewandte Migrationen landen in
# public.schema_migrations und werden bei folgenden Aufrufen uebersprungen.
#
# Bestands-Erkennung: ist die Tracker-Tabelle leer, aber das Schema zeigt
# schon Spuren (duels.mode aus 0003), werden alle vorhandenen Dateien
# einmalig als "schon angewandt" markiert -- so vermeidet das Skript
# Double-Apply auf einer Bestandsinstallation.
#
# Ports:
#   8000  -- Supabase API (Kong) + Studio
#   5432  -- Postgres (intern im Docker-Netz)

$ErrorActionPreference = 'Stop'

$supabase = 'C:\src\supabase\docker'
if (-not (Test-Path "$supabase\docker-compose.yml")) {
  throw "Supabase docker-compose nicht gefunden unter $supabase. Repo zuerst klonen: git clone --depth 1 https://github.com/supabase/supabase.git C:\src\supabase"
}
if (-not (Test-Path "$supabase\.env")) {
  Copy-Item "$supabase\.env.example" "$supabase\.env"
  Write-Host '.env aus .env.example erstellt'
}

function Invoke-Psql {
  param(
    [Parameter(Mandatory)][string]$Sql,
    [switch]$StopOnError,
    [switch]$Quiet
  )
  $psqlArgs = @('compose','exec','-T','db','psql','-U','postgres','-d','postgres')
  if ($StopOnError) { $psqlArgs += @('-v','ON_ERROR_STOP=1') }
  if ($Quiet) {
    $output = $Sql | & docker @psqlArgs 2>$null
  } else {
    $output = $Sql | & docker @psqlArgs
  }
  return @{ Output = $output; ExitCode = $LASTEXITCODE }
}

function Invoke-PsqlQuery {
  # -t -A: tuples only, no alignment -- one value per line, easy to parse.
  param([Parameter(Mandatory)][string]$Query)
  $output = & docker compose exec -T db psql -U postgres -d postgres -tAc $Query
  return @{ Output = $output; ExitCode = $LASTEXITCODE }
}

Push-Location $supabase
try {
  Write-Host '-> Container starten...'
  docker compose up -d

  Write-Host '-> Warte bis Postgres bereit ist...'
  $deadline = (Get-Date).AddMinutes(3)
  $ready = $false
  while ((Get-Date) -lt $deadline) {
    docker compose exec -T db pg_isready -U postgres -h localhost *>$null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw 'Postgres in 3 Minuten nicht bereit geworden.' }
  Write-Host 'OK Postgres bereit'

  # -- Migration runner -------------------------------------------------
  $migrationDir =
    (Resolve-Path (Join-Path $PSScriptRoot '..\supabase\migrations')).Path
  $files = @(Get-ChildItem -Path $migrationDir -Filter '*.sql' |
             Sort-Object Name)
  if ($files.Count -eq 0) {
    Write-Host 'Keine Migrationen gefunden -- Schema-Schritt uebersprungen.'
    return
  }

  Write-Host '-> Tracker-Tabelle public.schema_migrations sicherstellen...'
  $bootstrap = 'create table if not exists public.schema_migrations (filename text primary key, applied_at timestamptz not null default now());'
  $r = Invoke-Psql -Sql $bootstrap -StopOnError -Quiet
  if ($r.ExitCode -ne 0) { throw 'Tracker-Tabelle konnte nicht angelegt werden.' }

  $appliedRaw = (Invoke-PsqlQuery -Query 'select filename from public.schema_migrations').Output
  $applied = @{}
  foreach ($line in @($appliedRaw)) {
    $trim = ([string]$line).Trim()
    if ($trim) { $applied[$trim] = $true }
  }

  # First-Run-Backfill: Tracker leer, aber 0003 schon im Schema?
  # Dann liegt eine vor-Tracker-Migration vor -- alle vorhandenen Files
  # als angewandt markieren, damit nichts doppelt fliegt.
  if ($applied.Count -eq 0) {
    $probeSql = "select exists (select 1 from information_schema.columns where table_schema='public' and table_name='duels' and column_name='mode')"
    $probe = (Invoke-PsqlQuery -Query $probeSql).Output
    if (([string]$probe).Trim() -eq 't') {
      Write-Host '-> Bestand erkannt -- markiere bestehende Migrationen als angewandt'
      foreach ($f in $files) {
        $insert = "insert into public.schema_migrations (filename) values ('$($f.Name)') on conflict do nothing;"
        Invoke-Psql -Sql $insert -Quiet | Out-Null
        $applied[$f.Name] = $true
      }
    }
  }

  # Anwenden + Erfolg im Tracker eintragen.
  $appliedNow = 0
  foreach ($f in $files) {
    if ($applied.ContainsKey($f.Name)) {
      Write-Host "   skip $($f.Name)"
      continue
    }
    Write-Host "-> apply $($f.Name)..."
    $sql = Get-Content $f.FullName -Raw -Encoding utf8
    $apply = Invoke-Psql -Sql $sql -StopOnError
    if ($apply.ExitCode -ne 0) {
      throw "Migration $($f.Name) abgebrochen (exit $($apply.ExitCode))."
    }
    $record = "insert into public.schema_migrations (filename) values ('$($f.Name)');"
    Invoke-Psql -Sql $record -StopOnError -Quiet | Out-Null
    $appliedNow++
  }

  # PostgREST liest Schemas aus dem Cache; ohne reload sieht die App neue
  # Spalten erst nach Container-Neustart.
  Write-Host '-> PostgREST schema reload...'
  Invoke-Psql -Sql "notify pgrst, 'reload schema';" -Quiet | Out-Null

  if ($appliedNow -eq 0) {
    Write-Host 'OK Alle Migrationen bereits angewandt'
  } else {
    Write-Host "OK $appliedNow neue Migration(en) angewandt"
  }
} finally {
  Pop-Location
}

Write-Host ''
Write-Host '----------------------------------------'
Write-Host '  Supabase laeuft.'
Write-Host '  Studio:  http://localhost:8000'
Write-Host '  Login:   supabase / this_password_is_insecure_and_should_be_updated'
Write-Host '  API:     http://localhost:8000'
Write-Host '----------------------------------------'
