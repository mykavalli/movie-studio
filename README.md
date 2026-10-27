# Movie Studio — Hệ thống sản xuất phim AI

> Xưởng làm phim AI hoàn chỉnh: **6 trạm sản xuất + 1 cơ sở dữ liệu shot + 1 quy trình duyệt**.
> Mục tiêu: phim ngắn 2–5 phút, 30–60 shot, 1–3 nhân vật, làm lại được nhiều lần.

**Repo:** https://github.com/mykavalli/movie-studio

---

## Trạng thái

| Hạng mục | Trạng thái |
|---|---|
| GPU | Tier 1 — 24GB VRAM (xem `docs/07-CHI-PHI.md`) |
| SSH | ✅ Đã kết nối (thông tin thật lưu ở `local/`, không commit) |
| ComfyUI | ✅ 0.27.0 |
| PyTorch | ✅ 2.10.0 + CUDA 12.8 |
| ffmpeg | ✅ 6.1.1 |
| Model | ✅ Core: Qwen-Image-Edit 2511, Wan 2.2 I2V, SeedVR2 |
| Disk | ✅ 599GB trống |
| Volume | ⚠️ Không có — backup lên Google Drive |
| Custom node | ✅ 11 node |

**Việc đầu tiên cần làm:** chốt phương án disk (xem `docs/03-HA-TANG-VASTAI.md`) trước khi tải model.

---

## Mục lục tài liệu

| File | Nội dung |
|---|---|
| [docs/00-TONG-QUAN.md](docs/00-TONG-QUAN.md) | Mục tiêu, phạm vi, nguyên tắc thiết kế |
| [docs/01-KIEN-TRUC.md](docs/01-KIEN-TRUC.md) | Kiến trúc 6 trạm, luồng dữ liệu 1 shot |
| [docs/02-MODEL-STACK.md](docs/02-MODEL-STACK.md) | Chọn model nào cho việc gì, VRAM, license |
| [docs/03-HA-TANG-VASTAI.md](docs/03-HA-TANG-VASTAI.md) | Hạ tầng, SSH, disk, multi-GPU |
| [docs/04-QUY-TRINH.md](docs/04-QUY-TRINH.md) | Quy trình sản xuất, trạng thái shot, QC |
| [docs/05-DU-LIEU.md](docs/05-DU-LIEU.md) | Cấu trúc thư mục, project.json, versioning |
| [docs/06-KE-HOACH.md](docs/06-KE-HOACH.md) | Kế hoạch 4 tuần, milestone, Definition of Done |
| [docs/07-CHI-PHI.md](docs/07-CHI-PHI.md) | Phân hạng GPU & chi phí theo giai đoạn |
| [docs/08-RUI-RO.md](docs/08-RUI-RO.md) | Rủi ro và cách xử lý |
| [docs/09-AUDIT-MAU.md](docs/09-AUDIT-MAU.md) | Mẫu audit server (không chứa thông tin thật) |
| [docs/10-GOOGLE-DRIVE.md](docs/10-GOOGLE-DRIVE.md) | Lưu ảnh/video lên Google Drive bằng rclone |
| [docs/11-KET-QUA-TEST.md](docs/11-KET-QUA-TEST.md) | Kết quả test thực tế trên Tier 1 24GB |

**Cấu hình & mẫu:**

- `config/project.schema.json` — schema shot list
- `config/project.example.json` — ví dụ 1 cảnh / 3 shot
- `config/models.manifest.yaml` — danh sách model, tier, dung lượng
- `templates/character-bible.md` — hồ sơ nhân vật
- `templates/scene-brief.md` — brief bối cảnh
- `templates/shot-list.csv` — mẫu shot list

**Script (chạy trên server):**

| File | Việc |
|---|---|
| `scripts/00-bootstrap.sh` | Cài dependency, tạo thư mục model |
| `scripts/01-install-nodes.sh` | Cài 10 custom node cần thiết |
| `scripts/02-download-models.sh` | Tải model theo tier `core` / `full` |
| `scripts/03-healthcheck.sh` | Kiểm tra GPU, disk, ComfyUI, model |
| `scripts/04-restart-comfyui.sh` | Restart ComfyUI qua supervisor |
| `scripts/05-sync-outputs.ps1` | Kéo output từ server về máy local |
| `scripts/06-sync-gdrive.sh` | Đẩy ảnh/video lên Google Drive |

---

## Quick start

```bash
# 1. Vào server (điền host/port của bạn)
ssh -p <SSH_PORT> root@<HOST>

# 2. Đưa bộ tài liệu lên server (chạy từ máy local)
scp -P <SSH_PORT> -r movie-studio root@<HOST>:/workspace/

# 3. Bootstrap
cd /workspace/movie-studio
bash scripts/00-bootstrap.sh
bash scripts/01-install-nodes.sh

# 4. Tải bộ model tối thiểu (~58GB)
bash scripts/02-download-models.sh --tier core

# 5. Kiểm tra
bash scripts/03-healthcheck.sh
```

Thông tin kết nối thật (host, port, token) đặt trong `local/connection.md` — thư mục này đã được `.gitignore`.

---

## 5 nguyên tắc bất biến

1. **Keyframe-first** — không bao giờ render video trước khi chốt ảnh tĩnh.
2. **Shot là đơn vị sản xuất** — mỗi shot có ID, trạng thái, version; không đặt tên tay.
3. **Character LoRA** — nhân vật xuất hiện >3 shot phải có LoRA, không dựa vào reference.
4. **Hybrid model** — không chọn phe LTX/Wan; mỗi loại cảnh dùng model mạnh nhất.
5. **Không có "final_final"** — version tự động, trạng thái nằm trong `project.json`.

---

## Liên kết nhanh

- ComfyUI UI: `http://<HOST>:<UI_PORT>` (Basic Auth)
- Jupyter: port nội bộ `8080`, token trong biến môi trường `JUPYTER_TOKEN`
- ComfyUI API: `http://127.0.0.1:18188` (trên server) — dùng cho orchestrator
