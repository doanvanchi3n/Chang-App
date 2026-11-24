-- FEAT-02: đọc dữ liệu Dashboard bằng phiên khách hoặc tài khoản hiện tại.
-- RLS hiện có của từng bảng vẫn giới hạn dữ liệu theo auth.uid().
-- Không tạo dữ liệu mẫu, không cấp quyền ghi, không thay đổi policy.
BEGIN;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON TABLE
  public.profiles,
  public.user_preferences,
  public.tasks,
  public.projects,
  public.subtasks,
  public.schedule_events,
  public.focus_sessions
TO authenticated;
COMMIT;
