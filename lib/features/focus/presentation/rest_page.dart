import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/widgets/feature_surface.dart';

class RestPage extends StatefulWidget {
  const RestPage({super.key});
  @override
  State<RestPage> createState() => _RestPageState();
}

class _RestPageState extends State<RestPage> {
  final _end = DateTime.now().add(const Duration(minutes: 5));
  Timer? _timer;
  int get _remaining =>
      ((_end.difference(DateTime.now()).inMilliseconds + 999) ~/ 1000).clamp(
        0,
        300,
      );
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      if (_remaining == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeatureSurface(
    title: 'Nghỉ một chút nhé',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'assets/mascot/mascot_m29.png',
          height: 200,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          semanticLabel: 'Chặng đang nghỉ ngơi',
        ),
        const SizedBox(height: 24),
        Text(
          clockDuration(_remaining),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: changInk,
            fontSize: 64,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _remaining == 0
              ? 'Bạn đã nghỉ xong. Sẵn sàng cho chặng tiếp theo?'
              : 'Uống nước, thả lỏng vai và cho mắt nghỉ ngơi.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: changMuted, fontSize: 18, height: 1.5),
        ),
        const SizedBox(height: 24),
        FeatureButton(
          'Về hôm nay',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
