# FEAT-05, 17–20 — công việc và phiên tập trung

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
- M27: chọn việc/bước, 15/25/45 phút hoặc tùy chỉnh; chọn im lặng, nhiễu trắng hoặc file âm thanh cá nhân.
- Đang tập trung ↔ M29: tạm dừng, tiếp tục, kết thúc sớm, thu gọn về thanh phiên học.
- M30: thời gian thực tế, xác nhận bước độc lập, ghi chú, lưu về Home hoặc nghỉ 5 phút.

Khung tham chiếu 390 × 844 dp; chiều cao theo thiết bị và cuộn theo nội dung.
Mobile giữ chiều ngang nội dung tối đa 560 dp. Home, Hộp việc và công việc
có bố cục desktop từ 840 dp, khung tối đa 1180 dp; lề 20 dp trên mobile,
24 dp trên màn rộng. Phiên tập trung có bố cục riêng cho mobile và desktop.
Mascot M27, M29, M30 lấy từ asset được cung cấp. M13 nối tiếp sang M14/M15; xem `09_TASK_MANAGEMENT_AND_LAYOUT.md`.

## Tích hợp FEAT-18 với dự án và thông báo

- Giữ đồng hồ toàn màn hình, linh vật PNG tĩnh, tạm dừng/tiếp tục và PiP desktop /
  mini bar mobile của FEAT-18. Phiên mở qua `openFocusSession` để trạng thái
  mở rộng và thu gọn luôn đồng bộ, tránh xuất hiện thêm mini bar trên màn phiên.
- Giữ tab Dự án, danh sách đã hoàn thành/mở lại, dự án điền sẵn trong form
  và bộ chọn hạn hoàn thành từ `main`. Chuông thông báo hoạt động trên cả hai bố cục Home.
- Điều hướng desktop rời form có nội dung phải xác nhận; chọn Ở lại giữ nội dung.
  Thẻ công việc Home tự xếp dọc khi cột desktop hẹp để tránh tràn ở 840 dp.
- Lưu tổng kết làm mới cả danh sách công việc và lựa chọn phiên kế tiếp,
  giúp tiến độ dự án và trạng thái hoàn thành phản ánh dữ liệu vừa lưu.
- Không bổ sung migration hay dependency cho đợt ghép FEAT-18 này.

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

Đã build và khởi động bản Linux trong đợt chỉnh sửa âm thanh. Test lưu file âm thanh,
calendar và choice sheet đã chạy qua; chưa kiểm tra tương tác native file picker trên mobile.
Migration chưa được chạy trên Supabase từ phiên làm việc này.

## Âm thanh cá nhân

Chạy tiếp `supabase/migrations/20261124030000_custom_focus_audio.sql`.
Trong phần **Âm thanh nền**, mở danh sách và chọn thêm từ thiết bị. Hỗ trợ file
MP3, WAV, OGG, M4A, AAC, FLAC tối đa 50 MB; khả năng giải mã phụ thuộc codec hệ điều hành.
File được sao chép vào thư mục dữ liệu của ứng dụng, tiếp tục dùng được sau khi di chuyển
file gốc. Xóa khỏi thư viện không xóa file gốc. Không xóa file đang dùng trong phiên hiện tại.
Supabase chỉ lưu ID lựa chọn, không tải nội dung âm thanh lên cloud.
Thư viện cá nhân chỉ có trên thiết bị đã thêm file; thiết bị khác sẽ báo thiếu file.
Import qua native file selector hỗ trợ desktop/mobile; bản web chưa hỗ trợ import.
Sau khi thêm plugin, cần `flutter pub get` và khởi động lại app, không chỉ hot reload.
