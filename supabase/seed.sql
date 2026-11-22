-- ==============================================================================
-- DỮ LIỆU MẪU THỬ NGHIỆM (SEED DATA) CHO CHẶNG APP
-- Lưu ý: Chỉ chạy file này sau khi bạn đã đăng ký ít nhất 1 tài khoản trên app
-- và thay thế 'YOUR_USER_UUID_HERE' bằng UUID thật từ auth.users.
-- ==============================================================================

DO $$
DECLARE
    test_user_id UUID;
    project_ielts_id UUID;
    project_thesis_id UUID;
    task_ielts_reading_id UUID;
    goal_words_id UUID;
    habit_read_id UUID;
BEGIN
    -- Lấy ID của user đầu tiên trong auth.users để test (nếu có)
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;

    IF test_user_id IS NOT NULL THEN
        -- 1. Thêm Dự án mẫu
        INSERT INTO public.projects (id, user_id, name, description, color_hex, deadline)
        VALUES 
            (gen_random_uuid(), test_user_id, 'Luyện thi IELTS 7.5', 'Mục tiêu đạt chứng chỉ trong quý 1', '#345D83', NOW() + INTERVAL '60 days')
        RETURNING id INTO project_ielts_id;

        INSERT INTO public.projects (id, user_id, name, description, color_hex, deadline)
        VALUES 
            (gen_random_uuid(), test_user_id, 'Đồ án UI/UX Mobile', 'Đồ án tốt nghiệp ứng dụng Chặng', '#DF967E', NOW() + INTERVAL '30 days')
        RETURNING id INTO project_thesis_id;

        -- 2. Thêm Công việc mẫu & 5 Bước nhỏ
        INSERT INTO public.tasks (id, user_id, project_id, title, priority, due_date, scheduled_date, status, progress_percentage)
        VALUES 
            (gen_random_uuid(), test_user_id, project_ielts_id, 'Luyện đề Reading Cam 18 - Test 1', 'HIGH', NOW() + INTERVAL '2 days', CURRENT_DATE, 'IN_PROGRESS', 40)
        RETURNING id INTO task_ielts_reading_id;

        -- 5 bước nhỏ của công việc
        INSERT INTO public.subtasks (task_id, title, order_index, estimated_minutes, is_completed)
        VALUES 
            (task_ielts_reading_id, 'Đọc Passage 1 & Làm câu 1-13', 1, 20, TRUE),
            (task_ielts_reading_id, 'Đọc Passage 2 & Làm câu 14-26', 2, 20, TRUE),
            (task_ielts_reading_id, 'Đọc Passage 3 & Làm câu 27-40', 3, 25, FALSE),
            (task_ielts_reading_id, 'Tra cứu từ vựng khó Passage 1 & 2', 4, 15, FALSE),
            (task_ielts_reading_id, 'Phân tích lỗi sai & Ghi chú vào sổ tay', 5, 20, FALSE);

        -- 3. Thêm Mục tiêu định lượng mẫu
        INSERT INTO public.goals (id, user_id, title, target_value, current_value, unit, deadline, status)
        VALUES 
            (gen_random_uuid(), test_user_id, 'Học 100 từ vựng chuyên ngành', 100, 40, 'từ', NOW() + INTERVAL '14 days', 'ACTIVE')
        RETURNING id INTO goal_words_id;

        -- Nhật ký tích lũy từ vựng mẫu
        INSERT INTO public.goal_progress_logs (goal_id, delta_value, value_after, note)
        VALUES 
            (goal_words_id, 20, 20, 'Học ngày đầu tiên'),
            (goal_words_id, 20, 40, 'Học buổi sáng thứ 2');

        -- 4. Thêm Thói quen mẫu
        INSERT INTO public.habits (id, user_id, linked_goal_id, title, repeat_days, duration_minutes, current_streak, longest_streak)
        VALUES 
            (gen_random_uuid(), test_user_id, goal_words_id, 'Đọc sách tiếng Anh 15 phút', '[1,2,3,4,5,6,7]'::jsonb, 15, 7, 14)
        RETURNING id INTO habit_read_id;

        -- Điểm danh thói quen hôm nay
        INSERT INTO public.habit_logs (habit_id, user_id, log_date, status)
        VALUES (habit_read_id, test_user_id, CURRENT_DATE, 'COMPLETED');

        RAISE NOTICE 'Đã tạo thành công dữ liệu mẫu cho User: %', test_user_id;
    ELSE
        RAISE NOTICE 'Chưa có user nào trong auth.users. Vui lòng đăng ký tài khoản trước!';
    END IF;
END $$;
