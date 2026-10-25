# 04 — Quy trình sản xuất

## 1. Vòng đời một shot

```
planned
  │  (trạm 0: có record trong project.json)
  ▼
boarded
  │  (trạm 2: có first/mid/last keyframe)
  ▼
board_approved
  │  (duyệt ảnh — gate quan trọng nhất)
  ▼
rendering
  │  (trạm 3: đang render)
  ▼
rendered
  │  (có clip, chờ QC)
  ▼
approved
  │  (QC đạt)
  ▼
audio_done
  │  (trạm 4: voice + SFX + lip-sync)
  ▼
post_done
  │  (trạm 5: upscale + màu)
  ▼
final
```

**Quy tắc:** không nhảy trạng thái. Shot `rendered` nhưng QC fail → quay lại `boarded` (sửa ảnh) hoặc `rendering` (đổi seed/model).

---

## 2. Bảy phase của dự án

### P0 — Setup (0.5 ngày)
- [ ] SSH vào server
- [ ] Chốt phương án disk
- [ ] Chạy bootstrap + cài node
- [ ] Tải model core
- [ ] Test 1 ảnh Qwen-Edit + 1 clip Wan
- **Gate:** `03-healthcheck.sh` xanh, render được 1 clip 2s

### P1 — Pre-production (1 ngày)
- [ ] Logline + Treatment (1 trang)
- [ ] Character bible cho từng nhân vật
- [ ] Scene brief cho từng bối cảnh
- [ ] Shot list đầy đủ trong `project.json`
- [ ] Đọc toàn bộ thoại thành file text
- **Gate:** shot list duyệt, tổng thời lượng khớp

### P2 — Asset (1–2 ngày)
- [ ] Character sheet 6–10 ảnh/nhân vật
- [ ] Train LoRA nhân vật
- [ ] Test LoRA 5 bối cảnh
- [ ] Location plate 2 ảnh/bối cảnh
- [ ] Style guide (màu, ánh sáng, ống kính)
- **Gate:** 5 ảnh test nhân vật đạt; location duyệt

### P3 — Board (2–3 ngày)
- [ ] Keyframe first cho tất cả shot
- [ ] Keyframe mid/last cho shot cần
- [ ] Ghép animatic (slideshow + nhạc tạm)
- [ ] Duyệt animatic
- **Gate:** animatic duyệt — đây là "khóa" của phim

### P4 — Motion (3–5 ngày)
- [ ] Render từng shot theo model phù hợp
- [ ] QC từng shot
- [ ] Retake shot fail (tối đa 3 lần/shot)
- **Gate:** ≥ 90% shot `approved`

### P5 — Audio (1–2 ngày)
- [ ] TTS toàn bộ thoại
- [ ] Lip-sync shot cận mặt
- [ ] SFX theo hành động
- [ ] Nhạc nền
- **Gate:** nghe khớp, không lệch tiếng

### P6 — Post & Delivery (1–2 ngày)
- [ ] Upscale toàn bộ clip
- [ ] Nội suy nếu cần
- [ ] Dựng timeline, canh nhịp
- [ ] Color grade
- [ ] Phụ đề
- [ ] Mix audio
- [ ] Xuất master + bản web
- **Gate:** final review

---

## 3. Quy tắc đặt tên

```
<S><scene>_SH<shot>_v<version>_<model>_s<seed>.<ext>
```

Ví dụ:
```
S01_SH003_v001_qwen_edit_s884213.png
S01_SH003_v002_wan22q5_s884213.mp4
S01_SH003_v002_wan22q5_s884213_upscaled.mp4
```

Quy tắc:
- Scene 2 chữ số: `S01`
- Shot 3 chữ số: `SH003`
- Version 3 chữ số: `v001`
- Không dấu cách, không tiếng Việt có dấu
- Không bao giờ `final`, `final2`, `final_final`

---

## 4. QC checklist cho shot

### Ảnh (trạm 2)
- [ ] Đúng nhân vật (so với bible)
- [ ] Đúng bối cảnh, ánh sáng
- [ ] Bố cục đúng mô tả camera
- [ ] Tay/ngón tay không lỗi
- [ ] Mắt đối xứng, không lác
- [ ] Không có vật thể lạ
- [ ] Đúng aspect ratio cuối

### Video (trạm 3)
- [ ] Nhân vật không drift giữa các frame
- [ ] Chuyển động mượt, không nhảy
- [ ] Không morph mặt
- [ ] Không flicker màu
- [ ] Camera đúng ý
- [ ] Không có watermark
- [ ] Frame đầu khớp keyframe
- [ ] Frame cuối dùng được để nối shot sau

### Audio (trạm 4)
- [ ] Giọng đúng nhân vật
- [ ] Lip-sync khớp (sai số < 2 frame)
- [ ] SFX đúng hành động
- [ ] Không clipping
- [ ] Nhạc không lấn thoại

### Post (trạm 5)
- [ ] Độ nét đồng nhất giữa các shot
- [ ] Màu đồng nhất
- [ ] Không artifact do upscale
- [ ] Phụ đề đúng chính tả, đúng thời điểm

---

## 5. Nhịp làm việc hàng ngày

| Giờ | Việc |
|---|---|
| Sáng | Review output đêm qua; duyệt/từ chối shot |
| 9h–12h | Board keyframe cho shot tiếp theo |
| 12h–13h | Queue render video (chạy nền) |
| 13h–17h | Audio + post cho shot đã duyệt |
| 17h–18h | Cập nhật `project.json`, backup, lên queue đêm |

**Nguyên tắc:** ban ngày làm việc sáng tạo (board, duyệt), ban đêm chạy render hàng loạt.

---

## 6. Prompt template

### 6.1 Prompt ghép cảnh (trạm 2)

```
Image 1: character reference — keep face, hair, body proportions exactly.
Image 2: location reference — keep architecture, lighting direction, color palette.
Image 3: prop reference (optional).

Scene: <mô tả hành động + bối cảnh>
Camera: <loại cảnh>, <góc máy>, <ống kính>
Lighting: <nguồn sáng>, <hướng>, <nhiệt độ màu>
Style: <film look>, <color grade>
Composition: <vị trí nhân vật trong khung>

Do not change: face identity, hairstyle, clothing details.
```

### 6.2 Prompt chuyển động (trạm 3)

Chỉ mô tả **cái thay đổi**, không mô tả lại ngoại hình:

```
The character turns head slowly to the right, then looks down.
Camera: slow dolly in, shallow depth of field.
Hair moves slightly in the wind. Dust particles in the light beam.
```

### 6.3 Negative prompt dùng chung

```
blurry, low quality, distorted face, extra fingers, deformed hands,
flickering, morphing, watermark, text, logo, oversaturated, plastic skin
```

---

## 7. Xử lý shot fail

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| Mặt sai nhân vật | Ref/LoRA yếu | Tăng weight LoRA, thêm ref, giảm denoise |
| Tay lỗi | Model | Đổi seed, thêm "hands in pockets", crop lại |
| Chuyển động giật | Quá nhiều action trong 1 clip | Chia thành 2 shot, hoặc thêm keyframe giữa |
| Màu lệch | Prompt/VAE | Khóa prompt style, kiểm tra VAE |
| Nhân vật drift | Clip quá dài | Giảm còn 4s, dùng FLF2V |
| OOM | Quant quá cao | Giảm Q5→Q4, giảm resolution, `--reserve-vram` |

**Quy tắc 3 lần:** 1 shot fail 3 lần → dừng, xem lại keyframe/prompt, không đốt thêm GPU.
