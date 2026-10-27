#!/usr/bin/env bash
# 02-download-models.sh — tải model theo tier
# Dùng: bash scripts/02-download-models.sh --tier core [--dry-run]
#       bash scripts/02-download-models.sh --tier core --only wan22_i2v_high
#       bash scripts/02-download-models.sh --list
#
# Biến môi trường:
#   WAN_QUANT=Q4_K_M   (T1 24GB) hoặc Q5_K_M (T2 32GB)
#   QWEN_QUANT=Q6_K    (T1 24GB) hoặc Q8_0 (T2 32GB)
#   LTX_QUANT=Q4_K_S
set -euo pipefail

COMFY="${COMFY:-/workspace/ComfyUI}"
VENV="${VENV:-/venv/main}"
export HF_HOME="${HF_HOME:-/workspace/.hf_home}"
export HF_XET_HIGH_PERFORMANCE=1
# Tải chậm: đặt HF_ENDPOINT=https://hf-mirror.com
export HF_ENDPOINT="${HF_ENDPOINT:-https://huggingface.co}"

WAN_QUANT="${WAN_QUANT:-Q4_K_M}"
QWEN_QUANT="${QWEN_QUANT:-Q6_K}"
LTX_QUANT="${LTX_QUANT:-Q4_K_S}"

TIER="core"
DRY_RUN=false
ONLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --tier) TIER="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --only) ONLY="$2"; shift 2 ;;
    --list) TIER="list"; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Tham số lạ: $1"; exit 1 ;;
  esac
done

# id|tier|repo|file|dest|size_gb
MODELS=(
  # ---------- CORE: QWEN IMAGE EDIT ----------
  "qwen_edit_2511_gguf|core|unsloth/Qwen-Image-Edit-2511-GGUF|qwen-image-edit-2511-${QWEN_QUANT}.gguf|unet|17"
  "qwen_25_vl_7b|core|Comfy-Org/Qwen-Image_ComfyUI|split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors|text_encoders|8"
  "qwen_image_vae|core|Comfy-Org/Qwen-Image_ComfyUI|split_files/vae/qwen_image_vae.safetensors|vae|0.3"
  "qwen_edit_lightning|core|lightx2v/Qwen-Image-Edit-2511-Lightning|Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors|loras|0.9"

  # ---------- CORE: WAN 2.2 I2V ----------
  "wan22_i2v_high|core|QuantStack/Wan2.2-I2V-A14B-GGUF|HighNoise/Wan2.2-I2V-A14B-HighNoise-${WAN_QUANT}.gguf|unet|9"
  "wan22_i2v_low|core|QuantStack/Wan2.2-I2V-A14B-GGUF|LowNoise/Wan2.2-I2V-A14B-LowNoise-${WAN_QUANT}.gguf|unet|9"
  "umt5_xxl|core|Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors|text_encoders|5"
  "wan_vae|core|Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/vae/wan_2.1_vae.safetensors|vae|0.3"
  "wan22_lightning_high|core|Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors|loras|0.8"
  "wan22_lightning_low|core|Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors|loras|0.8"

  # ---------- CORE: POST ----------
  "seedvr2|core|numz/SeedVR2_comfyUI|seedvr2_ema_3b_fp16.safetensors|upscale_models|6"

  # ---------- FULL: LTX 2.3 ----------
  "ltx23_gguf|full|unsloth/LTX-2.3-GGUF|*${LTX_QUANT}.gguf|unet|12"
  "ltx23_gemma|full|Lightricks/LTX-2.3|*gemma_3_12B_it_fp8_scaled*|text_encoders|12"
  "ltx23_video_vae|full|Lightricks/LTX-2.3|*video*vae*bf16*|vae|3"
  "ltx23_audio_vae|full|Lightricks/LTX-2.3|*audio*vae*bf16*|vae|2"
  "ltx23_upscaler|full|Lightricks/LTX-2.3|*spatial*upscaler*x2*|latent_upscale_models|1"

  # ---------- FULL: AUDIO ----------
  "index_tts_2|full|IndexTeam/IndexTTS-2|*|audio_encoders/index-tts-2|2"

  # ---------- OPTIONAL: HEAVY ----------
  "minimax_h3|optional|Comfy-Org/MiniMax-H3|*|minimax-h3|36"
  "wan22_animate|optional|Wan-AI/Wan2.2-Animate-14B|*|diffusion_models|20"
)

if [ "$TIER" = "list" ]; then
  printf "%-24s %-9s %8s  %s\n" "ID" "TIER" "SIZE" "REPO"
  for m in "${MODELS[@]}"; do
    IFS='|' read -r id t repo file dest size <<< "$m"
    printf "%-24s %-9s %6sGB  %s\n" "$id" "$t" "$size" "$repo"
  done
  exit 0
fi

# shellcheck disable=SC1091
source "$VENV/bin/activate"
command -v hf >/dev/null || { echo "[ERR] thiếu hf CLI. Chạy 00-bootstrap.sh trước."; exit 1; }

avail_gb() { df --output=avail -BG "$COMFY" | tail -1 | tr -dc '0-9'; }

download_one() {
  local id="$1" repo="$2" file="$3" dest="$4" size="$5"
  local out="$COMFY/models/$dest"
  mkdir -p "$out"

  echo
  echo ">>> $id  (~$size GB)"
  echo "    $repo :: $file"

  if $DRY_RUN; then
    echo "    [dry-run] bỏ qua tải"
    return 0
  fi

  local avail
  avail=$(avail_gb)
  if [ "$avail" -lt "$size" ]; then
    echo "    [SKIP] không đủ disk: còn ${avail}GB, cần ${size}GB"
    return 1
  fi

  local tmp
  tmp="$(mktemp -d)"
  if ! hf download "$repo" "$file" --max-workers 8 --local-dir "$tmp"; then
    echo "    [ERR] tải thất bại: $repo :: $file"
    rm -rf "$tmp"
    return 1
  fi

  # flatten: đưa file về đúng thư mục ComfyUI
  find "$tmp" -type f -print0 | while IFS= read -r -d '' f; do
    mv -f "$f" "$out/"
  done
  rm -rf "$tmp"
  echo "    -> $out"
}

case "$TIER" in
  core) LEVEL=1 ;;
  full) LEVEL=2 ;;
  optional) LEVEL=3 ;;
  *) echo "Tier không hợp lệ: $TIER (core|full|optional)"; exit 1 ;;
esac

FAIL=0
for m in "${MODELS[@]}"; do
  IFS='|' read -r id t repo file dest size <<< "$m"
  if [ -n "$ONLY" ] && [ "$id" != "$ONLY" ]; then continue; fi
  if [ -z "$ONLY" ]; then
    case "$t" in
      core) T=1 ;;
      full) T=2 ;;
      optional) T=3 ;;
      *) T=9 ;;
    esac
    [ "$T" -gt "$LEVEL" ] && continue
  fi
  download_one "$id" "$repo" "$file" "$dest" "$size" || FAIL=$((FAIL+1))
done

echo
echo "=============================================="
echo " Xong. Lỗi/bỏ qua: $FAIL"
echo " Disk còn lại: $(avail_gb)GB"
echo " Kiểm tra: bash scripts/03-healthcheck.sh"
echo "=============================================="
