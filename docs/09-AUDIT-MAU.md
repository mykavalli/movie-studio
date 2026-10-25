# 09 — Mẫu audit server

> Đây là **mẫu**. Khi audit một instance mới, copy file này thành
> `local/audit-<ngày>.md` và điền thông tin thật. Không commit bản có thông tin thật.

## 1. Kết nối

```bash
ssh -p <SSH_PORT> root@<HOST>
```

- SSH port: `<SSH_PORT>`
- Ghi chú: kiểm tra port bằng `nmap`/vast.ai UI; port 22 thường đóng.

## 2. GPU

```
<TÊN_GPU>, <VRAM> MiB, driver <VERSION>
Tier: <T1|T1+|T2|T3|T4>
```

## 3. Hệ thống

```
RAM: <RAM_GB> GB
Disk: <DISK_SIZE>, còn trống <FREE>
Volume: <VOLUME_SIZE hoặc "không có">
Hostname: <HOSTNAME>
```

> Luôn kiểm tra `df -h /` — listing vast.ai có thể hiển thị dung lượng host, không phải dung lượng container.

## 4. Phần mềm

```
ComfyUI: <VERSION>
Python: <VERSION>
PyTorch: <VERSION>
ffmpeg: <VERSION>
```

## 5. Dịch vụ

```
supervisorctl status
```

## 6. Port

| Nội bộ | Công khai | Dịch vụ |
|---|---|---|
| 22 | `<SSH_PORT>` | SSH |
| 8080 | — | Jupyter |
| 18188 | `<UI_PORT>` | ComfyUI |
| 18288 | — | comfyui-api-wrapper |

## 7. Đường dẫn

```
/workspace/ComfyUI
/workspace/ComfyUI/models
/workspace/ComfyUI/custom_nodes
/workspace/ComfyUI/output
/var/log/portal/comfyui.log
/venv/main
```

## 8. Model hiện có

```
<TREE models/>
```

## 9. Custom node hiện có

```
<TREE custom_nodes/>
```

## 10. Việc cần làm ngay

1. Chốt phương án disk
2. Chạy `scripts/00-bootstrap.sh`
3. Chạy `scripts/01-install-nodes.sh`
4. Tải model core
5. Test 1 ảnh + 1 clip
