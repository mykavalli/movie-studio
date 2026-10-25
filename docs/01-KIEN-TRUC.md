# 01 — Kiến trúc 6 trạm

## Sơ đồ tổng thể

```
┌─────────────────────────────────────────────────────────────────┐
│  LỚP DỮ LIỆU:  project.json  ·  asset registry  ·  prompt library │
└─────────────────────────────────────────────────────────────────┘
          │
          ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ [0] SCRIPT   │──▶│ [1] ASSET    │──▶│ [2] BOARD    │
│ LLM          │   │ Character/   │   │ Multi-image  │
│ shot list    │   │ Location     │   │ → keyframe   │
└──────────────┘   └──────────────┘   └──────────────┘
                                             │
                                             ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ [5] POST     │◀──│ [4] AUDIO    │◀──│ [3] MOTION   │
│ upscale/edit │   │ voice/SFX    │   │ image(s) →   │
│ grade/sub    │   │ lip-sync     │   │ video        │
└──────────────┘   └──────────────┘   └──────────────┘
          │
          ▼
      FINAL FILM
```

---

## Bảng 6 trạm

| Trạm | Tên | Input | Output | Thời gian/shot |
|---|---|---|---|---|
| 0 | Script & Shot Design | ý tưởng, kịch bản | `project.json` có shot list | 1–2 phút (LLM) |
| 1 | Asset Lab | mô tả nhân vật/bối cảnh | character sheet, LoRA, location plate | 1–2 giờ (một lần) |
| 2 | Board Lab | shot record + asset refs | 1–3 keyframe PNG | 3–8 phút |
| 3 | Motion Lab | keyframe + prompt chuyển động | clip MP4 4–8s | 5–20 phút |
| 4 | Audio Lab | thoại, SFX, nhạc | WAV/MP3 + clip lip-sync | 3–10 phút |
| 5 | Post | clip + audio | clip upscale, màu, phụ đề | 5–15 phút |

---

## Chi tiết từng trạm

### Trạm 0 — Script & Shot Design

**Mục tiêu:** biến ý tưởng thành danh sách shot có cấu trúc.

**Công cụ:** LLM (Claude/GPT qua API, hoặc Qwen3 local).

**Input:**
- Logline, thể loại, thời lượng
- Nhân vật (tên, ngoại hình, tính cách)
- Bối cảnh

**Output:** `project.json` theo schema, mỗi shot có:
- `shot_id`, `scene`, `description`
- `characters`, `location`, `props`
- `camera` (loại cảnh + chuyển động)
- `duration_sec`
- `dialogue`
- `motion_prompt` (chỉ mô tả chuyển động, không mô tả lại ngoại hình)

**Prompt mẫu cho LLM:** xem `templates/shot-list.csv` + hướng dẫn trong `04-QUY-TRINH.md`.

**Gate:** shot list được duyệt, tổng thời lượng khớp mục tiêu.

---

### Trạm 1 — Asset Lab

**Mục tiêu:** tạo "linh hồn" của phim — nhân vật và bối cảnh nhất quán.

**Công cụ:**
- Ảnh: Qwen-Image-Edit 2511, Krea 2
- Train LoRA: AI Toolkit
- Quản lý: `01_assets/`

**Quy trình nhân vật:**
1. Viết `character-bible.md` (xem template)
2. Generate 6–10 ảnh: mặt trước, 3/4, nghiêng, sau, toàn thân, 3 biểu cảm
3. Chọn 5 ảnh tốt nhất → `refs/`
4. Train LoRA (30–50 ảnh, augment từ refs) → `lora/`
5. Test LoRA: 5 ảnh ở 5 bối cảnh khác nhau, cùng seed
6. Nếu mặt lệch >20% → bổ sung ảnh, train lại

**Quy trình bối cảnh:**
1. Viết `scene-brief.md`
2. Generate 3–5 "location plate" (không có nhân vật)
3. Chọn 2 plate: 1 wide, 1 medium
4. Ghi chú ánh sáng/màu vào `style.md`

**Gate:** 5 ảnh test nhân vật đạt; location plate được duyệt.

---

### Trạm 2 — Board Lab (nhiều ảnh → 1 ảnh)

**Mục tiêu:** dựng keyframe chính xác cho từng shot.

**Công cụ:**
- **Qwen-Image-Edit 2511** (chính): nhận 2–3 ảnh tham chiếu
- **Krea 2** (phụ): 4 ảnh tham chiếu, cân bằng bằng `Krea2EditRebalance`
- **Seedream 5.0 Pro** (API, tùy chọn): tới 14 ảnh, chất lượng cao nhất

**Input:**
- Ảnh nhân vật (từ LoRA hoặc refs)
- Ảnh bối cảnh (location plate)
- Ảnh prop (nếu cần)
- Prompt bố cục: "Image 1 là nhân vật, Image 2 là bối cảnh, đặt nhân vật ở 1/3 phải, ánh sáng vàng ấm từ cửa sổ..."

**Output:**
- `first.png` (bắt buộc)
- `mid.png` (nếu shot >4s hoặc có biến đổi)
- `last.png` (nếu cần khớp shot sau)
- Độ phân giải đúng aspect ratio cuối (vd 1280×704)

**Gate:** keyframe được duyệt. Đây là gate quan trọng nhất — sửa ở đây rẻ hơn 20 lần so với sửa video.

---

### Trạm 3 — Motion Lab (1 ảnh / nhiều ảnh → video)

**Mục tiêu:** làm clip từ keyframe.

**Công cụ theo loại cảnh:**

| Cảnh | Model | Ghi chú |
|---|---|---|
| Đối thoại, tĩnh, cần audio | LTX 2.3 | Nhanh, audio 1 pass |
| Hành động, chuyển động mạnh | Wan 2.2 I2V 14B | Motion fidelity cao |
| Nhiều keyframe | Wan22FMLF | 3–6 ảnh, đặt vị trí |
| Đầu–cuối cố định | Wan FLF2V | Native ComfyUI |
| Cần diễn xuất | Wan 2.2 Animate | Video reference |
| Nhiều ref + audio | MiniMax H3 R2V | Cần GPU 80GB |

**Input:** keyframe(s) + `motion_prompt` + seed + duration.

**Output:** `v001.mp4`, 24fps, 4–8s.

**Gate:** shot đạt QC (xem `04-QUY-TRINH.md`), hoặc chuyển sang retake.

---

### Trạm 4 — Audio Lab

**Mục tiêu:** âm thanh khớp hình.

**Công cụ:**
| Việc | Model |
|---|---|
| Voice / clone | IndexTTS2, F5-TTS (local); ElevenLabs (API) |
| Lip-sync | Wan 2.2 S2V, LatentSync |
| SFX | MMAudio |
| Nhạc | Stable Audio 2.5, ACE-Step |

**Quy trình:**
1. TTS theo từng câu thoại (giữ file riêng để mix lại)
2. Lip-sync nếu có cận mặt
3. SFX theo hành động (bước chân, cửa, va chạm)
4. Nhạc nền: chọn 1 track cho cả phim, không đổi giữa cảnh

**Gate:** nghe được, khớp miệng, không lệch tiếng.

---

### Trạm 5 — Post

**Mục tiêu:** đưa clip lên chất lượng phát hành.

**Công cụ:**
- Upscale: SeedVR2 (local), Topaz (nếu có)
- Nội suy: RIFE / GIMM-VFI (24 → 48fps nếu cần)
- Dựng/màu/phụ đề: DaVinci Resolve

**Quy trình:**
1. Upscale từng clip (không upscale cả phim 1 lần)
2. Nội suy nếu muốn mượt
3. Ghép theo timeline, canh nhịp
4. Color grade: LUT chung cho cả phim
5. Phụ đề: font, vị trí, màu cố định
6. Mix audio: -14 LUFS cho web, -23 LUFS cho broadcast

**Gate:** final review, xuất master.

---

## Thành phần xuyên suốt

### Orchestrator
Script Python đọc `project.json`, kiểm tra shot nào `queued`, gọi ComfyUI API (`/prompt`), theo dõi `/history`, cập nhật trạng thái.

### Hàng đợi
- 1 GPU: hàng đợi tuần tự trong ComfyUI
- Nhiều GPU: mỗi GPU 1 ComfyUI instance + dispatcher gán job theo trạm

### Storage
- `models/` — read-only, chia sẻ giữa các instance
- `project/` — read-write, backup hàng ngày
- `output/` — tách theo `shot_id`

---

## Luồng dữ liệu 1 shot

```
project.json (status=planned)
   │
   ├─▶ Trạm 2: đọc characters/location refs
   │      └─▶ 02_boards/S01_SH003/{first,mid,last}.png
   │
   ├─▶ Trạm 3: đọc keyframes + motion_prompt
   │      └─▶ 03_clips/S01_SH003/v001.mp4
   │
   ├─▶ Trạm 4: đọc dialogue
   │      └─▶ 04_audio/S01_SH003/{voice,sfx}.wav
   │
   └─▶ Trạm 5: đọc clip + audio
          └─▶ 05_post/S01_SH003/v001_upscaled.mp4
                 └─▶ status=final
```
