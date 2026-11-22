-- ==============================================================================
-- CHẶNG APP - SEED DỮ LIỆU MẪU CHUẨN GIAO DIỆN M05 (HOME DASHBOARD)
-- Chạy script này trực tiếp trên Supabase Dashboard -> SQL Editor
-- Script tự động:
--   1. Tìm user hiện có trong auth.users, hoặc tạo user mẫu 'chien@chang.app'
--   2. Tạo Profile "Chiến", Tùy chọn Onboarding hoàn tất
--   3. Tạo các Dự án: UI/UX Mobile, Tiếng Anh TOEIC, Cơ sở dữ liệu
--   4. Tạo 4 công việc ưu tiên & các bước nhỏ (Subtasks 5 bước) đúng theo UI M05:
--        - Phác thảo luồng đăng ký (UI/UX - 2/5 bước hoàn thành)
--        - Ôn 15 từ TOEIC (Đã lên lịch 19:00 hôm nay)
--        - Đọc tài liệu CSDL (Chưa lên lịch)
--        - Bài tập Stack (Quá hạn hôm qua - mục Rà soát cuối ngày)
--   5. Tạo Sự kiện lịch: 19:00 - 19:25 · Tiếng Anh (Phiên sắp tới)
--   6. Tạo Mục tiêu tuần & Thói quen: 3/4 buổi hoàn thành
-- ==============================================================================

DO $$
DECLARE
    target_user_id UUID;
    project_uiux_id UUID;
    project_english_id UUID;
    project_db_id UUID;
    task_uiux_id UUID;
    task_english_id UUID;
    task_db_id UUID;
    task_stack_id UUID;
    goal_week_id UUID;
BEGIN
    -- 1. LẤY HOẶC TẠO USER TEST
    SELECT id INTO target_user_id FROM auth.users ORDER BY created_at ASC LIMIT 1;

    IF target_user_id IS NULL THEN
        target_user_id := gen_random_uuid();
        INSERT INTO auth.users (
            id,
            instance_id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at
        ) VALUES (
            target_user_id,
            '00000000-0000-0000-0000-000000000000',
            'authenticated',
            'authenticated',
            'chien@chang.app',
            crypt('Chien123456!', gen_salt('bf')),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Chiến"}',
            NOW(),
            NOW()
        );
        RAISE NOTICE 'Đã tạo tài khoản mẫu: chien@chang.app (ID: %)', target_user_id;
    ELSE
        RAISE NOTICE 'Sử dụng tài khoản có sẵn trong auth.users: %', target_user_id;
    END IF;

    -- 2. TẠO PROFILE & TÙY CHỌN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (target_user_id, 'chien@chang.app', 'Chiến')
    ON CONFLICT (id) DO UPDATE 
    SET full_name = 'Chiến', updated_at = NOW();

    INSERT INTO public.user_preferences (
        user_id,
        daily_target_minutes,
        preferred_morning,
        preferred_evening,
        mascot_enabled,
        has_completed_onboarding
    ) VALUES (
        target_user_id,
        60,
        TRUE,
        TRUE,
        TRUE,
        TRUE
    )
    ON CONFLICT (user_id) DO UPDATE 
    SET has_completed_onboarding = TRUE, updated_at = NOW();

    -- 3. TẠO DỰ ÁN (PROJECTS)
    INSERT INTO public.projects (id, user_id, name, description, color_hex, deadline)
    VALUES 
        (gen_random_uuid(), target_user_id, 'UI/UX Mobile App', 'Thiết kế ứng dụng Chặng', '#1E67C6', NOW() + INTERVAL '30 days')
    RETURNING id INTO project_uiux_id;

    INSERT INTO public.projects (id, user_id, name, description, color_hex, deadline)
    VALUES 
        (gen_random_uuid(), target_user_id, 'Tiếng Anh TOEIC', 'Mục tiêu chứng chỉ 750+', '#FAC858', NOW() + INTERVAL '45 days')
    RETURNING id INTO project_english_id;

    INSERT INTO public.projects (id, user_id, name, description, color_hex, deadline)
    VALUES 
        (gen_random_uuid(), target_user_id, 'Hệ Quản trị CSDL', 'Môn học chuyên ngành Công nghệ thông tin', '#2763A8', NOW() + INTERVAL '60 days')
    RETURNING id INTO project_db_id;

    -- 4. TẠO CÁC CÔNG VIỆC ƯU TIÊN THEO GIAO DIỆN M05

    -- Task 01: Phác thảo luồng đăng ký (Active - 2/5 bước)
    INSERT INTO public.tasks (
        id, user_id, project_id, title, priority, due_date, scheduled_date, status, progress_percentage
    ) VALUES (
        gen_random_uuid(), target_user_id, project_uiux_id,
        'Phác thảo luồng đăng ký', 'HIGH',
        CURRENT_DATE + 1, CURRENT_DATE, 'IN_PROGRESS', 40
    ) RETURNING id INTO task_uiux_id;

    -- 5 bước nhỏ của Task 01 (2 bước xong, 3 bước chưa)
    INSERT INTO public.subtasks (task_id, title, order_index, estimated_minutes, is_completed, completed_at)
    VALUES 
        (task_uiux_id, 'Khảo sát luồng Onboarding tham khảo', 1, 20, TRUE, NOW() - INTERVAL '2 hours'),
        (task_uiux_id, 'Vẽ sơ đồ luồng thông tin (Wireframe)', 2, 25, TRUE, NOW() - INTERVAL '1 hour'),
        (task_uiux_id, 'Thiết kế giao diện High-fidelity M05', 3, 30, FALSE, NULL),
        (task_uiux_id, 'Thiết lập các trạng thái tương tác và Error', 4, 20, FALSE, NULL),
        (task_uiux_id, 'Đóng gói Prototype và kiểm thử trên máy', 5, 25, FALSE, NULL);

    -- Task 02: Ôn 15 từ TOEIC (Đã lên lịch 19:00)
    INSERT INTO public.tasks (
        id, user_id, project_id, title, priority, due_date, scheduled_date, status, progress_percentage
    ) VALUES (
        gen_random_uuid(), target_user_id, project_english_id,
        'Ôn 15 từ TOEIC', 'MEDIUM',
        CURRENT_DATE, CURRENT_DATE, 'TODO', 0
    ) RETURNING id INTO task_english_id;

    INSERT INTO public.subtasks (task_id, title, order_index, estimated_minutes, is_completed)
    VALUES 
        (task_english_id, 'Ôn 15 flashcards từ vựng chủ đề Office', 1, 15, FALSE),
        (task_english_id, 'Luyện tập làm bài tập điền từ ví dụ', 2, 10, FALSE);

    -- Task 03: Đọc tài liệu CSDL (Chưa lên lịch)
    INSERT INTO public.tasks (
        id, user_id, project_id, title, priority, due_date, scheduled_date, status, progress_percentage
    ) VALUES (
        gen_random_uuid(), target_user_id, project_db_id,
        'Đọc tài liệu CSDL', 'MEDIUM',
        CURRENT_DATE + 3, NULL, 'TODO', 0
    ) RETURNING id INTO task_db_id;

    INSERT INTO public.subtasks (task_id, title, order_index, estimated_minutes, is_completed)
    VALUES 
        (task_db_id, 'Đọc chương 3: Chuẩn hóa cơ sở dữ liệu 1NF - 3NF', 1, 30, FALSE);

    -- Task 04 (Dành cho thẻ Rà soát): Bài tập Stack (Quá hạn hôm qua)
    INSERT INTO public.tasks (
        id, user_id, project_id, title, priority, due_date, scheduled_date, status, progress_percentage
    ) VALUES (
        gen_random_uuid(), target_user_id, project_db_id,
        'Bài tập Stack', 'HIGH',
        CURRENT_DATE - 1, CURRENT_DATE - 1, 'TODO', 0
    ) RETURNING id INTO task_stack_id;

    -- 5. TẠO LỊCH HẸN: PHIÊN SẮP TỚI 19:00 – 19:25 (M05 UPCOMING CARD)
    INSERT INTO public.schedule_events (
        user_id, task_id, title, event_type, start_time, end_time, reminder_minutes
    ) VALUES (
        target_user_id,
        task_english_id,
        '19:00 – 19:25 · Tiếng Anh: Ôn 15 từ TOEIC',
        'STUDY',
        (CURRENT_DATE + TIME '19:00:00')::timestamptz,
        (CURRENT_DATE + TIME '19:25:00')::timestamptz,
        15
    );

    -- 6. TẠO MỤC TIÊU TUẦN (3/4 BUỔI HOÀN THÀNH)
    INSERT INTO public.goals (
        user_id, title, target_value, current_value, unit, deadline, status
    ) VALUES (
        target_user_id,
        'Nhịp học tuần này: Hoàn thành 4 buổi',
        4, 3, 'buổi',
        CURRENT_DATE + 4, 'ACTIVE'
    ) RETURNING id INTO goal_week_id;

    -- 7. TẠO THÓI QUEN (HABIT)
    INSERT INTO public.habits (
        user_id, linked_goal_id, title, repeat_days, duration_minutes, current_streak, longest_streak
    ) VALUES (
        target_user_id,
        goal_week_id,
        'Học tập trung mỗi ngày',
        '[1,2,3,4,5,6,7]'::jsonb,
        25,
        3,
        7
    );

    RAISE NOTICE '=== SEED DỮ LIỆU THÀNH CÔNG CHO CHẶNG APP (M05) ===';
END $$;
