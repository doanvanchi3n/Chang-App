-- M07: chỉ đọc thông báo của chính mình và cập nhật trạng thái đã đọc.
-- Chạy sau schema gốc; không seed và không thay đổi RLS hiện có.
BEGIN;
GRANT SELECT ON public.notifications TO authenticated;
GRANT UPDATE(is_read) ON public.notifications TO authenticated;
CREATE INDEX IF NOT EXISTS notifications_user_created_idx
  ON public.notifications(user_id,created_at DESC,id);
NOTIFY pgrst, 'reload schema';
COMMIT;
