# Griphos — Supabase stoppen (Daten bleiben in Docker-Volumes erhalten)
$ErrorActionPreference = 'Stop'
Push-Location 'C:\src\supabase\docker'
try {
  docker compose down
  Write-Host '✓ Supabase gestoppt. Daten bleiben erhalten.'
  Write-Host '  → Komplett löschen mit:  docker compose down -v'
} finally {
  Pop-Location
}
