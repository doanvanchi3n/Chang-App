import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/app_layout.dart';
import '../../../app/widgets/feature_surface.dart';
import '../../../app/widgets/main_navigation.dart';
import '../../../app/widgets/work_section_tabs.dart';
import '../../tasks/data/task_management_repository.dart';
import '../data/project_repository.dart';
import '../domain/study_project.dart';
import 'create_project_page.dart';
import 'project_detail_page.dart';
import 'widgets/project_widgets.dart';

class ProjectListPage extends ConsumerStatefulWidget {
  const ProjectListPage({super.key});
  @override
  ConsumerState<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends ConsumerState<ProjectListPage>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    ref.invalidate(projectListProvider);
    ref.invalidate(taskListProvider);
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await Future.wait([
        ref.read(projectListProvider.future),
        ref.read(taskListProvider.future),
      ]);
    } catch (_) {
      /* Render error below. */
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider),
        tasks = ref.watch(taskListProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: MainNavigation(
        inboxActive: true,
        onHome: () => context.go('/'),
        onInbox: () => context.go('/tasks'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppLayout.pagePadding(context),
                children: [
                  Row(
                    children: [
                      const Text(
                        'chặng',
                        style: TextStyle(
                          color: changInk,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (final color in const [
                        Color(0xFF9DCDEE),
                        Color(0xFFFFD060),
                        changBlue,
                      ])
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 12,
                    children: [
                      const Text(
                        'Dự án học tập',
                        style: TextStyle(
                          color: changInk,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: changBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _open(const CreateProjectPage()),
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo dự án'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gom những việc cùng hướng đến một mục tiêu.',
                    style: TextStyle(color: changMuted, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  WorkSectionTabs(
                    projects: true,
                    onChanged: (value) {
                      if (!value) context.go('/tasks');
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: changInput('Tìm dự án…').copyWith(
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa tìm kiếm',
                              onPressed: () => setState(_search.clear),
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  projects.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => ProjectLoadError(onRetry: _reload),
                    data: (items) => tasks.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => ProjectLoadError(onRetry: _reload),
                      data: (allTasks) {
                        final term = _search.text.trim().toLowerCase();
                        final visible = items
                            .where(
                              (p) => '${p.name} ${p.description ?? ''}'
                                  .toLowerCase()
                                  .contains(term),
                            )
                            .toList();
                        if (visible.isEmpty) {
                          return FeatureCard(
                            color: changSoft,
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.folder_outlined,
                                  size: 44,
                                  color: changBlue,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  items.isEmpty
                                      ? 'Bắt đầu một chặng học mới'
                                      : 'Không tìm thấy dự án',
                                  style: const TextStyle(
                                    color: changInk,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  items.isEmpty
                                      ? 'Tạo dự án, rồi thêm từng công việc để theo dõi mục tiêu.'
                                      : 'Thử một từ khóa khác.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: changMuted),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final project in visible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ProjectCard(
                                  project: project,
                                  progress: ProjectProgress(
                                    project.id,
                                    allTasks,
                                  ),
                                  onTap: () => _open(
                                    ProjectDetailPage(projectId: project.id),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
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
