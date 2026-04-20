# Crea el repositorio en GitHub y sube la rama actual (requiere: gh auth login).
# Uso:
#   .\tools\publish-github.ps1
#   .\tools\publish-github.ps1 -RepoName "mi-otro-nombre" -Private

param(
    [string]$RepoName = "ia-rogue-3d-godot",
    [switch]$Private
)

$ErrorActionPreference = "Stop"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

cmd /c "gh auth status >nul 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "No hay sesion en GitHub CLI. Ejecuta primero: gh auth login" -ForegroundColor Yellow
    exit 1
}

$me = (& gh api user -q .login).Trim()
if (-not $me) {
    Write-Error "No se pudo leer el usuario de GitHub."
    exit 1
}

$full = "$me/$RepoName"
$vis = if ($Private) { "--private" } else { "--public" }

if (git remote get-url origin 2>$null) {
    Write-Host "Ya existe 'origin'. Haciendo push..." -ForegroundColor Cyan
    git push -u origin main
    exit $LASTEXITCODE
}

Write-Host "Creando repo $full y subiendo..." -ForegroundColor Cyan
$desc = "IA ROGUE - roguelike 3D pixel art (Godot 4.6)"
& gh repo create $full $vis --source=. --remote=origin --push --description $desc
exit $LASTEXITCODE
