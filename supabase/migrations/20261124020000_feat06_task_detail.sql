-- FEAT-06 / M13: thực thi chi tiết công việc, cập nhật bước nhỏ và thêm bước nhỏ (tối đa 5 bước).
-- Chạy toàn bộ file trong Supabase SQL Editor trước khi dùng M13 trên dữ liệu thật.
-- Không tạo dữ liệu mẫu; giữ nguyên chính sách RLS hiện có theo auth.uid().
BEGIN;

GRANT USAGE ON SCHEMA public TO authenticated;

-- Cho phép phiên khách / người dùng đọc dự án, công việc và bước nhỏ của chính mình.
GRANT SELECT ON TABLE
  public.projects,
  public.tasks,
  public.subtasks
TO authenticated;

-- Cho phép thêm mới và cập nhật trạng thái hoàn thành của bước nhỏ (ràng buộc 1..5 & RLS vẫn áp dụng).
GRANT INSERT, UPDATE ON TABLE public.subtasks TO authenticated;

-- Cho phép trigger recalculate_task_progress() và thao tác hoàn thành/mở lại cập nhật tiến độ & trạng thái task.
GRANT UPDATE (status, progress_percentage, updated_at)
  ON TABLE public.tasks TO authenticated;

COMMIT;

-- Kết quả mong đợi: true, true, true, true.
SELECT
  has_table_privilege('authenticated', 'public.subtasks', 'INSERT') AS can_insert_subtask,
  has_table_privilege('authenticated', 'public.subtasks', 'UPDATE') AS can_update_subtask,
  has_column_privilege('authenticated', 'public.tasks', 'progress_percentage', 'UPDATE') AS can_update_progress,
  relrowsecurity AS subtasks_rls_enabled
FROM pg_class
WHERE oid = 'public.subtasks'::regclass;
