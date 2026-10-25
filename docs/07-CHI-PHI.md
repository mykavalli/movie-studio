# 07 — Phân hạng GPU & chi phí

> Giá vast.ai thay đổi theo host/thời điểm. Số dưới đây là ước tính để lập ngân sách, không phải báo giá.

## 1. Phân hạng theo giai đoạn

| Giai đoạn | GPU | VRAM | Giá/h | Phù hợp |
|---|---|---|---|---|
| **T1 — Học / thử nghiệm** | 1× RTX 3090 | 24GB | ~$0.20–0.30 | Làm quen ComfyUI, test 1 shot |
| **T1+ — Xưởng 1 người** | 1× RTX 4090 | 24GB | ~$0.35–0.50 | Dự án nhỏ, chạy core |
| **T2 — Render nhanh** | 1× RTX 5090 | 32GB | ~$0.70–1.00 | Core + LTX, 1 người làm phim |
| **T3 — Studio nhỏ** | 2× 32GB | 64GB | ~$1.40–2.00 | Ảnh + video song song |
| **T4 — Studio** | 1× A100 80GB | 80GB | ~$1.00–1.60 | MiniMax H3, model lớn |
| **T4+ — Studio batch** | 1× H100 80GB | 80GB | ~$2.00–3.00 | Batch lớn, nhiều dự án |

**Cách đọc:** chọn tier theo *việc cần làm*, không theo card cụ thể. Card chỉ là ví dụ cho tier đó.

---

## 2. Chi phí GPU theo tier

| Tier | Giờ/tháng | Tiền/tháng |
|---|---|---|
| T1 | 60 | $12–18 |
| T1+ | 60 | $21–30 |
| T2 | 60 | $42–60 |
| T3 | 60 | $84–120 |
| T4 | 40 | $40–64 |
| T4+ | 40 | $80–120 |

---

## 3. Chi phí lưu trữ

| Loại | Giá | Ghi chú |
|---|---|---|
| Disk instance | thường đã gồm trong giá thuê | mất khi destroy |
| Volume vast.ai | ~$0.07–0.15/GB/tháng | persistent |
| Volume 200GB | ~$14–30/tháng | khuyến nghị cho T2 |
| Volume 500GB | ~$35–75/tháng | cho T3 |
| Google Drive | đã có 5–10TB | **$0 thêm** — dùng làm backup |
| Object storage (R2/S3) | ~$0.015/GB/tháng | thay thế nếu cần API |

---

## 4. Chi phí API (tùy chọn)

| Dịch vụ | Dùng cho | Giá ước tính |
|---|---|---|
| Claude/GPT | viết shot list, prompt | $5–15/phim |
| Seedream 5.0 Pro | ghép ảnh hero (14 ref) | $0.03–0.08/ảnh |
| Seedance 2.0 | video hero multi-ref | $0.30–0.80/clip 5s |
| ElevenLabs | voice chất lượng cao | $5–22/tháng |
| Topaz | upscale master | $12–25/tháng (nếu mua) |

---

## 5. Kịch bản ngân sách cho 1 phim 3 phút

### Kịch bản A — Tối thiểu (T1, core only)
| Khoản | Chi phí |
|---|---|
| GPU 40 giờ | $10–16 |
| API LLM | $10 |
| Lưu trữ | $0 |
| **Tổng** | **~$20–26** |

### Kịch bản B — Khuyến nghị (T2 + volume 200GB)
| Khoản | Chi phí |
|---|---|
| GPU 60 giờ | $45–60 |
| Volume 200GB (1 tháng) | $20 |
| API LLM + 5 shot hero | $25 |
| **Tổng** | **~$90–105** |

### Kịch bản C — Studio (T3 + volume 500GB)
| Khoản | Chi phí |
|---|---|
| GPU 80 giờ | $112–160 |
| Volume 500GB | $50 |
| API LLM + 15 shot hero | $45 |
| **Tổng** | **~$207–255** |

### Kịch bản D — Cao cấp (T4+ + 2 GPU phụ)
| Khoản | Chi phí |
|---|---|
| GPU 60 giờ | $210–270 |
| Volume 1TB | $80–120 |
| API | $50 |
| **Tổng** | **~$340–440** |

---

## 6. Cách tiết kiệm

1. **Tắt instance khi không dùng** — đừng để chạy 24/7.
2. **Render ban đêm theo batch** — không cần máy mạnh cả ngày.
3. **Volume thay vì tải lại model** — tiết kiệm 1–2 giờ mỗi lần thuê.
4. **Nháp bằng LTX 8-step hoặc Wan 5B** — chỉ render final bằng model lớn.
5. **Giới hạn 3 lần retake/shot** — tránh đốt GPU vô hạn.
6. **Dùng API cho 5–10 shot hero**, không dùng cho toàn phim.
7. **Lưu output lên Google Drive** thay vì mua thêm volume.

---

## 7. Theo dõi chi phí

Ghi vào `local/chi-phi-thuc-te.md` (không commit):

| Ngày | Tier | Giờ | Tiền | Việc đã làm |
|---|---|---|---|---|
| | | | | |
