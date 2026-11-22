# TÀI LIỆU ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS), LOGIC NGHIỆP VỤ, FLOW & INPUT/OUTPUT
## ỨNG DỤNG HỌC TẬP & QUẢN LÝ TIẾN ĐỘ: CHẶNG (CHANG APP)

---

## 1. TỔNG QUAN DỰ ÁN

### 1.1. Tên ứng dụng & Định vị sản phẩm
- **Tên ứng dụng:** Chặng (Chặng App).
- **Slogan / Triết lý:** *"Chia nhỏ chặng đường – Vững bước mục tiêu"*.
- **Nền tảng mục tiêu:** Ứng dụng di động (Mobile App - iOS & Android), giao diện chuẩn Native Mobile.
- **Công nghệ cốt lõi:**
  - **Frontend:** Flutter (Dart 3.x), Quản lý State bằng BLoC / Riverpod, Hỗ trợ 60-120 FPS mượt mà.
  - **Backend & Cơ sở dữ liệu:** Supabase (PostgreSQL 15+, Supabase Auth, Row Level Security - RLS, Supabase Realtime, Supabase Storage).
  - **Điện toán đám mây & AI:** Supabase Edge Functions (Deno / TypeScript) tích hợp mô hình AI, kết hợp `pg_cron` xử lý tác vụ định kỳ tự động.
  - **Kiến trúc Offline-First:** Bộ đệm cục bộ (Drift / Hive / SQLite) đồng bộ 2 chiều (Bidirectional Sync) với Supabase khi có kết nối mạng.
- **Đối tượng người dùng:** Học sinh, sinh viên, người tự học, người chuẩn bị thi chứng chỉ cần giải pháp chống trì hoãn, quản lý thời gian khoa học và duy trì động lực bền bỉ.

### 1.2. Triết lý thiết kế & Vấn đề giải quyết
1. **Chống tê liệt vì việc lớn (Anti-Overwhelm):** Áp dụng nguyên tắc chia nhỏ việc lớn thành tối đa 5 bước vi mô (Micro-steps). Người dùng không phải đối mặt với một đề án 20 trang mà chỉ cần giải quyết từng bước nhỏ 15–25 phút.
2. **Độc lập thời gian & Tiến độ:** Phiên học đo lường thời gian thực tế (không làm tròn cứng nhắc 25 phút nếu kết thúc sớm); hoàn thành một bước nhỏ không đồng nghĩa với hoàn thành cả công việc; số lượng phiên không tự ý đẩy tiến độ nếu chưa có xác nhận từ người học.
3. **Lập lịch thực tế & Tôn trọng quyền tự chủ:** Hệ thống phát hiện xung đột lịch và Trợ lý AI đóng vai trò người gợi ý (Co-pilot), luôn yêu cầu người dùng xem trước (Preview) và cho phép hoàn tác (Undo).
4. **Đồng hành không xao nhãng:** Linh vật thương hiệu phản ứng theo ngữ cảnh (trạng thái tĩnh/đổi tư thế khi chuyển trạng thái, không chạy animation lặp gây xao nhãng khi đang trong phiên tập trung).

---

## 2. HỆ THỐNG DESIGN SYSTEM & DESIGN TOKENS

### 2.1. Bảng màu (Color Tokens)
| Token Variable | Mã Hex | Ý nghĩa & Vùng áp dụng |
| :--- | :--- | :--- |
| `brand/primary` | `#345D83` | Xanh thương hiệu chủ đạo, nút bấm chính (CTA), tiêu đề nổi bật |
| `brand/primary-hover` | `#2B4F71` | Nút chính ở trạng thái hover/focus |
| `brand/primary-pressed` | `#203F5C` | Nút chính khi người dùng nhấn giữ (active/pressed) |
| `brand/soft` | `#E4EEF3` | Nền chip được chọn, background nút phụ, selection background |
| `brand/honey` | `#F4D578` | Vàng mật ong nhấn mạnh thành tựu, huy hiệu, mốc mục tiêu hoàn thành |
| `brand/honey-soft` | `#FFF5D6` | Nền tổng kết phiên học, banner động viên linh vật |
| `brand/peach` | `#DF967E` | Cam đào trang trí, chi tiết nhấn trên linh vật, tag việc ưu tiên cao |
| `brand/peach-soft` | `#FBECE5` | Nền nhấn nhẹ, badge thông báo nhẹ |
| `background/page` | `#FFFCF5` | Nền tổng thể toàn bộ màn hình ứng dụng (ấm áp, êm dịu cho mắt) |
| `background/surface` | `#FFFFFF` | Nền thẻ Card, ô nhập liệu Input, Bottom Sheet, Popover |
| `background/subtle` | `#F3F5F7` | Nền vùng phụ, dải phân cách section, placeholder card |
| `background/disabled` | `#E8EDF1` | Nền của nút bấm hoặc ô nhập liệu bị vô hiệu hóa |
| `text/primary` | `#20374C` | Chữ tiêu đề H1/H2/H3, nội dung quan trọng |
| `text/secondary` | `#526577` | Mô tả phụ, nhãn hướng dẫn, thời gian |
| `text/muted` | `#657587` | Placeholder văn bản, chú thích nhỏ (caption) |
| `text/inverse` | `#FFFFFF` | Chữ trắng trên nền nút xanh `brand/primary` |
| `text/link` | `#345D83` | Văn bản liên kết có thể nhấp |
| `text/disabled` | `#8794A1` | Chữ xám mờ của control bị vô hiệu hóa |
| `border/subtle` | `#DCE4EB` | Viền mỏng phân chia card, đường kẻ ngang list divider |
| `border/control` | `#8193A3` | Viền ô input, checkbox chưa được chọn |
| `border/focus` | `#345D83` | Viền khi ô input được focus hoặc control được kích hoạt |
| `status/success` | `#28654C` | Trạng thái thành công, check-in hoàn thành |
| `status/success-bg` | `#E8F3EC` | Nền toast/banner thông báo thành công |
| `status/warning` | `#805C16` | Cảnh báo việc sắp đến hạn, xung đột lịch cần giải quyết |
| `status/warning-bg` | `#FFF3D6` | Nền thông báo cảnh báo |
| `status/error` | `#A43E3E` | Lỗi nhập liệu, việc quá hạn (overdue), thất bại |
| `status/error-bg` | `#FBEAEA` | Nền thông báo lỗi |
| `status/info` | `#345D83` | Hướng dẫn, giải thích thông số AI |
| `status/info-bg` | `#E4EEF3` | Nền hộp thông tin hỗ trợ |
| `overlay/scrim` | `rgba(32, 55, 76, 0.4)` | Lớp phủ làm tối màn hình sau Modal/Bottom Sheet |

### 2.2. Token Kích thước (Dimensions & Spacing)
- **Spacing:** `space/0` (0px), `space/4` (4px), `space/8` (8px), `space/12` (12px), `space/16` (16px - Padding tiêu chuẩn mobile), `space/24` (24px), `space/32` (32px), `space/40` (40px), `space/48` (48px), `space/64` (64px).
- **Corner Radius:** `radius/4` (4px - checkbox), `radius/8` (8px - tag, badge), `radius/12` (12px - input, button, card tiêu chuẩn), `radius/16` (16px - card nổi bật), `radius/24` (24px - top corners modal/bottom sheet), `radius/full` (999px - avatar, chip pill).
- **Control Targets:** Nút bấm tiêu chuẩn cao `48px` (`size/control-default`), Touch target tối thiểu `48x48px` theo chuẩn Android/iOS HIG, Icon navigation `24px` (`size/icon-lg`), Icon inline `20px` (`size/icon-md`).

### 2.3. Kiểu chữ (Typography)
- Font Family: `Inter` (Hỗ trợ tiếng Việt đầy đủ, tối ưu hóa cho màn hình di động độ phân giải cao).
- Trọng số sử dụng: Regular (400), Medium (500), Semi Bold (600), Bold (700).

---

## 3. CỦNG CỐ LOGIC NGHIỆP VỤ CỐT LÕI (CORE BUSINESS LOGIC RULES)

### 3.1. Quy tắc chia nhỏ công việc (5-Step Micro-Task Rule)
- Mỗi công việc (Task) chỉ được phép có **tối đa 5 bước nhỏ** (Subtasks).
- **Lý do thiết kế:** Ngăn chặn hội chứng "tê liệt vì lập kế hoạch" (analysis paralysis). Nếu người dùng có hơn 5 bước, hệ thống sẽ khuyến nghị tách thành Dự án (Project) hoặc Công việc mới.
- Mỗi bước nhỏ có các trường: `id`, `task_id`, `title`, `order_index` (1..5), `estimated_minutes` (mặc định 25), `is_completed`, `completed_at`.
- Không bắt buộc người dùng phải kéo thả (drag & drop) vì trên mobile dễ thao tác nhầm; cung cấp menu tùy chọn ("Chuyển lên", "Chuyển xuống", "Sửa", "Xóa") bên cạnh icon reorder.

### 3.2. Quy tắc Phiên tập trung Pomodoro cải tiến & Tính thời gian thực tế
- **Độc lập thời gian thực tế (Actual Focus Duration):**
  - Thời lượng dự kiến có thể là 25, 45 hoặc 50 phút.
  - Nếu người dùng dừng sớm hoặc kết thúc giữa chừng: Hệ thống **chỉ ghi nhận chính xác số phút và giây thực tế** đồng hồ đã chạy, KHÔNG được làm tròn hay mặc định tính đủ thời gian ban đầu.
- **Tách bạch giữa Hoàn thành bước nhỏ và Hoàn thành công việc:**
  - Kết thúc phiên tập trung vào Bước 3: Người dùng được hỏi: *"Bạn đã hoàn thành Bước 3 chưa?"*.
  - Nếu chọn "Đã hoàn thành": Tiến độ công việc tăng từ `2/5` lên `3/5`. Toàn bộ công việc vẫn ở trạng thái `IN_PROGRESS`.
  - Công việc chỉ chuyển sang trạng thái `COMPLETED` khi: (1) Cả 5 bước đều hoàn thành HOẶC (2) Người dùng bấm chủ động nút "Hoàn thành toàn bộ công việc".
- **Không tự động tăng tiến độ theo số phiên:** Số phiên học tăng là thước đo công sức (Effort), không tự động biến thành tiến độ kết quả (Progress) nếu người dùng không xác nhận.
- **Hành vi linh vật trong phiên:** Linh vật đổi tư thế theo sự kiện (Bắt đầu -> Tập trung, Tạm dừng -> Nghỉ ngơi, Hoàn thành -> Ăn mừng). Màn hình đếm giờ không chạy animation lặp vô tận để chống gây mất tập trung (ADHD-friendly).

### 3.3. Quy tắc Giải quyết Xung đột Lịch (Conflict Resolution Engine)
- Khi xếp công việc vào một khung giờ (Time slot) trong ngày:
  - Hệ thống kiểm tra khoảng thời gian `[Start_Time, End_Time]` với toàn bộ các lịch đã có (`ScheduleEvent`).
  - Nếu phát hiện trùng lặp: Chuyển hướng tới màn hình `M26 (Xử lý trùng lịch)`.
  - Ba phương án xử lý rõ ràng:
    1. **Chấp nhận khung giờ trống gợi ý:** Hệ thống tự động tính toán khoảng trống kế tiếp khả dụng (ví dụ gợi ý `20:10 - 20:35` ngay sau lịch học tiếng Anh) -> quay về xem trước với giờ mới.
    2. **Tự chọn khung giờ khác:** Mở time picker để người dùng điều chỉnh.
    3. **Ghi đè/Xếp song song (Vẫn thêm vào giờ trùng):** Lưu lịch mới theo lựa chọn người dùng, giữ nguyên sự kiện cũ. Chỉ lưu dữ liệu khi người dùng xác nhận dứt khoát tại bước cuối cùng.

### 3.4. Quy tắc Mục tiêu định lượng: "Ghi nhận thêm" vs "Điều chỉnh đích"
Hai luồng này có nghiệp vụ toán học hoàn toàn khác nhau:
1. **Luồng Ghi nhận thêm (Add Progress Log):**
   - Ví dụ: Đang đạt 40/100 từ vựng. Người dùng học thêm 10 từ -> Nhập `+10`.
   - Kết quả: Tiến độ trở thành `50/100` từ (Tăng từ 40% lên 50%). Hệ thống tạo một bản ghi lịch sử `GoalLog` mới với số gia `delta = +10`.
2. **Luồng Điều chỉnh đích (Adjust Target Value):**
   - Ví dụ: Đang đạt 40/100 từ vựng. Người dùng nhận thấy mục tiêu quá sức và hạ chỉ tiêu xuống 80 từ.
   - Kết quả: Tiến độ trở thành `40/80` từ (Tỷ lệ tăng từ 40% lên 50%), nhưng **tổng số lượng từ thực tế đã học vẫn giữ nguyên là 40 từ**, không có bản ghi học thêm từ vựng nào được sinh ra. Lịch sử ghi nhận cũ được bảo toàn trọn vẹn.

### 3.5. Quy tắc Thói quen & Tính toán Streak (Habit & Streak Logic)
- Thói quen có các ngày kích hoạt trong tuần (ví dụ: Thứ 2, Thứ 4, Thứ 6).
- **Phân biệt 3 trạng thái của một ngày:**
  1. `COMPLETED`: Ngày đã thực hiện và được check-in.
  2. `REST_DAY` (Ngày nghỉ kế hoạch): Ngày không nằm trong lịch kích hoạt, không bị coi là đứt chuỗi (broken streak).
  3. `PENDING` (Ngày chưa đến hoặc hôm nay chưa check-in): Hiển thị trạng thái chờ.
- Chỉ khi đến ngày kích hoạt mà qua 23:59 không check-in thì chuỗi streak mới bị reset về 0 (hoặc kích hoạt tính năng đóng băng streak nếu người dùng có streak freeze).

### 3.6. Quy tắc Rà soát cuối ngày (End-of-day Review Rollover)
- Chạy vào buổi tối (mặc định 21:30 hoặc khi người dùng mở M10):
- Quét các công việc được lên kế hoạch làm trong ngày hôm nay nhưng chưa hoàn thành:
  - **Tùy chọn A - Chuyển sang ngày mai:** Cập nhật `scheduled_date = Tomorrow`. Giữ nguyên `deadline` gốc của công việc.
  - **Tùy chọn B - Trả về Hộp việc (Unscheduled Inbox):** Gỡ bỏ `scheduled_date` (set thành `null`), công việc quay lại `M01` để lên lịch lại khi phù hợp. Hạn nộp tuyệt đối không bị thay đổi.

### 3.7. Quy tắc Trợ lý AI lập kế hoạch thông minh (AI Guardrails & Human-in-the-loop)
- AI không bao giờ được phép âm thầm ghi trực tiếp vào lịch người dùng.
- Quy trình bắt buộc:
  1. Khảo sát nhu cầu & Làm rõ thời gian rảnh (`M41`, `M42`).
  2. Hiển thị rõ phạm vi dữ liệu AI truy cập (`M43`).
  3. Xử lý tạo bản nháp có thanh tiến trình và nút Hủy (`M44`).
  4. Hiển thị màn hình Xem trước bản nháp (`M45`) kèm giải thích lý do (`M46`).
  5. Cho phép người dùng tinh chỉnh trực tiếp (`M47`).
  6. Sau khi bấm "Áp dụng", lưu trạng thái lịch sử với nút "Hoàn tác" (Undo) tại `M48` và quản lý audit log tại `M50`.

---

## 4. CHI TIẾT 50 MÀN HÌNH (M01 - M50): CHỨC NĂNG, FLOW, INPUT & OUTPUT

### PHÂN HỆ 1: KHỞI ĐỘNG, ONBOARDING & THIẾT LẬP CÁ NHÂN (M01 - M10)

#### M06: Màn hình Giới thiệu tương tác (Splash / Interactive Intro)
- **Mục đích:** Đón chào người dùng lần đầu, giới thiệu triết lý cốt lõi: Lên kế hoạch -> Tập trung -> Nhìn lại.
- **Thành phần UI:** Linh vật Chặng vẫy tay chào (animation 1–1.5s chạy 1 lần), 3 tiêu điểm giới thiệu, nút CTA "Bắt đầu", nút "Bỏ qua".
- **Flow:**
  - Mở app lần đầu -> Animation chạy 1.2s -> Hiện nút.
  - Bấm "Bắt đầu" -> Chuyển đến `M03`.
  - Bấm "Bỏ qua" -> Khởi tạo thiết lập mặc định -> Đi thẳng vào `M05 (Home)`.
  - Lần mở app thứ 2 trở đi: Bỏ qua M06, vào thẳng M05.
- **Input:** Cờ `has_completed_onboarding` từ bộ nhớ cục bộ.
- **Output:** Cập nhật trạng thái `has_seen_intro = true`.

#### M03: Chọn mục tiêu sử dụng chính (Onboarding - Goal Selection)
- **Mục đích:** Thu thập định hướng học tập của người dùng để cá nhân hóa gợi ý.
- **Thành phần UI:** Danh sách thẻ chọn (Thi học kỳ, Luyện thi chứng chỉ IELTS/TOEIC, Học kỹ năng mới, Cải thiện sự tập trung), thanh tiến trình Onboarding (Bước 1/2), nút "Tiếp tục".
- **Flow:** Chọn 1 hoặc nhiều mục tiêu -> Nút "Tiếp tục" sáng xanh -> Bấm -> Chuyển sang `M04`.
- **Input:** Mảng danh mục mục tiêu `primary_goals: string[]`.
- **Output:** Lưu vào `UserPreference.primary_goals`.

#### M04: Thiết lập thời gian học lý tưởng (Onboarding - Study Schedule Setup)
- **Mục đích:** Đăng ký khung giờ vàng trong ngày và mục tiêu số phút tập trung hàng ngày.
- **Thành phần UI:** Chọn khung giờ ưu tiên (Sáng: 06:00-09:00, Chiều: 14:00-17:00, Tối: 19:30-22:30), slider chọn thời lượng mục tiêu mỗi ngày (mặc định 60 phút), nút "Hoàn tất", nút "Bỏ qua".
- **Flow:** Chọn khung giờ & thời lượng -> Bấm "Hoàn tất" -> Chuyển sang `M05 (Home)`.
- **Input:** Khung giờ vàng `preferred_slots`, thời lượng `daily_target_minutes`.
- **Output:** Cập nhật `UserPreference`, tạo bản ghi Mục tiêu tuần đầu tiên, chuyển `has_completed_onboarding = true`.

#### M05: Màn hình Chính (Home Dashboard)
- **Mục đích:** Trung tâm điều khiển một ngày học tập.
- **Thành phần UI:**
  - Header: Lời chào cá nhân hóa, biểu tượng linh vật theo trạng thái cảm xúc, nút Thông báo (`M07`), Avatar (`M08`).
  - Widget "Kế hoạch hôm nay": Tiến độ công việc trong ngày (Ví dụ: 3/5 việc), nút "Lên kế hoạch" (`M02`).
  - Widget "Lịch gần nhất": Sự kiện kế tiếp kèm đồng hồ đếm ngược đến giờ bắt đầu.
  - Widget "Mục tiêu tuần": Thanh tiến độ trực quan (ví dụ: 75/120 phút, 3/4 phiên).
  - Nút truy cập nhanh: "Chia nhỏ việc nhanh" (`M12`), "Bắt đầu tập trung ngay" (`M27`).
- **Flow:**
  - Chạm vào thẻ công việc -> Mở `M13 (Chi tiết công việc)`.
  - Chạm vào lịch gần nhất -> Mở `M22 (Lịch ngày)`.
  - Chạm vào mục tiêu tuần -> Mở `M31 (Tổng quan mục tiêu)`.
  - Chạm vào biểu tượng trợ lý AI -> Mở `M41`.
- **Input:** Dữ liệu tổng hợp từ SQLite/Room: danh sách việc hôm nay, sự kiện lịch kế tiếp, tiến độ tuần.
- **Output:** Điều hướng sang các phân hệ tương ứng.

#### M01: Hộp việc chưa lên kế hoạch (Unscheduled Inbox)
- **Mục đích:** Lưu trữ các ý tưởng, bài tập, công việc vừa phát sinh nhưng chưa ấn định ngày giờ cụ thể.
- **Thành phần UI:** Danh sách thẻ việc không có `scheduled_date`, nút Quick Add (nhập nhanh tên việc), nút "Xếp việc vào hôm nay" đưa sang `M02`.
- **Input:** Văn bản tên việc mới, deadline (tùy chọn).
- **Output:** Bản ghi `Task` với `scheduled_date = null`.

#### M02: Lên kế hoạch cho hôm nay (Daily Planning / Today's Queue)
- **Mục đích:** Chọn các việc từ Inbox hoặc việc tồn đọng để cam kết thực hiện trong ngày hôm nay.
- **Thành phần UI:** Danh sách việc được gợi ý (việc quan trọng, việc sắp đến hạn), danh sách chọn việc cho hôm nay, tổng thời gian ước tính, nút "Bắt đầu ngày mới".
- **Input:** Lựa chọn danh sách `task_id[]`.
- **Output:** Cập nhật `Task.scheduled_date = Today`, đồng bộ lên widget Home `M05`.

#### M07: Trung tâm thông báo (Notification Center)
- **Mục đích:** Hiển thị các thông báo nhắc nhở lịch học, deadline, gợi ý AI, chúc mừng mốc học tập.
- **Thành phần UI:** Danh sách thông báo chia theo Hôm nay/Trước đó, nút "Đánh dấu tất cả đã đọc", bộ lọc loại thông báo.
- **Flow:** Chạm vào một thông báo -> Điều hướng trực tiếp đến đúng đối tượng liên quan (Mở việc `M13`, mở lịch `M24`, hoặc kết quả AI `M48`). Đánh dấu đã đọc chỉ giảm badge đếm chưa đọc, KHÔNG thay đổi trạng thái của công việc.
- **Input:** Click event trên thông báo ID.
- **Output:** Cập nhật `Notification.is_read = true`, giảm badge count.

#### M08: Hồ sơ học tập (Learner Profile)
- **Mục đích:** Xem thông tin cá nhân, tổng số giờ tích lũy, chuỗi ngày streak học tập, danh hiệu.
- **Thành phần UI:** Avatar, Họ tên, Danh hiệu học tập, Thẻ thống kê (Tổng giờ tập trung, Tỷ lệ hoàn thành việc, Chuỗi ngày dài nhất), nút sang `M09`.
- **Input:** Dữ liệu người dùng, aggregate queries từ `FocusSession` và `HabitLog`.
- **Output:** Cập nhật thông tin profile khi sửa.

#### M09: Cài đặt trải nghiệm (Settings)
- **Mục đích:** Tùy biến nhắc nhở, khoảng thời gian yên tĩnh (Do Not Disturb), linh vật và chuyển động.
- **Thành phần UI:**
  - Switch bật/tắt thông báo âm thanh / rung.
  - Thiết lập "Giờ yên tĩnh" (Quiet Hours: ví dụ 22:30 - 06:30): chặn mọi thông báo nhắc việc.
  - Lựa chọn hình thái Linh vật (Bật/Tắt hiển thị trên Home).
  - Switch "Giảm chuyển động" (Reduced Motion): hiển thị ảnh tĩnh thay vì hiệu ứng động.
- **Input:** Các giá trị cài đặt boolean, time range.
- **Output:** Lưu trữ vào bảng `AppSettings` / SharedPreferences.

#### M10: Rà soát cuối ngày (End-of-day Review)
- **Mục đích:** Dọn dẹp các việc chưa làm xong trong ngày, giải phóng tâm trí trước khi nghỉ ngơi.
- **Thành phần UI:** Danh sách các việc chưa hoàn thành hôm nay, đối với từng việc có 2 hành động: [Chuyển sang ngày mai] hoặc [Đưa về Hộp việc], nút xác nhận "Hoàn tất rà soát".
- **Flow:** Người dùng chọn hướng xử lý cho từng việc -> Bấm hoàn tất -> Cập nhật CSDL -> Hiện lời động viên từ linh vật -> Quay về Home `M05`.
- **Input:** Lựa chọn hành động trên danh sách `task_id`.
- **Output:** Cập nhật `scheduled_date` của từng task, ghi nhận log rà soát ngày.

---

### PHÂN HỆ 2: QUẢN LÝ CÔNG VIỆC & CHIA NHỎ 5 BƯỚC (M11 - M16, M20)

#### M11: Danh sách công việc (Task List View)
- **Mục đích:** Quản lý toàn bộ công việc theo trạng thái, hạn chót và phát hiện việc quá hạn.
- **Thành phần UI:** Tab phân loại (Hôm nay, Sắp tới, Tất cả, Quá hạn), thanh tìm kiếm nhanh, nút FAB "Thêm công việc" (`M12`), thẻ công việc hiển thị: Tên việc, Tag Dự án, Hạn chót, Progress bar bước nhỏ (ví dụ `3/5`).
- **Input:** Bộ lọc tab, từ khóa tìm kiếm.
- **Output:** Danh sách công việc tương ứng.

#### M12: Tạo công việc mới (Create Task)
- **Mục đích:** Khởi tạo công việc với phương pháp chia nhỏ 5 bước ngay từ đầu.
- **Thành phần UI:**
  - Ô nhập Tên công việc (Bắt buộc).
  - Chọn Dự án liên kết (Dropdown / Picker).
  - Chọn Hạn nộp (Deadline: Ngày & Giờ) kèm mức độ ưu tiên (Thấp / Trung bình / Cao).
  - Khu vực "Chia nhỏ bước thực hiện (Tối đa 5 bước)": Mặc định có 3 ô bước nhỏ, nút "+ Thêm bước" (cho phép tối đa 5 bước).
  - Nút "Lưu công việc".
- **Flow:** Nhập dữ liệu hợp lệ -> Bấm Lưu -> Tạo Task & Subtasks -> Chuyển đến màn hình Chi tiết `M13`.
- **Input:** `title`, `project_id`, `due_date`, `priority`, `subtasks: string[]` (độ dài 1..5).
- **Validation:** `title` không rỗng, số bước nhỏ `<= 5`, `due_date` không được ở quá khứ.
- **Output:** Bản ghi mới trong bảng `Task` và bảng `Subtask`.

#### M13: Chi tiết công việc (Task Detail)
- **Mục đích:** Trọng tâm thực thi công việc: theo dõi tiến độ từng bước, cập nhật trạng thái và khởi động phiên học.
- **Thành phần UI:**
  - Header: Tên việc, Dự án, Deadline, Badge trạng thái.
  - Danh sách 5 bước nhỏ: Mỗi bước có Checkbox hoàn thành, Tên bước, nút "Tập trung vào bước này" (`M27`).
  - Thanh tổng tiến độ: Hiển thị tỷ lệ (ví dụ `2/5 bước - 40%`).
  - Nút "Chỉnh sửa công việc" (`M14`), nút "Quản lý 5 bước" (`M15`).
- **Flow:**
  - Tích chọn checkbox một bước -> Bước đó gạch ngang, tiến độ tăng từ `2/5` lên `3/5`.
  - Nhấn nút "Tập trung vào bước 3" -> Mở màn hình Chuẩn bị phiên `M27` với bước 3 được chọn sẵn.
- **Input:** Chạm checkbox bước nhỏ ID.
- **Output:** Cập nhật `Subtask.is_completed`, tính lại tỷ lệ `Task.progress_percentage`.

#### M14: Chỉnh sửa công việc (Edit Task)
- **Mục đích:** Chỉnh sửa thông tin công việc, phân biệt rõ dữ liệu đang chỉnh sửa (Draft) với dữ liệu gốc đã lưu.
- **Thành phần UI:** Form chỉnh sửa tương tự M12, nút "Hủy thay đổi" (cảnh báo nếu có dữ liệu chưa lưu), nút "Lưu thay đổi", nút "Xóa công việc" (màu đỏ nguy hiểm).
- **Flow:** Sửa tiêu đề/hạn nộp -> Bấm "Lưu" -> Cập nhật CSDL -> Quay về `M13`. Nếu bấm "Hủy", hoàn nguyên dữ liệu cũ.
- **Input:** Form data chỉnh sửa.
- **Output:** Cập nhật bản ghi `Task`.

#### M15: Quản lý bước nhỏ (Subtask Management)
- **Mục đích:** Thêm, sửa tên, xóa và sắp xếp thứ tự các bước nhỏ (Tối đa 5 bước).
- **Thành phần UI:** Danh sách các bước nhỏ hiện tại, menu 3 chấm trên mỗi bước ("Chuyển lên trên", "Chuyển xuống dưới", "Đổi tên", "Xóa bước"), ô thêm bước mới nếu số bước `< 5`, nút "Lưu các bước".
- **Flow:** Thao tác đổi thứ tự qua menu -> Xem preview thứ tự mới -> Nhấn "Lưu các bước" -> Ghi vào CSDL và đóng modal.
- **Input:** Danh sách subtasks đã sắp xếp lại với `order_index` mới.
- **Output:** Cập nhật `Subtask.order_index` trong CSDL.

#### M16: Tìm kiếm và lọc nâng cao (Search & Filter)
- **Mục đích:** Tra cứu nhanh công việc theo nhiều tiêu chí kết hợp.
- **Thành phần UI:** Thanh search từ khóa, bộ lọc theo Dự án, theo Trạng thái (Chưa làm, Đang làm, Đã xong, Quá hạn), theo Độ ưu tiên, nút "Áp dụng", nút "Xóa bộ lọc".
- **Input:** Query string, filter chips selection.
- **Output:** Render danh sách kết quả phù hợp kèm số lượng kết quả tìm thấy.

#### M20: Công việc đã hoàn thành (Completed Tasks Archive)
- **Mục đích:** Xem lại các thành quả đã đạt được, cho phép mở lại (Reopen) công việc khi cần.
- **Thành phần UI:** Danh sách các công việc đã xong kèm ngày hoàn thành, nút "Mở lại việc" (Reopen) chuyển trạng thái về `IN_PROGRESS`.
- **Input:** Click nút "Mở lại" trên Task ID.
- **Output:** Cập nhật `Task.status = IN_PROGRESS`, khôi phục về danh sách chính.

---

### PHÂN HỆ 3: QUẢN LÝ DỰ ÁN HỌC TẬP (M17 - M19)

#### M17: Danh sách dự án (Project List)
- **Mục đích:** Nhóm các công việc có cùng mục tiêu lớn (Đồ án tốt nghiệp, Ôn thi cuối kỳ, Khóa học ngoại ngữ).
- **Thành phần UI:** Danh sách thẻ dự án, mỗi thẻ gồm: Tên dự án, Màu nhận diện, Số lượng việc (Đã xong / Tổng số), Progress ring, Hạn nộp dự án, nút "+" tạo dự án mới (`M18`).
- **Input:** Danh sách `Project` từ CSDL.
- **Output:** Chuyển sang `M19` khi chạm vào dự án.

#### M18: Tạo dự án mới (Create Project)
- **Mục đích:** Thiết lập dự án học tập mới.
- **Thành phần UI:** Ô nhập Tên dự án, Mục tiêu chính của dự án, Ngày bắt đầu & Hạn chót dự án, Bảng chọn màu nhận diện (Color picker với 6 màu trong design system), nút "Tạo dự án".
- **Flow:** Nhập thông tin -> Bấm Tạo -> Dự án khởi tạo ở trạng thái **chưa có công việc** -> Mở `M19`.
- **Input:** `name`, `description`, `deadline`, `color_hex`.
- **Output:** Bản ghi mới trong bảng `Project`.

#### M19: Chi tiết dự án (Project Detail)
- **Mục đích:** Theo dõi tiến độ toàn cục và quản lý danh sách công việc thuộc riêng dự án đó.
- **Thành phần UI:** Banner thông tin dự án, thanh tiến độ tổng thể, danh sách công việc thuộc dự án, nút "Thêm việc vào dự án" (Mở thẳng form `M12` với trường Dự án được điền sẵn).
- **Flow:** Bấm "Thêm việc" -> Mở M12 -> Lưu xong việc mới tự động gán vào dự án hiện tại. Chạm vào tên việc -> Mở `M13`.
- **Input:** `project_id`.
- **Output:** CSDL liên kết giữa Task và Project.

---

### PHÂN HỆ 4: LỊCH BIỂU & XẾP LỊCH THÔNG MINH (M21 - M26)

#### M21: Lịch tuần trên Mobile (Weekly Calendar Strip)
- **Mục đích:** Cái nhìn tổng quan về mật độ lịch học trong tuần dành cho màn hình di động nhỏ gọn.
- **Thành phần UI:** Dải chọn ngày (Date Strip: Thứ 2 đến Chủ nhật) kèm chỉ báo chấm màu mức độ bận rộn, khu vực bên dưới hiển thị timeline của ngày đang chọn, nút chuyển tuần.
- **Flow:** Chạm vào một ngày trên dải tuần -> Timeline bên dưới lập tức cập nhật các sự kiện của ngày đó. Chuyển sang xem lịch ngày chi tiết `M22`.
- **Input:** Ngày được chọn `selected_date`.
- **Output:** Render timeline sự kiện tương ứng.

#### M22: Lịch ngày chi tiết (Daily Schedule Timeline)
- **Mục đích:** Hiển thị thứ tự thời gian chi tiết trong ngày, làm nổi bật các khoảng trống khả dụng để xếp lịch học.
- **Thành phần UI:** Trục thời gian 24 giờ (hoặc từ 06:00 đến 23:00), các khối lịch sự kiện đã có, vạch đỏ chỉ giờ hiện tại (Current time indicator), các **Khoảng trống (Free Time Slots)** có nút bấm nhanh "Xếp việc vào đây" (`M25`).
- **Flow:** Chạm vào một sự kiện đã có -> Mở `M24` để xem/sửa. Chạm vào khoảng trống -> Mở `M25`. Bấm FAB "+" -> Mở form tạo lịch `M23`.
- **Input:** Danh sách `ScheduleEvent` của ngày.
- **Output:** Điều hướng sang M23, M24 hoặc M25.

#### M23: Tạo lịch hẹn / Khung giờ học mới (Create Schedule Event)
- **Mục đích:** Lên lịch cố định cho tiết học, ca ôn tập hoặc sự kiện cá nhân.
- **Thành phần UI:** Tiêu đề sự kiện, Loại lịch (Học trên lớp, Tự học, Thi cử, Sinh hoạt), Giờ bắt đầu & Giờ kết thúc, Tùy chọn lặp lại (Hàng ngày, Hàng tuần), Nhắc nhở trước (15 phút, 30 phút, 1 giờ), nút "Lưu vào lịch".
- **Flow:** Nhập dữ liệu -> Kiểm tra xung đột lịch -> Nếu trùng giờ mở `M26`, nếu không trùng -> Lưu vào CSDL -> Quay về `M22`.
- **Input:** `title`, `event_type`, `start_time`, `end_time`, `recurrence_rule`, `reminder_minutes`.
- **Output:** Bản ghi mới trong bảng `ScheduleEvent`.

#### M24: Chi tiết & Chỉnh sửa lịch (Edit Schedule Event)
- **Mục đích:** Xem và điều chỉnh giờ giấc của lịch đã tạo; so sánh giờ hiện tại với thay đổi chưa lưu.
- **Thành phần UI:** Chi tiết sự kiện, Picker đổi giờ bắt đầu/kết thúc, hiển thị so sánh: "Giờ cũ: 19:00 - 20:00 -> Giờ mới: 19:30 - 20:30", nút "Lưu thay đổi", nút "Hủy thay đổi" (giữ nguyên dữ liệu cũ), nút "Xóa lịch".
- **Flow:** Thay đổi giờ -> Nhấn Lưu -> Kiểm tra xung đột -> Cập nhật lịch. Bấm Hủy -> Hoàn nguyên.
- **Input:** `event_id`, thông tin thời gian mới.
- **Output:** Cập nhật bảng `ScheduleEvent`.

#### M25: Xếp công việc vào lịch (Schedule Task to Time Slot)
- **Mục đích:** Gắn một công việc hoặc một bước nhỏ cụ thể vào một khoảng thời gian trống đã chọn trên lịch.
- **Thành phần UI:** Chọn Công việc (từ danh sách việc cần làm), chọn Bước nhỏ cụ thể (ví dụ: Bước 3), chọn thời lượng dự kiến (ví dụ: 25 phút), khu vực "Xem trước trên lịch", nút "Thêm vào lịch".
- **Flow:** Chọn việc & bước nhỏ -> Hệ thống tính toán khung giờ dự kiến -> Kiểm tra xung đột:
  - Nếu trùng giờ -> Tự động chuyển tiếp đến `M26 (Xử lý trùng lịch)`.
  - Nếu không trùng giờ -> Hiện xem trước -> Nhấn "Thêm vào lịch" -> Lưu sự kiện liên kết với Task ID vào CSDL.
- **Input:** `task_id`, `subtask_id`, `slot_start_time`, `duration_minutes`.
- **Output:** Tạo `ScheduleEvent` với `task_id` được liên kết.

#### M26: Xử lý trùng lịch (Conflict Resolution Modal)
- **Mục đích:** Giải quyết triệt để xung đột thời gian khi người dùng xếp việc đè lên lịch đã có.
- **Thành phần UI:**
  - Cảnh báo trực quan: Thể hiện sự kiện hiện tại (Ví dụ: "Học Tiếng Anh 19:00 - 20:00") bị đè bởi việc dự kiến (19:45 - 20:10).
  - Lựa chọn 1: **Chấp nhận khung giờ đề xuất** (Ví dụ gợi ý: `20:10 - 20:35` ngay sau khi lớp tiếng Anh kết thúc).
  - Lựa chọn 2: **Tự chọn giờ khác** (Mở time picker chỉnh tay).
  - Lựa chọn 3: **Vẫn thêm vào giờ trùng** (Chấp nhận xếp song song, không thay đổi lịch cũ).
- **Flow:**
  - Chọn Lựa chọn 1 -> Quay về phần xem trước của `M25` với khung giờ mới `20:10 - 20:35`; chỉ ghi vào CSDL khi người dùng nhấn "Thêm vào lịch".
  - Chọn Lựa chọn 2 -> Quay lại `M25` để sửa giờ.
  - Chọn Lựa chọn 3 -> Lưu lịch mới theo lựa chọn người dùng, giữ nguyên sự kiện cũ.
- **Input:** Quyết định của người dùng (`ACCEPT_SUGGESTION` | `CUSTOM_TIME` | `FORCE_OVERLAP`).
- **Output:** Quyết định điều phối khung giờ hợp lệ cho `ScheduleEvent`.

---

### PHÂN HỆ 5: PHIÊN TẬP TRUNG POMODORO & LINH VẬT TƯƠNG TÁC (M27 - M30)

#### M27: Chuẩn bị phiên tập trung (Focus Prep Screen)
- **Mục đích:** Thiết lập tâm lý vững vàng trước khi bước vào phiên học sâu.
- **Thành phần UI:**
  - Thẻ hiển thị Công việc và Bước nhỏ được chọn (cho phép đổi bước nếu muốn).
  - Chọn Thời lượng phiên: Chip chọn nhanh (15 phút, 25 phút, 45 phút, Tùy chỉnh).
  - Chọn Âm thanh nền (White noise: Mưa rào, Quán cà phê, Tiếng sóng biển, Im lặng).
  - Hình ảnh linh vật Chặng ở tư thế chuẩn bị sẵn sàng (đeo tai nghe, cầm sách).
  - Nút CTA lớn: "Bắt đầu tập trung".
- **Flow:** Chọn thông số -> Bấm "Bắt đầu" -> Chuyển sang `M28`.
- **Input:** `task_id`, `subtask_id`, `duration_minutes`, `sound_ambient_id`.
- **Output:** Khởi tạo đối tượng `FocusSession` ở trạng thái `IN_PROGRESS`.

#### M28: Đang tập trung (Active Focus Session)
- **Mục đích:** Môi trường học tập thuần khiết, không gây xao nhãng.
- **Thành phần UI:**
  - Đồng hồ đếm ngược kích thước lớn dạng tròn (Circular Countdown Timer).
  - Nhãn hiển thị: Tên bước nhỏ đang làm (ví dụ: "Bước 3: Dịch đoạn 1-15").
  - Linh vật Chặng ở tư thế học tập tập trung tĩnh (KHÔNG chạy animation lặp đi lặp lại để tránh phân tâm).
  - Nút "Tạm dừng" (`M29`).
  - Nút "Kết thúc phiên sớm".
  - Nút "Thu gọn phiên" (Picture-in-picture hoặc floating mini-widget).
- **Flow:**
  - Đồng hồ chạy đếm ngược từng giây.
  - Nhấn "Tạm dừng" -> Dừng đếm giờ, chuyển sang `M29`.
  - Nhấn "Thu gọn phiên" -> Quay về màn hình trước đó, đồng hồ vẫn tiếp tục chạy ngầm trong background service với thanh trạng thái mini.
  - Hết giờ hoặc bấm "Kết thúc phiên" -> Chuyển sang `M30 (Tổng kết phiên)`.
- **Input:** Timer tick events từ Background Service.
- **Output:** Cập nhật `elapsed_seconds` trong phiên.

#### M29: Tạm dừng phiên tập trung (Paused Session)
- **Mục đích:** Xử lý các tình huống gián đoạn ngắn (uống nước, nghe điện thoại) mà không làm mất phiên học.
- **Thành phần UI:**
  - Đồng hồ hiển thị thời gian đang dừng lại chính xác tại giây đó.
  - Linh vật ở tư thế thư giãn nghỉ ngơi.
  - Nút chính: "Tiếp tục học" (Resume).
  - Nút phụ: "Kết thúc phiên tại đây" (End now).
- **Flow:**
  - Bấm "Tiếp tục học" -> Quay lại `M28`, đồng hồ tiếp tục chạy tiếp từ giây đã dừng.
  - Bấm "Kết thúc phiên tại đây" -> Chuyển sang `M30` với thời gian thực tế đã học trước khi tạm dừng.
- **Input:** User click event.
- **Output:** Cập nhật trạng thái phiên `FocusSession.status = PAUSED`.

#### M30: Tổng kết phiên tập trung (Session Summary)
- **Mục đích:** Ghi nhận thành quả học tập thực tế và xác nhận riêng rẽ tiến độ công việc.
- **Thành phần UI:**
  - Thẻ chúc mừng từ linh vật với nền vàng `brand/honey-soft`.
  - Hiển thị **Thời gian tập trung thực tế**: Ví dụ phiên đặt 25 phút nhưng dừng ở phút thứ 18 thì màn hình hiển thị chính xác **18 phút 35 giây**, tuyệt đối không tự làm tròn thành 25 phút.
  - Hộp kiểm xác nhận tiến độ: *"Bạn đã hoàn thành Bước 3 chưa?"* với 2 nút [Đã hoàn thành] / [Chưa xong, cần làm thêm].
  - Nút "Về màn hình chính" hoặc "Nghỉ giải lao 5 phút".
- **Flow:**
  - Nếu người dùng chọn "Đã hoàn thành": Hệ thống đánh dấu bước 3 hoàn thành, cập nhật tiến độ công việc từ `2/5` lên `3/5`. Không tự ý hoàn thành toàn bộ công việc nếu còn các bước khác.
  - Bấm "Về màn hình chính" -> Đồng bộ vào tổng số phút học trong ngày -> Mở Home `M05`.
- **Input:** Xác nhận hoàn thành bước nhỏ (`is_subtask_finished: boolean`).
- **Output:** Lưu bản ghi hoàn chỉnh vào bảng `FocusSession` (lưu `actual_duration_seconds`), cập nhật bảng `Subtask`, cập nhật tiến độ tuần.

---

### PHÂN HỆ 6: MỤC TIÊU ĐỊNH LƯỢNG & MILESTONE (M31 - M34, M40)

#### M31: Tổng quan mục tiêu (Goal Overview)
- **Mục đích:** Theo dõi các mục tiêu định lượng dài hạn hoặc trung hạn (Ví dụ: Học 500 từ vựng, Luyện 30 đề thi).
- **Thành phần UI:** Danh sách thẻ mục tiêu: Tên mục tiêu, Thước đo & Đơn vị (từ vựng, đề thi, trang sách), Tiến độ số học (ví dụ: `40/100 từ`), Thanh phần trăm trực quan, Hạn chót mục tiêu, nút "+" tạo mục tiêu (`M32`).
- **Input:** Danh sách `Goal` từ CSDL.
- **Output:** Điều hướng sang `M33` khi chọn mục tiêu.

#### M32: Tạo mục tiêu định lượng (Create Goal)
- **Mục đích:** Khai báo mục tiêu có thể đo lường chính xác bằng con số.
- **Thành phần UI:** Tên mục tiêu, Số lượng mục tiêu cần đạt (Target value, ví dụ: 100), Đơn vị đo lường (Từ, Trang, Bài, Giờ), Chu kỳ hoàn thành (Hạn chót cụ thể), Cách thức ghi nhận, nút "Lưu mục tiêu".
- **Input:** `title`, `target_value`, `unit`, `deadline`.
- **Validation:** `target_value > 0`, `unit` không rỗng.
- **Output:** Bản ghi mới trong bảng `Goal`.

#### M33: Chi tiết mục tiêu & Lịch sử ghi nhận (Goal Detail & Progress Log)
- **Mục đích:** Xem biểu đồ tăng trưởng số liệu, danh sách lịch sử các lần check-in và ghi nhận tiến độ mới.
- **Thành phần UI:**
  - Vòng tròn tiến độ lớn hiển thị con số hiện tại (ví dụ: `40/100 từ`).
  - Danh sách lịch sử cập nhật (Log entries: Ngày, Giờ, Số lượng thêm, Ghi chú).
  - Nút hành động chính: "Ghi nhận thêm" (Mở popup nhập số lượng học thêm).
  - Nút hành động phụ: "Điều chỉnh mục tiêu" (`M34`).
- **Flow (Nhánh Ghi nhận thêm):**
  - Đang ở mức `40/100 từ`, bấm "Ghi nhận thêm" -> Nhập `10` -> Xem trước kết quả `50/100` -> Bấm Lưu -> Cập nhật CSDL, thêm bản ghi log `+10`.
  - Nếu giá trị sau khi cộng đạt hoặc vượt mục tiêu (ví dụ 100/100) -> Tự động kích hoạt màn hình Chúc mừng mốc mục tiêu `M40`.
- **Input:** Giá trị số học bổ sung `delta_value: number`.
- **Output:** Thêm bản ghi vào `GoalProgressLog`, cập nhật `Goal.current_value`.

#### M34: Điều chỉnh đích mục tiêu (Adjust Goal Target)
- **Mục đích:** Sửa đổi con số mục tiêu ban đầu khi kế hoạch thực tế thay đổi mà vẫn bảo tồn lịch sử học tập.
- **Thành phần UI:**
  - Ô nhập Đích mục tiêu mới (Target value).
  - Màn hình so sánh xem trước thay đổi: Ví dụ giữ nguyên đã học `40 từ`, đổi đích từ `100` thành `80` -> Tỷ lệ tăng từ `40% lên 50%`.
  - Chú thích rõ ràng: *"Toàn bộ lịch sử ghi nhận cũ được giữ nguyên, không có thêm tiến độ nào được ghi nhận."*
  - Nút "Lưu đích mới", nút "Hủy".
- **Flow:** Nhập số đích mới 80 -> Bấm Lưu -> Cập nhật `Goal.target_value = 80`. Số từ đã học vẫn là 40 từ.
- **Input:** `new_target_value: number`.
- **Output:** Cập nhật trường `target_value` trong bảng `Goal`.

#### M40: Đạt mốc mục tiêu (Milestone Celebration)
- **Mục đích:** Tôn vinh nỗ lực của người học khi đạt mốc quan trọng (hoàn thành 100% mục tiêu hoặc chuỗi học).
- **Thành phần UI:**
  - Hiệu ứng pháo hoa nhẹ, linh vật Chặng giơ cúp vàng với nền vàng `brand/honey`.
  - Thông điệp chúc mừng cá nhân hóa kèm số liệu tổng kết chặng đường.
  - Nút 1: "Về hôm nay" -> Quay lại Home, cập nhật chỉ số hoàn thành.
  - Nút 2: "Xem hành trình đã thực hiện" -> Mở lại `M33` với huy hiệu hoàn thành.
  - Nút 3: "Đặt mục tiêu mới" -> Mở form `M32` để thiết lập chặng tiếp theo (không tự động tăng chỉ tiêu mục tiêu cũ).
- **Input:** Sự kiện trigger khi `Goal.current_value >= Goal.target_value`.
- **Output:** Cập nhật `Goal.status = COMPLETED`, ghi nhận huy hiệu.

---

### PHÂN HỆ 7: THÓI QUEN RÈN LUYỆN HÀNG NGÀY (M35 - M37)

#### M35: Thói quen hôm nay (Habits Today)
- **Mục đích:** Quản lý các hành vi lặp lại cần xây dựng (Đọc sách 15p, Học 10 từ vựng mỗi sáng).
- **Thành phần UI:** Danh sách các thói quen cần làm trong ngày hôm nay, nút Checkbox tròn để đánh dấu, nút "Hoàn tác" (Undo) nếu lỡ tay bấm nhầm, streak hiện tại (ví dụ: 🔥 7 ngày).
- **Flow:** Bấm check hoàn thành -> Icon chuyển tick xanh, chuỗi streak tăng +1, hiện snackbar "Đã hoàn thành - [Hoàn tác]" trong 4 giây.
- **Input:** Click check-in hoặc undo.
- **Output:** Tạo hoặc xóa bản ghi trong bảng `HabitLog` của ngày hôm nay, cập nhật `current_streak`.

#### M36: Tạo thói quen mới (Create Habit)
- **Mục đích:** Thiết lập thói quen mới với tần suất và lời nhắc rõ ràng.
- **Thành phần UI:** Tên thói quen, Chọn các ngày lặp lại trong tuần (T2, T3, T4, T5, T6, T7, CN), Thời lượng dự kiến, Giờ nhắc nhở, Liên kết với Mục tiêu (Tùy chọn), nút "Lưu thói quen".
- **Flow:** Nhập thông tin -> Bấm Lưu -> Xuất hiện trong danh sách `M35` từ ngày bắt đầu được chọn.
- **Input:** `title`, `repeat_days: number[]`, `duration_minutes`, `reminder_time`, `linked_goal_id`.
- **Output:** Bản ghi mới trong bảng `Habit`.

#### M37: Chi tiết thói quen & Chuỗi ngày (Habit Detail & Streak Heatmap)
- **Mục đích:** Xem biểu đồ nhiệt (Heatmap) lịch sử thực hiện, phân tích tính kiên trì.
- **Thành phần UI:**
  - Lưới lịch các ngày trong tháng với màu sắc phân biệt rõ rệt:
    * Màu xanh: Ngày đã hoàn thành (`COMPLETED`).
    * Màu xám nhạt: Ngày nghỉ theo kế hoạch (`REST_DAY` - không làm đứt chuỗi).
    * Ô viền chấm: Ngày chưa đến hoặc chưa check-in.
  - Chỉ số: Chuỗi hiện tại, Chuỗi dài nhất, Tỷ lệ kiên trì tháng.
  - Nút "Chỉnh sửa thói quen": Dùng lại form tạo thói quen `M36` với dữ liệu có sẵn và nút "Lưu thay đổi".
- **Input:** `habit_id`.
- **Output:** Dữ liệu trực quan hóa từ `HabitLog`.

---

### PHÂN HỆ 8: BÁO CÁO, THỐNG KÊ & TRỢ LÝ AI (M38, M39, M41 - M50)

#### M38: Tổng quan tiến độ học tập (Learning Analytics & Stats)
- **Mục đích:** Thống kê tổng hợp số giờ học và hiệu suất theo ngày/tuần/tháng.
- **Thành phần UI:**
  - Thẻ tổng thời gian tập trung (ví dụ: 100 phút sau 4 phiên đủ 25 phút).
  - Số lượng phiên tập trung hoàn thành (ví dụ: `4/4 phiên`).
  - Số lượng công việc hoàn thành (Chỉ tăng khi người dùng xác nhận xong việc, không tăng theo số phiên).
  - Biểu đồ phân bổ thời gian học theo các môn/dự án.
- **Input:** Khoảng thời gian thống kê (Hôm nay / Tuần này / Tháng này).
- **Output:** Render biểu đồ và các chỉ số tổng hợp.

#### M39: Nhìn lại tuần (Weekly Retrospective)
- **Mục đích:** Đánh giá định kỳ cuối tuần về năng suất và rút kinh nghiệm cho tuần tới.
- **Thành phần UI:** Biểu đồ cột phân bổ giờ học theo từng ngày trong tuần, phát hiện khung giờ vàng có độ tập trung cao nhất, số việc tồn đọng đã giải quyết, lời khuyên cải thiện từ trợ lý.
- **Input:** Aggregate query từ thứ 2 đến chủ nhật.
- **Output:** Báo cáo tổng kết tuần.

#### M41: Bắt đầu với Trợ lý AI (AI Assistant Starter)
- **Mục đích:** Cung cấp điểm chạm đầu tiên để người dùng ra lệnh cho AI lập lịch học tự động.
- **Thành phần UI:**
  - Các chip mẫu câu lệnh (Prompt Templates): "Lập lịch ôn thi cuối kỳ tuần này", "Sắp xếp 3 việc quan trọng hôm nay", "Tìm khoảng trống học 45 phút".
  - Ô nhập văn bản tự do (Prompt Input) kèm nút gửi.
  - Nút tùy chọn "Lập kế hoạch học thủ công" để vào thẳng biểu mẫu chuẩn.
- **Flow:** Chọn chip mẫu hoặc gõ yêu cầu -> Bấm Gửi -> Chuyển sang màn hình hội thoại `M42`.
- **Input:** Chuỗi văn bản yêu cầu của người dùng `user_prompt: string`.
- **Output:** Khởi tạo phiên làm việc `AIAssistantSession`.

#### M42: Hội thoại làm rõ yêu cầu (AI Clarification Dialog)
- **Mục đích:** AI tương tác hai chiều để làm rõ các ràng buộc về thời gian, việc ưu tiên và giờ nghỉ ngơi.
- **Thành phần UI:** Giao diện hội thoại dạng tin nhắn, các câu hỏi trắc nghiệm nhanh từ AI (Ví dụ: "Hôm nay bạn muốn học tối đa mấy tiếng?", "Bạn muốn nghỉ giải lao bao lâu giữa các phiên?"), nút "Tiếp tục kiểm tra".
- **Flow:** Người dùng chọn câu trả lời hoặc gõ bổ sung -> AI nắm đủ thông tin -> Chuyển sang `M43`.
- **Input:** Câu trả lời làm rõ từ người dùng.
- **Output:** Tập hợp các tham số ràng buộc `AIPlanningParams`.

#### M43: Kiểm tra yêu cầu & Phạm vi dữ liệu (AI Request & Privacy Audit)
- **Mục đích:** Minh bạch hóa phạm vi dữ liệu AI được phép đọc trước khi thuật toán chạy.
- **Thành phần UI:**
  - Bảng tóm tắt các yêu cầu đã chốt (Thời gian, danh sách việc, mục tiêu).
  - Khu vực **Phạm vi dữ liệu cho phép truy cập (Data Scope)**: Cho biết AI sẽ đọc lịch hiện có từ ngày X đến ngày Y và danh sách công việc chưa làm; cam kết không gửi dữ liệu cá nhân nhạy cảm ra ngoài.
  - Cho phép sửa trực tiếp thông tin nếu chưa đúng ý.
  - Nút CTA: "Tạo kế hoạch học".
- **Flow:** Kiểm tra thông tin -> Bấm "Tạo kế hoạch" -> Chuyển sang `M44`.
- **Input:** Xác nhận phạm vi dữ liệu từ người dùng.
- **Output:** Gửi payload đã kiểm duyệt đến bộ engine lập lịch AI.

#### M44: Đang tạo kế hoạch (AI Generating Screen)
- **Mục đích:** Thể hiện trạng thái hệ thống đang tính toán xếp lịch thông minh và cung cấp quyền hủy.
- **Thành phần UI:** Animation linh vật Chặng đang suy nghĩ tính toán, thanh tiến trình mô tả các bước ("Đang quét lịch trống...", "Đang phân bổ độ ưu tiên..."), nút "Hủy tạo kế hoạch".
- **Flow:**
  - Nếu thành công -> Tự động chuyển tiếp đến `M45 (Xem trước kế hoạch)`.
  - Nếu thất bại hoặc không tìm được lịch -> Chuyển sang `M49`.
  - Nếu người dùng bấm "Hủy" -> Dừng tiến trình, quay về `M41`.
- **Input:** Tín hiệu xử lý từ AI Service.
- **Output:** Đối tượng bản nháp kế hoạch `AIPlanProposal`.

#### M45: Xem trước kế hoạch do AI đề xuất (Preview Proposed Schedule)
- **Mục đích:** Hiển thị trực quan toàn bộ các khung giờ và thay đổi dự kiến để người học phê duyệt.
- **Thành phần UI:**
  - Danh sách các khối lịch dự kiến xếp vào ngày/tuần (thể hiện rõ: Giờ bắt đầu, Giờ kết thúc, Tên việc, Bước nhỏ được xếp).
  - Huy hiệu phân biệt: Các sự kiện mới được thêm màu xanh nhạt.
  - Nút "Xem giải thích đề xuất" (`M46`).
  - Nút "Chỉnh sửa đề xuất" (`M47`).
  - Nút CTA chính: "Áp dụng kế hoạch này".
- **Flow:**
  - Bấm "Xem giải thích" -> Mở bottom sheet `M46`.
  - Bấm "Chỉnh sửa" -> Mở `M47`.
  - Bấm "Áp dụng" -> Ghi toàn bộ các sự kiện vào lịch chính thức -> Chuyển sang `M48`.
- **Input:** `proposal_id`.
- **Output:** Quyết định phê duyệt của người dùng.

#### M46: Giải thích đề xuất của AI (Explain AI Reasoning)
- **Mục đích:** Tạo dựng sự tin cậy bằng cách giải thích tường tận căn cứ khoa học đằng sau kế hoạch.
- **Thành phần UI:**
  - Danh sách căn cứ đã sử dụng: Lịch học hiện có, Hạn nộp công việc gần nhất, Khung giờ vàng tập trung của người dùng (từ M04).
  - Giả định đặt ra: "Xếp môn Toán vào buổi sáng vì độ tập trung cao nhất".
  - Liệt kê các phần người dùng có thể tự do thay đổi.
- **Input:** Metadata giải thích từ AI engine.
- **Output:** Hiển thị dạng Bottom sheet thông tin cho người dùng.

#### M47: Chỉnh sửa đề xuất AI (Tweak Proposal)
- **Mục đích:** Cho phép người học can thiệp, đổi thứ tự ưu tiên hoặc thời lượng của các khối lịch AI vừa tạo.
- **Thành phần UI:**
  - Danh sách các khối lịch trong bản nháp cho phép điều chỉnh.
  - Nút tăng/giảm thời lượng (ví dụ: từ 45p giảm còn 30p).
  - Nút đổi thứ tự hoặc xóa bỏ một khối lịch không muốn học.
  - Tự động kiểm tra lại lịch để đảm bảo không phát sinh xung đột mới.
  - Nút "Lưu bản nháp" -> Quay lại xem trước `M45` với bản nháp đã cập nhật.
- **Flow:** Chỉnh sửa -> Nhấn Lưu bản nháp -> Quay lại M45 -> Nhấn "Áp dụng".
- **Input:** Payload các thay đổi trên item đề xuất.
- **Output:** Bản nháp `AIPlanProposal` đã được cập nhật.

#### M48: Kết quả áp dụng kế hoạch AI (Applied Success & Undo)
- **Mục đích:** Thông báo thành công và cung cấp chốt an toàn để người dùng có thể hoàn tác ngay lập tức.
- **Thành phần UI:**
  - Biểu tượng thành công `circle-check` xanh lá.
  - Danh sách tóm tắt các lịch vừa được thêm vào hệ thống.
  - Nút nổi bật: **"Hoàn tác áp dụng" (Undo All Changes)**.
  - Nút "Về màn hình Lịch" (`M22`).
- **Flow:**
  - Nếu bấm "Hoàn tác áp dụng": Hệ thống tự động xóa sạch toàn bộ các sự kiện vừa tạo từ đợt áp dụng AI này, khôi phục lại lịch ban đầu 100%.
  - Nếu bấm "Về màn hình Lịch": Chuyển sang xem lịch ngày `M22` với các sự kiện mới đã hiển thị sẵn sàng.
- **Input:** Click nút Hoàn tác hoặc Xác nhận xong.
- **Output:** Xóa batch sự kiện nếu Undo, hoặc giữ nguyên và lưu vào audit log `M50`.

#### M49: Xử lý khi chưa tạo được kế hoạch (AI Fallback / Error Handling)
- **Mục đích:** Hỗ trợ người dùng khi AI không thể phân bổ lịch (do kín lịch, ràng buộc mâu thuẫn hoặc lỗi mạng).
- **Thành phần UI:**
  - Minh họa linh vật tỏ vẻ băn khoăn, nêu rõ nguyên nhân (Ví dụ: "Lịch hôm nay đã kín 100%, không còn khoảng trống nào trên 20 phút").
  - Lưu giữ nguyên vẹn nội dung yêu cầu ban đầu (không bắt người dùng gõ lại).
  - Các lựa chọn hành động:
    * "Thử lại với gợi ý giảm bớt thời lượng".
    * "Sửa lại yêu cầu ban đầu".
    * "Tự xếp lịch thủ công" (Mở `M25`).
- **Input:** Mã lỗi hoặc lý do không thỏa mãn thuật toán xếp lịch.
- **Output:** Điều hướng theo lựa chọn giải quyết của người dùng.

#### M50: Kiểm soát AI và Lịch sử can thiệp (AI Audit Log & History)
- **Mục đích:** Đảm bảo quyền kiểm soát tuyệt đối của người dùng đối với các hành vi tự động hóa của AI.
- **Thành phần UI:**
  - Lịch sử các lần AI từng can thiệp và áp dụng kế hoạch (Ngày, giờ, số sự kiện đã thêm).
  - Nút "Hoàn tác đợt áp dụng này" cho phép hoàn tác cả các lần trong quá khứ.
  - Quản lý phạm vi dữ liệu: Bật/tắt các quyền đọc dữ liệu của AI.
- **Input:** Lựa chọn hoàn tác batch sự kiện theo `proposal_id`.
- **Output:** Xóa các `ScheduleEvent` liên đới, cập nhật trạng thái proposal thành `REVERTED`.

---

## 5. TỔNG HỢP MATRIX INPUT / OUTPUT TOÀN HỆ THỐNG

| Phân hệ | Màn hình | Dữ liệu Đầu vào (Input) | Dữ liệu Đầu ra (Output) | Tác động CSDL / State |
| :--- | :--- | :--- | :--- | :--- |
| **Onboarding** | M03, M04, M06 | Tùy chọn mục tiêu, giờ học lý tưởng | Cờ Onboarding = true, UserPreference | Tạo bản ghi User, UserPreference |
| **Home & Inbox** | M01, M02, M05 | Tên việc nhanh, chọn việc hôm nay | Task với scheduled_date = Today/null | Cập nhật Task.scheduled_date |
| **Công việc** | M11 - M16, M20 | Tên việc, deadline, 1..5 subtasks | Task ID, Subtask list | INSERT/UPDATE bảng Task, Subtask |
| **Dự án** | M17 - M19 | Tên dự án, màu sắc, hạn chót | Project ID, Task list thuộc Project | INSERT bảng Project, UPDATE Task.project_id |
| **Lịch biểu** | M21 - M26 | Ngày giờ, Task gắn kèm, quyết định trùng lịch | ScheduleEvent, cập nhật xung đột | INSERT bảng ScheduleEvent |
| **Tập trung** | M27 - M30 | Chọn bước nhỏ, thời lượng, tick hoàn thành | Actual focus seconds, Subtask completed | INSERT bảng FocusSession, UPDATE Subtask |
| **Mục tiêu** | M31 - M34, M40 | Chỉ tiêu số lượng, delta cộng thêm | Goal ID, GoalProgressLog, Milestone badge | INSERT bảng Goal, GoalProgressLog |
| **Thói quen** | M35 - M37 | Các ngày lặp, check-in hôm nay | HabitLog hôm nay, streak count | INSERT/DELETE bảng HabitLog |
| **Báo cáo & AI** | M38, M39, M41-M50 | Câu lệnh prompt, phản hồi câu hỏi, duyệt preview | AIPlanProposal, Batch ScheduleEvent, Undo state | INSERT AIProposal, Batch Event, Audit Log |

---
*Tài liệu được thiết kế chuyên biệt cho phiên bản Ứng dụng Di động Native (Mobile App), tuân thủ trọn vẹn bộ Token và 15 Đợt cấu trúc màn hình của Chặng App.*
