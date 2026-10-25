# 10 — Lưu ảnh/video lên Google Drive

> **Có, hoàn toàn được.** Google Drive 5–10TB là lựa chọn tốt để lưu archive.
> Nhưng **không dùng Drive làm nơi load model** — nó không phải block storage.

## 1. Nguyên tắc

| Dùng Drive cho | Không dùng Drive cho |
|---|---|
| Ảnh keyframe, clip đã render | Load model safetensors/gguf |
| Bản final, poster, phụ đề | ComfyUI `models/` |
| Backup `project.json`, asset | Output đang render (ghi liên tục) |
| Lưu trữ dài hạn | Thư viện node/python |

Lý do: Drive là object storage qua API, độ trễ cao, không random-access tốt. Mount Drive làm ổ model sẽ cực chậm và dễ lỗi.

---

## 2. Cài rclone trên server

```bash
curl https://rclone.org/install.sh | sudo bash
rclone version
```

Hoặc:

```bash
apt-get update && apt-get install -y rclone
```

---

## 3. Tạo remote Google Drive

### Cách A — Làm trên máy local rồi copy config (dễ nhất)

Máy local có trình duyệt:

```powershell
winget install Rclone.Rclone
rclone config
```

Chọn:
```
n) New remote
name> gdrive
Storage> drive
client_id> (Enter)
client_secret> (Enter)
scope> 1 (full access) hoặc 3 (drive.file)
root_folder_id> (Enter)
service_account_file> (Enter)
Edit advanced config? n
Use web browser to automatically authenticate? y
```

Trình duyệt mở → đăng nhập Google → Allow.
Kiểm tra:

```powershell
rclone lsd gdrive:
```

Copy file config lên server:

```powershell
scp -P <SSH_PORT> "$env:APPDATA\rclone\rclone.conf" root@<HOST>:~/.config/rclone/rclone.conf
```

### Cách B — Làm trực tiếp trên server (không có browser)

Trên **máy local**:

```bash
rclone authorize "drive"
```

Nó in ra một token JSON. Trên **server**:

```bash
rclone config
# n → name: gdrive → storage: drive → ...
# Use auto config? n
# Paste token JSON vừa lấy
```

Kiểm tra:

```bash
rclone lsd gdrive:
```

> Config nằm ở `~/.config/rclone/rclone.conf`. `chmod 600` file này. **Không commit.**

---

## 4. Cấu trúc thư mục trên Drive

```
gdrive:movie-studio/
├── projects/
│   └── phim-01/
│       ├── project.json
│       ├── 01_assets/
│       ├── 02_boards/
│       ├── 03_clips/
│       ├── 04_audio/
│       ├── 05_post/
│       └── 06_final/
├── assets-library/
│   ├── characters/
│   └── locations/
└── backups/
    └── project-json/
```

---

## 5. Lệnh sync

### Đẩy toàn bộ dự án

```bash
rclone copy /workspace/movie-studio gdrive:movie-studio/projects/phim-01 \
  --transfers 4 --checkers 8 --progress \
  --drive-chunk-size 128M
```

### Chỉ đẩy output (nhanh, chạy hàng ngày)

```bash
rclone copy /workspace/movie-studio/02_boards gdrive:movie-studio/projects/phim-01/02_boards -P
rclone copy /workspace/movie-studio/03_clips  gdrive:movie-studio/projects/phim-01/03_clips  -P
rclone copy /workspace/movie-studio/06_final  gdrive:movie-studio/projects/phim-01/06_final  -P
```

### Đồng bộ 1 chiều có backup bản cũ

```bash
rclone sync /workspace/movie-studio/03_clips gdrive:movie-studio/projects/phim-01/03_clips \
  --backup-dir gdrive:movie-studio/_trash/$(date +%F) \
  -P
```

`sync` sẽ **xóa** file trên Drive nếu không còn ở local. Dùng `copy` nếu muốn an toàn tuyệt đối.

### Kiểm tra

```bash
rclone check /workspace/movie-studio/03_clips gdrive:movie-studio/projects/phim-01/03_clips --size-only
rclone size gdrive:movie-studio
```

---

## 6. Tự động hóa

### Cron trên server (mỗi 2 giờ)

```bash
crontab -e
```

Thêm:

```cron
0 */2 * * * /workspace/movie-studio/scripts/06-sync-gdrive.sh >> /workspace/movie-studio/local/gdrive.log 2>&1
```

### Systemd timer (ổn định hơn)

`/etc/systemd/system/movie-sync.service`:

```ini
[Unit]
Description=Movie Studio Google Drive sync
After=network-online.target

[Service]
Type=oneshot
User=root
Environment=GDRIVE_REMOTE=gdrive:movie-studio
ExecStart=/workspace/movie-studio/scripts/06-sync-gdrive.sh
```

`/etc/systemd/system/movie-sync.timer`:

```ini
[Unit]
Description=Run movie sync every 2 hours

[Timer]
OnBootSec=10min
OnUnitActiveSec=2h

[Install]
WantedBy=timers.target
```

```bash
systemctl daemon-reload
systemctl enable --now movie-sync.timer
systemctl list-timers
```

---

## 7. Giới hạn cần biết

| Giới hạn | Giá trị | Ảnh hưởng |
|---|---|---|
| Upload/ngày | ~750GB/ngày/user | 10TB mất ~14 ngày nếu đẩy liên tục |
| Download/ngày | ~10TB/ngày | Không lo |
| Số file | Rất lớn | Chia thư mục để dễ quản lý |
| File > 5TB | Không hỗ trợ | Clip của bạn nhỏ hơn nhiều |
| Tốc độ | phụ thuộc host | Dùng `--transfers 4` là đủ |

**Khuyến nghị:** đẩy clip ngay sau khi duyệt, đừng để cuối dự án mới đẩy 1 lần.

---

## 8. Bảo mật

- `rclone.conf` chứa refresh token → `chmod 600`, không commit
- Nếu dùng máy chung, tạo Google account riêng cho studio
- Có thể giới hạn quyền `drive.file` thay vì full access
- Kiểm tra `rclone about gdrive:` để xem dung lượng

---

## 9. So sánh với lựa chọn khác

| Giải pháp | Ưu | Nhược |
|---|---|---|
| **Google Drive + rclone** | Đã có 5–10TB, $0 | Upload chậm, API quota |
| vast.ai volume | Nhanh, gắn trực tiếp | Trả tiền/tháng, gắn host |
| Cloudflare R2 | Rẻ, API tốt | Trả tiền egress |
| Syncthing (có sẵn) | Real-time | Cần máy local bật 24/7 |

**Kết luận:** dùng **Google Drive cho archive**, **volume cho model**. Kết hợp cả hai.
