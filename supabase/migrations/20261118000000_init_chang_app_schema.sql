-- ==============================================================================
-- CHẶNG APP - DATABASE MIGRATION SCRIPT (SUPABASE / POSTGRESQL 15+)
-- Phiên bản: 1.0.0
-- Mô tả: Khởi tạo toàn bộ 15 bảng nghiệp vụ, triggers tự động, RLS bảo mật và Realtime
-- ==============================================================================

-- 1. BẬT CÁC EXTENSION CẦN THIẾT
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. ĐỊNH NGHĨA CÁC KIỂU ENUM
-- ==============================================================================
CREATE TYPE task_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH');
CREATE TYPE task_status AS ENUM ('TODO', 'IN_PROGRESS', 'COMPLETED');
CREATE TYPE session_status AS ENUM ('COMPLETED', 'EARLY_STOPPED', 'CANCELLED');
CREATE TYPE ambient_sound_type AS ENUM ('RAIN', 'CAFE', 'OCEAN', 'FOREST', 'SILENT');
CREATE TYPE schedule_event_type AS ENUM ('CLASS', 'STUDY', 'EXAM', 'PERSONAL');
CREATE TYPE goal_status_type AS ENUM ('ACTIVE', 'COMPLETED', 'PAUSED', 'ARCHIVED');
CREATE TYPE habit_status_type AS ENUM ('ACTIVE', 'ARCHIVED');
CREATE TYPE ai_proposal_status_type AS ENUM ('DRAFT', 'APPLIED', 'REVERTED', 'DISCARDED');
CREATE TYPE notification_type AS ENUM ('REMINDER_TASK', 'SCHEDULE_CONFLICT', 'MILESTONE', 'AI_PLAN', 'SYSTEM');

-- ==============================================================================
-- 3. CÁC BẢNG QUẢN LÝ NGƯỜI DÙNG & HỒ SƠ
-- ==============================================================================

-- 3.1. Bảng Hồ sơ người học (Liên kết trực tiếp với auth.users của Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 3.2. Bảng Tùy chọn & Cài đặt người dùng (User Preferences)
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_target_minutes INTEGER DEFAULT 60 NOT NULL,
    preferred_morning BOOLEAN DEFAULT TRUE NOT NULL,   -- 06:00 - 09:00
    preferred_afternoon BOOLEAN DEFAULT FALSE NOT NULL, -- 14:00 - 17:00
    preferred_evening BOOLEAN DEFAULT TRUE NOT NULL,   -- 19:30 - 22:30
    quiet_hours_start TIME DEFAULT '22:30' NOT NULL,
    quiet_hours_end TIME DEFAULT '06:30' NOT NULL,
    mascot_enabled BOOLEAN DEFAULT TRUE NOT NULL,
    reduced_motion BOOLEAN DEFAULT FALSE NOT NULL,
    has_completed_onboarding BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ==============================================================================
-- 4. QUẢN LÝ DỰ ÁN, CÔNG VIỆC & QUY TẮC 5 BƯỚC NHỎ
-- ==============================================================================

-- 4.1. Bảng Dự án học tập (Projects)
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    color_hex VARCHAR(7) DEFAULT '#345D83' NOT NULL,
    deadline TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 4.2. Bảng Công việc chính (Tasks)
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority task_priority DEFAULT 'MEDIUM' NOT NULL,
    due_date TIMESTAMPTZ,
    scheduled_date DATE, -- NULL biểu thị công việc đang nằm trong Hộp việc chưa lên lịch (Inbox)
    status task_status DEFAULT 'TODO' NOT NULL,
    is_archived BOOLEAN DEFAULT FALSE NOT NULL,
    progress_percentage INTEGER DEFAULT 0 NOT NULL CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 4.3. Bảng Bước nhỏ (Subtasks) - RÀNG BUỘC TỐI ĐA 5 BƯỚC (5-Step Micro-Task Rule)
CREATE TABLE IF NOT EXISTS public.subtasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    order_index INTEGER NOT NULL CHECK (order_index >= 1 AND order_index <= 5),
    estimated_minutes INTEGER DEFAULT 25 NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE NOT NULL,
    completed_at TIMESTAMPTZ,
    CONSTRAINT unique_task_subtask_order UNIQUE (task_id, order_index)
);

-- ==============================================================================
-- 5. PHIÊN TẬP TRUNG POMODORO (FOCUS SESSIONS) & THỜI GIAN THỰC TẾ
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.focus_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
    subtask_id UUID REFERENCES public.subtasks(id) ON DELETE SET NULL,
    target_duration_seconds INTEGER DEFAULT 1500 NOT NULL,
    actual_duration_seconds INTEGER DEFAULT 0 NOT NULL, -- Ghi nhận số giây thực tế, không làm tròn
    status session_status DEFAULT 'COMPLETED' NOT NULL,
    ambient_sound ambient_sound_type DEFAULT 'SILENT' NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ==============================================================================
-- 6. LỊCH BIỂU (SCHEDULE EVENTS)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.schedule_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
    subtask_id UUID REFERENCES public.subtasks(id) ON DELETE SET NULL,
    ai_proposal_id UUID, -- Khóa ngoại trỏ đến đề xuất AI nếu sự kiện do AI tạo
    title VARCHAR(200) NOT NULL,
    event_type schedule_event_type DEFAULT 'STUDY' NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    recurrence_rule VARCHAR(50) DEFAULT 'NONE' NOT NULL,
    reminder_minutes INTEGER DEFAULT 15 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT check_event_time CHECK (end_time > start_time)
);

-- ==============================================================================
-- 7. MỤC TIÊU ĐỊNH LƯỢNG & NHẬT KÝ TIẾN ĐỘ
-- ==============================================================================

-- 7.1. Bảng Mục tiêu (Goals)
CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    target_value NUMERIC(10, 2) NOT NULL CHECK (target_value > 0),
    current_value NUMERIC(10, 2) DEFAULT 0 NOT NULL CHECK (current_value >= 0),
    unit VARCHAR(50) NOT NULL, -- 'từ', 'trang', 'giờ', 'đề thi'
    deadline TIMESTAMPTZ,
    status goal_status_type DEFAULT 'ACTIVE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 7.2. Bảng Lịch sử ghi nhận thêm tiến độ (+Delta Log)
CREATE TABLE IF NOT EXISTS public.goal_progress_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES public.goals(id) ON DELETE CASCADE,
    delta_value NUMERIC(10, 2) NOT NULL CHECK (delta_value > 0),
    value_after NUMERIC(10, 2) NOT NULL,
    note TEXT,
    logged_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ==============================================================================
-- 8. THÓI QUEN HÀNG NGÀY & ĐIỂM DANH STREAK
-- ==============================================================================

-- 8.1. Bảng Thói quen (Habits)
CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    linked_goal_id UUID REFERENCES public.goals(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    repeat_days JSONB DEFAULT '[1,2,3,4,5,6,7]'::jsonb NOT NULL, -- Mảng ngày trong tuần [1..7]
    duration_minutes INTEGER DEFAULT 15 NOT NULL,
    reminder_time TIME,
    current_streak INTEGER DEFAULT 0 NOT NULL,
    longest_streak INTEGER DEFAULT 0 NOT NULL,
    status habit_status_type DEFAULT 'ACTIVE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 8.2. Bảng Nhật ký điểm danh thói quen (Habit Logs)
CREATE TABLE IF NOT EXISTS public.habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'COMPLETED' NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_habit_daily_log UNIQUE (habit_id, log_date)
);

-- ==============================================================================
-- 9. TRỢ LÝ AI LẬP KẾ HOẠCH & CHỐT AN TOÀN HOÀN TÁC (ROLLBACK)
-- ==============================================================================

-- 9.1. Bảng Đề xuất lập lịch AI (AI Plan Proposals)
CREATE TABLE IF NOT EXISTS public.ai_plan_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    original_prompt TEXT NOT NULL,
    status ai_proposal_status_type DEFAULT 'DRAFT' NOT NULL,
    applied_at TIMESTAMPTZ,
    reverted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Bổ sung ràng buộc khóa ngoại cho schedule_events trỏ đến ai_plan_proposals
ALTER TABLE public.schedule_events 
    ADD CONSTRAINT fk_schedule_ai_proposal 
    FOREIGN KEY (ai_proposal_id) 
    REFERENCES public.ai_plan_proposals(id) 
    ON DELETE SET NULL;

-- 9.2. Bảng Khối lịch nháp AI đề xuất (AI Proposal Items)
CREATE TABLE IF NOT EXISTS public.ai_proposal_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id UUID NOT NULL REFERENCES public.ai_plan_proposals(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    subtask_id UUID REFERENCES public.subtasks(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    reasoning TEXT,
    is_accepted BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT check_proposal_time CHECK (end_time > start_time)
);

-- ==============================================================================
-- 10. THÔNG BÁO & NHẬT KÝ RÀ SOÁT CUỐI NGÀY
-- ==============================================================================

-- 10.1. Bảng Thông báo (Notifications)
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    body TEXT NOT NULL,
    type notification_type DEFAULT 'SYSTEM' NOT NULL,
    reference_id UUID,
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    scheduled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 10.2. Bảng Nhật ký rà soát cuối ngày (Day Review Logs)
CREATE TABLE IF NOT EXISTS public.day_review_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    review_date DATE NOT NULL,
    completed_tasks_count INTEGER DEFAULT 0 NOT NULL,
    rolled_over_count INTEGER DEFAULT 0 NOT NULL,
    return_to_inbox_count INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_user_daily_review UNIQUE (user_id, review_date)
);

-- ==============================================================================
-- 11. HÀM & TRIGGER TỰ ĐỘNG HÓA THÔNG MINH
-- ==============================================================================

-- 11.1. Hàm tự động cập nhật timestamp updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Gắn trigger cho các bảng có trường updated_at
CREATE TRIGGER tr_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER tr_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER tr_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER tr_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER tr_schedule_events_updated_at BEFORE UPDATE ON public.schedule_events FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER tr_goals_updated_at BEFORE UPDATE ON public.goals FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER tr_habits_updated_at BEFORE UPDATE ON public.habits FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 11.2. Trigger tự động tính toán % tiến độ của Task khi Subtask thay đổi
CREATE OR REPLACE FUNCTION public.recalculate_task_progress()
RETURNS TRIGGER AS $$
DECLARE
    target_task_id UUID;
    total_subtasks INTEGER;
    completed_subtasks INTEGER;
    new_percentage INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_task_id := OLD.task_id;
    ELSE
        target_task_id := NEW.task_id;
    END IF;

    SELECT COUNT(*), COUNT(*) FILTER (WHERE is_completed = TRUE)
    INTO total_subtasks, completed_subtasks
    FROM public.subtasks
    WHERE task_id = target_task_id;

    IF total_subtasks = 0 THEN
        new_percentage := 0;
    ELSE
        new_percentage := ROUND((completed_subtasks::NUMERIC / total_subtasks::NUMERIC) * 100);
    END IF;

    UPDATE public.tasks
    SET progress_percentage = new_percentage,
        status = CASE 
            WHEN new_percentage = 100 THEN 'COMPLETED'::task_status
            WHEN new_percentage > 0 THEN 'IN_PROGRESS'::task_status
            ELSE 'TODO'::task_status
        END,
        updated_at = NOW()
    WHERE id = target_task_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_subtasks_progress_change
AFTER INSERT OR UPDATE OR DELETE ON public.subtasks
FOR EACH ROW EXECUTE FUNCTION public.recalculate_task_progress();

-- 11.3. Trigger tự động khởi tạo Hồ sơ (Profile) và Cài đặt khi có User đăng ký mới
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Tạo profile
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url'
    );

    -- Tạo user_preferences mặc định
    INSERT INTO public.user_preferences (user_id)
    VALUES (NEW.id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Gắn trigger lắng nghe auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 12. TỐI ƯU HÓA CHỈ MỤC TRUY VẤN (INDEXES)
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_tasks_scheduled_date ON public.tasks(user_id, scheduled_date, status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(user_id, due_date, status);
CREATE INDEX IF NOT EXISTS idx_subtasks_task_order ON public.subtasks(task_id, order_index);
CREATE INDEX IF NOT EXISTS idx_schedule_events_time ON public.schedule_events(user_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_schedule_ai_proposal ON public.schedule_events(ai_proposal_id);
CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON public.habit_logs(habit_id, log_date);
CREATE INDEX IF NOT EXISTS idx_focus_sessions_time ON public.focus_sessions(user_id, started_at);
CREATE INDEX IF NOT EXISTS idx_goal_logs_goal_id ON public.goal_progress_logs(goal_id, logged_at DESC);

-- ==============================================================================
-- 13. KÍCH HOẠT BẢO MẬT ROW LEVEL SECURITY (RLS) TRÊN TOÀN BỘ 15 BẢNG
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subtasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_progress_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_plan_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_proposal_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_review_logs ENABLE ROW LEVEL SECURITY;

-- 13.1. RLS Policies: Profiles & Preferences
CREATE POLICY "Users can view and edit own profile" 
ON public.profiles FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can manage own preferences" 
ON public.user_preferences FOR ALL USING (auth.uid() = user_id);

-- 13.2. RLS Policies: Projects & Tasks
CREATE POLICY "Users can manage own projects" 
ON public.projects FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own tasks" 
ON public.tasks FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage subtasks of own tasks" 
ON public.subtasks FOR ALL USING (
    EXISTS (SELECT 1 FROM public.tasks WHERE tasks.id = subtasks.task_id AND tasks.user_id = auth.uid())
);

-- 13.3. RLS Policies: Focus Sessions & Schedule Events
CREATE POLICY "Users can manage own focus sessions" 
ON public.focus_sessions FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own schedule events" 
ON public.schedule_events FOR ALL USING (auth.uid() = user_id);

-- 13.4. RLS Policies: Goals & Logs
CREATE POLICY "Users can manage own goals" 
ON public.goals FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage logs of own goals" 
ON public.goal_progress_logs FOR ALL USING (
    EXISTS (SELECT 1 FROM public.goals WHERE goals.id = goal_progress_logs.goal_id AND goals.user_id = auth.uid())
);

-- 13.5. RLS Policies: Habits & Logs
CREATE POLICY "Users can manage own habits" 
ON public.habits FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own habit logs" 
ON public.habit_logs FOR ALL USING (auth.uid() = user_id);

-- 13.6. RLS Policies: AI Proposals
CREATE POLICY "Users can manage own AI proposals" 
ON public.ai_plan_proposals FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage items of own AI proposals" 
ON public.ai_proposal_items FOR ALL USING (
    EXISTS (SELECT 1 FROM public.ai_plan_proposals WHERE ai_plan_proposals.id = ai_proposal_items.proposal_id AND ai_plan_proposals.user_id = auth.uid())
);

-- 13.7. RLS Policies: Notifications & Day Review
CREATE POLICY "Users can manage own notifications" 
ON public.notifications FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own day review logs" 
ON public.day_review_logs FOR ALL USING (auth.uid() = user_id);

-- ==============================================================================
-- 14. BẬT SUPABASE REALTIME ĐỒNG BỘ TỨC THÌ LÊN FLUTTER APP
-- ==============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.subtasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.schedule_events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.focus_sessions;

-- ==============================================================================
-- HOÀN TẤT THIẾT LẬP CƠ SỞ DỮ LIỆU CHẶNG APP
-- ==============================================================================
