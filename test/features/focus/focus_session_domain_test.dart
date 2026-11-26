import 'package:chang_app/features/focus/domain/focus_session.dart';
import 'package:chang_app/features/focus/presentation/widgets/focus_session_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatFocusClock định dạng MM:SS chính xác và chặn số âm', () {
    expect(formatFocusClock(-5), '00:00');
    expect(formatFocusClock(0), '00:00');
    expect(formatFocusClock(22), '00:22');
    expect(formatFocusClock(1478), '24:38');
    expect(formatFocusClock(3661), '61:01');
  });

  test('formatElapsedDuration định dạng giây/phút tự nhiên theo thiết kế', () {
    expect(formatElapsedDuration(-1), '0 giây');
    expect(formatElapsedDuration(0), '0 giây');
    expect(formatElapsedDuration(22), '22 giây');
    expect(formatElapsedDuration(60), '1 phút');
    expect(formatElapsedDuration(125), '2 phút 5 giây');
  });

  test('computeFocusProgress tính đúng tỷ lệ [0..1] và xử lý target <= 0', () {
    expect(computeFocusProgress(22000, 1500), closeTo(22 / 1500, 0.0001));
    expect(computeFocusProgress(2000000, 1500), 1.0);
    expect(computeFocusProgress(500, 0), 0.0);
  });

  test('FocusSession.elapsedAt cộng thời gian khi chạy và giữ nguyên khi tạm dừng', () {
    final running = FocusSession({
      'id': 'sess-1',
      'status': 'IN_PROGRESS',
      'target_duration_seconds': 1500,
      'elapsed_milliseconds': 10000,
      'revision': 1,
      'ambient_sound': 'SILENT',
      'running_since': '2026-11-26T10:00:00Z',
      'server_now': '2026-11-26T10:00:12Z',
    });
    expect(running.elapsedAt(DateTime.utc(2026, 11, 26, 10, 0, 12)), 22000);
    // Không vượt quá target_duration_seconds.
    expect(running.elapsedAt(DateTime.utc(2026, 11, 26, 11, 0, 0)), 1500000);

    final paused = FocusSession({
      'id': 'sess-2',
      'status': 'PAUSED',
      'target_duration_seconds': 1500,
      'elapsed_milliseconds': 22000,
      'revision': 2,
      'ambient_sound': 'SILENT',
      'running_since': null,
      'server_now': '2026-11-26T10:05:00Z',
    });
    expect(paused.elapsedAt(DateTime.utc(2026, 11, 26, 10, 10, 0)), 22000);
  });

  test('Ngưỡng responsive tách rõ Mobile (< 840dp) và Desktop (>= 840dp)', () {
    expect(isFocusDesktopWidth(390), isFalse);
    expect(isFocusDesktopWidth(839.9), isFalse);
    expect(isFocusDesktopWidth(840), isTrue);
    expect(isFocusDesktopWidth(1280), isTrue);
  });
}
