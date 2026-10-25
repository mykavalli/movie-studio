#!/usr/bin/env bash
# 04-restart-comfyui.sh — restart ComfyUI và xem log
set -uo pipefail

LOG="${LOG:-/var/log/portal/comfyui.log}"

echo "--- Trước khi restart"
supervisorctl status comfyui || true

echo
echo "--- Restart"
supervisorctl restart comfyui || { echo "restart lỗi"; exit 1; }

echo
echo "--- Chờ khởi động"
for i in $(seq 1 20); do
  if curl -sf --max-time 2 http://127.0.0.1:18188/system_stats >/dev/null; then
    echo "ComfyUI đã lên sau ${i}s"
    break
  fi
  sleep 1
done

echo
echo "--- Trạng thái"
supervisorctl status comfyui || true

echo
echo "--- 30 dòng log cuối"
tail -n 30 "$LOG" 2>/dev/null || echo "không thấy $LOG"
