# 00 — Tổng quan

## 1. Mục tiêu

Xây một **xưởng sản xuất phim AI** có thể lặp lại, không phải một bộ sưu tập workflow rời rạc.

| Hạng mục | Mục tiêu |
|---|---|
| Sản phẩm | Phim ngắn 2–5 phút, 30–60 shot |
| Nhân vật | 1–3 nhân vật chính, nhất quán xuyên phim |
| Bối cảnh | 3–8 location, có style guide |
| Thời gian | 1 shot hoàn chỉnh: 15–30 phút (gồm duyệt) |
| Chất lượng | Tỷ lệ shot được duyệt ngay lần 1: ≥ 50% |
| Tái sử dụng | Cùng quy trình cho phim thứ 2, 3... |

**Ngoài phạm vi giai đoạn này:** phim dài 30+ phút, 3D/CGI, realtime, live-action compositing phức tạp.

---

## 2. Vấn đề cần giải

Làm phim AI thất bại không phải vì model yếu, mà vì:

1. **Không có nguồn sự thật duy nhất** — mỗi lần generate lại mô tả nhân vật khác nhau.
2. **Không có thứ tự sản xuất** — render video trước khi chốt thiết kế → sửa 1 chi tiết phải làm lại cả clip.
3. **Không có version** — không biết shot nào đã duyệt, shot nào còn nháp.
4. **Không có QC** — lỗi tay, mắt, drift màu lọt vào bản final.
5. **Chọn model theo cảm tính** — dùng 1 model cho mọi cảnh, hoặc đổi model giữa phim.

Xưởng này giải quyết bằng: **shot database + 6 trạm + gate duyệt**.

---

## 3. Định nghĩa "xưởng"

Một xưởng gồm 3 lớp:

```
LỚP 1 — DỮ LIỆU       project.json + asset registry + prompt library
LỚP 2 — SẢN XUẤT      6 trạm (script → asset → board → motion → audio → post)
LỚP 3 — ĐIỀU PHỐI     orchestrator + hàng đợi + backup
```

Thiếu lớp 1 thì không tái sử dụng được.
Thiếu lớp 3 thì chỉ là "làm thủ công có tổ chức".

---

## 4. Nguyên tắc thiết kế

### 4.1 Keyframe-first
Ảnh tĩnh rẻ, sửa nhanh, dễ duyệt. Video đắt, sửa chậm.
→ Luôn chốt bố cục/ánh sáng/nhân vật ở trạm 2 trước khi sang trạm 3.

### 4.2 Một nguồn sự thật cho nhân vật
- `character-bible.md`: mô tả bằng lời
- `refs/`: 6–10 ảnh chuẩn
- `lora/`: LoRA đã train
- `token`: cụm từ cố định dùng trong mọi prompt

Mọi prompt sinh nhân vật phải tham chiếu cùng bộ này.

### 4.3 Model theo cảnh, không theo sở thích
| Loại cảnh | Model |
|---|---|
| Đối thoại, cận mặt, cần audio | LTX 2.3 |
| Hành động, chuyển động phức tạp | Wan 2.2 |
| Cần diễn xuất chính xác | Wan 2.2 Animate |
| Nhiều keyframe trong 1 shot | Wan22FMLF |

### 4.4 Duyệt theo gate
Không có cảnh nào đi tiếp khi gate trước chưa đạt. Xem `04-QUY-TRINH.md`.

### 4.5 Version hóa tự động
`S01_SH003_v003_wan22_seed884213.mp4` — không đặt tên tay.

---

## 5. KPI theo dõi

| Chỉ số | Cách đo | Mục tiêu |
|---|---|---|
| Shot/ngày | Đếm shot `approved` | ≥ 6 |
| Tỷ lệ duyệt lần 1 | approved / rendered | ≥ 50% |
| Drift nhân vật | % shot phải làm lại vì mặt/sai nhân vật | < 15% |
| Thời gian 1 shot | từ `boarded` → `approved` | < 30 phút |
| Chi phí/film | tiền GPU + API | < $60 |

---

## 6. Quyết định cần chốt trước khi bắt đầu

| # | Quyết định | Lựa chọn | Ảnh hưởng |
|---|---|---|---|
| D1 | Disk | 80GB hiện tại / gắn volume 200GB / thuê instance mới | Có chạy được LTX + full stack hay không |
| D2 | Có dùng API premium? | Không / Seedream + Seedance cho hero shot | Chất lượng vs chi phí |
| D3 | Có train LoRA nhân vật? | Không / có (khuyến nghị) | Độ nhất quán |
| D4 | Ngôn ngữ phim | Việt / Anh | Prompt, TTS, lip-sync |
| D5 | Định dạng | 16:9 1080p / 9:16 | Resolution, model |

Ghi quyết định vào `docs/06-KE-HOACH.md` mục "Quyết định đã chốt".
