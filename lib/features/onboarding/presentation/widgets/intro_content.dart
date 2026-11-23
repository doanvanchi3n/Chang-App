import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import 'intro_mascot.dart';

const _ink = Color(0xFF071E61);
const _blue = Color(0xFF006BFF);
const _mutedBlue = Color(0xFF426EB4);

/// M06: real controls and text remain usable with large text and screen readers.
class IntroContent extends StatelessWidget {
  const IntroContent({
    super.key,
    required this.saving,
    required this.error,
    required this.onContinue,
    required this.onIntroFinished,
  });

  final bool saving;
  final String? error;
  final VoidCallback onContinue;
  final VoidCallback onIntroFinished;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _CloudsPainter(),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 560,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 56),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: _Wordmark()),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: saving ? null : onContinue,
                              style: TextButton.styleFrom(
                                foregroundColor: _mutedBlue,
                              ),
                              child: const Text('Bỏ qua'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        IntroMascot(onFinished: onIntroFinished),
                        const _Highlights(),
                        const SizedBox(height: 24),
                        const Text(
                          'Chặng nhỏ,\ntiến bộ mỗi ngày.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Lên kế hoạch tự học theo nhịp của bạn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _mutedBlue,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 320,
                          child: FilledButton(
                            onPressed: saving ? null : onContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: _blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Bắt đầu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (saving)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Đang lưu trạng thái giới thiệu',
                            ),
                          ),
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                          TextButton(
                            onPressed: saving ? null : onContinue,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chặng',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              const Text(
                'chặng',
                style: TextStyle(
                  color: Color(0xFF080565),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              for (final color in const [
                Color(0xFF9CCAFF),
                Color(0xFFFFC000),
                _blue,
              ])
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _HighlightConnectionsPainter(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in const [
            (Icons.menu_book_rounded, 'Lên kế hoạch', Color(0xFFCCE5FF), 0.0),
            (Icons.timer_outlined, 'Tập trung', Color(0xFFFFE8A5), 20.0),
            (Icons.flag_rounded, 'Nhìn lại', Color(0xFFCCE5FF), 0.0),
          ])
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: item.$4, left: 2, right: 2),
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: item.$3,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.$1, size: 32, color: _ink),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HighlightConnectionsPainter extends CustomPainter {
  const _HighlightConnectionsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Connect icon centers; the opaque circles cover the line beneath them.
    final path = Path()
      ..moveTo(size.width / 6, 29)
      ..quadraticBezierTo(size.width / 3, 49, size.width / 2, 49)
      ..quadraticBezierTo(size.width * 2 / 3, 49, size.width * 5 / 6, 29);
    final paint = Paint()
      ..color = const Color(0xFFA3CFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 18) {
        canvas.drawPath(metric.extractPath(offset, offset + 9), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HighlightConnectionsPainter oldDelegate) => false;
}

class _CloudsPainter extends CustomPainter {
  const _CloudsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height - 50)
      ..quadraticBezierTo(
        size.width * .10,
        size.height - 80,
        size.width * .18,
        size.height - 40,
      )
      ..quadraticBezierTo(
        size.width * .30,
        size.height - 55,
        size.width * .40,
        size.height,
      )
      ..lineTo(size.width * .62, size.height)
      ..quadraticBezierTo(
        size.width * .73,
        size.height - 50,
        size.width * .82,
        size.height - 35,
      )
      ..quadraticBezierTo(
        size.width * .90,
        size.height - 85,
        size.width,
        size.height - 50,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFD9ECFF));
  }

  @override
  bool shouldRepaint(_CloudsPainter oldDelegate) => false;
}
