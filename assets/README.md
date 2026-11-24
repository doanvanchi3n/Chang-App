# Tài nguyên ứng dụng

| Thư mục | Nội dung |
| --- | --- |
| `images/` | Ảnh minh họa, ảnh nền |
| `icons/` | Icon riêng của thương hiệu |
| `animations/` | Animation linh vật |
| `audio/` | Âm thanh tập trung |
| `fonts/` | Font Inter và giấy phép đi kèm |

Đã có mascot SVG, ảnh tham chiếu UI và font Inter kèm giấy phép.
Các đường dẫn được khai báo trong `flutter.assets` và `flutter.fonts`
của `pubspec.yaml`; tài nguyên sử dụng được offline.
Không đặt file môi trường hoặc khóa bí mật vào assets.

## M06 — Intro

- Thiết kế tham chiếu: `UI/M06.png`.
- Mascot gốc: `mascot/spash Screen.svg` (giữ nguyên tên file người dùng cung cấp).
- `mascot/splash_body.svg` và `mascot/splash_wing.svg` là hai lớp tách từ
  mascot gốc, cùng viewBox `40 33 745 790`. Flutter xoay lớp `waving-wing`
  quanh vai `(600, 430)` trong 1,2 giây; lớp thân giữ nguyên.
- Khi đổi SVG gốc, cập nhật lại hai lớp và điểm xoay trong `IntroMascot`.
- M06 dùng chữ và nút Flutter thực, không dùng ảnh tham chiếu làm màn hình.
