import 'package:flutter/material.dart';

import 'feature_surface.dart';

class WorkSectionTabs extends StatelessWidget {
  const WorkSectionTabs({
    super.key,
    required this.projects,
    required this.onChanged,
  });
  final bool projects;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SegmentedButton<bool>(
    showSelectedIcon: false,
    style: SegmentedButton.styleFrom(
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFFF3F7FA),
      selectedBackgroundColor: changSoft,
      selectedForegroundColor: changBlue,
      foregroundColor: changMuted,
      minimumSize: const Size(0, 48),
    ),
    segments: const [
      ButtonSegment(value: false, label: Text('Công việc')),
      ButtonSegment(value: true, label: Text('Dự án')),
    ],
    selected: {projects},
    onSelectionChanged: (value) => onChanged(value.single),
  );
}
