#!/usr/bin/env bash
# 01-install-nodes.sh — cài custom node cần thiết cho 6 trạm
# Chạy: bash scripts/01-install-nodes.sh [--fix-kornia]
set -euo pipefail

COMFY="${COMFY:-/workspace/ComfyUI}"
VENV="${VENV:-/venv/main}"
NODES_DIR="$COMFY/custom_nodes"
FIX_KORNIA=false
[ "${1:-}" = "--fix-kornia" ] && FIX_KORNIA=true

# name|url
NODES=(
  "ComfyUI-GGUF|https://github.com/city96/ComfyUI-GGUF"
  "ComfyUI-KJNodes|https://github.com/kijai/ComfyUI-KJNodes"
  "ComfyUI-LTXVideo|https://github.com/Lightricks/ComfyUI-LTXVideo"
  "WhatDreamsCost-ComfyUI|https://github.com/WhatDreamsCost/WhatDreamsCost-ComfyUI"
  "ComfyUI-PromptRelay|https://github.com/kijai/ComfyUI-PromptRelay"
  "ComfyUI-Wan22FMLF|https://github.com/wallen0322/ComfyUI-Wan22FMLF"
  "ComfyUI-VideoHelperSuite|https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
  "ComfyUI-Frame-Interpolation|https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
  "ComfyUI-SeedVR2_VideoUpscaler|https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler"
  "ComfyUI-MMAudio|https://github.com/kijai/ComfyUI-MMAudio"
)

echo "=============================================="
echo " Movie Studio — install custom nodes"
echo "=============================================="

mkdir -p "$NODES_DIR"
# shellcheck disable=SC1091
source "$VENV/bin/activate"

for entry in "${NODES[@]}"; do
  name="${entry%%|*}"
  url="${entry##*|}"
  echo
  echo "--- $name"
  if [ -d "$NODES_DIR/$name/.git" ]; then
    echo "  đã có, bỏ qua (không auto-pull để tránh phá version)"
  else
    git clone --depth 1 "$url" "$NODES_DIR/$name" || {
      echo "  [WARN] clone lỗi: $url"
      continue
    }
  fi
  if [ -f "$NODES_DIR/$name/requirements.txt" ]; then
    echo "  pip install requirements"
    python -m pip install -q -r "$NODES_DIR/$name/requirements.txt" || \
      echo "  [WARN] requirements lỗi — kiểm tra thủ công"
  fi
done

# --- Fix lỗi kornia.pad của ComfyUI-LTXVideo ---
patch_kornia() {
  local f="$NODES_DIR/ComfyUI-LTXVideo/pyramid_blending.py"
  [ -f "$f" ] || { echo "  không thấy pyramid_blending.py"; return 0; }
  python - "$f" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text()
if "import" not in s:
    sys.exit(0)
m = re.search(r"from kornia\.geometry\.transform\.pyramid import ([^\n]+)", s)
if not m or "pad" not in m.group(1):
    print("  không cần patch")
    sys.exit(0)
p.with_suffix(".py.bak_kornia_fix").write_text(s)
names = [n.strip() for n in m.group(1).replace("(", "").replace(")", "").split(",")]
names = [n for n in names if n and n != "pad"]
new_import = "from kornia.geometry.transform.pyramid import " + ", ".join(names)
s = s.replace(m.group(0), new_import)
if "pad = F.pad" not in s:
    s = "import torch.nn.functional as F\npad = F.pad\n" + s
p.write_text(s)
print("  đã patch kornia.pad")
PY
}

if $FIX_KORNIA; then
  echo
  echo "--- Patch kornia (LTXVideo)"
  patch_kornia
fi

echo
echo "Restart ComfyUI..."
supervisorctl restart comfyui || true
sleep 6
supervisorctl status comfyui || true

echo
echo "Kiểm tra log nếu có node đỏ:"
echo "  tail -n 80 /var/log/portal/comfyui.log"
echo
echo "Nếu ComfyUI-LTXVideo lỗi 'kornia pad', chạy lại:"
echo "  bash scripts/01-install-nodes.sh --fix-kornia"
