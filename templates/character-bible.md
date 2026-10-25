# Character Bible — `<tên nhân vật>`

> Điền đầy đủ trước khi generate bất kỳ ảnh nào.
> Mọi prompt sinh nhân vật phải dùng đúng `token` và `negative` dưới đây.

## 1. Định danh

| Trường | Giá trị |
|---|---|
| ID | `linh` |
| Tên | Linh |
| Tuổi | 27 |
| Giới tính | Nữ |
| Vai trò | Nhân vật chính |
| Quốc tịch / vùng miền | Việt Nam, Hà Nội |

## 2. Ngoại hình

| Trường | Mô tả |
|---|---|
| Khuôn mặt | Trái xoan, gò má cao nhẹ |
| Mắt | Nâu đen, một mí, hơi xếch |
| Lông mày | Đen, mảnh, cong tự nhiên |
| Mũi | Cao vừa, đầu mũi tròn |
| Miệng | Môi dưới đầy, màu tự nhiên |
| Da | Trắng ngà, hơi ửng |
| Tóc | Đen, ngang vai, mái lệch |
| Chiều cao | 1m63 |
| Dáng | Mảnh, vai nhỏ |
| Dấu đặc biệt | Nốt ruồi dưới mắt trái |

## 3. Trang phục

| Bối cảnh | Trang phục |
|---|---|
| Chính | Áo sơ mi trắng, quần tây đen, giày da |
| Ngoài đường | Khoác trench be, khăn len xám |
| Ở nhà | Áo thun rộng, quần short |

## 4. Biểu cảm đặc trưng

1. Bình thản — mắt hơi nhíu, môi khép
2. Ngạc nhiên — mắt mở lớn, môi hé
3. Buồn — mắt nhìn xuống, vai xuôi

## 5. Prompt token (dùng nguyên văn)

```
linh, 27yo vietnamese woman, oval face, high cheekbones, dark brown monolids,
thin arched black eyebrows, straight nose, full lower lip, ivory skin,
shoulder-length black hair with side-swept bangs, mole under left eye,
slim build, 163cm
```

## 6. Negative prompt riêng

```
different face, round face, double eyelids, blonde hair, short hair,
tattoo, glasses, heavy makeup, child, elderly
```

## 7. Tài nguyên

| Loại | Đường dẫn |
|---|---|
| Refs | `01_assets/characters/linh/refs/` |
| LoRA | `01_assets/characters/linh/lora/linh_v1.safetensors` |
| Test | `01_assets/characters/linh/tests/` |

### Danh sách refs
- [ ] `front.png` — mặt chính diện, trung tính
- [ ] `three-quarter.png` — 3/4 trái
- [ ] `profile.png` — nghiêng phải
- [ ] `full-body.png` — toàn thân
- [ ] `smile.png`
- [ ] `sad.png`
- [ ] `surprised.png`

## 8. Ghi chú diễn xuất

- Điệu bộ: hay vuốt tóc khi lo lắng
- Ánh mắt: ít giao tiếp trực diện, thường nhìn chếch
- Giọng: trầm, nói chậm

## 9. Lịch sử train LoRA

| Version | Ngày | Số ảnh | Steps | Kết quả |
|---|---|---|---|---|
| v1 | | | | |
