# Chặng App

Ứng dụng học tập và quản lý tiến độ: **Chia nhỏ chặng đường – Vững bước mục tiêu**.

## Trạng thái

Ứng dụng Flutter dùng Riverpod, go_router và Supabase. Đã có onboarding,
Home, Hộp việc, kế hoạch hôm nay và luồng tạo công việc → chi tiết → chuẩn bị →
tập trung/tạm dừng → tổng kết; dự án học tập và danh sách công việc đã hoàn thành/mở lại.
Nút chuông trên Home mở trung tâm thông báo trong ứng dụng, có bộ lọc và trạng thái đã đọc.
Dữ liệu nghiệp vụ lấy từ Supabase, hiện dùng
phiên đăng nhập ẩn danh; chưa có màn đăng nhập/đăng ký.

Xem [hướng dẫn SQL và luồng công việc/phiên học](docs/08_TASK_AND_FOCUS_FLOW.md)
trước khi chạy các màn công việc. Với M17–M20, xem
[luồng dự án, việc đã hoàn thành và file SQL FEAT-10/11](docs/10_PROJECTS_AND_COMPLETED_TASKS.md).
Xem [lịch, hộp xác nhận và SQL cho thông báo](docs/11_DIALOGS_AND_NOTIFICATIONS.md)
để cấp quyền đọc/đánh dấu thông báo trên Supabase.

## Chạy dự án

Môi trường tạo bộ khung: Flutter **3.47.5**, Dart **3.13.4**. Dùng Flutter phiên bản
tương thích với ràng buộc SDK trong `pubspec.yaml` và các package trong
`pubspec.lock`.

Chạy cửa sổ ứng dụng Linux:

```bash
flutter pub get
flutter run -d linux
```

Chạy trên Firefox:

```bash
flutter run -d web-server --web-hostname 127.0.0.1
```

Mở URL được in trong terminal bằng Firefox; Flutter tự chọn cổng trống để tránh
xung đột với chương trình khác. Dùng `Ctrl+Shift+M` để bật chế độ
màn hình điện thoại. `web-server` có hỗ trợ debug hạn chế; nếu giao diện chưa
cập nhật sau khi tải lại code trong terminal, refresh trang Firefox.

Trong **VS Code**, mở **Run and Debug**, chọn **Chặng — Linux** hoặc
**Chặng — Web (mở bằng Firefox)** rồi nhấn **F5**. Khi chạy Linux bằng F5,
`Ctrl+S` sẽ hot reload. Khi chạy bằng terminal, nhấn `r` để hot reload,
`R` để hot restart, `q` để thoát. Các file cache/build được ẩn khỏi Explorer.

Linux cần `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev` và
thư viện C++ phát triển. Xem [hướng dẫn Flutter Linux](https://docs.flutter.dev/platform-integration/linux/setup).
Android cần SDK và thiết bị phù hợp; iOS cần macOS/Xcode.

App dùng Project URL và publishable key mặc định trong
[`SupabaseConfig`](lib/core/config/supabase_config.dart), không cần `.env` để chạy.
Onboarding không yêu cầu nhập tài khoản; các màn nghiệp vụ dùng phiên ẩn danh để áp dụng RLS.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Kiểm tra kết nối thật bằng Supabase SDK (cần mạng):

```bash
flutter test --dart-define=RUN_SUPABASE_CHECK=true test/live/supabase_connection_test.dart
```

Test này truy vấn `tasks` với `select('id').limit(0)`, không tải nội dung công việc
và không ghi dữ liệu. Nó xác nhận URL/key và endpoint truy vấn hoạt động, chưa
kiểm tra đăng nhập hoặc quyền RLS của người dùng. Test mạng được bỏ qua khi chạy
`flutter test` thông thường.

## Cấu trúc chính

```text
Chang-app/
├── .vscode/                  # Chạy Linux/web bằng F5, hot reload khi lưu
├── linux/                    # Runner Linux desktop
├── web/                      # Trang khởi động web, manifest, icons
├── android/                  # Giữ cấu hình build Android
├── ios/                      # Giữ cấu hình build iOS
├── lib/
│   ├── main.dart             # Entry point
│   ├── bootstrap.dart        # Khởi tạo Supabase, ứng dụng và ProviderScope
│   ├── app/                  # MaterialApp và router
│   ├── core/                 # Hằng số và cấu hình Supabase public
│   ├── theme/                # Design tokens và ThemeData
│   ├── data/remote/          # Supabase client provider dùng chung
│   └── features/             # Onboarding, home, tasks, projects, focus
├── assets/                   # Hướng dẫn thêm tài nguyên khi cần
├── test/                     # Unit/widget tests; đã có test khởi động
├── supabase/
│   ├── migrations/           # Migration SQL có sẵn
│   └── seed.sql              # Dữ liệu mẫu có sẵn
├── docs/                     # SRS, use case, ERD, roadmap và cấu trúc file
├── tools/diagrams/           # Script tạo ERD và sơ đồ use case
├── .env.example              # Mẫu cấu hình client/backend/MCP có sẵn
├── analysis_options.yaml     # Dart analyzer và Flutter lints
├── pubspec.yaml              # SDK, dependencies và cấu hình Flutter
└── pubspec.lock              # Phiên bản dependencies đã resolve
```

Xem [hướng dẫn cấu trúc và ánh xạ M01–M50](docs/07_PROJECT_STRUCTURE.md) để biết
nơi đặt từng chức năng. Chỉ tạo thư mục tính năng/lớp khi có code thực tế;
không giữ hàng loạt thư mục rỗng. Các công cụ `.agents/`, `skills`, `.gemini/`
được giữ riêng và không thuộc mã ứng dụng.

Script sơ đồ dùng Python, Pillow và font Noto Sans của hệ thống:

```bash
python3 tools/diagrams/generate_erd.py
python3 tools/diagrams/generate_usecase.py
```

Kết quả ghi vào `docs/` theo vị trí project, không phụ thuộc thư mục chạy lệnh.

## Cấu hình và tài nguyên

- Cấu hình app chỉ chứa URL và publishable key. Có thể ghi đè bằng
  `--dart-define=SUPABASE_URL=...` và `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
  `.env.example` còn chứa các biến dành cho backend/MCP; không đóng gói toàn bộ
  `.env` vào Flutter. Xem [quy ước cấu hình](lib/core/config/README.md).
- Font Inter, mascot SVG và âm thanh đã được khai báo trong `pubspec.yaml`.
  Tài nguyên bổ sung đặt trong `assets/` với giấy phép phù hợp.
- Bundle/application ID đang là `com.example.chang_app` từ template. Cần đặt ID
  chính thức và cấu hình ký ứng dụng trước khi phát hành.

## Tài liệu

- [SRS, luồng nghiệp vụ và design tokens](docs/01_SRS_LOGIC_FLOW_IO.md)
- [Đặc tả use case](docs/02_USECASE_SPECIFICATION.md)
- [Thiết kế cơ sở dữ liệu](docs/03_DATABASE_ERD_DESIGN.md)
- [Danh sách tính năng và roadmap](docs/04_FUNCTION_LIST_AND_ROADMAP_DAY30.md)
- [Supabase và bảo mật](docs/06_SUPABASE_MCP_AND_SECURITY_GUIDE.md)
- [Cấu trúc file](docs/07_PROJECT_STRUCTURE.md)

Tham khảo công cụ: [Flutter CLI](https://docs.flutter.dev/reference/create-new-app),
[Flutter web/Firefox](https://docs.flutter.dev/platform-integration/web/setup),
[Riverpod](https://pub.dev/packages/flutter_riverpod),
[go_router](https://pub.dev/packages/go_router),
[khởi tạo Supabase Flutter](https://supabase.com/docs/reference/dart/initializing).

## FEAT-03 — Hộp việc dùng Supabase

1. Chạy `supabase/migrations/20261123000000_feat03_guest_inbox.sql` trong SQL Editor.
   Script cho phép `profiles.email` rỗng đối với khách và cấp quyền SELECT/INSERT
   trên `tasks` cho `authenticated`, giữ nguyên chính sách RLS của dự án.
2. Bật **Authentication → Sign In / Providers → Allow anonymous sign-ins**.
3. Chạy `flutter pub get`, rồi mở **Hộp việc chưa lên lịch** từ Home.
   Phiên khách được tạo khi mở Inbox lần đầu và lưu trên thiết bị bởi Supabase SDK.
4. Thêm việc, đóng/mở app để kiểm tra dữ liệu; dùng nút Làm mới hoặc kéo xuống
   để đọc lại Supabase. Không có dữ liệu mẫu dự phòng khi mất kết nối.

Inbox chỉ lấy `tasks` của người dùng hiện tại với `scheduled_date IS NULL`,
`is_archived = false`, trạng thái `TODO` hoặc `IN_PROGRESS`. Quick Add ghi tên
việc tối đa 200 ký tự; chỉ xóa nội dung nhập sau khi Supabase xác nhận thành công.
`seed.sql` không còn tạo dữ liệu mẫu. Không tự xóa các bản ghi đã tồn tại trên
Supabase vì schema chưa có cột phân biệt bản ghi thử nghiệm và dữ liệu thật.

Phiên khách chưa gắn email/mật khẩu: xóa dữ liệu ứng dụng hoặc đổi thiết bị
sẽ mất quyền truy cập phiên cũ. Khi triển khai đăng nhập sau này, cần liên kết
phiên khách với tài khoản để giữ các công việc đã lưu.

Kiểm thử (HTTP giả lập trong test, không ghi dữ liệu lên Supabase):

```bash
flutter test test/features/tasks
```
