# FEAT-10, FEAT-11 — Dự án và công việc đã hoàn thành

## Luồng sử dụng

Trong **Công việc**, chọn tab **Dự án** để mở M17. Có thể tìm dự án theo tên hoặc mục tiêu.
Chọn **Tạo dự án** để mở M18: tên bắt buộc (tối đa 150 ký tự), mục tiêu tối đa
4.000 ký tự, hạn hoàn thành tùy chọn, biểu tượng và 6 màu nhận diện.
Hạn được lưu ở cuối ngày đã chọn theo giờ địa phương. Xem trước cập nhật theo form.
Hủy/quay lại có xác nhận khi đã sửa; trong lúc lưu không thể rời form hoặc gửi lặp.
Nếu mất kết nối, **Thử lưu lại** giữ nguyên UUID và nội dung yêu cầu.

Tạo thành công mở M19. Dự án mới có **0 công việc**, tiến độ **0%** và nhãn
**Chưa có công việc**. Không sinh công việc hoặc bước nhỏ mẫu.

- **Thêm việc** mở M12 và điền sẵn dự án. Người dùng vẫn có thể chọn lại dự án.
- Lưu việc bằng RPC tạo việc hiện có; mở M13 như luồng công việc thông thường.
- Chạm tên việc trong M19 mở M13. Menu từng việc cho phép chỉnh sửa hoặc đổi trạng thái.
- Các tab **Tất cả / Chưa xong / Đã xong** chỉ lọc công việc thuộc dự án hiện tại.
- Checkbox hoàn thành công việc không đánh dấu lại các bước nhỏ.
- Trong tab Đã xong, **Xem danh sách đã hoàn thành** mở M20 và giữ bộ lọc dự án.
  M11 cũng có đường vào M20 cho toàn bộ công việc.

M20 hỗ trợ tìm tên, lọc dự án, xem ngày/giờ hoàn thành và chuyển giữa Chưa xong /
Đã hoàn thành. Mới hoàn thành được xếp trước. Chạm thẻ mở M13.
**Mở lại** mở hộp xác nhận, hiển thị ảnh hưởng tới tiến độ dự án nếu dữ liệu khả dụng.
Hủy không ghi dữ liệu. Xác nhận chuyển trạng thái sang `IN_PROGRESS`, xóa ngày hoàn thành,
giữ nguyên ID, nội dung, thứ tự và trạng thái của tất cả bước nhỏ.
Thao tác mở lại trong M13 và M19 dùng cùng hộp xác nhận với M20.

## Quy tắc tiến độ và dữ liệu

Tiến độ dự án = số việc có `status = COMPLETED` / tổng số việc không bị lưu trữ
(`is_archived = false`) thuộc dự án. Không cộng/trung bình phần trăm bước nhỏ.
Một công việc vừa mở lại có thể vẫn có 100% bước nhỏ đã xong; dự án vẫn tính việc đó
là chưa xong. Hoàn thành việc cuối cùng đưa nhãn dự án thành **Đã hoàn thành**;
mở lại việc đưa nhãn về **Đang thực hiện**. Nhãn này suy ra từ công việc,
không đổi `projects.status` (dùng để xác định dự án còn hoạt động).

FEAT-10 là danh sách thành quả theo trạng thái hoàn thành; không chuyển `is_archived`
thành `true` khi hoàn thành. Các việc bị lưu trữ riêng không xuất hiện ở các danh sách này.

Repository tải toàn bộ các trang, mỗi trang 100 bản ghi, lọc `user_id` và dùng RLS
của Supabase. Danh sách dự án đang hoạt động và danh sách công việc được dùng lại
giữa các màn. Thay đổi trạng thái/bước nhỏ/tạo/xóa/sửa việc làm mới dữ liệu liên quan;
quay về từ màn con hoặc mở lại ứng dụng sẽ tải lại. Không có dữ liệu giả trong app.

Khung tham chiếu 390 × 844 dp, nội dung tối đa 560 dp trên cửa sổ lớn.
Tên và các nhóm nút xuống dòng; form và danh sách cuộn dọc, không cố định chiều cao.

## SQL người dùng cần chạy

Sau các migration hiện có, đặc biệt `20261124040000_task_edit_steps.sql`,
chạy toàn bộ file này trong Supabase SQL Editor:

[`20261127000000_feat10_11_projects_completed.sql`](../supabase/migrations/20261127000000_feat10_11_projects_completed.sql)

File bổ sung:

- `tasks.completed_at` và trigger ghi thời điểm chuyển sang COMPLETED, giữ nguyên mốc
  này khi sửa metadata, xóa mốc khi mở lại. Áp dụng cả khi hoàn thành từ bước nhỏ/phiên tập trung.
- Với việc đã hoàn thành từ trước, dùng `updated_at` cũ làm mốc gần đúng;
  không thể khôi phục chính xác thời điểm hoàn thành vốn chưa được ghi lại.
- `projects.icon_name`, `create_fingerprint`, quyền tạo dự án cho authenticated và
  RPC `create_study_project` kiểm tra dữ liệu, quyền sở hữu và chống tạo trùng khi thử lại.
- Index theo người dùng và thứ tự tạo dự án. Không seed và không thay đổi chính sách RLS.

RPC dùng quyền người gọi theo [hướng dẫn Supabase](https://supabase.com/docs/guides/database/functions).
Trigger dùng BEFORE để gán timestamp vào bản ghi theo
[tài liệu PostgreSQL](https://www.postgresql.org/docs/current/plpgsql-trigger.html).
Ứng dụng không tự chạy migration. SQL này chưa được áp dụng lên Supabase thật trong phiên làm việc.

## Kiểm tra

```bash
flutter analyze
flutter test test/features/tasks/project_progress_test.dart \
  test/features/tasks/project_repository_test.dart \
  test/features/tasks/projects_flow_test.dart \
  test/features/tasks/task_management_test.dart \
  test/features/tasks/task_detail_repository_test.dart \
  test/features/tasks/task_detail_domain_test.dart \
  test/features/tasks/task_detail_page_test.dart
```

Các test bao phủ tiến độ theo trạng thái, phân trang và phạm vi người dùng,
payload thử lại, chỉ cập nhật công việc khi mở lại, xác nhận/hủy/lỗi mạng,
lọc theo dự án, dự án mới rỗng, M12 nhận sẵn dự án, lưu việc rồi quay về M19/M13; giao diện có tên dài
ở 320/390/768/1280 dp (cỡ chữ 130% tại 320 dp).

Kiểm thử thủ công sau khi chạy SQL: tạo dự án → thêm việc và bước nhỏ → mở M13
→ hoàn thành → M19/Đã xong → M20 → hủy mở lại → xác nhận mở lại → kiểm tra số việc,
ngày hoàn thành và các bước nhỏ; tải lại ứng dụng để xác nhận dữ liệu đã lưu.

Bộ test toàn app ở commit gốc còn 10 test lỗi tại Home/onboarding và Hộp việc;
đã tái hiện trên bản gốc riêng trong `/tmp`, không sửa các phần ngoài phạm vi này.
Lần chạy toàn bộ sau khi triển khai: 60 test qua, 10 test cũ lỗi, 1 test mạng được bỏ qua.
