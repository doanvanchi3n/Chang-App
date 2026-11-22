# HƯỚNG DẪN SỬ DỤNG BỘ SKILLS VÀ PLUGINS ĐÃ CÀI ĐẶT
## DỰ ÁN ỨNG DỤNG CHẶNG (CHANG APP)

---

## 1. TỔNG QUAN BỘ SKILLS VỪA CÀI ĐẶT

Dự án đã được tích hợp thành công **78 Skills** và **5 Plugins** chuyên sâu từ 5 kho lưu trữ hàng đầu dành cho AI Agent:

| STT | Kho lưu trữ (Repository) | Danh mục / Vai trò | Số lượng Skills |
| :---: | :--- | :--- | :---: |
| 1 | **[microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)** | Tự động hóa kiểm thử trình duyệt, chụp ảnh, snapshot UI qua CLI | 1 skill + references |
| 2 | **[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)** | Tối ưu hóa code tối giản (Lazy senior dev mode), YAGNI, audit nợ kỹ thuật | 6 skills |
| 3 | **[Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify)** | Xây dựng đồ thị tri thức mã nguồn (Knowledge Graph), GraphRAG truy vấn kiến trúc | 1 skill + references |
| 4 | **[cheaper-inference/OmniRoute](https://github.com/cheaper-inference/OmniRoute)** | Điều phối mô hình AI, nén prompt, định tuyến chi phí, resilience, tunnel | 45 skills |
| 5 | **[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)** | Bộ quy chuẩn công nghệ phần mềm: TDD, Spec, Code Review, Security, Performance | 25 skills + 4 Personas + references |
| **Tổng** | **5 Bộ Công cụ** | **Toàn bộ hệ sinh thái Agentic Engineering** | **78 Skills** |

---

## 2. CẤU TRÚC LƯU TRỮ TRONG PROJECT

Toàn bộ các kỹ năng được tổ chức theo đúng chuẩn **Antigravity Customization System** tại thư mục gốc của dự án:

```text
Chang-app/
├── .agents/
│   ├── skills/                        # 78 Skills độc lập có SKILL.md
│   │   ├── playwright-cli/
│   │   ├── graphify/
│   │   ├── ponytail/
│   │   ├── ponytail-audit/
│   │   ├── test-driven-development/
│   │   ├── spec-driven-development/
│   │   ├── code-review-and-quality/
│   │   ├── omni-inference/
│   │   └── ... (78 skills)
│   ├── plugins/                       # 5 Plugins đóng gói hoàn chỉnh
│   │   ├── playwright-cli/
│   │   ├── ponytail/
│   │   ├── graphify/
│   │   ├── omniroute/
│   │   └── agent-skills/
│   ├── references/                    # Danh mục tài liệu tham chiếu dùng chung
│   │   ├── testing-patterns.md
│   │   ├── security-checklist.md
│   │   ├── performance-checklist.md
│   │   └── definition-of-done.md
│   ├── agents/                        # 4 Chuyên gia lập trình (Personas)
│   │   ├── code-reviewer.md
│   │   ├── security-auditor.md
│   │   ├── test-engineer.md
│   │   └── web-performance-auditor.md
│   ├── skills.json                    # Cấu hình đăng ký skills cho Antigravity
│   └── plugins.json                   # Cấu hình đăng ký plugins cho Antigravity
├── .gemini/
│   ├── skills -> ../.agents/skills    # Symlink tương thích đa môi trường
│   └── plugins -> ../.agents/plugins
└── skills -> .agents/skills           # Root symlink truy cập nhanh
```

---

## 3. CHI TIẾT CÁC BỘ KỸ NĂNG NỔI BẬT

### 3.1. Bộ Kỹ năng Kỹ nghệ Phần mềm (addyosmani/agent-skills - 25 Skills)
Bộ tiêu chuẩn thực hành phát triển phần mềm được Addy Osmani đúc kết:
- **`spec-driven-development`:** Soạn thảo đặc tả chi tiết và làm rõ yêu cầu trước khi viết bất kỳ dòng mã nào.
- **`test-driven-development`:** Quy trình kiểm thử hướng kiểm thử (TDD) chuẩn Red-Green-Refactor.
- **`code-review-and-quality`:** Đánh giá mã nguồn đa trục: tính đúng đắn, bảo mật, hiệu năng, khả năng mở rộng.
- **`planning-and-task-breakdown`:** Phân rã bài toán lớn thành các đầu việc nhỏ có thể kiểm chứng.
- **`debugging-and-error-recovery`:** Định vị và sửa lỗi gốc rễ (Root Cause Analysis) một cách có hệ thống.
- **`performance-optimization`:** Tối ưu hóa hiệu năng frontend, backend, câu truy vấn database và caching.
- **`security-and-hardening`:** Rà soát lỗ hổng bảo mật OWASP Top 10, phân quyền và kiểm soát đầu vào.
- **`code-simplification`:** Tối giản mã nguồn, loại bỏ độ phức tạp không cần thiết mà không thay đổi hành vi.
- **`api-and-interface-design`:** Thiết kế hợp đồng API REST, GraphQL và ranh giới module rõ ràng.
- **`interview-me`:** Phỏng vấn người dùng từng câu hỏi một để làm rõ 95% ý định thực sự trước khi bắt tay làm.

### 3.2. Bộ Kỹ năng Tối giản Mã nguồn (DietrichGebert/ponytail - 6 Skills)
Áp dụng triết lý "Lazy Senior Developer" – giải pháp đơn giản nhất giải quyết trọn vẹn vấn đề:
- **`ponytail`:** Bật chế độ tối giản (`lite`, `full`, `ultra`). Yêu cầu tận dụng thư viện tiêu chuẩn trước khi kéo thêm dependency.
- **`ponytail-audit`:** Kiểm toán toàn bộ repo: chỉ ra code thừa, bloat, những đoạn có rủi ro cao và đề xuất xóa/gộp.
- **`ponytail-review`:** Review code theo góc nhìn của lập trình viên trực vận hành (người sẽ bị paged khi hệ thống gãy).
- **`ponytail-debt`:** Quản lý sổ nợ kỹ thuật (technical debt ledger) từ các chú thích `shortcut:`.

### 3.3. Trí tuệ Đồ thị Mã nguồn (Graphify-Labs/graphify - 1 Skill + References)
- **`graphify`:** Biến toàn bộ thư mục mã nguồn và tài liệu thành **Knowledge Graph**:
  - Tra cứu cấu trúc dự án không cần grep: `/graphify query "<câu hỏi>"`.
  - Tìm đường đi ngắn nhất giữa 2 module: `/graphify path "AuthModule" "Database"`.
  - Phân tích ranh giới cộng đồng mã nguồn và xuất ra báo cáo trực quan `graph.html`.

### 3.4. Kiểm thử Tự động Trình duyệt (microsoft/playwright-cli - 1 Skill + References)
- **`playwright-cli`:** Điều khiển trình duyệt không đầu (headless) từ dòng lệnh:
  - Mở trang, điều hướng, click, nhập liệu thông qua selector/snapshot.
  - Chụp ảnh màn hình, quay video phiên chạy, tạo bài test tự động.

### 3.5. Điều phối Mô hình AI & Hạ tầng Agent (cheaper-inference/OmniRoute - 45 Skills)
- **`omni-inference` / `cli-chat`:** Giao tiếp suy luận AI linh hoạt qua nhiều nhà cung cấp.
- **`omni-combos-routing` / `cli-routing`:** Định tuyến thông minh theo chi phí, fallback dự phòng khi một nhà cung cấp gặp sự cố.
- **`omni-compression`:** Nén ngữ cảnh prompt giúp tiết kiệm từ 60% đến 90% lượng token tiêu thụ.
- **`omni-mcp` / `cli-mcp`:** Quản lý các công cụ giao thức Model Context Protocol (MCP).
- **`cli-resilience`:** Giám sát Circuit Breaker, tự động hồi phục khi API bị nghẽn mạng.

---

## 4. CÁCH KÍCH HOẠT VÀ SỬ DỤNG TRONG ANTIGRAVITY

Cơ chế **Progressive Disclosure** của Antigravity sẽ tự động kích hoạt kỹ năng tương ứng khi bạn đưa ra yêu cầu:

1. **Khi bạn yêu cầu viết test hoặc sửa lỗi:**
   - Agent tự động gợi ý và kích hoạt `test-driven-development` hoặc `debugging-and-error-recovery`.
2. **Khi bạn yêu cầu review code:**
   - Bạn có thể nói: *"Review lại PR này theo chuẩn code review"* -> Agent kích hoạt `code-review-and-quality`.
   - Hoặc *"Hãy review theo phong cách ponytail"* -> Agent kích hoạt `ponytail-review`.
3. **Khi bạn muốn kiểm tra nợ kỹ thuật hoặc làm sạch code:**
   - Gọi: *"Chạy ponytail-audit trên dự án"* -> Agent kích hoạt `ponytail-audit`.
   - Gọi: *"Làm đơn giản hóa hàm này"* -> Agent kích hoạt `code-simplification`.
4. **Khi bạn muốn tra cứu đồ thị kiến trúc:**
   - Gọi: *"Chạy graphify phân tích liên kết giữa các module"* -> Agent kích hoạt `graphify`.
5. **Khi bạn muốn tự động hóa kiểm thử UI:**
   - Gọi: *"Sử dụng playwright-cli để kiểm tra flow đăng nhập"* -> Agent kích hoạt `playwright-cli`.

---
*Tất cả 78 kỹ năng đã sẵn sàng phục vụ quá trình phát triển dự án Chặng App!*
