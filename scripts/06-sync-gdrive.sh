#!/usr/bin/env bash
# 06-sync-gdrive.sh — đẩy ảnh/video lên Google Drive bằng rclone
#
# Chuẩn bị:
#   rclone config        (tạo remote tên "gdrive")
#   export GDRIVE_REMOTE="gdrive:movie-studio"
#
# Dùng:
#   bash scripts/06-sync-gdrive.sh
#   PROJECT=phim-01 bash scripts/06-sync-gdrive.sh
#   DRY_RUN=1 bash scripts/06-sync-gdrive.sh
#
set -euo pipefail

ROOT="${ROOT:-/workspace/movie-studio}"
PROJECT="${PROJECT:-phim-01}"
REMOTE="${GDRIVE_REMOTE:-gdrive:movie-studio}"
DRY_RUN="${DRY_RUN:-0}"
LOG_DIR="$ROOT/local"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/gdrive-sync.log"

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

command -v rclone >/dev/null || {
  log "LỖI: chưa cài rclone. Chạy: curl https://rclone.org/install.sh | sudo bash"
  exit 1
}

log "=== sync $ROOT -> $REMOTE/projects/$PROJECT ==="
rclone about "$REMOTE" >>"$LOG" 2>&1 || log "CẢNH BÁO: không đọc được quota $REMOTE"

FLAGS=(--transfers 4 --checkers 8 --stats 30s)
if [ "$DRY_RUN" = "1" ]; then
  FLAGS+=(--dry-run)
  log "DRY RUN — không upload thật"
fi

copy_dir() {
  local name="$1"
  local src="$ROOT/$name"
  [ -d "$src" ] || { log "bỏ qua $name (không có)"; return 0; }
  log "-> $name"
  rclone copy "$src" "$REMOTE/projects/$PROJECT/$name" "${FLAGS[@]}" 2>&1 | tee -a "$LOG"
}

copy_dir "01_assets"
copy_dir "02_boards"
copy_dir "03_clips"
copy_dir "04_audio"
copy_dir "05_post"
copy_dir "06_final"

if [ -f "$ROOT/project.json" ]; then
  log "-> project.json"
  rclone copyto "$ROOT/project.json" "$REMOTE/projects/$PROJECT/project.json" "${FLAGS[@]}" 2>&1 | tee -a "$LOG"
fi

log "=== xong ==="
rclone size "$REMOTE/projects/$PROJECT" 2>&1 | tee -a "$LOG" || true
