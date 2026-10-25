# 05-sync-outputs.ps1 — kéo output + project từ server về máy local
# Chạy trên Windows:
#   $env:MOVIE_HOST="1.2.3.4"; $env:MOVIE_PORT="2222"
#   powershell -ExecutionPolicy Bypass -File scripts/05-sync-outputs.ps1
#
# Không hard-code host/port trong file này.

param(
    [string]$RemoteHost = $env:MOVIE_HOST,
    [int]$Port = 22,
    [string]$User = "root",
    [string]$RemoteProject = "/workspace/movie-studio",
    [string]$LocalRoot = ".\sync",
    [string]$Project = ""
)

$ErrorActionPreference = "Stop"

if (-not $RemoteHost) {
    throw "Thiếu host. Đặt biến môi trường MOVIE_HOST hoặc truyền -RemoteHost."
}
if ($env:MOVIE_PORT) {
    $Port = [int]$env:MOVIE_PORT
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$target = Join-Path $LocalRoot $stamp
New-Item -ItemType Directory -Force -Path $target | Out-Null

Write-Host "=== Sync ${RemoteHost}:${Port} -> $target ==="

$remoteData = if ($Project) { "$RemoteProject/$Project" } else { $RemoteProject }

Write-Host "[1/3] project data"
scp -P $Port -r "${User}@${RemoteHost}:${remoteData}/project.json" $target 2>$null
scp -P $Port -r "${User}@${RemoteHost}:${remoteData}/02_boards" $target 2>$null
scp -P $Port -r "${User}@${RemoteHost}:${remoteData}/03_clips" $target 2>$null

Write-Host "[2/3] comfy output"
scp -P $Port -r "${User}@${RemoteHost}:/workspace/ComfyUI/output" (Join-Path $target "comfy_output") 2>$null

Write-Host "[3/3] log"
ssh -p $Port "${User}@${RemoteHost}" "tail -n 200 /var/log/portal/comfyui.log" |
    Out-File -Encoding utf8 (Join-Path $target "comfyui.log")

Write-Host ""
Write-Host "Xong. Dữ liệu tại: $target"
Get-ChildItem $target | Select-Object Name, Length, LastWriteTime
