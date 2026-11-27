import 'package:flutter/material.dart';

/// Design reference: 390 × 844 logical pixels. Runtime height stays flexible.
abstract final class AppLayout {
  static const designWidth = 390.0;
  static const designHeight = 844.0;
  static const maxContentWidth = 560.0;
  static const desktopBreakpoint = 840.0;
  static const maxDesktopWidth = 1180.0;
  static const controlHeight = 52.0;

  static bool isDesktopWidth(double width) => width >= desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      isDesktopWidth(MediaQuery.sizeOf(context).width);

  static double gutter(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600 ? 20 : 24;
  static EdgeInsets pagePadding(
    BuildContext context, {
    double top = 16,
    double bottom = 24,
  }) => EdgeInsets.fromLTRB(gutter(context), top, gutter(context), bottom);
}
