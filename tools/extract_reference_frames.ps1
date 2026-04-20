# Extrae PNGs de un video de referencia para comparar con capturas del juego.
# Uso (PowerShell):
#   .\tools\extract_reference_frames.ps1 -Video "C:\ruta\video.mp4"
# Requiere ffmpeg en PATH (winget install Gyan.FFmpeg).

param(
    [Parameter(Mandatory = $true)][string]$Video,
    [string]$OutDir = "",
    [int]$Fps = 2
)

if (-not (Test-Path -LiteralPath $Video)) {
    Write-Error "No existe el archivo: $Video"
    exit 1
}

if ($OutDir -eq "") {
    $OutDir = Join-Path (Split-Path (Resolve-Path $Video) -Parent) "ref_frames_png"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$pattern = Join-Path $OutDir "ref_%04d.png"

& ffmpeg -y -i $Video -vf "fps=$Fps" $pattern 2>&1 | Out-Host
Write-Host "Frames en: $OutDir"
