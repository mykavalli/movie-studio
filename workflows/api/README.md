# API Workflows

Các workflow ở đây là **API format** — gửi trực tiếp vào ComfyUI `/prompt`.

## Danh sách

| File | Model | Thời gian (T1 24GB) |
|---|---|---|
| `qwen_edit_2511_lightning.json` | Qwen-Image-Edit 2511 Q6 + Lightning 4-step | ~37s/ảnh |
| `qwen_edit_2511_20step.json` | Qwen-Image-Edit 2511 Q6 (dev) | ~173s/ảnh |
| `wan22_i2v_lightning.json` | Wan 2.2 I2V Q4 + Lightning 4-step | ~92s/49 frame 480p |

## Chạy

```bash
curl -X POST http://127.0.0.1:18188/prompt \
  -H "Content-Type: application/json" \
  --data-binary @qwen_edit_2511_lightning.json
```

Response:

```json
{"prompt_id":"...","number":0,"node_errors":{}}
```

Theo dõi:

```bash
curl http://127.0.0.1:18188/history/<prompt_id>
```

## Sửa nhanh

### Qwen

| Node | Field | Ý nghĩa |
|---|---|---|
| `4` | `image` | ảnh input trong `ComfyUI/input/` |
| `6` | `prompt` | prompt tích cực |
| `7` | `prompt` | negative |
| `10` | `seed` | seed |
| `13` | `filename_prefix` | thư mục output |

Thêm ảnh tham chiếu thứ 2: thêm `LoadImage` và nối vào `image2` của node `6` và `7`.

### Wan

| Node | Field | Ý nghĩa |
|---|---|---|
| `7` | `image` | frame đầu |
| `10` | `width`, `height`, `length` | độ phân giải + số frame (`4n+1`) |
| `11` | `noise_seed` | seed |
| `15` | `filename_prefix` | thư mục output |

Tăng chất lượng: đổi `Q4_K_M` → `Q5_K_M` trong `unet_name` (cần tải thêm), hoặc tăng steps 4 → 6.
