import 'package:flutter/material.dart';

import '../../../../app/widgets/feature_surface.dart';
import '../../domain/study_project.dart';

String projectDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

Color projectColor(String hex) => Color(
  int.tryParse(hex.replaceFirst('#', 'FF'), radix: 16) ?? changBlue.toARGB32(),
);
IconData projectIcon(String name) => switch (name) {
  'school' => Icons.school_outlined,
  'book' => Icons.menu_book_outlined,
  _ => Icons.folder_outlined,
};

class ProjectSymbol extends StatelessWidget {
  const ProjectSymbol({
    super.key,
    required this.colorHex,
    required this.iconName,
  });
  final String colorHex, iconName;
  @override
  Widget build(BuildContext context) {
    final color = projectColor(colorHex);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(projectIcon(iconName), color: color, size: 29),
    );
  }
}

class ProjectProgressView extends StatelessWidget {
  const ProjectProgressView({
    super.key,
    required this.progress,
    this.explain = false,
  });
  final ProjectProgress progress;
  final bool explain;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              progress.total == 0
                  ? 'Chưa có công việc'
                  : '${progress.completed}/${progress.total} công việc hoàn thành',
              style: const TextStyle(
                color: changMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${progress.percent}%',
            style: const TextStyle(
              color: changBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: progress.percent / 100,
        minHeight: explain ? 12 : 8,
        borderRadius: BorderRadius.circular(12),
        color: changBlue,
        backgroundColor: const Color(0xFFE9F1F7),
        semanticsLabel: 'Tiến độ dự án',
        semanticsValue: '${progress.percent}%',
      ),
      if (explain) ...[
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: changMuted, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tiến độ tính theo công việc, không theo bước nhỏ.',
                style: TextStyle(color: changMuted),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.progress,
    required this.onTap,
  });
  final StudyProject project;
  final ProjectProgress progress;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: changBorder),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProjectSymbol(
              colorHex: project.colorHex,
              iconName: project.iconName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: changSoft,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '●  ${progress.label}',
                        style: const TextStyle(
                          color: changBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.name,
                    style: const TextStyle(
                      color: changInk,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (project.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      project.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: changMuted),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ProjectProgressView(progress: progress),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 19,
                        color: changBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          project.deadline == null
                              ? 'Chưa đặt hạn'
                              : 'Hạn ${projectDate(project.deadline!)}',
                          style: const TextStyle(
                            color: changMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: changBlue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProjectLoadError extends StatelessWidget {
  const ProjectLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        const Text(
          'Chưa tải được dữ liệu. Kiểm tra kết nối rồi thử lại.',
          textAlign: TextAlign.center,
        ),
        TextButton(onPressed: onRetry, child: const Text('Tải lại')),
      ],
    ),
  );
}
