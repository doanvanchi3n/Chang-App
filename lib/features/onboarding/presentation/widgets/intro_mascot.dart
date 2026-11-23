import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IntroMascot extends StatefulWidget {
  const IntroMascot({super.key, required this.onFinished, this.play = true});
  final VoidCallback onFinished;
  final bool play;

  @override
  State<IntroMascot> createState() => _IntroMascotState();
}

class _IntroMascotState extends State<IntroMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      });
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!widget.play || MediaQuery.disableAnimationsOf(context)) {
          _controller.value = 1;
        } else {
          _controller.forward();
        }
      });
    } else if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.value = 1;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Linh vật chim cánh cụt Chặng vẫy tay chào bạn',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 240,
          child: Center(
            child: AspectRatio(
              aspectRatio: 745 / 790,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      child: SvgPicture.asset('assets/mascot/splash_wing.svg'),
                      builder: (context, child) => Transform.rotate(
                        angle: math.sin(_controller.value * math.pi * 4) * 0.10,
                        // Shoulder pivot in the Splash SVG viewBox (40, 33, 745, 790).
                        alignment: const FractionalOffset(560 / 745, 397 / 790),
                        child: child,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: SvgPicture.asset('assets/mascot/splash_body.svg'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
