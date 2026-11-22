# Cấu trúc file Chặng App

## Phạm vi bộ khung

Dựa trên SRS và roadmap, ứng dụng dùng Flutter, Riverpod cho
state/dependency injection và go_router cho điều hướng. Bộ khung chọn cách chia
theo tính năng để mỗi module quản lý dữ liệu, nghiệp vụ và giao diện của mình.

Phát triển hằng ngày trên Linux hoặc web/Firefox; giữ `android/` và `ios/`
để tiếp tục build mobile. Các runner nền tảng không phải Android Emulator.

Hiện chỉ trang chào `/` có mã giao diện. Chỉ tạo thư mục khi có code thực tế;
không giữ `.gitkeep`, repository giả, API giả hoặc màn hình CRUD giả.
App đã có Supabase SDK và cấu hình public. Khởi động app không tự chạy migration
hoặc seed, không tạo bảng `todos` từ ví dụ của Supabase.

## Các thư mục dùng chung

| Đường dẫn | Trách nhiệm |
| --- | --- |
| `lib/main.dart` | Entry point gọi `bootstrap()` |
| `lib/bootstrap.dart` | Khởi tạo binding, chờ Supabase.initialize rồi mở app trong ProviderScope |
| `lib/app/app.dart` | MaterialApp, locale tiếng Việt, theme, router |
| `lib/app/router/app_router.dart` | Đăng ký route; hiện có `/` |
| `lib/core/constants/` | Hằng số dùng toàn ứng dụng |
| `lib/core/config/` | SupabaseConfig với URL/key public mặc định và hỗ trợ dart-define |
| `lib/theme/` | Màu, spacing, radius, kích thước và ThemeData |
| `lib/data/remote/` | supabaseClientProvider cung cấp client đã khởi tạo |
| `assets/` | Hướng dẫn thêm ảnh, icon, animation, âm thanh, font |
| `test/` | Test UI, bootstrap và phép thử kết nối thật trong live/ (bật riêng) |
| `supabase/migrations/` | Schema, constraints, RLS, triggers phía PostgreSQL |
| `linux/`, `web/` | Runner Linux và khởi động web |
| `android/`, `ios/` | Cấu hình build mobile, giữ để phát triển sau này |
| `.vscode/` | Cấu hình F5 cho Linux/web, hot reload khi lưu |
| `tools/diagrams/` | Hai script Python sinh sơ đồ vào docs/ |
| `docs/` | Đặc tả và hướng dẫn dự án |

Các thư mục `.agents/`, `skills`, `.gemini/` phục vụ công cụ phát triển, không
thuộc mã ứng dụng. `build/`, `.dart_tool/` là file sinh tự động, được Git bỏ qua
và ẩn trong VS Code Explorer; không chứa mã cần chỉnh sửa.

## Ánh xạ module với màn hình

Đây là **bản đồ phát triển**, không phải danh sách thư mục đã tồn tại.
Hiện chỉ `home/presentation/pages/` có code. Khi triển khai module, tạo các lớp
`data/`, `domain/`, `presentation/` cần thiết cho luồng đó.

| Module trong `lib/features/` | Màn hình | Phạm vi |
| --- | --- | --- |
| `auth/` | Chưa có mã M riêng | Đăng nhập, đăng ký, phiên Supabase Auth |
| `onboarding/` | M03, M04, M06 | Intro, mục tiêu sử dụng, giờ học lý tưởng |
| `home/` | M05 | Dashboard tổng hợp; hiện có trang chào ban đầu |
| `notifications/` | M07 | Trung tâm thông báo và trạng thái đã đọc |
| `profile/` | M08 | Hồ sơ học tập |
| `settings/` | M09 | Giờ yên tĩnh, linh vật, giảm chuyển động |
| `review/` | M10 | Rà soát cuối ngày, chuyển ngày hoặc về Inbox |
| `tasks/` | M01, M02, M11–M16, M20 | Inbox, kế hoạch hôm nay, công việc và tối đa 5 bước nhỏ |
| `projects/` | M17–M19 | Dự án học tập và công việc thuộc dự án |
| `calendar/` | M21–M26 | Lịch tuần/ngày, sự kiện, khoảng trống và xung đột |
| `focus/` | M27–M30 | Chuẩn bị, đếm giờ, tạm dừng, tổng kết phiên |
| `goals/` | M31–M34, M40 | Mục tiêu định lượng, nhật ký tăng trưởng, milestone |
| `habits/` | M35–M37 | Thói quen, check-in, streak |
| `analytics/` | M38, M39 | Thống kê và nhìn lại tuần |
| `ai_assistant/` | M41–M50 | Hội thoại, preview, chỉnh sửa, áp dụng, undo và audit |

## Quy tắc ba lớp

```text
features/<module>/
├── data/           # DTO, data source, triển khai repository
├── domain/         # Entity, quy tắc nghiệp vụ, hợp đồng repository
└── presentation/   # Trang, widget riêng, Riverpod provider/controller
```

- `domain` dùng Dart thuần, không import Flutter, Riverpod hoặc Supabase SDK.
- `data` triển khai hợp đồng trong `domain`, sử dụng hạ tầng ở `lib/data/`.
- `presentation` hiển thị state và gọi nghiệp vụ qua provider/controller.
  Khởi tạo repository ở provider hoặc bootstrap; widget không tự chạy SQL/API.
- Module khác dùng hợp đồng nghiệp vụ đã công bố; tránh import thẳng data source
  hoặc widget nội bộ của nhau. Không chuyển mọi entity vào `core`.
- Logic riêng từng module ở feature. `lib/data/` chỉ chứa hạ tầng dùng chung.
- Repository provider lấy client bằng `ref.watch(supabaseClientProvider)` rồi
  truyền vào data source. Widget không gọi Supabase trực tiếp.
- Tạo `lib/widgets/` khi có widget dùng chung thực tế; widget riêng ở
  `features/<module>/presentation/widgets/`.
- Chỉ tạo thêm thư mục con khi bắt đầu viết mã ở đó. Không cần lớp use case
  riêng cho thao tác chuyển tiếp đơn giản.

Ví dụ **khi triển khai** tính năng công việc (các file này chưa được tạo):

```text
features/tasks/
├── data/
│   ├── models/task_dto.dart
│   ├── datasources/task_local_data_source.dart
│   ├── datasources/task_remote_data_source.dart
│   └── repositories/task_repository_impl.dart
├── domain/
│   ├── entities/task.dart
│   ├── entities/subtask.dart
│   └── repositories/task_repository.dart
└── presentation/
    ├── pages/task_list_page.dart
    ├── pages/task_detail_page.dart
    ├── providers/task_list_provider.dart
    └── widgets/task_card.dart
```

Tên file/thư mục dùng `snake_case`; class dùng `PascalCase`. Test tương ứng đặt
ở `test/features/tasks/..._test.dart`. Khi thêm màn hình, đăng ký route trong
`lib/app/router/app_router.dart`.

## Những phần chưa triển khai

- **Backend:** đã có `supabase_flutter`, khởi tạo client và provider dùng chung.
  Chưa có màn hình Auth hoặc repository CRUD. Phép thử mạng chỉ kiểm tra kết nối
  đọc với publishable key, chưa kiểm tra phân quyền cho người dùng đăng nhập.
- **Offline:** chưa chọn database hoặc viết đồng bộ. Khi triển khai, tạo
  `lib/data/local/` và `lib/data/sync/`. Migration PostgreSQL không dùng trực tiếp
  cho SQLite.
- **Design system:** đã có tokens màu/kích thước, theme sáng cơ bản. Font Inter,
  linh vật, âm thanh và giao diện chi tiết chưa có; app dùng font mặc định.
- **Native:** Android đã có quyền INTERNET ở manifest chính cho cả bản release.
  Chưa cấu hình background timer,
  thông báo, OAuth deep link hoặc ký bản phát hành.
- **Kiểm thử:** đã có test khởi tạo Supabase/provider và widget test cho trang
  chào, màn hình nhỏ/cỡ chữ lớn. `test/live/supabase_connection_test.dart` kiểm
  tra bảng `tasks` với `limit(0)`, chỉ chạy khi `RUN_SUPABASE_CHECK=true`.
  Khi có luồng nhiều màn hình, tạo `integration_test/`, thêm `integration_test`
  từ Flutter SDK vào dev dependencies, chạy
  `flutter test integration_test -d <device-id>`. Dùng backend test riêng nếu ghi dữ liệu.
- **Edge Functions:** khi triển khai trợ lý AI, tạo
  `supabase/functions/<function-name>/index.ts`; chỉ tạo `_shared/` khi có mã chung.
  Secret chỉ đọc ở server. Function phải xác thực người dùng và quyền dữ liệu;
  tạo preview không được áp dụng thay đổi. Apply/undo cần transaction và audit theo SRS.

Xem [lệnh chạy Linux, Firefox và VS Code](../README.md#chạy-dự-án).

## Bắt đầu phát triển

1. Chọn feature theo [roadmap](04_FUNCTION_LIST_AND_ROADMAP_DAY30.md).
2. Viết entity/quy tắc cùng test cho nghiệp vụ có ràng buộc.
3. Thêm repository/data source cần cho luồng đó.
4. Kết nối provider, giao diện và route.
5. Chạy formatter, `flutter analyze`, `flutter test`; kiểm tra trên thiết bị
   khi thay đổi luồng hoặc tính năng native.
