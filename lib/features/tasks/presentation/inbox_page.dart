import '../../../app/widgets/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daily_plan_page.dart';
import 'create_task_page.dart';
import 'inbox_provider.dart';
import 'task_detail_page.dart';
import 'widgets/inbox_widgets.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  final _title = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _selected = <String>{};
  bool _saving = false;
  bool _planning = false;
  bool _taskOpen = false;
  String? _saveError;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_saving || _planning || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await ref.read(inboxRepositoryProvider).add(_title.text);
      if (!mounted) return;
      _title.clear();
      ref.invalidate(inboxProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu việc vào hộp việc.')),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError = 'Chưa xác nhận được việc đã lưu. Hãy làm mới danh sách trước khi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _refresh() async {
    if (_planning) return;
    try {
      ref.invalidate(inboxProvider);
      await ref.read(inboxProvider.future);
    } catch (_) {
      // The list displays the provider error and its retry action.
    }
  }

  Future<void> _openTaskDetail(String taskId) async {
    if (_planning || _saving) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: taskId)),
    );
    if (mounted) ref.invalidate(inboxProvider);
  }

  Future<void> _planToday() async {
    if (_planning || _saving) return;
    final tasks = ref.read(inboxProvider);
    if (tasks.isLoading) return;
    final ids = tasks.asData?.value
        .where((task) => _selected.contains(task.id))
        .map((task) => task.id)
        .toList();
    if (ids == null || ids.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _planning = true);
    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => DailyPlanPage(initialTaskIds: ids)),
      );
      if (!mounted) return;
      ref.invalidate(inboxProvider);
      if (saved == true && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  Future<void> _openTaskPage(Widget page) async {
    if (_saving || _planning || _taskOpen) return;
    _taskOpen = true;
    try {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => page));
    } finally {
      _taskOpen = false;
      if (mounted) ref.invalidate(inboxProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(inboxProvider);
    final items = tasks.asData?.value;
    final selectedCount =
        items?.where((task) => _selected.contains(task.id)).length ?? 0;
    final canAdd = !_saving && !_planning && tasks.asData != null;
    return PopScope(
      canPop: !_planning,
      child: AbsorbPointer(
        absorbing: _planning,
        child: ExcludeFocus(
          excluding: _planning,
          child: Scaffold(
            backgroundColor: Colors.white,
            bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
                ? null
                : InboxBottomBar(
                    selectedCount: selectedCount,
                    planning: _planning,
                    onPlanToday: !_saving && !tasks.isLoading && items != null
                        ? _planToday
                        : null,
                  ),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppLayout.maxContentWidth,
                      ),
                      child: Padding(
                        padding: AppLayout.pagePadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InboxHeader(
                              onRefresh: () => ref.invalidate(inboxProvider),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Hộp việc',
                              style: TextStyle(
                                color: inboxInk,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ghi lại trước, chọn lúc làm sau.',
                              style: TextStyle(color: inboxMuted, fontSize: 18),
                            ),
                            const SizedBox(height: 20),
                            Form(
                              key: _form,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final field = TextFormField(
                                    controller: _title,
                                    enabled: !_saving && !_planning,
                                    maxLength: 200,
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(color: inboxInk),
                                    decoration: InputDecoration(
                                      hintText: 'Bạn cần làm gì?',
                                      hintStyle: const TextStyle(
                                        color: inboxMuted,
                                      ),
                                      counterText: '',
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: inboxMuted,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 16,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFACCCFF),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: inboxBlue,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Nhập tên việc trước khi thêm.'
                                        : value.trim().runes.length > 200
                                        ? 'Tên việc tối đa 200 ký tự.'
                                        : null,
                                    onFieldSubmitted: (_) {
                                      if (canAdd) _add();
                                    },
                                  );
                                  final button = FilledButton.icon(
                                    onPressed: canAdd ? _add : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: inboxBlue,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(48, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      _saving ? 'Đang lưu…' : 'Ghi lại',
                                    ),
                                  );
                                  if (constraints.maxWidth < 400 ||
                                      MediaQuery.textScalerOf(context)
                                              .scale(16) >
                                          22) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        field,
                                        const SizedBox(height: 10),
                                        button,
                                      ],
                                    );
                                  }
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: field),
                                      const SizedBox(width: 12),
                                      button,
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: inboxMuted,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Chưa cần chọn ngày hoặc giờ.',
                                    style: TextStyle(color: inboxMuted),
                                  ),
                                ),
                              ],
                            ),
                            if (_saveError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _saveError!,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _saving || _planning
                                    ? null
                                    : () =>
                                          _openTaskPage(const CreateTaskPage()),
                                icon: const Icon(Icons.playlist_add),
                                label: const Text(
                                  'Tạo công việc và chia bước nhỏ',
                                ),
                              ),
                            ),
                            const InboxMascotMessage(),
                            const SizedBox(height: 24),
                            Text(
                              items == null
                                  ? 'Chưa lên kế hoạch'
                                  : 'Chưa lên kế hoạch · ${items.length} việc',
                              style: const TextStyle(
                                color: inboxInk,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            tasks.when(
                              skipLoadingOnRefresh: false,
                              loading: () => const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    semanticsLabel: 'Đang tải hộp việc',
                                  ),
                                ),
                              ),
                              error: (error, stack) => Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: inboxSoft,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Chưa tải được hộp việc. Vui lòng thử lại.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: inboxInk),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          ref.invalidate(inboxProvider),
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              ),
                              data: (items) => items.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 32,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: inboxBorder),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.inbox_outlined,
                                            color: inboxMuted,
                                            size: 32,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Hộp việc đang trống.\nGhi lại việc đầu tiên của bạn ở phía trên.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: inboxMuted,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : InboxTaskList(
                                      items: items,
                                      selected: _selected,
                                      onOpen: (id) => _openTaskPage(
                                        TaskDetailPage(taskId: id),
                                      ),
                                      onToggle: (id) => setState(() {
                                        if (!_selected.add(id)) {
                                          _selected.remove(id);
                                        }
                                      }),
                                      onToggleAll: () => setState(() {
                                        final allSelected = items.every(
                                          (task) => _selected.contains(task.id),
                                        );
                                        _selected.clear();
                                        if (!allSelected) {
                                          _selected.addAll(
                                            items.map((task) => task.id),
                                          );
                                        }
                                      }),
                                      onOpenDetail: _openTaskDetail,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
