# 05 — Dữ liệu dự án

## 1. Cấu trúc thư mục

```
movie-studio/
├── project.json                  ← nguồn sự thật duy nhất
├── 00_script/
│   ├── treatment.md
│   ├── screenplay.md
│   └── shot-notes.md
├── 01_assets/
│   ├── characters/
│   │   └── linh/
│   │       ├── bible.md
│   │       ├── refs/             (6–10 ảnh chuẩn)
│   │       ├── lora/             (file .safetensors)
│   │       └── tests/            (5 ảnh test)
│   ├── locations/
│   │   └── quan_dem/
│   │       ├── brief.md
│   │       ├── plates/           (wide + medium)
│   │       └── style.md
│   ├── props/
│   └── style-guide.md
├── 02_boards/
│   └── S01_SH003/
│       ├── first.png
│       ├── mid.png
│       └── last.png
├── 03_clips/
│   └── S01_SH003/
│       ├── v001_wan22q5_s884213.mp4
│       └── v002_wan22q5_s991027.mp4
├── 04_audio/
│   ├── voice/S01_SH003_linh_01.wav
│   ├── sfx/
│   └── music/
├── 05_post/
│   └── S01_SH003/
│       └── v002_upscaled.mp4
├── 06_final/
│   ├── master_1080p.mp4
│   └── web_1080p.mp4
└── 07_backup/
```

**Quy tắc:** mỗi shot có thư mục riêng theo `shot_id`; không để file rời.

---

## 2. `project.json`

Xem schema đầy đủ tại `config/project.schema.json`, ví dụ tại `config/project.example.json`.

### Cấu trúc cấp cao

```json
{
  "project": {
    "id": "phim-01",
    "title": "Ánh Đèn Cuối Phố",
    "format": "16:9",
    "resolution": "1920x1080",
    "fps": 24,
    "language": "vi",
    "target_duration_sec": 180
  },
  "style": {
    "look": "cinematic, muted teal-orange",
    "lens": "35mm anamorphic",
    "grade_lut": "assets/luts/teal-orange.cube"
  },
  "characters": ["linh", "huy"],
  "locations": ["quan_dem", "duong_pho"],
  "shots": [ ... ]
}
```

### Một shot record

```json
{
  "shot_id": "S01_SH003",
  "scene": 1,
  "description": "Linh bước vào quán, ánh mắt dáo dác tìm người",
  "characters": ["linh"],
  "location": "quan_dem",
  "props": ["den_long"],
  "camera": "medium shot, slow dolly in",
  "duration_sec": 4.0,
  "dialogue": "Không có ai ở đây...",
  "motion_prompt": "She walks in slowly, eyes scanning the room, dust in the light beam",
  "keyframes": {
    "first": "02_boards/S01_SH003/first.png",
    "mid": null,
    "last": "02_boards/S01_SH003/last.png"
  },
  "render": {
    "model": "wan22_i2v_q5",
    "seed": 884213,
    "version": 2,
    "status": "board_approved"
  },
  "audio": {
    "voice_file": null,
    "sfx": [],
    "lip_sync": false
  },
  "qc": {
    "identity": null,
    "motion": null,
    "color": null,
    "notes": ""
  }
}
```

### Trạng thái hợp lệ

`planned` · `boarded` · `board_approved` · `rendering` · `rendered` · `approved` · `audio_done` · `post_done` · `final` · `blocked`

### Quy tắc cập nhật
- Chỉ orchestrator hoặc người duyệt được đổi `status`
- Mỗi lần render tăng `version`
- `seed` giữ nguyên khi chỉ đổi prompt; đổi khi muốn biến thể mới
- `qc` phải có đủ 3 mục trước khi `approved`

---

## 3. Asset registry

### `character-bible.md` — các mục bắt buộc
1. Tên, tuổi, giới tính
2. Ngoại hình: mặt, tóc, da, chiều cao, dáng
3. Trang phục chính + phụ
4. 3 biểu cảm đặc trưng
5. Từ khóa prompt cố định (`token`)
6. Negative prompt riêng
7. Đường dẫn refs + LoRA
8. Ghi chú diễn xuất

### `location/brief.md` — các mục bắt buộc
1. Tên, loại không gian
2. Thời điểm, thời tiết
3. Nguồn sáng chính + hướng
4. Palette màu
5. Vật liệu chủ đạo
6. Ống kính / góc máy đặc trưng
7. Âm thanh nền
8. Plate wide + medium

---

## 4. Prompt library

Lưu tại `01_assets/prompts/`:

| File | Nội dung |
|---|---|
| `style.txt` | prompt style chung, dùng cho mọi ảnh |
| `negative.txt` | negative dùng chung |
| `camera.txt` | các cụm camera chuẩn |
| `lighting.txt` | các cụm ánh sáng chuẩn |
| `character-<name>.txt` | token nhân vật |

**Quy tắc:** prompt trong code/workflow phải import từ library, không hard-code.

---

## 5. Versioning

| Loại | Quy tắc |
|---|---|
| Ảnh keyframe | `first.png` ghi đè; bản cũ đổi thành `first_v001.png` |
| Clip | `v###_<model>_s<seed>.mp4` — không ghi đè |
| Workflow | `workflows/<station>/<name>_v###.json` |
| `project.json` | git commit mỗi ngày |

**Không dùng:** `final`, `final2`, `copy`, `new`, `test` trong tên file chính thức.

---

## 6. Orchestrator (giai đoạn sau)

```
orchestrator/
├── main.py            đọc project.json, chọn shot theo status
├── comfy_client.py    gọi /prompt, /history, /queue
├── station_image.py   build graph cho trạm 2
├── station_video.py   build graph cho trạm 3
├── station_audio.py   build graph cho trạm 4
└── update_status.py   ghi lại project.json
```

Nguyên tắc:
- Mỗi station là 1 workflow JSON đã export API format
- Orchestrator chỉ thay tham số, không sửa graph
- Mọi job có `shot_id` + `version` để trace
