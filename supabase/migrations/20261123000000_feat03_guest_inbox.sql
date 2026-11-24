-- FEAT-03: hỗ trợ phiên khách khi chưa triển khai màn đăng nhập/đăng ký.
-- Sau khi chạy: bật Authentication > Sign In / Providers > Anonymous Sign-ins.
-- Không xóa dữ liệu, không tạo seed và không nới lỏng RLS hiện có.
BEGIN;

-- Trigger handle_new_user ghi NEW.email; khách ẩn danh không có email.
ALTER TABLE public.profiles ALTER COLUMN email DROP NOT NULL;

-- Anonymous Sign-ins nhận role authenticated, không phải role anon.
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT ON TABLE public.tasks TO authenticated;

COMMIT;

-- Kết quả mong đợi: true, true, true.
SELECT
  has_table_privilege('authenticated', 'public.tasks', 'SELECT') AS can_select,
  has_table_privilege('authenticated', 'public.tasks', 'INSERT') AS can_insert,
  relrowsecurity AS rls_enabled
FROM pg_class
WHERE oid = 'public.tasks'::regclass;
