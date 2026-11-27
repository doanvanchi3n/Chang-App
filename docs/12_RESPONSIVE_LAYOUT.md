# Responsive cho mobile, tablet và web/desktop

## Quy tắc chung

Các ngưỡng trong `AppLayout` là logical pixels của cửa sổ Flutter, áp dụng cho cả
web, desktop và thiết bị di động. Layout thay đổi theo không gian được cấp,
kể cả khi xoay màn hình hoặc thay đổi kích thước trình duyệt.

| Chiều rộng | Điều hướng trang chính | Nội dung |
| --- | --- | --- |
| Dưới 600 | Thanh dưới | Một cột, lề 20 |
| 600–1023 | NavigationRail bên trái | Mở theo cửa sổ, chia cột khi đủ chỗ |
| Từ 1024 | Thanh trên | Nội dung tối đa 1180, form tối đa 960 |

Giới hạn 560 chỉ dành cho sheet chọn ngắn (`maxSheetWidth`). Trang chính và form
không sử dụng giới hạn này. Màn phiên tập trung giữ đồng hồ ở giữa với bề rộng vừa đọc.

## Các thành phần dùng lại

- `FeatureSurface`: trang có nút quay lại, cuộn theo nội dung và bàn phím;
  mặc định dùng `maxFormWidth`, trang danh sách có thể chọn `maxDesktopWidth`.
- `AdaptiveColumns`: hai vùng nội dung nằm cạnh nhau khi mỗi vùng đủ rộng;
  tính thêm cỡ chữ và tỉ lệ flex, tự chuyển về xếp dọc khi thiếu chỗ.
- `AdaptiveCardGrid`: thẻ tự chia 1–3 cột, giữ chiều cao theo nội dung thực tế.
  Có thể giới hạn `maxColumns` và điều chỉnh `minCardWidth` cho từng danh sách.
- `AdaptiveNavigationFrame`: bổ sung rail cho Home, Hộp việc, công việc và dự án
  trên tablet; rail cuộn được khi cửa sổ thấp.

Áp dụng cho Home, Hộp việc, danh sách/chi tiết/tạo/sửa công việc, bước nhỏ,
danh sách/tạo/chi tiết dự án, việc đã xong, thông báo, kế hoạch hôm nay,
chuẩn bị/phiên tập trung và giới thiệu. Bộ chọn ngày, sheet và dialog tiếp tục
co theo không gian của cửa sổ. Các controller và state nghiệp vụ giữ nguyên khi đổi layout.

## Kiểm tra

`test/app/widgets/adaptive_layout_test.dart` kiểm tra 16 màn hình ở các chiều rộng
320, 390, 600, 768, 840, 1024 và 1440; bổ sung màn ngang 844×390,
chữ 2× trên mobile/tablet/desktop, thay đổi kích thước bản nháp và mở bàn phím.
Fixture chỉ nằm trong test, không kết nối backend thật.

```bash
flutter analyze --no-pub
flutter test --no-pub test/app/widgets/adaptive_layout_test.dart
flutter test --no-pub
flutter build web --no-pub
```

Để dựng ảnh kiểm tra trực quan, chạy widget test với
`--dart-define=CAPTURE_ADAPTIVE_UI=true`. Ảnh được ghi vào
`/tmp/chang-responsive-<screen>-<width>.png`.
