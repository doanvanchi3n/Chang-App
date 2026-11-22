# Chặng App

Ứng dụng học tập và quản lý tiến độ: **Chia nhỏ chặng đường – Vững bước mục tiêu**.

## Trạng thái

Bộ khung Flutter, phát triển trực tiếp trên **Linux hoặc web/Firefox**; vẫn giữ
project Android/iOS cho phát triển mobile. Đã có Riverpod, go_router, giao diện khởi động tiếng Việt,
theme cơ bản, Supabase SDK và widget test. App khởi tạo Supabase trước khi mở
giao diện, dùng client chung qua Riverpod. Các màn hình nghiệp vụ M01–M50,
đăng nhập và đồng bộ offline chưa triển khai. Trang `/` hiện là trang chào,
chưa phải dashboard M05 hoàn chỉnh.

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
Trang chào chưa yêu cầu đăng nhập và chưa tải dữ liệu công việc.

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
│   └── features/home/        # Trang chào hiện có
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
- Chưa nạp font Inter hoặc asset thương hiệu. Thêm file có giấy phép phù hợp
  vào `assets/`, rồi khai báo trong `pubspec.yaml` theo [hướng dẫn](assets/README.md).
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
