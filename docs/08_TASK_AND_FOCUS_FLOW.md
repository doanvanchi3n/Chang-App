# FEAT-05, 17, 19, 20 — công việc và phiên tập trung

## Chuẩn bị Supabase

Sau các migration hiện có, đặc biệt `20261124010000_feat04_daily_plan.sql`,
chạy toàn bộ `supabase/migrations/20261124020000_tasks_and_focus_flow.sql`
trong Supabase SQL Editor. File có hai transaction để commit giá trị enum mới
trước khi sử dụng. Không chạy `seed.sql`; flow này không cần dữ liệu mẫu.

Migration bổ sung trạng thái phiên đang chạy, tạm dừng và chờ tổng kết;
lưu thời gian chính xác đến mili giây, ghi chú và xác nhận hoàn thành bước.
Các RPC dùng `auth.uid()` và RLS hiện có, tương thích tài khoản ẩn danh đã bật.
Không cần service-role key trong app.

## Luồng giao diện

- Home → **Thêm việc** hoặc Hộp việc → **Tạo công việc và chia bước nhỏ**.
- M12: tên, mô tả, dự án thật (không bắt buộc), hạn ngày/giờ, ưu tiên,
  thời lượng và 1–5 bước. Tạo task và các bước trong cùng transaction.
- Chi tiết: tiến độ, checkbox từng bước và nút chuẩn bị phiên học.
- M27: chọn việc/bước, 15/25/45 phút hoặc tùy chỉnh, bật/tắt nhiễu trắng.
- Đang tập trung ↔ M29: tạm dừng, tiếp tục, kết thúc sớm, thu gọn về thanh phiên học.
- M30: thời gian thực tế, xác nhận bước độc lập, ghi chú, lưu về Home hoặc nghỉ 5 phút.

Màn mới dùng cùng chiều ngang tối đa 560 px và padding 24 px với Home/Hộp việc.
Mascot M27, M29, M30 lấy từ asset được cung cấp. Màn Chi tiết và Đang tập trung
được bổ sung để nối flow; không triển khai các màn sửa việc/quản lý bước M14/M15.

## Quy tắc dữ liệu

- Đồng hồ dựa trên thời điểm bắt đầu/chạy tiếp, không cộng từng tick UI.
  Thời gian tạm dừng bị loại trừ; phiên đầy đủ dừng tại thời lượng đã chọn.
- Chỉ một phiên đang mở cho mỗi người dùng, kể cả phiên chưa lưu tổng kết.
- Hết giờ không tự hoàn thành bước. Chỉ lựa chọn **Đã hoàn thành** kèm **Lưu**
  mới cập nhật bước; chưa chọn hoặc cần làm tiếp giữ nguyên tiến độ hiện có.
- Phiên kết thúc sớm vẫn lưu số giây thực tế và cộng vào thời gian học tuần.
  Số phiên hoàn thành chỉ đếm phiên đủ thời lượng.
- Start và các lệnh điều khiển có mã yêu cầu ổn định. Lỗi mạng giữ lệnh chờ
  trong bộ nhớ thiết bị để thử lại mà không nhân đôi phiên/kết quả lưu.
- Khi app mở lại hoặc trở về foreground, tải phiên từ Supabase và tính lại
  thời gian. Chưa thêm native foreground service hay thông báo ngoài ứng dụng;
  nếu hệ điều hành treo app, xử lý hết giờ và chuông tiếp tục khi app hoạt động lại.
- Ghi chú/lựa chọn tổng kết chưa bấm Lưu được giữ khi thu gọn trong cùng lần mở app.
  Sau khi bấm Lưu, yêu cầu đang chờ đồng bộ được giữ cả khi khởi động lại.

## Dependency và kiểm tra

Chạy `flutter pub get` rồi khởi động lại app để nạp plugin âm thanh `audioplayers`.
Linux plugin dùng GStreamer (`gstreamer-1.0`, `gstreamer-app-1.0`,
`gstreamer-audio-1.0`). Các file WAV được tổng hợp tại chỗ, không tải bản ghi bên ngoài.

Chưa chạy app, build, test hoặc migration trên Supabase trong đợt chỉnh sửa này.
Kiểm tra tĩnh bằng Dart analyzer; phần chạy thử và kiểm tra giao diện dành cho người dùng.
