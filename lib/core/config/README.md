# Cấu hình ứng dụng

`supabase_config.dart` chứa Project URL và publishable key của Chặng App.
`bootstrap.dart` dùng cấu hình này để khởi tạo Supabase trước `runApp`.
Đây là cấu hình public cho client; quyền dữ liệu phải được kiểm soát bằng
Supabase Auth và RLS. Xem [API keys](https://supabase.com/docs/guides/api/api-keys).

App đọc `SUPABASE_URL` và `SUPABASE_PUBLISHABLE_KEY` bằng
`String.fromEnvironment`, dùng giá trị mặc định nếu không truyền `--dart-define`.
Khi đổi project, ghi đè cả hai giá trị:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key
```

App không tự đọc file `.env`. Dữ liệu truyền vào Flutter có thể trích xuất từ
binary; `--dart-define` không phải cách bảo vệ secret.

`.env.example` ở gốc chứa cả biến client và biến dành cho backend/MCP.
Không dùng toàn bộ file này với `--dart-define-from-file`, không đưa `.env` vào
Flutter assets. `service_role`, mật khẩu database và access token quản trị chỉ
được đọc phía backend/MCP. Không log giá trị khóa.
