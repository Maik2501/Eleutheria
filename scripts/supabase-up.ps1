# Sophia — lokales Supabase via Docker starten + Schema migrieren
# Nutzung:  .\scripts\supabase-up.ps1
#
# Voraussetzung: Docker Desktop läuft. Beim ersten Start zieht Docker
# ~5 GB Container-Images (postgres, kong, auth, postgrest, realtime,
# storage, studio …). Folgende Starts sind dann in Sekunden hochgefahren.
$ErrorActionPreference = 'Stop'

$supabase = 'C:\src\supabase\docker'
if (-not (Test-Path "$supabase\docker-compose.yml")) {
  throw "Supabase docker-compose nicht gefunden unter $supabase. Repo zuerst klonen: git clone --depth 1 https://github.com/supabase/supabase.git C:\src\supabase"
}
if (-not (Test-Path "$supabase\.env")) {
  Copy-Item "$supabase\.env.example" "$supabase\.env"
  Write-Host "→ .env aus .env.example erstellt"
}

Push-Location $supabase
try {
  Write-Host '→ Container starten…'
  docker compose up -d
  Write-Host '→ Warte bis Postgres bereit ist…'
  $deadline = (Get-Date).AddMinutes(3)
  while ((Get-Date) -lt $deadline) {
    $status = docker compose exec -T db pg_isready -U postgres -h localhost 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host '✓ Postgres bereit'; break }
    Start-Sleep -Seconds 2
  }

  $sql = Join-Path $PSScriptRoot '..\supabase\migrations\0001_init.sql'
  if (Test-Path $sql) {
    Write-Host "→ Schema migrieren ($sql)…"
    Get-Content $sql -Raw | docker compose exec -T db psql -U postgres -d postgres
    Write-Host '✓ Schema angelegt'
  }
} finally {
  Pop-Location
}

Write-Host ''
Write-Host '────────────────────────────────────────'
Write-Host '  Supabase läuft.'
Write-Host '  Studio:  http://localhost:8000'
Write-Host '  Login:   supabase / this_password_is_insecure_and_should_be_updated'
Write-Host '  API:     http://localhost:8000'
Write-Host '────────────────────────────────────────'
