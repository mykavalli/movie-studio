# 06 — Kế hoạch triển khai

## Quyết định đã chốt

| # | Quyết định | Giá trị | Ngày |
|---|---|---|---|
| D1 | Disk | ⬜ chưa chốt (A/B/C) | |
| D2 | API premium | ⬜ chưa chốt | |
| D3 | Train LoRA nhân vật | ⬜ chưa chốt | |
| D4 | Ngôn ngữ phim | ⬜ chưa chốt | |
| D5 | Format | ⬜ chưa chốt | |

> Điền vào bảng này trước khi bắt đầu Tuần 1.

---

## Tuần 1 — Hạ tầng & test end-to-end

| # | Việc | Deliverable | DoD |
|---|---|---|---|
| 1.1 | Chốt phương án disk | Quyết định D1 | Có volume hoặc chấp nhận core-only |
| 1.2 | Chạy `00-bootstrap.sh` | `hf` CLI, thư mục model | `hf --version` chạy |
| 1.3 | Chạy `01-install-nodes.sh` | 10 custom node | ComfyUI khởi động không lỗi import |
| 1.4 | Tải model core | ~58GB | `03-healthcheck.sh` liệt kê đủ model |
| 1.5 | Test Qwen-Edit | 1 ảnh ghép 2 ref | Ảnh đúng nhân vật + bối cảnh |
| 1.6 | Test Wan I2V | 1 clip 2s | Không lỗi, không OOM |
| 1.7 | Đo thời gian | Bảng benchmark | Có số thực tế cho ảnh + video |

**Milestone M1:** render được 1 shot hoàn chỉnh (ảnh → clip) trong < 30 phút.

---

## Tuần 2 — Asset & nhân vật

| # | Việc | Deliverable | DoD |
|---|---|---|---|
| 2.1 | Viết treatment + shot list | `project.json` | 20–30 shot, đủ field |
| 2.2 | Character bible | `bible.md` | Đủ 8 mục |
| 2.3 | Character sheet | 6–10 ảnh | 3 góc + 3 biểu cảm |
| 2.4 | Train LoRA | `.safetensors` | Loss ổn định, test 5 ảnh |
| 2.5 | Location plate | 2 ảnh/bối cảnh | Wide + medium |
| 2.6 | Style guide | `style-guide.md` | Palette + LUT + lens |

**Milestone M2:** 5 ảnh test nhân vật ở 5 bối cảnh khác nhau, nhận ra cùng một người.

---

## Tuần 3 — Board & motion

| # | Việc | Deliverable | DoD |
|---|---|---|---|
| 3.1 | Board toàn bộ shot | `02_boards/` | 100% shot có `first.png` |
| 3.2 | Animatic | MP4 slideshow | Duyệt được nhịp phim |
| 3.3 | Render 10 shot đầu | `03_clips/` | ≥ 7 shot `approved` |
| 3.4 | Retake | Clip mới | Shot fail được sửa |
| 3.5 | Benchmark model | Bảng model/cảnh | Chốt model cho từng loại cảnh |

**Milestone M3:** 10 shot approved, nhìn liền mạch khi ghép.

---

## Tuần 4 — Hoàn thiện cảnh 1 + post

| # | Việc | Deliverable | DoD |
|---|---|---|---|
| 4.1 | Render nốt cảnh 1 | 15–20 shot | ≥ 90% approved |
| 4.2 | Audio | Voice + SFX + nhạc | Khớp miệng, không lệch |
| 4.3 | Upscale | Clip 1080p | Không artifact |
| 4.4 | Dựng + màu | Timeline | Xuất được bản 1 phút |
| 4.5 | Retrospective | `retro.md` | 3 điều giữ, 3 điều bỏ |

**Milestone M4:** cảnh 1 hoàn chỉnh 60–90 giây, phát được.

---

## Sau 4 tuần — mở rộng

| Việc | Khi nào |
|---|---|
| Cảnh 2–5 | Tuần 5–8 |
| Multi-GPU | Khi > 10 shot/ngày |
| API premium cho hero shot | Khi cần chất lượng cao hơn local |
| Orchestrator tự động | Khi quy trình đã ổn định, không đổi |

---

## Definition of Done cho từng loại

### Một shot
- [ ] `status = final` trong `project.json`
- [ ] Có keyframe, clip, audio, bản upscale
- [ ] QC pass 4 nhóm
- [ ] Tên file đúng convention

### Một cảnh
- [ ] 100% shot `final`
- [ ] Ghép liền mạch, không lộ mối nối
- [ ] Audio khớp
- [ ] Màu đồng nhất

### Một phim
- [ ] Master 1080p + bản web
- [ ] Phụ đề Việt
- [ ] Poster/thumbnail
- [ ] `project.json` + asset backup đầy đủ

---

## Rủi ro tiến độ

| Rủi ro | Xác suất | Ảnh hưởng | Giảm thiểu |
|---|---|---|---|
| Disk đầy giữa tuần 1 | Cao | Cao | Chốt volume trước |
| LoRA không đạt | Trung bình | Cao | Dự phòng: dùng ref + Qwen-Edit |
| Wan quá chậm | Trung bình | Trung bình | Dùng 5B hoặc LTX cho nháp |
| Node LTX lỗi import | Cao | Trung bình | Fix kornia, khóa version |
| Scope creep | Cao | Cao | Khóa shot list cuối tuần 2 |
