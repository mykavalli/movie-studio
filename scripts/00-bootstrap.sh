#!/usr/bin/env bash
# 00-bootstrap.sh — chuẩn bị môi trường trên vast.ai
# Chạy: bash scripts/00-bootstrap.sh
set -euo pipefail

COMFY="${COMFY:-/workspace/ComfyUI}"
VENV="${VENV:-/venv/main}"
HF_HOME="${HF_HOME:-/workspace/.hf_home}"

echo "=============================================="
echo " Movie Studio — bootstrap"
echo " ComfyUI : $COMFY"
echo " venv    : $VENV"
echo " HF_HOME : $HF_HOME"
echo "=============================================="

# --- 1. Kiểm tra môi trường ---
if [ ! -d "$COMFY" ]; then
  echo "[ERR] Không thấy $COMFY. Kiểm tra đường dẫn ComfyUI."
  exit 1
fi

if [ ! -f "$VENV/bin/activate" ]; then
  echo "[ERR] Không thấy venv tại $VENV"
  exit 1
fi

echo "[1/6] GPU"
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || true

echo "[2/6] Disk"
df -h "$COMFY" || true

# --- 2. Python deps ---
echo "[3/6] Cài Python deps"
# shellcheck disable=SC1091
source "$VENV/bin/activate"
python -m pip install -q -U pip
python -m pip install -q -U "huggingface_hub[cli]" hf_transfer imageio-ffmpeg
export HF_HOME
export HF_HUB_ENABLE_HF_TRANSFER=1
mkdir -p "$HF_HOME"

python -c "import huggingface_hub, sys; print('huggingface_hub', huggingface_hub.__version__)"
command -v hf >/dev/null && hf --version || echo "[WARN] hf CLI chưa có trong PATH"

# --- 3. Thư mục model ---
echo "[4/6] Tạo thư mục model"
for d in \
  unet diffusion_models checkpoints \
  text_encoders clip clip_vision \
  vae vae_approx loras \
  upscale_models latent_upscale_models \
  audio_encoders controlnet frame_interpolation; do
  mkdir -p "$COMFY/models/$d"
done

# --- 4. ffmpeg / imageio ---
echo "[5/6] ffmpeg"
if command -v ffmpeg >/dev/null; then
  ffmpeg -version | head -1
else
  echo "[WARN] Không có ffmpeg — CreateVideo/SaveVideo sẽ lỗi."
fi
python -c "import imageio_ffmpeg; print('imageio-ffmpeg', imageio_ffmpeg.__version__)"

# --- 5. Kiểm tra quyền ghi ---
echo "[6/6] Quyền ghi"
touch "$COMFY/models/.write_test" && rm "$COMFY/models/.write_test"
echo "OK"

echo
echo "Bootstrap xong. Bước tiếp theo:"
echo "  bash scripts/01-install-nodes.sh"
echo "  bash scripts/02-download-models.sh --tier core"
