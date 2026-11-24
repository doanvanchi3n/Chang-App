-- Cho phép lưu ngày thực hiện của việc đã chọn từ Inbox.
-- Chỉ cần bổ sung nếu authenticated chưa có quyền UPDATE trên cột này.
-- RLS hiện có tiếp tục giới hạn cập nhật theo chủ sở hữu.
BEGIN;
GRANT UPDATE (scheduled_date) ON TABLE public.tasks TO authenticated;
COMMIT;
