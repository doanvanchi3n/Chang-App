# FEAT-07, 08, 09 — quản lý công việc

## Khung giao diện thống nhất

**390 × 844 dp** là khung tham chiếu mobile. Giao diện hiện thích ứng theo cửa sổ;
quy tắc responsive đầy đủ được ghi tại `12_RESPONSIVE_LAYOUT.md`.
`lib/app/widgets/app_layout.dart` là nguồn kích thước chung:

- Mobile dùng chiều ngang thiết bị, lề 20 dp; nội dung dài cuộn dọc, tôn trọng SafeArea/bàn phím.
- Tablet 600–1023 dp có thanh điều hướng bên cạnh; desktop từ 1024 dp dùng thanh trên.
- Trang chính căn giữa với chiều ngang tối đa 1180 dp; form tối đa 960 dp, lề 24 dp trên màn rộng.
- Nút hành động chính cao tối thiểu 52 dp. Chữ được co giãn theo cài đặt hệ thống.
- Danh sách chia cột theo chiều rộng thực tế. Form và các nhóm nội dung xếp dọc khi thiếu chỗ hoặc tăng cỡ chữ.
- M13 đã chuyển về một cột trên laptop để thống nhất với các màn còn lại.
- M11, M14, M15, M16 dựa theo ảnh người dùng; các hàng dài và bộ lọc xuống dòng trên mobile.

## Flow

Tab **Công việc** → M11. Home và M11 vẫn có đường vào **Hộp việc** M01.

- Tên việc → M13 → **Chỉnh sửa** M14 → **Lưu thay đổi** → M13 được tải mới.
- M14 giữ bản nháp tên, mô tả, dự án, deadline, ưu tiên, thời lượng; hủy/back có xác nhận khi đã sửa.
- M13/M14 → **Quản lý N bước** M15. Thêm tối đa 5 bước, đổi tên, thời lượng, checkbox.
- Menu từng bước: đưa lên/đưa xuống/xóa. Menu đóng trước khi áp dụng vào bản nháp;
  chỉ **Lưu các bước** mới ghi Supabase. Giữ ID các bước khi đổi thứ tự để bảo toàn liên kết phiên học.
- Nếu M15 được lưu từ M14, thông tin đang nhập trên M14 vẫn giữ nguyên. Cập nhật phiên bản gốc
  khi server chỉ thay đổi các bước; nếu metadata cũng đổi, báo xung đột trước khi ghi đè.
- M11: Tất cả/Hôm nay/Sắp tới/Quá hạn; tìm từ khóa trong tên/mô tả, không phân biệt hoa thường.
- M16: panel bộ lọc theo dự án, trạng thái, hạn, ưu tiên. **Áp dụng** mới cập nhật kết quả.
  **Đặt lại** chỉ xóa điều kiện trong panel; đóng/hủy không ảnh hưởng bộ lọc đang dùng.
- Hôm nay tính ngày dự kiến hoặc ngày deadline; Sắp tới là việc chưa hoàn thành có ngày tương lai.
  Quá hạn tính chính xác thời điểm deadline và loại việc đã hoàn thành. Tuần tính từ thứ Hai.

## Supabase — người dùng chạy SQL

Sau các migration hiện có (bao gồm cả `20261124020000_feat06_task_detail.sql`
và `20261124020000_tasks_and_focus_flow.sql`), chạy toàn bộ:

`supabase/migrations/20261124040000_task_edit_steps.sql`

File không seed dữ liệu. Bao gồm:

- `save_task_details`: lưu metadata trong một transaction, kiểm tra phiên bản `updated_at`.
- `save_task_steps`: lưu toàn bộ bản nháp 0–5 bước trong một transaction, giữ ID và kiểm tra phiên bản.
- `delete_task_checked`: xóa việc có xác nhận, chặn khi còn phiên tập trung chưa lưu tổng kết.
- Lưu bước cũng chặn xóa bước đang được phiên tập trung sử dụng.
- Request UUID ổn định khi thử lại sau lỗi mạng; không nhân đôi bước hoặc ghi lặp từ cùng yêu cầu.
- RPC dùng quyền người dùng (`SECURITY INVOKER`) và RLS hiện có; tương thích anonymous sign-in.

Danh sách tải từ Supabase theo trang 100 bản ghi rồi tìm/lọc trên tập đã tải, tránh bỏ sót
công việc ngoài trang đầu. Không có danh sách mẫu hoặc fallback dữ liệu giả trong app.
Hiện tìm kiếm/lọc ở phía ứng dụng, phù hợp tập công việc cá nhân; chưa thêm server-side search.
Bản nháp ở trong bộ nhớ màn hình, chưa hỗ trợ khôi phục bản nháp sau khi tắt hẳn app.

## Kiểm tra

- Dart analyzer và widget/unit test cho bản nháp, menu đổi thứ tự, request retry, bộ lọc,
  dữ liệu phân trang, M13 và kích thước 320/390/1280 dp.
- Fixture giả chỉ nằm trong test, không dùng cho sản phẩm.
- SQL được cung cấp để người dùng chạy; chưa kiểm chứng RPC trên Supabase thật trong phiên này.
