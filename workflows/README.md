# Workflows

Thư mục chứa workflow JSON đã export, chia theo trạm.

## Cấu trúc

```
workflows/
├── station2_board/
│   ├── qwen_edit_2511_multi_ref_v1.json
│   └── krea2_multi_ref_v1.json
├── station3_motion/
│   ├── wan22_i2v_q5_lightning_v1.json
│   ├── wan22_flf2v_v1.json
│   ├── wan22fmlf_3frames_v1.json
│   ├── ltx23_director_v1.json
│   └── wan22_animate_v1.json
├── station4_audio/
│   ├── index_tts2_v1.json
│   ├── mmaudio_sfx_v1.json
│   └── wan22_s2v_lipsync_v1.json
└── station5_post/
    ├── seedvr2_upscale_v1.json
    └── rife_interp_v1.json
```

## Nguồn workflow có sẵn

| Workflow | Lấy ở đâu |
|---|---|
| LTX 2.3 Director 2.0 | `WhatDreamsCost-ComfyUI/example_workflows/` |
| Wan 2.2 I2V | ComfyUI → Workflow → Browse Templates → Video → Wan 2.2 |
| Wan 2.2 FLF2V | ComfyUI template `video_wan2_2_14B_flf2v` |
| Wan 2.2 Prompt Relay | `ComfyUI-PromptRelay/example_workflows/` |
| Wan22FMLF | `ComfyUI-Wan22FMLF/example_workflows/` |
| Qwen-Image-Edit 2511 | ComfyUI template `image_qwen_image_edit_2511` |
| SeedVR2 | `ComfyUI-SeedVR2_VideoUpscaler/example_workflows/` |

## Quy tắc

1. Mỗi workflow phải export **API format** để orchestrator gọi được.
2. Đặt tên: `<model>_<purpose>_v<###>.json`.
3. Không sửa workflow đã dùng để render shot `approved` — tạo version mới.
4. Ghi chú tham số quan trọng vào đầu file bằng node Note.
5. Không hard-code đường dẫn tuyệt đối; dùng path tương đối trong `ComfyUI/input`.

## Tham số chuẩn cho Tier 2 (32GB)

| Model | Steps | CFG | Resolution | Ghi chú |
|---|---|---|---|---|
| Qwen-Edit 2511 + Lightning | 4 | 1.0 | 1280×704 | `--reserve-vram 1` |
| Wan 2.2 I2V + Lightning | 4 | 1.0 | 832×480 | 81 frame |
| Wan 2.2 I2V (dev) | 20 | 3.0 | 832×480 | final |
| LTX 2.3 distilled | 8 | 1.0 | 768×512 → ×2 | frame `8n+1` |
| LTX 2.3 dev | 20 | 3.0 | 768×512 → ×2 | final |
