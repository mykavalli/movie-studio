#!/usr/bin/env bash
# 03-healthcheck.sh — kiểm tra sức khỏe xưởng
set -uo pipefail

COMFY="${COMFY:-/workspace/ComfyUI}"
API="${API:-http://127.0.0.1:18188}"
LOG="${LOG:-/var/log/portal/comfyui.log}"

echo "=============================================="
echo " Movie Studio — healthcheck"
echo " $(date)"
echo "=============================================="

echo
echo "--- GPU"
if command -v nvidia-smi >/dev/null; then
  nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu,temperature.gpu \
    --format=csv,noheader
else
  echo "KHÔNG có nvidia-smi"
fi

echo
echo "--- Disk"
df -h "$COMFY" 2>/dev/null || df -h /

echo
echo "--- RAM"
free -g | head -2

echo
echo "--- ComfyUI service"
supervisorctl status comfyui 2>/dev/null || echo "không có supervisorctl"

echo
echo "--- API"
if curl -sf --max-time 5 "$API/system_stats" >/tmp/_stats.json; then
  python3 - <<'PY'
import json
d=json.load(open('/tmp/_stats.json'))
s=d.get('system',{})
print("comfyui :", s.get('comfyui_version'))
print("python  :", s.get('python_version','')[:40])
print("pytorch :", s.get('pytorch_version'))
for dev in d.get('devices',[]):
    print(f"device  : {dev.get('name')}  VRAM {dev.get('vram_total',0)/1e9:.1f} GB")
PY
else
  echo "KHÔNG gọi được $API/system_stats"
fi

echo
echo "--- Queue"
curl -s --max-time 5 "$API/queue" | python3 -c "import sys,json;d=json.load(sys.stdin);print('running',len(d.get('queue_running',[])),'pending',len(d.get('queue_pending',[])))" 2>/dev/null || echo "không đọc được queue"

echo
echo "--- Model inventory"
for d in unet diffusion_models checkpoints text_encoders vae loras upscale_models latent_upscale_models audio_encoders; do
  n=$(find "$COMFY/models/$d" -maxdepth 1 -type f \( -name '*.safetensors' -o -name '*.gguf' -o -name '*.pt' -o -name '*.pth' \) 2>/dev/null | wc -l)
  sz=$(du -sh "$COMFY/models/$d" 2>/dev/null | cut -f1)
  printf "  %-24s %3s file  %s\n" "$d" "$n" "$sz"
done

echo
echo "--- Custom nodes"
ls -1 "$COMFY/custom_nodes" 2>/dev/null | grep -v '^__' | sed 's/^/  /'

echo
echo "--- Lỗi gần đây trong log"
if [ -f "$LOG" ]; then
  grep -iE "error|traceback|out of memory|failed" "$LOG" | tail -8 | sed 's/^/  /' || echo "  không có"
else
  echo "  không thấy $LOG"
fi

echo
echo "=============================================="
