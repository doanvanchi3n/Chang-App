import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Panes stack when the actual content area cannot accommodate both columns.
class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
    this.minPaneWidth = 320,
    this.spacing = 24,
  });

  final Widget primary, secondary;
  final int primaryFlex, secondaryFlex;
  final double minPaneWidth, spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final totalFlex = primaryFlex + secondaryFlex;
      final smallestFlex = math.min(primaryFlex, secondaryFlex);
      final wide =
          constraints.maxWidth >=
          (minPaneWidth * totalFlex / smallestFlex + spacing) *
              scale.clamp(1, 1.5);
      if (!wide) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primary,
            SizedBox(height: spacing),
            secondary,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: primaryFlex, child: primary),
          SizedBox(width: spacing),
          Expanded(flex: secondaryFlex, child: secondary),
        ],
      );
    },
  );
}

/// Cards retain their natural height, including with long or enlarged text.
class AdaptiveCardGrid extends StatelessWidget {
  const AdaptiveCardGrid({
    super.key,
    required this.children,
    this.minCardWidth = 320,
    this.maxColumns = 3,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minCardWidth, spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final columns = math.max(
        1,
        math.min(
          maxColumns,
          ((constraints.maxWidth + spacing) /
                  (minCardWidth * scale.clamp(1, 1.5) + spacing))
              .floor(),
        ),
      );
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
