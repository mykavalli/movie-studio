# 03 — Hạ tầng vast.ai

> Tài liệu này dùng **placeholder** cho thông tin kết nối. Thông tin thật lưu ở `local/connection.md` (đã gitignore).

## 1. Mẫu audit instance

| Hạng mục | Giá trị |
|---|---|
| Instance ID | `<INSTANCE_ID>` |
| Host | `<HOST>` |
| SSH port | `<SSH_PORT>` |
| User | `root` |
| GPU | Tier 2 — 32GB VRAM |
| RAM | `<RAM_GB>` GB |
| Disk container | `<DISK_GB>` GB |
| Volume | `<VOLUME_GB>` GB (hoặc "không có") |
| Giá | `$<PRICE>/giờ` |

### Phần mềm

| Thành phần | Giá trị |
|---|---|
| ComfyUI | 0.27.0 tại `/workspace/ComfyUI` |
| Python | 3.12 (venv `/venv/main`) |
| PyTorch | 2.10.0 + cu128 |
| ffmpeg | 6.1.1 (`/usr/bin/ffmpeg`) |
| `hf` CLI | cài bằng `scripts/00-bootstrap.sh` |
| Custom node | `ComfyUI-Manager` |

### Port & dịch vụ

| Port nội bộ | Dịch vụ | Ghi chú |
|---|---|---|
| 22 | sshd | map ra `<SSH_PORT>` |
| 8080 | Jupyter | token trong `$JUPYTER_TOKEN` |
| 18188 | ComfyUI | chỉ listen 127.0.0.1 |
| 8188 | Caddy → ComfyUI | UI công khai, Basic Auth |
| 18288 | comfyui-api-wrapper | API phụ |
| 1111 | Caddy portal | |
| 8384 | Syncthing | |

### Đường dẫn quan trọng

```
/workspace/ComfyUI                 ← thư mục ComfyUI
/workspace/ComfyUI/models          ← model
/workspace/ComfyUI/custom_nodes    ← custom node
/workspace/ComfyUI/output          ← output mặc định
/var/log/portal/comfyui.log        ← log ComfyUI
/venv/main/bin/activate            ← venv chính
```

### Kiểm tra nhanh

```bash
nvidia-smi
df -h /
curl -s http://127.0.0.1:18188/system_stats | python3 -m json.tool
curl -s http://127.0.0.1:18188/queue
supervisorctl status comfyui
tail -f /var/log/portal/comfyui.log
```

---

## 2. SSH

### Cấu hình local

Thêm vào `~/.ssh/config`:

```
Host movie-studio
    HostName <HOST>
    Port <SSH_PORT>
    User root
    IdentityFile <ĐƯỜNG_DẪN_PRIVATE_KEY>
    ServerAliveInterval 30
    ServerAliveCountMax 4
```

Sau đó:

```bash
ssh movie-studio
```

### Yêu cầu
- Public key phải được bật trong vast.ai Account → SSH Keys
- Nếu `Permission denied (publickey)`: kiểm tra lại key, đợi 30–60s
- **Không** đưa private key vào repo

### Lấy thông tin web UI

```bash
# Basic auth của Caddy (nếu cần)
echo "$PORTAL_CONFIG"

# Jupyter token
echo "$JUPYTER_TOKEN"
```

Không ghi các giá trị này vào tài liệu/repo.

---

## 3. Vấn đề disk

### Thực trạng chung
- Model core (Qwen + Wan + audio + upscale) ≈ **58GB**
- Full stack (thêm LTX + Krea + FLUX2) ≈ **120GB**
- Output 1 phim 3 phút 1080p ≈ 5–15GB (kể cả intermediate)

### Phương án

| PA | Cách làm | Ưu | Nhược | Chi phí |
|---|---|---|---|---|
| **A** | Disk 80GB, chỉ cài core | Không tốn thêm | Không có LTX, chật vật output | $0 |
| **B** | Volume 200GB, thuê lại instance có volume | Model persistent, đủ full stack | Phải destroy instance hiện tại (nếu đang trống thì không mất gì) | ~$15–25/tháng |
| **C** | Thuê instance mới disk 200GB (không volume) | Nhanh, rẻ hơn volume | Destroy là mất model | +$0.05–0.10/h |
| **D** | Giữ instance + lưu output lên Google Drive | Không mất output | Model vẫn phải tải lại | $0 (đã có Drive) |

**Khuyến nghị: PA B** nếu làm dự án dài; **PA D** nếu muốn tiết kiệm và chấp nhận tải lại model.

Quy trình PA B:
1. vast.ai → Volumes → Create Volume 200GB (cùng region với host)
2. Destroy instance hiện tại
3. Thuê instance Tier 2 mới, attach volume, mount tại `/workspace`
4. Cài lại theo `scripts/00-bootstrap.sh`

> Volume vast.ai gắn theo host/region. Kiểm tra volume hiển thị trong lúc thuê instance.

### Nếu chưa muốn đổi — chế độ "core only"
- Cài Qwen-Image-Edit + Wan 2.2 + audio + upscale
- Không cài LTX, Krea, FLUX2
- Xuất output ra ngoài (Google Drive) sau mỗi buổi, xóa intermediate

---

## 4. Thiết kế multi-GPU

### Nguyên tắc
**ComfyUI không chia 1 model qua nhiều GPU hiệu quả.** Multi-GPU = nhiều trạm chạy song song, không phải "model to hơn".

Muốn chạy model > VRAM 1 card (MiniMax H3) → phải có **1 card ≥ 48–80GB**, không phải 2×24GB.

### Sơ đồ tier

| Tier | GPU | VRAM | Disk | Dùng cho | Chi phí/h |
|---|---|---|---|---|---|
| **T1** | 1× RTX 3090 | 24GB | 80–100GB | Học, test 1 shot | ~$0.20–0.30 |
| **T1+** | 1× RTX 4090 | 24GB | 100–200GB | Xưởng 1 người | ~$0.35–0.50 |
| **T2** | 1× RTX 5090 | 32GB | 200GB volume | Render nhanh, core + LTX | ~$0.70–1.00 |
| **T3** | 2× 32GB | 64GB | 500GB volume | Ảnh + video song song | ~$1.40–2.00 |
| **T4** | 1× A100/H100 80GB + 2× 32GB | 144GB | 1TB volume | Studio, MiniMax H3 | ~$3.50–5.50 |

### Cách chạy nhiều instance ComfyUI

```bash
# GPU 0 — ảnh
CUDA_VISIBLE_DEVICES=0 python main.py --port 18188

# GPU 1 — video
CUDA_VISIBLE_DEVICES=1 python main.py --port 18189

# GPU 2 — post/audio
CUDA_VISIBLE_DEVICES=2 python main.py --port 18190
```

Dispatcher (Python) đọc `project.json`, gửi job đến đúng port theo `station`.

### Chia sẻ model
- Cách tốt nhất: volume chung mount `/workspace/models`
- Symlink `ComfyUI/models` → `/workspace/models`
- Không copy model vào từng instance

---

## 5. Bảo mật

- SSH chỉ dùng key, không bật password
- Không commit token/API key vào `movie-studio/`
- `.gitignore` đã chặn `.env`, `*.key`, `secrets/`, `local/`
- Web UI có Basic Auth — không tắt nếu host public
- Khi chia sẻ workflow, kiểm tra không lộ path/token

---

## 6. Backup

| Dữ liệu | Tần suất | Cách |
|---|---|---|
| `project.json`, `01_assets`, `02_boards` | mỗi ngày | `rclone` lên Google Drive |
| `03_clips` đã duyệt | mỗi ngày | Google Drive + ổ local |
| Model | không cần | tải lại từ HF |
| Workflow JSON | mỗi khi đổi | git repo |

Xem `docs/10-GOOGLE-DRIVE.md` và `scripts/06-sync-gdrive.sh`.
