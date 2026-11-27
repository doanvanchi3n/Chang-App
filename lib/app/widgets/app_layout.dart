import 'package:flutter/material.dart';

/// Window breakpoints use logical pixels, independent of device or platform.
abstract final class AppLayout {
  static const designWidth = 390.0;
  static const designHeight = 844.0;
  // Keep short choices/dialogs readable without restricting entire pages.
  static const maxSheetWidth = 560.0;
  static const tabletBreakpoint = 600.0;
  static const desktopBreakpoint = 1024.0;
  static const maxDesktopWidth = 1180.0;
  static const maxFormWidth = 960.0;
  static const controlHeight = 52.0;

  static bool isDesktopWidth(double width) => width >= desktopBreakpoint;

  static bool isMobileWidth(double width) => width < tabletBreakpoint;

  static bool isTabletWidth(double width) =>
      width >= tabletBreakpoint && width < desktopBreakpoint;

  static bool isMobile(BuildContext context) =>
      isMobileWidth(MediaQuery.sizeOf(context).width);

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
