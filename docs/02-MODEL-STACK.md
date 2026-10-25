# 02 — Model Stack

## Nguyên tắc chọn model

1. **Mỗi trạm một model chính**, không dùng 1 model cho tất cả.
2. **Ưu tiên local** cho việc lặp nhiều lần (ảnh, video nháp).
3. **Dùng API có chọn lọc** cho shot hero hoặc việc local chưa làm tốt (multi-ref 14 ảnh, video ref+audio).
4. **Quant vừa VRAM** — GPU consumer (T1–T2) không có FP8 tăng tốc, dùng GGUF.
5. **License phải rõ** trước khi dùng thương mại.

---

## Bảng model theo trạm

| Trạm | Việc | Model chính (local) | Model phụ / API | VRAM |
|---|---|---|---|---|
| 0 | Kịch bản, shot list | Qwen3 (local, tùy chọn) | **Claude / GPT** (khuyến nghị) | — |
| 1 | Character sheet | **Qwen-Image-Edit 2511** | Krea 2, FLUX.2 | 20–24GB |
| 1b | Train LoRA nhân vật | **AI Toolkit** | — | 24GB+ |
| 2 | Ghép nhiều ảnh → 1 ảnh | **Qwen-Image-Edit 2511** | **Krea 2**, FLUX.2, **Seedream 5.0 Pro** (API) | 20–28GB |
| 3 | 1 ảnh → video (action) | **Wan 2.2 I2V 14B** | Seedance 2.0, Kling 4.0 | 24–30GB |
| 3 | Nhiều ảnh → video | **Wan22FMLF** + Wan 2.2 | Seedance 2.0 (9 ảnh) | 24–30GB |
| 3 | Đầu–cuối | **Wan 2.2 FLF2V** | — | 24–30GB |
| 3 | Nháp nhanh + audio | **LTX 2.3** | — | 22–28GB |
| 3 | Diễn xuất từ video ref | **Wan 2.2 Animate** | Kling Motion | 24–30GB |
| 3 | Nhiều ref + audio | MiniMax H3 R2V | Seedance 2.0 | 48–80GB |
| 4 | Voice / clone | **IndexTTS2**, F5-TTS | ElevenLabs | 4–8GB |
| 4 | Lip-sync | **Wan 2.2 S2V**, LatentSync | — | 16–24GB |
| 4 | SFX | **MMAudio** | ElevenLabs SFX | 6–10GB |
| 4 | Nhạc | **Stable Audio 2.5**, ACE-Step | Suno / Udio | 8–12GB |
| 5 | Upscale | **SeedVR2** | Topaz Video AI | 8–16GB |
| 5 | Nội suy | **RIFE / GIMM-VFI** | — | 2–4GB |

---

## Bộ "core" cho Tier 2 (32GB) / disk 80GB (~58GB)

Đây là bộ tối thiểu để chạy **1 shot end-to-end**.

### Ảnh — Qwen-Image-Edit 2511

| File | Repo | Dest | Size |
|---|---|---|---|
| `Qwen-Image-Edit-2511-Q6_K.gguf` | `QuantStack/Qwen-Image-Edit-2511-GGUF` | `models/unet/` | ~17GB |
| `qwen_2.5_vl_7b_fp8_scaled.safetensors` | `Comfy-Org/HunyuanVideo_1.5_repackaged` | `models/text_encoders/` | ~8GB |
| `qwen_image_vae.safetensors` | `Comfy-Org/Qwen-Image_ComfyUI` | `models/vae/` | ~0.3GB |
| `Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors` | `lightx2v/Qwen-Image-Edit-2511-Lightning` | `models/loras/` | ~0.9GB |

**Thiết lập:** 4 step, CFG 1.0, 1328×1328 hoặc 1280×704.
**Thời gian:** ~20–35s/ảnh trên Tier 2 (32GB).

### Video — Wan 2.2 I2V 14B

| File | Repo | Dest | Size |
|---|---|---|---|
| `*high-noise*Q5_K_M.gguf` | `QuantStack/Wan2.2-I2V-A14B-GGUF` | `models/unet/` | ~10GB |
| `*low-noise*Q5_K_M.gguf` | `QuantStack/Wan2.2-I2V-A14B-GGUF` | `models/unet/` | ~10GB |
| `umt5_xxl_fp8_e4m3fn_scaled.safetensors` | `Comfy-Org/Wan_2.2_ComfyUI_Repackaged` | `models/text_encoders/` | ~5GB |
| `wan_2.1_vae.safetensors` | `Comfy-Org/Wan_2.2_ComfyUI_Repackaged` | `models/vae/` | ~0.3GB |
| `wan2.2_i2v_lightx2v_4steps_lora_v1_*_noise.safetensors` | `lightx2v/Wan2.2-Lightning` | `models/loras/` | ~1.5GB |

**Thiết lập:** 4 step Lightning, 480p hoặc 720p, 81 frame.
**Thời gian:** 480p ~2–4 phút; 720p ~6–10 phút.

### Hậu kỳ & audio tối thiểu

| Việc | Repo / node | Size |
|---|---|---|
| Upscale | `numz/ComfyUI-SeedVR2_VideoUpscaler` + model SeedVR2 | ~3–7GB |
| Nội suy | `Fannovel16/ComfyUI-Frame-Interpolation` (RIFE) | ~0.2GB |
| Voice | `IndexTeam/IndexTTS-2` | ~2GB |
| SFX | `kijai/ComfyUI-MMAudio` + model | ~1–2GB |

> Tổng core ≈ **58GB**. Với disk 74GB còn trống, chỉ dư ~16GB cho output — đủ để test, **không đủ cho dự án thật**.

---

## Bộ "full" (cần volume ≥ 200GB)

Thêm vào core:

### LTX 2.3 — nháp nhanh + audio

| File | Repo | Dest | Size |
|---|---|---|---|
| `ltx-2.3-22b-...-Q4_K_S.gguf` | `unsloth/LTX-2.3-GGUF` | `models/unet/` | ~12GB |
| `gemma_3_12B_it_fp8_scaled.safetensors` | `Lightricks/LTX-2.3` | `models/text_encoders/` | ~12GB |
| video VAE + audio VAE | `Lightricks/LTX-2.3` | `models/vae/` | ~5GB |
| `ltx-2.3-spatial-upscaler-x2-1.1.safetensors` | `Lightricks/LTX-2.3` | `models/latent_upscale_models/` | ~1GB |
| distilled LoRA + gemma abliterated LoRA | `Lightricks/LTX-2.3` | `models/loras/` | ~2GB |

> LTX chiếm ~32GB. Nếu giữ cả Wan + LTX + Qwen → ~90GB model.

### Tùy chọn nâng cao

| Model | Repo | Size | Khi nào dùng |
|---|---|---|---|
| Krea 2 Turbo | `Comfy-Org/Krea-2` | ~15–25GB | Ghép 4 ảnh ref |
| FLUX.2 dev | `black-forest-labs/FLUX.2-dev` | ~20–32GB (GGUF Q4) | Multi-ref, chất lượng cao |
| Wan 2.2 Animate | `Wan-AI/Wan2.2-Animate-14B` | ~15–20GB | Cảnh action có diễn xuất |
| Wan 2.2 S2V | `Wan-AI/Wan2.2-S2V-14B` | ~15–20GB | Lip-sync |
| MiniMax H3 | `Comfy-Org/MiniMax-H3` | ~36GB | Chỉ GPU ≥ 48GB |

---

## VRAM math trên Tier 2 (32GB)

ComfyUI nạp **tuần tự**: text encoder → unload → diffusion → VAE decode. Vì vậy peak thường = model lớn nhất + VAE, không cộng dồn tất cả.

| Pipeline | Peak ước tính | Kết luận |
|---|---|---|
| Qwen Edit Q6 + TE 8GB | ~20GB | ✅ thoải mái |
| Wan Q5 high+low + TE | ~22GB | ✅ ổn |
| Wan Q8 high+low | ~30GB | ⚠️ sát trần, dễ OOM |
| LTX Q6 + Gemma 12GB | ~21GB | ✅ ổn |
| FLUX.2 Q4 + TE | ~22GB | ✅ ổn |
| MiniMax H3 int8 | ~40GB+ | ❌ không chạy |

**Khuyến nghị:** Q5–Q6 cho Wan/LTX, Q6–Q8 cho Qwen (chỉ 1 model/lúc). Không dùng Q8 cho Wan.

---

## License — kiểm tra trước khi dùng thương mại

| Model | License | Ghi chú |
|---|---|---|
| Qwen-Image-Edit | Apache 2.0 | Dùng thương mại được |
| Wan 2.2 | Apache 2.0 | Dùng thương mại được |
| LTX 2.3 | LTX-2 Community License | Miễn phí nếu doanh thu < $10M/năm |
| FLUX.2 dev | FLUX.2 Non-Commercial | **Không dùng thương mại** |
| Krea 2 | Kiểm tra model card | Có thể hạn chế |
| Seedream / Seedance | API terms | Trả tiền theo lần gọi |
| MiniMax H3 | H3 Community License | Cần đăng ký ở một số quốc gia |

---

## Model manifest

Danh sách máy đọc được: `config/models.manifest.yaml`.
Script tải: `scripts/02-download-models.sh --tier core|full|optional`.
