# 08 — Rủi ro & cách xử lý

## 1. Rủi ro kỹ thuật

| # | Rủi ro | Dấu hiệu | Xác suất | Tác động | Cách xử lý |
|---|---|---|---|---|---|
| R1 | Disk đầy | `df -h` < 10GB | Cao | Cao | Volume 200GB; xóa intermediate; sync output ra ngoài |
| R2 | OOM khi render | CUDA out of memory | Cao | Trung bình | Giảm quant Q6→Q5→Q4; giảm resolution; `--reserve-vram 1`; tiled VAE |
| R3 | Nhân vật drift | Mặt khác giữa các shot | Cao | Cao | Train LoRA; khóa seed; dùng FLF2V; giảm clip còn 4s |
| R4 | Node LTX lỗi import | `kornia.pad` ImportError | Cao | Trung bình | Sửa `pyramid_blending.py`; khóa version node |
| R5 | Model tải lỗi/thiếu file | ComfyUI báo thiếu model | Trung bình | Trung bình | Dùng `hf download` có resume; kiểm tra size |
| R6 | ComfyUI update phá node | Node đỏ sau update | Trung bình | Cao | Không update giữa dự án; snapshot volume trước khi update |
| R7 | Instance bị thu hồi | SSH mất kết nối | Thấp | Cao | Backup hàng ngày; volume persistent; không lưu only-on-instance |
| R8 | Chất lượng không đạt kỳ vọng | Shot fail liên tục | Trung bình | Cao | Hạ scope; dùng API cho hero shot; test model trước khi cam kết |

### R9 — SeedVR2 không load: `No module named 'flash_attn'`

**Nguyên nhân:** `xformers` được cài nhưng build thiếu `flash_attn`; diffusers import xformers → lỗi.

**Cách xử lý:** ComfyUI đã chạy với `--disable-xformers`, nên gỡ xformers:

```bash
source /venv/main/bin/activate
pip uninstall -y xformers
supervisorctl restart comfyui
```

Sau đó SeedVR2 load bình thường. Nếu một node khác cần xformers, cài lại bản tương thích torch.

---

## 2. Rủi ro quy trình

| # | Rủi ro | Cách xử lý |
|---|---|---|
| P1 | Scope creep (thêm cảnh giữa chừng) | Khóa shot list cuối tuần 2; thay đổi phải ghi changelog |
| P2 | Sửa video thay vì sửa keyframe | Quy tắc: mọi lỗi bố cục → quay về trạm 2 |
| P3 | Không ai duyệt, render tràn lan | Gate duyệt bắt buộc; tối đa 3 retake/shot |
| P4 | Quên backup | Script sync chạy cuối ngày; lịch tự động |
| P5 | Đặt tên lộn xộn | Convention bắt buộc; orchestrator tự đặt tên |

## 3. Rủi ro pháp lý

| # | Rủi ro | Cách xử lý |
|---|---|---|
| L1 | Dùng model non-commercial cho việc bán | Kiểm tra license từng model; FLUX.2 dev là non-commercial |
| L2 | LTX doanh thu > $10M | Mua license thương mại từ Lightricks |
| L3 | Voice clone người thật | Có consent bằng văn bản |
| L4 | Nhạc có bản quyền | Dùng Stable Audio/ACE-Step hoặc mua license |
| L5 | Deepfake người thật | Không dùng; chính sách nội bộ |

## 4. Rủi ro tài chính

| # | Rủi ro | Cách xử lý |
|---|---|---|
| F1 | Quên tắt instance | Đặt lịch nhắc; dùng vast.ai auto-shutdown nếu có |
| F2 | Retake vô hạn | Ngân sách 3 lần/shot; log chi phí |
| F3 | Volume phình to | Dọn model không dùng; giữ 1 quant/model |

## 5. Kế hoạch dự phòng

### Nếu Wan quá chậm trên Tier 2
→ Dùng Wan 2.2 5B TI2V cho nháp, 14B chỉ cho final.
→ Hoặc chuyển sang LTX 2.3 cho toàn bộ, chấp nhận motion kém hơn.

### Nếu LoRA nhân vật không đạt
→ Dùng Qwen-Image-Edit với 2–3 ref ảnh + prompt khóa.
→ Hoặc dùng Seedream 5.0 Pro (14 ref) cho keyframe.

### Nếu disk không nâng được
→ Chỉ cài core (Qwen + Wan).
→ Render xong sync ngay, xóa intermediate.
→ Không dùng LTX/Krea/FLUX2.

### Nếu instance bị mất
→ Volume còn → thuê instance mới, attach volume, chạy lại bootstrap.
→ Volume mất → tải lại model (~1–2h), restore project từ backup local.

## 6. Checklist trước khi bắt đầu dự án mới

- [ ] Disk còn ≥ 50GB trống
- [ ] `03-healthcheck.sh` xanh
- [ ] Model core đủ
- [ ] `project.json` validate schema
- [ ] Character bible + refs + LoRA sẵn sàng
- [ ] Backup tự động đã bật
- [ ] Ngân sách GPU đã đặt
