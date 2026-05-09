# Sophia — App in Chrome starten (mit lokalem Supabase)
# Nutzung:  .\scripts\run.ps1
#
# Ports:
#   8080  — Flutter-Web (die App)
#   8000  — Supabase API (Kong)
#   8000/  — auch das Studio (UI für Tabellen, Auth, …)
$ErrorActionPreference = 'Stop'

# Demo-Anon-Key aus dem Supabase self-hosting Setup.
# Gegen einen frischen Key tauschbar — er muss zum JWT_SECRET in C:\src\supabase\docker\.env passen.
$env:SUPABASE_URL = 'http://localhost:8000'
$env:SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE'

Push-Location $PSScriptRoot\..
try {
  & "C:\src\flutter\bin\flutter.bat" run -d chrome --web-port=8080 `
    --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
    --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
} finally {
  Pop-Location
}
