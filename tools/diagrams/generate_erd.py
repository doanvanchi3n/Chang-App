from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

W, H = 2000, 1850
img = Image.new('RGB', (W, H), '#F9FBFD')
draw = ImageDraw.Draw(img)

# Fonts
font_title = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf', 30)
font_sub = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf', 16)
font_tbl_h = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf', 16)
font_field = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf', 14)
font_type = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf', 13)
font_badge = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf', 11)
font_legend = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf', 14)
font_conn = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf', 12)

# Header banner with Flutter & Supabase branding note
draw.rectangle([(0, 0), (W, 95)], fill='#345D83')
draw.text((50, 18), 'SƠ ĐỒ CƠ SỞ DỮ LIỆU THỰC THỂ LIÊN KẾT (ERD) - CHẶNG APP', fill='#FFFFFF', font=font_title)
draw.text((50, 58), 'CÔNG NGHỆ: FLUTTER (DART) + SUPABASE (POSTGRESQL) | BẢO MẬT RLS (ROW LEVEL SECURITY) | CHUẨN 3NF', fill='#E4EEF3', font=font_sub)

entities = [
    # Col 1 (x=50)
    {
        "name": "AUTH.USERS / PROFILES",
        "tag": "Supabase Auth + RLS",
        "x": 50, "y": 125, "w": 380,
        "rows": [
            ("id", "UUID (auth.uid)", "PK"),
            ("email", "VARCHAR(255)", "UK"),
            ("full_name", "VARCHAR(100)", ""),
            ("avatar_url", "TEXT (Storage)", ""),
            ("created_at", "TIMESTAMPTZ", ""),
            ("updated_at", "TIMESTAMPTZ", "")
        ]
    },
    {
        "name": "USER_PREFERENCES",
        "tag": "Cài đặt & RLS",
        "x": 50, "y": 420, "w": 380,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("daily_target_minutes", "INTEGER (60)", ""),
            ("preferred_morning", "BOOLEAN", ""),
            ("preferred_afternoon", "BOOLEAN", ""),
            ("preferred_evening", "BOOLEAN", ""),
            ("quiet_hours_start", "TIME (22:30)", ""),
            ("quiet_hours_end", "TIME (06:30)", ""),
            ("mascot_enabled", "BOOLEAN (true)", ""),
            ("reduced_motion", "BOOLEAN (false)", ""),
            ("has_completed_onboarding", "BOOLEAN", ""),
            ("updated_at", "TIMESTAMPTZ", "")
        ]
    },
    {
        "name": "DAY_REVIEW_LOGS",
        "tag": "Rà soát cuối ngày (RLS)",
        "x": 50, "y": 910, "w": 380,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("review_date", "DATE", ""),
            ("completed_tasks_count", "INTEGER", ""),
            ("rolled_over_count", "INTEGER", ""),
            ("return_to_inbox_count", "INTEGER", ""),
            ("created_at", "TIMESTAMPTZ", "")
        ]
    },
    {
        "name": "NOTIFICATIONS",
        "tag": "Supabase Realtime (RLS)",
        "x": 50, "y": 1240, "w": 380,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("title", "VARCHAR(150)", ""),
            ("body", "TEXT", ""),
            ("type", "VARCHAR(50)", ""),
            ("reference_id", "UUID", ""),
            ("is_read", "BOOLEAN (false)", ""),
            ("scheduled_at", "TIMESTAMPTZ", "")
        ]
    },

    # Col 2 (x=500)
    {
        "name": "PROJECTS",
        "tag": "Dự án học tập (RLS)",
        "x": 500, "y": 125, "w": 420,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("name", "VARCHAR(150)", ""),
            ("description", "TEXT", ""),
            ("color_hex", "VARCHAR(7)", ""),
            ("deadline", "TIMESTAMPTZ", ""),
            ("status", "VARCHAR(20)", ""),
            ("created_at", "TIMESTAMPTZ", "")
        ]
    },
    {
        "name": "TASKS",
        "tag": "Realtime Stream (RLS)",
        "x": 500, "y": 480, "w": 420,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("project_id", "UUID (NULL)", "FK"),
            ("title", "VARCHAR(200)", ""),
            ("description", "TEXT", ""),
            ("priority", "ENUM(L,M,H)", ""),
            ("due_date", "TIMESTAMPTZ", ""),
            ("scheduled_date", "DATE (NULL=Inbox)", ""),
            ("status", "ENUM(TODO,IP,DONE)", ""),
            ("is_archived", "BOOLEAN (false)", ""),
            ("progress_percentage", "INTEGER (0-100)", ""),
            ("created_at", "TIMESTAMPTZ", "")
        ]
    },
    {
        "name": "SUBTASKS",
        "tag": "Ràng buộc 1..5 bước (RLS)",
        "x": 500, "y": 1000, "w": 420,
        "rows": [
            ("id", "UUID", "PK"),
            ("task_id", "UUID (CASCADE)", "FK"),
            ("title", "VARCHAR(200)", ""),
            ("order_index", "INTEGER (CHECK 1..5)", ""),
            ("estimated_minutes", "INTEGER (25)", ""),
            ("is_completed", "BOOLEAN", ""),
            ("completed_at", "TIMESTAMPTZ", "")
        ]
    },
    {
        "name": "FOCUS_SESSIONS",
        "tag": "Thời gian thực tế (RLS)",
        "x": 500, "y": 1340, "w": 420,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("task_id", "UUID (NULL)", "FK"),
            ("subtask_id", "UUID (NULL)", "FK"),
            ("target_duration_seconds", "INTEGER", ""),
            ("actual_duration_seconds", "INTEGER (Thực tế)", ""),
            ("status", "VARCHAR(30)", ""),
            ("ambient_sound", "VARCHAR(30)", ""),
            ("started_at", "TIMESTAMPTZ", ""),
            ("ended_at", "TIMESTAMPTZ", "")
        ]
    },

    # Col 3 (x=990)
    {
        "name": "SCHEDULE_EVENTS",
        "tag": "Realtime Sync (RLS)",
        "x": 990, "y": 125, "w": 430,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("task_id", "UUID (NULL)", "FK"),
            ("subtask_id", "UUID (NULL)", "FK"),
            ("ai_proposal_id", "UUID (Rollback)", "FK"),
            ("title", "VARCHAR(200)", ""),
            ("event_type", "VARCHAR(50)", ""),
            ("start_time", "TIMESTAMPTZ", ""),
            ("end_time", "TIMESTAMPTZ", ""),
            ("recurrence_rule", "VARCHAR(50)", ""),
            ("reminder_minutes", "INTEGER (15)", "")
        ]
    },
    {
        "name": "AI_PLAN_PROPOSALS",
        "tag": "Edge Function Output (RLS)",
        "x": 990, "y": 640, "w": 430,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("original_prompt", "TEXT", ""),
            ("status", "ENUM(DRAFT,APPLIED,REV)", ""),
            ("applied_at", "TIMESTAMPTZ", ""),
            ("reverted_at", "TIMESTAMPTZ", ""),
            ("created_at", "TIMESTAMPTZ", "")
        ]
    },
    {
        "name": "AI_PROPOSAL_ITEMS",
        "tag": "Khối lịch nháp AI (RLS)",
        "x": 990, "y": 1010, "w": 430,
        "rows": [
            ("id", "UUID", "PK"),
            ("proposal_id", "UUID (CASCADE)", "FK"),
            ("task_id", "UUID", "FK"),
            ("subtask_id", "UUID (NULL)", "FK"),
            ("start_time", "TIMESTAMPTZ", ""),
            ("end_time", "TIMESTAMPTZ", ""),
            ("reasoning", "TEXT", ""),
            ("is_accepted", "BOOLEAN (true)", "")
        ]
    },

    # Col 4 (x=1490)
    {
        "name": "GOALS",
        "tag": "Mục tiêu định lượng (RLS)",
        "x": 1490, "y": 125, "w": 450,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("title", "VARCHAR(200)", ""),
            ("target_value", "NUMERIC (Số đích)", ""),
            ("current_value", "NUMERIC (Tích lũy)", ""),
            ("unit", "VARCHAR(50)", ""),
            ("deadline", "TIMESTAMPTZ", ""),
            ("status", "VARCHAR(30)", ""),
            ("created_at", "TIMESTAMPTZ", "")
        ]
    },
    {
        "name": "GOAL_PROGRESS_LOGS",
        "tag": "Lịch sử ghi nhận thêm (RLS)",
        "x": 1490, "y": 560, "w": 450,
        "rows": [
            ("id", "UUID", "PK"),
            ("goal_id", "UUID (CASCADE)", "FK"),
            ("delta_value", "NUMERIC (+Số gia)", ""),
            ("value_after", "NUMERIC", ""),
            ("note", "TEXT", ""),
            ("logged_at", "TIMESTAMPTZ", "")
        ]
    },
    {
        "name": "HABITS",
        "tag": "Thói quen lặp lại (RLS)",
        "x": 1490, "y": 900, "w": 450,
        "rows": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("linked_goal_id", "UUID (NULL)", "FK"),
            ("title", "VARCHAR(200)", ""),
            ("repeat_days", "JSONB ([1,2,3,4,5])", ""),
            ("duration_minutes", "INTEGER", ""),
            ("reminder_time", "TIME", ""),
            ("current_streak", "INTEGER", ""),
            ("longest_streak", "INTEGER", ""),
            ("status", "VARCHAR(30)", "")
        ]
    },
    {
        "name": "HABIT_LOGS",
        "tag": "Check-in Streak (RLS)",
        "x": 1490, "y": 1370, "w": 450,
        "rows": [
            ("id", "UUID", "PK"),
            ("habit_id", "UUID (CASCADE)", "FK"),
            ("user_id", "UUID (auth.uid)", "FK"),
            ("log_date", "DATE (UK-Combo)", ""),
            ("status", "VARCHAR(30)", ""),
            ("logged_at", "TIMESTAMPTZ", "")
        ]
    }
]

# Draw entities
for ent in entities:
    x, y, w = ent["x"], ent["y"], ent["w"]
    row_h = 26
    header_h = 44
    card_h = header_h + len(ent["rows"]) * row_h + 12

    # Card background & shadow
    draw.rounded_rectangle([(x+3, y+3), (x + w+3, y + card_h+3)], radius=12, fill='#E8EDF1')
    draw.rounded_rectangle([(x, y), (x + w, y + card_h)], radius=12, fill='#FFFFFF', outline='#DCE4EB', width=1)

    # Header bar
    draw.rounded_rectangle([(x, y), (x + w, y + header_h)], radius=12, fill='#345D83')
    draw.rectangle([(x, y + header_h - 12), (x + w, y + header_h)], fill='#345D83')
    draw.text((x + 14, y + 10), ent["name"], fill='#FFFFFF', font=font_tbl_h)
    draw.text((x + w - 170, y + 13), ent["tag"], fill='#FFF5D6', font=font_badge)

    # Rows
    cur_y = y + header_h + 8
    for i, (fname, ftype, badge) in enumerate(ent["rows"]):
        if i % 2 == 1:
            draw.rectangle([(x+1, cur_y - 2), (x + w - 1, cur_y + row_h - 3)], fill='#F8FAFC')

        # Badge
        if badge == "PK":
            draw.rounded_rectangle([(x + 12, cur_y), (x + 38, cur_y + 18)], radius=4, fill='#F4D578')
            draw.text((x + 17, cur_y + 2), "PK", fill='#20374C', font=font_badge)
        elif badge == "FK":
            draw.rounded_rectangle([(x + 12, cur_y), (x + 38, cur_y + 18)], radius=4, fill='#E4EEF3')
            draw.text((x + 18, cur_y + 2), "FK", fill='#345D83', font=font_badge)
        elif badge == "UK":
            draw.rounded_rectangle([(x + 12, cur_y), (x + 38, cur_y + 18)], radius=4, fill='#FBECE5')
            draw.text((x + 17, cur_y + 2), "UK", fill='#DF967E', font=font_badge)
        else:
            draw.ellipse([(x + 22, cur_y + 6), (x + 27, cur_y + 11)], fill='#8193A3')

        draw.text((x + 46, cur_y + 1), fname, fill='#20374C', font=font_field)
        draw.text((x + w - 165, cur_y + 2), ftype, fill='#657587', font=font_type)
        cur_y += row_h

def draw_line(x1, y1, x2, y2, color='#8193A3', label="1:N"):
    draw.line([(x1, y1), (x2, y2)], fill=color, width=2)
    mx, my = (x1 + x2)//2, (y1 + y2)//2
    draw.rounded_rectangle([(mx - 15, my - 9), (mx + 15, my + 9)], radius=4, fill='#FFFFFF', outline=color, width=1)
    draw.text((mx - 10, my - 7), label, fill=color, font=font_conn)

draw_line(710, 410, 710, 480, '#345D83', '1:N')
draw_line(710, 890, 710, 1000, '#345D83', '1:5')
draw_line(710, 1260, 710, 1340, '#28654C', '1:N')
draw_line(1715, 470, 1715, 560, '#DF967E', '1:N')
draw_line(1715, 1270, 1715, 1370, '#F4D578', '1:N')
draw_line(1205, 910, 1205, 1010, '#345D83', '1:N')

# Footer Legend
draw.rectangle([(0, H - 70), (W, H)], fill='#FFFFFF', outline='#DCE4EB', width=1)
draw.text((50, H - 45), 'CHÚ GIẢI SUPABASE & FLUTTER:', fill='#20374C', font=font_field)

draw.rounded_rectangle([(280, H - 50), (310, H - 30)], radius=4, fill='#F4D578')
draw.text((286, H - 48), 'PK', fill='#20374C', font=font_badge)
draw.text((320, H - 46), 'Khóa chính UUID', fill='#526577', font=font_legend)

draw.rounded_rectangle([(490, H - 50), (520, H - 30)], radius=4, fill='#E4EEF3')
draw.text((496, H - 48), 'FK', fill='#345D83', font=font_badge)
draw.text((530, H - 46), 'Khóa ngoại liên kết', fill='#526577', font=font_legend)

draw.rounded_rectangle([(710, H - 50), (740, H - 30)], radius=4, fill='#FFF5D6')
draw.text((716, H - 48), 'RLS', fill='#805C16', font=font_badge)
draw.text((750, H - 46), 'Bảo mật Row Level Security', fill='#526577', font=font_legend)

draw.text((1050, H - 46), '* Đồng bộ 2 chiều Flutter (Offline-First Drift/Hive) <-> Supabase Managed PostgreSQL', fill='#657587', font=font_legend)

out_path = Path(__file__).resolve().parents[2] / 'docs' / 'erd_diagram.png'
img.save(out_path, dpi=(300, 300))
print('ERD diagram regenerated successfully with Supabase specs at:', out_path)
