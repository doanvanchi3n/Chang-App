import 'app_layout.dart';

import 'package:flutter/material.dart';

const changInk = Color(0xFF082451);
const changBlue = Color(0xFF006BFF);
const changMuted = Color(0xFF4667A6);
const changSoft = Color(0xFFEAF5FF);
const changBorder = Color(0xFFD8E7FF);

class FeatureSurface extends StatelessWidget {
  const FeatureSurface({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
    this.trailing,
    this.maxWidth = AppLayout.maxFormWidth,
  });
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: AppLayout.pagePadding(context, bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                        tooltip: 'Quay lại',
                        style: IconButton.styleFrom(backgroundColor: changSoft),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: changInk,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: changInk,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.child,
    this.color = Colors.white,
  });
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: changBorder),
      borderRadius: BorderRadius.circular(20),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class FeatureButton extends StatelessWidget {
  const FeatureButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: changBlue,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
    return secondary
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: changBlue,
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.all(14),
              side: const BorderSide(color: changBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: text,
          )
        : FilledButton(onPressed: onPressed, style: style, child: text);
  }
}

InputDecoration changInput(String label) => InputDecoration(
  labelText: label,
  alignLabelWithHint: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: changBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: changBlue, width: 2),
  ),
);

String preciseDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return rest == 0 ? '$minutes phút' : '$minutes phút $rest giây';
}

String clockDuration(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
