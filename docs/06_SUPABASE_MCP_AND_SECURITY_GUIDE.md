# HƯỚNG DẪN KẾT NỐI SUPABASE MCP SERVER & NGUYÊN TẮC BẢO MẬT API
## DỰ ÁN ỨNG DỤNG CHẶNG (CHANG APP)

---

## PHẦN 1: TỔNG QUAN & VỊ TRÍ MÃ NGUỒN ĐÃ PULL VỀ

Hệ thống đã pull thành công toàn bộ mã nguồn của bộ công cụ **[supabase-mcp-server](https://github.com/alexander-zuev/supabase-mcp-server)** vào dự án:
- **Đường dẫn lưu trữ trong dự án:**  
  [`.agents/mcp/supabase-mcp-server/`](file:///home/vanchien/Project/Chang-app/.agents/mcp/supabase-mcp-server)

### Các công cụ (Tools) mà bộ MCP này cung cấp cho AI Agent:
1. **Database Tools:** Chạy truy vấn SQL an toàn, quản lý migrations, xem lược đồ bảng (`get_table_schema`, `get_tables`, `get_schemas`).
2. **Auth Admin SDK Tools:** Quản lý người dùng học sinh, phân quyền qua Supabase Auth Admin.
3. **Management API Tools:** Quản lý cài đặt dự án, cấu hình bucket storage, edge functions từ xa.
4. **Logs & Analytics Tools:** Tra cứu realtime logs, auth logs, postgres logs để chẩn đoán lỗi.
5. **Safety Tools:** Kiểm soát mức độ rủi ro của câu lệnh SQL (Safe / Write / Destructive) chống xóa nhầm dữ liệu.

---

## PHẦN 2: NGUYÊN TẮC BẢO MẬT SỐNG CÒN ĐỐI VỚI SUPABASE & API KEYS

Vì bạn đã nhấn mạnh: **"ưu tiên việc trong quá trình làm ấy, bảo mật là quan trọng đối với các API quan trọng"**, đây là các nguyên tắc bảo mật bắt buộc phải tuân thủ nghiêm ngặt:

### 2.1. Phân cấp 3 tầng khóa API trong Supabase

| Loại Khóa (Key) | Quyền hạn | Được phép lộ? | Nơi sử dụng an toàn |
| :--- | :--- | :---: | :--- |
| **`anon / public key`** | Giới hạn theo Row Level Security (RLS). Người dùng chỉ đọc/sửa được dữ liệu của chính mình. | **CÓ** | Nhúng trực tiếp vào mã nguồn **Flutter Mobile Client**. |
| **`service_role key`** | **TOÀN QUYỀN (SUPERADMIN)**: Bỏ qua (Bypass) 100% chính sách RLS. Có thể xóa sạch database, đọc mật khẩu hash và thông tin mọi người học. | **TUYỆT ĐỐI KHÔNG** | Chỉ dùng trên Server nội bộ, Supabase Edge Functions hoặc MCP Server chạy cục bộ trên máy lập trình viên. **CẤM NHÚNG VÀO FLUTTER APP!** |
| **`Database Password`** | Quyền root truy cập trực tiếp cổng PostgreSQL 5432/6543. | **TUYỆT ĐỐI KHÔNG** | Chỉ lưu trong file biến môi trường cục bộ hoặc connection string bảo mật. |
| **`Personal Access Token`** | Quản lý toàn bộ tổ chức (Organization) trên Supabase. | **TUYỆT ĐỐI KHÔNG** | Dùng để gọi Supabase Management API. |

### 2.2. Các biện pháp chống rò rỉ khóa đã được thiết lập sẵn trong Project:
1. **Hàng rào `.gitignore` nghiêm ngặt:** Đã thiết lập chặn tự động toàn bộ các file `.env`, `.env.*`, `*.secret`, `*service_role*`, và các thư mục `.venv`, `.git` con.
2. **Mẫu an toàn `.env.example`:** Đã tạo sẵn tại thư mục gốc [`.env.example`](file:///home/vanchien/Project/Chang-app/.env.example) chỉ chứa placeholder giả định, an toàn để chia sẻ với team.
### 2.2. Về dịch vụ bên thứ ba (thequery.dev):
> [!NOTE]
> Trang web `thequery.dev` là dịch vụ proxy bên thứ ba do tác giả cũ tích hợp, nhưng hiện tác giả **đã chính thức đóng cửa dịch vụ này** (gây ra lỗi `DNS_PROBE_FINISHED_NXDOMAIN` khi bạn truy cập).
> - **Bạn KHÔNG CẦN và KHÔNG NÊN tìm kiếm `QUERY_API_KEY` nữa.**
> - Tôi đã gỡ bỏ hoàn toàn việc gọi sang `thequery.dev` trong mã nguồn local của dự án. Giờ đây MCP kết nối **100% TRỰC TIẾP và BẢO MẬT NỘI BỘ** tới Supabase của bạn, không gửi bất kỳ truy vấn nào ra dịch vụ trung gian bên ngoài!

---

## PHẦN 3: HƯỚNG DẪN TỪNG BƯỚC LẤY THÔNG SỐ TỪ WEBSITE SUPABASE

Đăng nhập vào tài khoản Supabase của bạn tại: **[https://supabase.com/dashboard](https://supabase.com/dashboard)**

### Bước 1: Lấy Mã định danh Dự án (`SUPABASE_PROJECT_REF`) & Khu vực (`SUPABASE_REGION`)
1. Nhấp vào Dự án bạn đã tạo trên Dashboard.
2. Nhìn lên thanh địa chỉ trình duyệt, URL sẽ có dạng:
   `https://supabase.com/dashboard/project/abcdefghijklmnopqrst`
   -> Phần chuỗi ký tự sau `/project/` chính là **`SUPABASE_PROJECT_REF`** (Ví dụ: `abcdefghijklmnopqrst`).
3. Vào menu bên trái: **Project Settings** -> **General**.
   - Tại mục **Region**: Xem vùng máy chủ lưu trữ (Nếu bạn chọn Singapore thì mã là `ap-southeast-1`).
   > [!IMPORTANT]
   > Tham số `SUPABASE_REGION` cực kỳ quan trọng! Nếu điền sai region, MCP server sẽ báo lỗi: *"Tenant or user not found"*.

### Bước 2: Lấy Mật khẩu Cơ sở dữ liệu (`SUPABASE_DB_PASSWORD`)
- Đây là mật khẩu bạn đã tự đặt khi bấm nút "New Project".
- Nếu bạn quên mật khẩu:
  1. Vào **Project Settings** -> **Database**.
  2. Cuộn xuống phần **Database password** và bấm **Reset database password** để đặt mật khẩu mới an toàn.

### Bước 3: Lấy các khóa API (`SUPABASE_ANON_KEY` & `SUPABASE_SERVICE_ROLE_KEY`)
1. Vào **Project Settings** -> **API**.
2. Tại mục **Project API keys**:
   - `anon` `public`: Sao chép để đưa vào ứng dụng Flutter.
   - `service_role` `secret`: Bấm nút con mắt để hiện và sao chép. **Khóa này chỉ dùng cho MCP Server!**

### Bước 4: Lấy Access Token cá nhân (`SUPABASE_ACCESS_TOKEN`)
1. Nhấp vào Avatar góc trên cùng bên phải -> Chọn **Account Preferences** (hoặc truy cập thẳng [https://supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens)).
2. Nhấp **Generate New Token**.
3. Đặt tên (ví dụ: `chang-app-mcp`), chọn quyền và bấm Tạo -> Sao chép chuỗi token có tiền tố `sbp_...`.

### Bước 5: Lấy API Key từ thequery.dev (Dành cho bộ alexander-zuev)
1. Truy cập **[https://thequery.dev](https://thequery.dev)**.
2. Đăng ký/Đăng nhập miễn phí và tạo một **Query API Key** (dạng `query_...`).

---

## PHẦN 4: HƯỚNG DẪN CẤU HÌNH KẾT NỐI MCP AN TOÀN

Có 2 phương án cấu hình tùy theo công cụ bạn sử dụng:

### PHƯƠNG ÁN 1: Cấu hình qua File Biến môi trường Hệ thống (Khuyên dùng - An toàn nhất)
Tạo file cấu hình nằm **bên ngoài thư mục dự án Git** để loại bỏ 100% rủi ro vô tình commit khóa lên GitHub:

1. Chạy lệnh tạo thư mục cấu hình trên máy của bạn:
   ```bash
   mkdir -p ~/.config/supabase-mcp
   ```
2. Tạo file `~/.config/supabase-mcp/.env`:
   ```env
   # API Key từ thequery.dev
   QUERY_API_KEY=query_xxxxxxxxxxxxxxxxxxxx

   # Thông tin dự án Supabase
   SUPABASE_PROJECT_REF=abcdefghijklmnopqrst
   SUPABASE_DB_PASSWORD=MatKhauDatabaseCuaBan123!@#
   SUPABASE_REGION=ap-southeast-1

   # Khóa quản trị (Chỉ để tại đây, không đưa vào code)
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOi...
   SUPABASE_ACCESS_TOKEN=sbp_xxxxxxxxxxxxxxxxxxxx
   ```

3. Cài đặt package server qua `uv` hoặc `pipx` (hoặc chạy từ source):
   ```bash
   pipx install supabase-mcp-server
   # hoặc dùng uv:
   # uv tool install supabase-mcp-server
   ```

---

### PHƯƠNG ÁN 2: Cấu hình Trực tiếp vào Client MCP (Antigravity / Cursor / Claude Desktop)

#### 1. Cấu hình cho Antigravity IDE
Trong dự án, tạo file `.agents/mcp_config.json` (đã được bảo vệ bởi `.gitignore` nếu có chứa env):

```json
{
  "mcpServers": {
    "supabase-query": {
      "command": "uv",
      "args": [
        "run",
        "--with",
        "supabase-mcp-server",
        "supabase-mcp-server"
      ],
      "env": {
        "QUERY_API_KEY": "query_your_key_here",
        "SUPABASE_PROJECT_REF": "your_project_ref",
        "SUPABASE_DB_PASSWORD": "your_db_password",
        "SUPABASE_REGION": "ap-southeast-1",
        "SUPABASE_SERVICE_ROLE_KEY": "your_service_role_key",
        "SUPABASE_ACCESS_TOKEN": "your_access_token"
      }
    }
  }
}
```

#### 2. Cấu hình cho Cursor IDE
Vào **Settings** -> **Features** -> **MCP Servers** -> **Add New Server**:
- **Name:** `supabase`
- **Type:** `command`
- **Command:**
  ```bash
  uvx supabase-mcp-server
  ```
- Hoặc truyền trực tiếp biến môi trường trong file cấu hình Cursor `~/.cursor/mcp.json`.

---

## PHẦN 5: KIỂM TRA KẾT NỐI & XÁC THỰC THÀNH CÔNG

Sau khi cấu hình xong và khởi động MCP server:
1. Bạn sẽ thấy biểu tượng đèn xanh (Green dot) hiển thị cạnh server `supabase-query`.
2. Danh sách các công cụ khả dụng xuất hiện:
   - `get_tables`: Liệt kê các bảng hiện có.
   - `execute_query`: Thực thi câu lệnh SQL đọc/ghi có kiểm duyệt rủi ro.
   - `get_table_schema`: Xem chi tiết cấu trúc cột và khóa ngoại.
3. Khi bạn yêu cầu Agent: *"Hãy kiểm tra danh sách bảng trong database Supabase của tôi"*, Agent sẽ tự động gọi tool `get_tables` để đối chiếu với mô hình 15 bảng trong tài liệu [03_DATABASE_ERD_DESIGN.md](file:///home/vanchien/Project/Chang-app/docs/03_DATABASE_ERD_DESIGN.md).

---
*Tài liệu hướng dẫn bảo mật chuẩn hóa cho Hệ sinh thái Chặng App.*
