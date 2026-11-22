from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

W, H = 2200, 1850
img = Image.new('RGB', (W, H), '#F9FBFD')
draw = ImageDraw.Draw(img)

# Fonts
font_title = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf', 32)
font_sub = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf', 17)
font_pkg_title = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf', 16)
font_uc = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Medium.ttf', 13)
font_actor = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf', 15)
font_actor_sub = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf', 12)
font_legend = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf', 14)

# Header
draw.rectangle([(0, 0), (W, 95)], fill='#345D83')
draw.text((50, 18), 'SƠ ĐỒ USE CASE HỆ THỐNG CHI TIẾT - CHẶNG APP (MOBILE APP)', fill='#FFFFFF', font=font_title)
draw.text((50, 60), 'Nền tảng Flutter (Dart) + Supabase | Đặc tả 8 Phân hệ | 50 Màn hình (M01-M50) | Tác nhân: Người học, Trợ lý AI, System Daemon', fill='#E4EEF3', font=font_sub)

# System Boundary
box_left, box_top, box_right, box_bot = 320, 120, 1880, 1750
draw.rounded_rectangle([(box_left, box_top), (box_right, box_bot)], radius=16, fill='#FFFFFF', outline='#345D83', width=2)
draw.rectangle([(box_left + 20, box_top - 12), (box_left + 420, box_top + 14)], fill='#FFFFFF')
draw.text((box_left + 30, box_top - 10), 'Ranh giới hệ thống: Ứng dụng Di động Chặng', fill='#345D83', font=font_pkg_title)

# Draw Actor Helper
def draw_actor(x, y, name, role, color='#345D83'):
    # Head
    draw.ellipse([(x - 22, y - 50), (x + 22, y - 6)], fill='#FFFFFF', outline=color, width=3)
    # Body
    draw.line([(x, y - 6), (x, y + 36)], fill=color, width=3)
    # Arms
    draw.line([(x - 30, y + 10), (x + 30, y + 10)], fill=color, width=3)
    # Legs
    draw.line([(x, y + 36), (x - 24, y + 74)], fill=color, width=3)
    # Right leg
    draw.line([(x, y + 36), (x + 24, y + 74)], fill=color, width=3)
    # Text
    bbox = font_actor.getbbox(name)
    tw = bbox[2] - bbox[0]
    draw.text((x - tw//2, y + 84), name, fill='#20374C', font=font_actor)
    bbox_sub = font_actor_sub.getbbox(role)
    tsw = bbox_sub[2] - bbox_sub[0]
    draw.text((x - tsw//2, y + 106), role, fill='#657587', font=font_actor_sub)

# Left Actor: Learner
draw_actor(160, 850, "Người học (Learner)", "Primary Actor", '#345D83')

# Right Actor 1: AI Assistant
draw_actor(2040, 520, "Trợ lý AI (AI Copilot)", "Secondary AI System", '#DF967E')

# Right Actor 2: System Daemon
draw_actor(2040, 1300, "System Daemon", "Background / Cron", '#28654C')

# Packages in System Boundary: 2 columns inside system boundary
# Col 1: left=350, w=720
# Col 2: left=1100, w=740

packages = [
    # Column 1
    {
        "title": "1. Khởi động & Thiết lập cá nhân",
        "bg": "#F4F8FA", "border": "#DCE4EB",
        "x": 350, "y": 145, "w": 720, "h": 160,
        "cases": [
            "UC01: Xem Intro tương tác & Khởi tạo (M06)",
            "UC02: Chọn mục tiêu & Giờ học vàng (M03, M04)",
            "UC03: Quản lý Hồ sơ học tập (M08)",
            "UC04: Cài đặt Giờ yên tĩnh & Chuyển động (M09)"
        ]
    },
    {
        "title": "2. Quản lý Công việc & 5 Bước nhỏ",
        "bg": "#F4F8FA", "border": "#DCE4EB",
        "x": 350, "y": 325, "w": 720, "h": 220,
        "cases": [
            "UC05: Tạo công việc & Chia nhỏ tối đa 5 bước (M12)",
            "UC06: Cập nhật tiến độ & Quản lý bước nhỏ (M13, M15)",
            "UC07: Chỉnh sửa công việc (Draft vs Saved) (M14)",
            "UC08: Quản lý Hộp việc chưa lên kế hoạch (M01, M02)",
            "UC09: Tìm kiếm, lọc & Lưu trữ việc đã xong (M11, M16, M20)"
        ]
    },
    {
        "title": "3. Quản lý Dự án học tập",
        "bg": "#F4F8FA", "border": "#DCE4EB",
        "x": 350, "y": 565, "w": 720, "h": 150,
        "cases": [
            "UC10: Tạo dự án mới & Chọn màu nhận diện (M18)",
            "UC11: Theo dõi danh sách & Tiến độ dự án (M17, M19)"
        ]
    },
    {
        "title": "4. Phiên tập trung Pomodoro cải tiến",
        "bg": "#FFFDF0", "border": "#F4D578",
        "x": 350, "y": 735, "w": 720, "h": 225,
        "cases": [
            "UC12: Chuẩn bị phiên & Chọn bước nhỏ (M27)",
            "UC13: Đang tập trung & Thu gọn PiP (M28)",
            "UC14: Tạm dừng / Tiếp tục học (M29)",
            "UC15: Tổng kết thời gian thực tế & Xác nhận bước (M30)"
        ]
    },
    {
        "title": "5. Rà soát & Báo cáo tiến độ",
        "bg": "#F4F8FA", "border": "#DCE4EB",
        "x": 350, "y": 980, "w": 720, "h": 190,
        "cases": [
            "UC16: Rà soát cuối ngày (Mai vs Inbox) (M10)",
            "UC17: Thống kê tổng quan giờ học (M38)",
            "UC18: Nhìn lại tuần & Năng suất (M39)"
        ]
    },

    # Column 2
    {
        "title": "6. Lịch biểu & Xếp lịch thông minh",
        "bg": "#F4F8FA", "border": "#DCE4EB",
        "x": 1100, "y": 145, "w": 750, "h": 220,
        "cases": [
            "UC19: Xem Lịch tuần & Lịch ngày timeline (M21, M22)",
            "UC20: Tạo & Chỉnh sửa lịch hẹn cố định (M23, M24)",
            "UC21: Xếp công việc vào khoảng trống (M25)",
            "UC22: Giải quyết xung đột trùng lịch (M26)"
        ]
    },
    {
        "title": "7. Mục tiêu định lượng & Thói quen",
        "bg": "#FFF6F2", "border": "#DF967E",
        "x": 1100, "y": 385, "w": 750, "h": 280,
        "cases": [
            "UC23: Tạo & Theo dõi mục tiêu định lượng (M31, M32)",
            "UC24: Ghi nhận thêm tiến độ số học (+delta) (M33)",
            "UC25: Điều chỉnh đích (giữ nguyên lịch sử) (M34)",
            "UC26: Đạt mốc mục tiêu & Ăn mừng (M40)",
            "UC27: Quản lý thói quen & Điểm danh / Hoàn tác (M35, M36)",
            "UC28: Xem Heatmap chuỗi ngày (Streak) (M37)"
        ]
    },
    {
        "title": "8. Trợ lý Lập kế hoạch AI (Co-pilot)",
        "bg": "#F4F8FA", "border": "#345D83",
        "x": 1100, "y": 685, "w": 750, "h": 320,
        "cases": [
            "UC29: Bắt đầu yêu cầu & Hội thoại làm rõ (M41, M42)",
            "UC30: Kiểm duyệt phạm vi dữ liệu AI truy cập (M43, M44)",
            "UC31: Xem trước & Giải thích đề xuất (M45, M46)",
            "UC32: Tinh chỉnh đề xuất kế hoạch (M47)",
            "UC33: Áp dụng kế hoạch & Hoàn tác nhanh (Undo) (M48)",
            "UC34: Xử lý tình huống không xếp được lịch (M49)",
            "UC35: Kiểm soát lịch sử can thiệp của AI (M50)"
        ]
    },
    {
        "title": "9. Trung tâm Thông báo & Phím tắt",
        "bg": "#F4F8FA", "border": "#DCE4EB",
        "x": 1100, "y": 1025, "w": 750, "h": 145,
        "cases": [
            "UC36: Xem & Đánh dấu đã đọc thông báo (M07)",
            "UC37: Điều hướng thông minh từ Dashboard Home (M05)"
        ]
    }
]

# Draw Packages and Use Case Ovals
for pkg in packages:
    px, py, pw, ph = pkg["x"], pkg["y"], pkg["w"], pkg["h"]
    draw.rounded_rectangle([(px, py), (px + pw, py + ph)], radius=12, fill=pkg["bg"], outline=pkg["border"], width=1)
    # Header tag
    draw.text((px + 16, py + 10), pkg["title"], fill='#20374C', font=font_pkg_title)

    # Use cases inside
    uc_y = py + 38
    for uc_text in pkg["cases"]:
        # Draw clean pill / oval for Use Case
        draw.rounded_rectangle([(px + 20, uc_y), (px + pw - 20, uc_y + 26)], radius=13, fill='#FFFFFF', outline='#8193A3', width=1)
        draw.text((px + 32, uc_y + 4), uc_text, fill='#20374C', font=font_uc)
        uc_y += 33

# Connect Actors to Packages
# Learner lines
for ly in [220, 430, 640, 840, 1070]:
    draw.line([(240, 850), (350, ly)], fill='#8193A3', width=1)

# AI Assistant lines
for ay in [250, 520, 840]:
    draw.line([(1960, 520), (1850, ay)], fill='#DF967E', width=1)

# System Daemon lines
for dy in [850, 1070]:
    draw.line([(1960, 1300), (1070, dy)], fill='#28654C', width=1)

# Footer Legend
draw.rectangle([(0, H - 70), (W, H)], fill='#FFFFFF', outline='#DCE4EB', width=1)
draw.text((50, H - 45), 'CHÚ GIẢI TÁC NHÂN & QUY ƯỚC:', fill='#20374C', font=font_pkg_title)
draw.text((360, H - 45), '— Người học (Chính)', fill='#345D83', font=font_legend)
draw.text((620, H - 45), '— Trợ lý AI (Hệ thống thông minh)', fill='#DF967E', font=font_legend)
draw.text((950, H - 45), '— System Daemon (Nền tảng & Cron)', fill='#28654C', font=font_legend)
draw.text((1350, H - 45), '* Tuân thủ đầy đủ 50 màn hình (M01-M50) & quy chuẩn UML Use Case 2.5', fill='#657587', font=font_legend)

out_uc = Path(__file__).resolve().parents[2] / 'docs' / 'usecase_diagram.png'
img.save(out_uc, dpi=(300, 300))
print('Use case diagram generated successfully at:', out_uc)
