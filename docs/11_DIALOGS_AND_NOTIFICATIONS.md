# Lịch, hộp xác nhận và thông báo

## Giao diện dùng chung

- `showChangDate` dùng lịch một cột, tiêu đề và ngày đã chọn có thể xuống dòng,
  cuộn dọc khi cửa sổ thấp/ngang. Có Hôm nay, Ngày mai, chọn tháng/năm và nút đóng/hủy.
  M18 dùng trực tiếp bộ chọn ngày này, rồi lưu hạn vào cuối ngày như trước.
- `showChangDeadline` dùng cùng lịch rồi chọn giờ 24 giờ cho công việc.
- `showChangConfirmation` thống nhất hộp xác nhận rời form, bỏ thay đổi,
  tải lại kế hoạch, xóa việc/âm thanh, kết thúc phiên. Xóa dùng nút đỏ;
  thao tác thông thường dùng nút xanh. Đóng hộp luôn tương đương hủy.
- `AppTheme` quy định nền trắng, viền và màu chữ cho dialog/menu/bottom sheet,
  cùng snackbar nổi có chữ trắng. Nút và nội dung dài tự xuống dòng/cuộn.

## Nút chuông và M07

Nút chuông trên Home mở trung tâm thông báo; `/notifications` cũng có thể mở trực tiếp.
Badge đếm thông báo chưa đọc (tối đa hiển thị 99+), dấu `!` khi chưa tải được.
Lỗi tải thông báo không chặn Dashboard và nút chuông vẫn mở được màn thử lại.

Danh sách lấy từ bảng `notifications` của Supabase, phân trang 100 bản ghi,
lọc người dùng hiện tại và chỉ lấy bản ghi có `scheduled_at` rỗng hoặc đã đến giờ.
Sắp xếp theo thời điểm gửi, chia **Hôm nay / Trước đó**, lọc **Tất cả / Chưa đọc**
và loại (công việc, lịch học, cột mốc, gợi ý AI, hệ thống).

Chạm thông báo chưa đọc cập nhật riêng `notifications.is_read`:

- `REMINDER_TASK` có `reference_id` mở M13 của công việc đó.
- Các loại khác mở nội dung đầy đủ. Màn chi tiết lịch M24/kết quả AI M48 chưa có
  trong app nên chưa điều hướng tới các màn đó.
- **Đánh dấu tất cả đã đọc** chỉ cập nhật thông báo của người dùng đã đến giờ gửi.
- Không đổi trạng thái/tiến độ công việc. Lỗi ghi giữ số chưa đọc và báo lỗi;
  người dùng vẫn xem được nội dung.

Dữ liệu làm mới mỗi phút khi có màn đang sử dụng, khi quay lại app và khi người dùng
nhấn làm mới. Không tạo thông báo mẫu trong sản phẩm.
Đây là trung tâm thông báo trong ứng dụng; chưa thêm push của hệ điều hành,
quyền thông báo thiết bị hoặc bộ lập lịch tự sinh nhắc việc.

## SQL cần chạy

Trong Supabase SQL Editor, sau schema gốc, chạy toàn bộ:

[`20261127010000_notifications_read.sql`](../supabase/migrations/20261127010000_notifications_read.sql)

File cấp SELECT và UPDATE riêng cột `is_read` cho `authenticated`, bổ sung index
và giữ nguyên chính sách RLS theo `user_id`. Không seed hoặc tự chạy trên app.
Trong phiên này chưa áp dụng SQL hoặc kiểm chứng trên Supabase thật.
Sau khi chạy file, bảng chưa có thông báo sẽ hiển thị trạng thái **Chưa có thông báo**.

## Kiểm tra

```bash
flutter analyze
flutter test test/app/widgets/dialogs_test.dart \
  test/app/widgets/focus_picker_test.dart test/features/notifications \
  test/features/tasks/projects_flow_test.dart \
  test/features/tasks/task_management_test.dart
```

Test dùng font Inter/Material Icons thật; kiểm tra cửa sổ nhỏ, chữ 150%, cửa sổ ngang,
chọn ngày/hủy/xác nhận, badge, bộ lọc, quyền và phân trang truy vấn, mở đúng task,
đánh dấu đã đọc, lỗi mạng và trạng thái trống. Có thể xuất ảnh render vào `/tmp`:

```bash
flutter test --update-goldens --dart-define=CAPTURE_DIALOG_UI=true \
  test/app/widgets/dialogs_test.dart test/features/notifications/notifications_page_test.dart
```

Kết quả kiểm chứng: analyzer sạch, định dạng đúng, 62 test hồi quy liên quan đều qua.
Chạy toàn bộ vẫn còn đúng 10 test lỗi đã tồn tại ở Home/onboarding/Hộp việc;
đối chiếu báo cáo trước đợt thay đổi không có test lỗi mới.
