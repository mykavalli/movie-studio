# 11 — Kết quả test thực tế

## Môi trường test

| Hạng mục | Giá trị |
|---|---|
| Tier | **T1 — 24GB** |
| GPU | RTX 3090 24GB |
| CPU | AMD EPYC 7702P, 128 threads |
| RAM | 503GB |
| ComfyUI | 0.27.0 |
| PyTorch | 2.10.0 + cu128 |
| Disk | 1.8TB, còn 599GB |

---

## 1. Qwen-Image-Edit 2511 — 20 steps

| Thông số | Giá trị |
|---|---|
| Model | `qwen-image-edit-2511-Q6_K.gguf` |
| Text encoder | `qwen_2.5_vl_7b_fp8_scaled` |
| Resolution | ~1MP (FluxKontextImageScale) |
| Steps / CFG | 20 / 2.5 |
| Sampler | euler + simple |
| **Thời gian** | **172.6 giây** (~2m53s) |
| Kết quả | ✅ Thành công, không OOM |

**Nhận xét:** 20 steps quá chậm để iterate. Chỉ dùng cho bản final nếu cần.

---

## 2. Qwen-Image-Edit 2511 + Lightning 4 steps

| Thông số | Giá trị |
|---|---|
| LoRA | `Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16` |
| Steps / CFG | 4 / 1.0 |
| **Thời gian** | **36.6 giây** |
| Kết quả | ✅ Nét hơn, màu đậm hơn bản 20 steps |

**Kết luận:** dùng **4 steps + Lightning** làm mặc định. Nhanh gấp **4.7 lần**.

---

## 3. Wan 2.2 I2V 14B — 49 frames

| Thông số | Giá trị |
|---|---|
| Model | HighNoise/LowNoise `Q4_K_M.gguf` |
| LoRA | `wan2.2_i2v_lightx2v_4steps` high + low |
| Resolution | 832 × 480 |
| Frames | 49 (2.04s @ 24fps) |
| Steps / CFG | 4 / 1.0 (2 high + 2 low) |
| **Thời gian** | **92.3 giây** |
| Kết quả | ✅ MP4 h264, 832×480, 49 frame, 222KB |

**Ước tính cho 81 frame (3.4s):** ~2.5 phút.
**Ước tính 720p:** ~2× thời gian.

---

## 4. Tổng kết tốc độ

| Việc | Thời gian | Ghi chú |
|---|---|---|
| 1 ảnh Qwen-Edit (4 step) | **37s** | Dùng hàng ngày |
| 1 ảnh Qwen-Edit (20 step) | 173s | Chỉ final |
| 1 clip Wan 49f 480p | **92s** | 2 giây video |
| 1 clip Wan 81f 480p (ước tính) | ~150s | 3.4 giây video |
| 1 shot hoàn chỉnh (ảnh + clip) | **~2–3 phút** | Chưa tính duyệt |

---

## 5. File test

| File | Vị trí |
|---|---|
| Workflow Qwen 4-step | `workflows/api/qwen_edit_2511_lightning.json` |
| Workflow Qwen 20-step | `workflows/api/qwen_edit_2511_20step.json` |
| Workflow Wan I2V | `workflows/api/wan22_i2v_lightning.json` |
| Ảnh test | `ComfyUI/output/movie_studio/qwen_lightning_00001_.png` |
| Video test | `ComfyUI/output/movie_studio/wan_test_00001_.mp4` |

---

## 6. Cách chạy lại

Từ máy local (qua tunnel):

```bash
curl -X POST http://127.0.0.1:8188/prompt \
  -H "Content-Type: application/json" \
  --data-binary @workflows/api/qwen_edit_2511_lightning.json
```

Hoặc trên server:

```bash
curl -X POST http://127.0.0.1:18188/prompt \
  -H "Content-Type: application/json" \
  --data-binary @/workspace/movie-studio/workflows/api/wan22_i2v_lightning.json
```

Sau đó xem `/workspace/ComfyUI/output/movie_studio/`.

---

## 7. Việc chưa test

- LTX 2.3 (chưa tải — tier `full`)
- SeedVR2 upscale
- MMAudio / IndexTTS2
- Wan22FMLF multi-keyframe
- LTX Director timeline

Các mục này sẽ test khi mở rộng lên tier `full`.
