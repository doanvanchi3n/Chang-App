import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_dimensions.dart';
import '../../domain/task_detail.dart';

const Color _activeRowBackground = Color(0xFFECF4FC);
const Color _activeBadgeBackground = Color(0xFFD5E7F8);
const Color _inactiveBadgeBackground = Color(0xFFEFF3F7);
const Color _primaryActionBlue = Color(0xFF2364A5);

String formatFullDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

String formatShortDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String focusCtaLabel(TaskDetail task, TaskSubtask? focusStep) {
  if (focusStep != null) {
    return 'Tập trung vào bước ${focusStep.orderIndex}';
  }
  if (task.subtasks.isEmpty) {
    return 'Bắt đầu tập trung';
  }
  return 'Tập trung ôn lại';
}

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = switch (status) {
      TaskStatus.inProgress => (
        const Color(0xFFE5F0FB),
        _primaryActionBlue,
        _primaryActionBlue,
      ),
      TaskStatus.completed => (
        AppColors.successBackground,
        AppColors.success,
        AppColors.success,
      ),
      TaskStatus.todo => (
        AppColors.subtle,
        AppColors.textSecondary,
        AppColors.borderControl,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskPriorityBadge extends StatelessWidget {
  const TaskPriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (priority) {
      TaskPriority.high => (AppColors.errorBackground, AppColors.error),
      TaskPriority.medium => (AppColors.warningBackground, AppColors.warning),
      TaskPriority.low => (AppColors.brandSoft, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}

class TaskProgressBar extends StatelessWidget {
  const TaskProgressBar({super.key, required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0, 100);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Tiến độ công việc',
            value: '$clamped%',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: clamped / 100,
                minHeight: 10,
                color: clamped == 100 ? AppColors.success : _primaryActionBlue,
                backgroundColor: AppColors.brandSoft,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Text(
          '$clamped%',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class SubtaskListSection extends StatelessWidget {
  const SubtaskListSection({
    super.key,
    required this.task,
    required this.isWide,
    required this.focusStep,
    required this.busySubtaskIds,
    required this.addingStep,
    required this.showAddForm,
    required this.addTitleController,
    required this.addMinutesController,
    required this.addFormKey,
    required this.onToggleSubtask,
    required this.onSelectFocusStep,
    required this.onOpenAddForm,
    required this.onCancelAddForm,
    required this.onSubmitNewSubtask,
  });

  final TaskDetail task;
  final bool isWide;
  final TaskSubtask? focusStep;
  final Set<String> busySubtaskIds;
  final bool addingStep;
  final bool showAddForm;
  final TextEditingController addTitleController;
  final TextEditingController addMinutesController;
  final GlobalKey<FormState> addFormKey;
  final ValueChanged<TaskSubtask> onToggleSubtask;
  final ValueChanged<TaskSubtask> onSelectFocusStep;
  final VoidCallback onOpenAddForm;
  final VoidCallback onCancelAddForm;
  final VoidCallback onSubmitNewSubtask;

  @override
  Widget build(BuildContext context) {
    final nextStepId = task.nextStep?.id;
    final focusStepId = focusStep?.id;
    final completed = task.completedSubtaskCount;
    final total = task.totalSubtaskCount;
    final progress = task.computedProgressPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWide)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s4,
            children: [
              const Text(
                'Các bước thực hiện',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completed/$total bước hoàn thành',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        else
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s4,
            runSpacing: AppSpacing.s4,
            children: [
              const Text(
                'Các bước',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '· $completed/$total hoàn thành',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.s12),
        TaskProgressBar(percentage: progress),
        const SizedBox(height: AppSpacing.s12),
        if (task.subtasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.subtle,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: const Text(
              'Chưa có bước nhỏ nào. Chia nhỏ công việc thành tối đa 5 bước để dễ bắt đầu hơn.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < task.subtasks.length; i++) ...[
                if (i > 0 &&
                    task.subtasks[i].id != focusStepId &&
                    task.subtasks[i - 1].id != focusStepId)
                  const Divider(height: 1, color: Color(0xFFEDF1F5)),
                SubtaskRow(
                  step: task.subtasks[i],
                  isNextStep: task.subtasks[i].id == nextStepId,
                  isFocusedStep: task.subtasks[i].id == focusStepId,
                  isBusy: busySubtaskIds.contains(task.subtasks[i].id),
                  onToggle: () => onToggleSubtask(task.subtasks[i]),
                  onSelect: task.subtasks[i].isCompleted
                      ? null
                      : () => onSelectFocusStep(task.subtasks[i]),
                ),
              ],
            ],
          ),
        const SizedBox(height: AppSpacing.s8),
        if (showAddForm && task.canAddSubtask)
          _AddSubtaskForm(
            formKey: addFormKey,
            titleController: addTitleController,
            minutesController: addMinutesController,
            stepNumber: task.nextOrderIndex ?? (task.subtasks.length + 1),
            saving: addingStep,
            onCancel: onCancelAddForm,
            onSubmit: onSubmitNewSubtask,
          )
        else
          _AddStepTrigger(
            canAdd: task.canAddSubtask,
            onPressed: task.canAddSubtask ? onOpenAddForm : null,
          ),
      ],
    );
  }
}

class SubtaskRow extends StatelessWidget {
  const SubtaskRow({
    super.key,
    required this.step,
    required this.isNextStep,
    required this.isFocusedStep,
    required this.isBusy,
    required this.onToggle,
    this.onSelect,
  });

  final TaskSubtask step;
  final bool isNextStep;
  final bool isFocusedStep;
  final bool isBusy;
  final VoidCallback onToggle;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final highlighted = isFocusedStep && !step.isCompleted;
    final badgeText = isNextStep
        ? 'Bước tiếp theo'
        : isFocusedStep && !step.isCompleted
        ? 'Đang chọn'
        : null;

    final badgeWidget = badgeText == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _activeBadgeBackground,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: _primaryActionBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
    final stackBadgeBelow =
        MediaQuery.textScalerOf(context).scale(14) > 20 ||
        MediaQuery.sizeOf(context).width < 360;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: highlighted ? 2 : 0),
      child: Material(
        color: highlighted ? _activeRowBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: InkWell(
          key: ValueKey('subtask-row-${step.id}'),
          borderRadius: BorderRadius.circular(AppRadius.r12),
          onTap: isBusy ? null : onSelect,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: 2,
              ),
              child: Row(
                crossAxisAlignment: stackBadgeBelow
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: highlighted
                          ? _activeBadgeBackground
                          : _inactiveBadgeBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${step.orderIndex}',
                      style: TextStyle(
                        color: highlighted
                            ? _primaryActionBlue
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: highlighted
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  SizedBox(
                    width: AppSizes.control,
                    height: AppSizes.control,
                    child: Center(
                      child: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primaryActionBlue,
                              ),
                            )
                          : Checkbox(
                              key: ValueKey('subtask-checkbox-${step.id}'),
                              value: step.isCompleted,
                              activeColor: _primaryActionBlue,
                              checkColor: AppColors.textInverse,
                              side: const BorderSide(
                                color: AppColors.borderControl,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.r4,
                                ),
                              ),
                              semanticLabel:
                                  'Hoàn thành bước ${step.orderIndex}: ${step.title}',
                              onChanged: (_) => onToggle(),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            color: step.isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: highlighted
                                ? FontWeight.w600
                                : FontWeight.w400,
                            decoration: step.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                        if (badgeWidget != null && stackBadgeBelow) ...[
                          const SizedBox(height: 6),
                          badgeWidget,
                        ],
                      ],
                    ),
                  ),
                  if (badgeWidget != null && !stackBadgeBelow) ...[
                    const SizedBox(width: AppSpacing.s8),
                    badgeWidget,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddStepTrigger extends StatelessWidget {
  const _AddStepTrigger({required this.canAdd, required this.onPressed});

  final bool canAdd;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final button = Tooltip(
      message: canAdd
          ? 'Thêm bước nhỏ cho công việc'
          : 'Mỗi công việc chỉ nên chia tối đa 5 bước để chống quá tải. Hãy tạo công việc mới nếu cần.',
      child: TextButton(
        key: const ValueKey('add-subtask-button'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: _primaryActionBlue,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s8,
          ),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: canAdd ? _activeBadgeBackground : AppColors.disabled,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color: canAdd ? _primaryActionBlue : AppColors.textDisabled,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            const Flexible(
              child: Text(
                'Thêm bước',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    if (canAdd) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        button,
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.s8, top: 2),
          child: Text(
            'Đã đủ tối đa 5 bước nhỏ cho công việc này.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _AddSubtaskForm extends StatelessWidget {
  const _AddSubtaskForm({
    required this.formKey,
    required this.titleController,
    required this.minutesController,
    required this.stepNumber,
    required this.saving,
    required this.onCancel,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController minutesController;
  final int stepNumber;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thêm bước $stepNumber/${TaskDetail.maxSubtasks}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextFormField(
              key: const ValueKey('new-subtask-title-field'),
              controller: titleController,
              enabled: !saving,
              autofocus: true,
              maxLength: TaskDetail.maxSubtaskTitleLength,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!saving) onSubmit();
              },
              decoration: InputDecoration(
                hintText: 'Nhập nội dung bước nhỏ...',
                counterText: '',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(
                    color: _primaryActionBlue,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return 'Nhập tên bước nhỏ trước khi lưu.';
                if (trimmed.runes.length > TaskDetail.maxSubtaskTitleLength) {
                  return 'Tên bước nhỏ tối đa 200 ký tự.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s12,
              runSpacing: AppSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    key: const ValueKey('new-subtask-minutes-field'),
                    controller: minutesController,
                    enabled: !saving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Dự kiến',
                      suffixText: 'phút',
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                    ),
                    validator: (value) {
                      final minutes = int.tryParse(value ?? '');
                      if (minutes == null ||
                          minutes < TaskDetail.minEstimatedMinutes ||
                          minutes > TaskDetail.maxEstimatedMinutes) {
                        return '1–1440 phút';
                      }
                      return null;
                    },
                  ),
                ),
                Wrap(
                  spacing: AppSpacing.s8,
                  children: [
                    TextButton(
                      onPressed: saving ? null : onCancel,
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      key: const ValueKey('submit-new-subtask-button'),
                      onPressed: saving ? null : onSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryActionBlue,
                        foregroundColor: AppColors.textInverse,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                        ),
                      ),
                      child: Text(saving ? 'Đang lưu…' : 'Lưu bước'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TaskActionButtons extends StatelessWidget {
  const TaskActionButtons({
    super.key,
    required this.task,
    required this.focusStep,
    required this.onStartFocus,
    required this.onSchedule,
  });

  final TaskDetail task;
  final TaskSubtask? focusStep;
  final VoidCallback onStartFocus;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const ValueKey('focus-step-button'),
          onPressed: onStartFocus,
          style: FilledButton.styleFrom(
            backgroundColor: _primaryActionBlue,
            foregroundColor: AppColors.textInverse,
            minimumSize: const Size.fromHeight(AppSizes.control),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(focusCtaLabel(task, focusStep)),
        ),
        const SizedBox(height: AppSpacing.s12),
        OutlinedButton(
          key: const ValueKey('schedule-task-button'),
          onPressed: onSchedule,
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryActionBlue,
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.borderSubtle),
            minimumSize: const Size.fromHeight(AppSizes.control),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Xếp vào lịch'),
        ),
      ],
    );
  }
}

class TaskInfoSidebarCard extends StatelessWidget {
  const TaskInfoSidebarCard({
    super.key,
    required this.task,
    required this.focusStep,
    required this.onStartFocus,
    required this.onSchedule,
    required this.onAskAssistant,
    this.onTapProject,
  });

  final TaskDetail task;
  final TaskSubtask? focusStep;
  final VoidCallback onStartFocus;
  final VoidCallback onSchedule;
  final VoidCallback onAskAssistant;
  final VoidCallback? onTapProject;

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue(DateTime.now());
    final sessionMinutes = task.expectedSessionMinutes(focusStep);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Thông tin công việc',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _InfoRow(
            icon: Icons.folder_outlined,
            label: 'Dự án',
            value: task.project != null
                ? InkWell(
                    onTap: onTapProject,
                    child: Text(
                      task.project!.name,
                      style: const TextStyle(
                        color: _primaryActionBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: _primaryActionBlue,
                      ),
                    ),
                  )
                : const Text(
                    'Chưa gắn dự án',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Hạn hoàn thành',
            value: Text(
              task.dueDate != null
                  ? formatFullDate(task.dueDate!)
                  : 'Chưa đặt hạn',
              style: TextStyle(
                color: overdue ? AppColors.error : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: overdue ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Ưu tiên',
            value: TaskPriorityBadge(priority: task.priority),
          ),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Phiên dự kiến',
            value: Text(
              '$sessionMinutes phút',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Divider(height: 1, color: Color(0xFFEDF1F5)),
          ),
          TaskActionButtons(
            task: task,
            focusStep: focusStep,
            onStartFocus: onStartFocus,
            onSchedule: onSchedule,
          ),
          const SizedBox(height: AppSpacing.s16),
          _AssistantHintBanner(onTap: onAskAssistant),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.s8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: value),
        ),
      ],
    );
  }
}

class _AssistantHintBanner extends StatelessWidget {
  const _AssistantHintBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.honeySoft, Color(0xFFFBE293)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cần chia nhỏ hơn?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  key: const ValueKey('ask-assistant-link'),
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Nhờ trợ lý gợi ý →',
                      style: TextStyle(
                        color: _primaryActionBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: _primaryActionBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          SvgPicture.asset(
            'assets/mascot/checktask.svg',
            width: 72,
            height: 72,
            semanticsLabel: 'Linh vật Chặng gợi ý chia nhỏ bước',
          ),
        ],
      ),
    );
  }
}

class TaskDetailWebTopBar extends StatelessWidget {
  const TaskDetailWebTopBar({
    super.key,
    required this.onTapHome,
    required this.onTapTasks,
    required this.onTapAddTask,
  });

  final VoidCallback onTapHome;
  final VoidCallback onTapTasks;
  final VoidCallback onTapAddTask;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'chặng',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      for (final color in const [
                        Color(0xFF9DCDEE),
                        AppColors.honey,
                        _primaryActionBlue,
                      ])
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.s32),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _WebNavItem(
                            label: 'Hôm nay',
                            active: false,
                            onTap: onTapHome,
                          ),
                          _WebNavItem(
                            label: 'Công việc',
                            active: true,
                            onTap: onTapTasks,
                          ),
                          const _WebNavItem(
                            label: 'Lịch',
                            active: false,
                            onTap: null,
                          ),
                          const _WebNavItem(
                            label: 'Tiến độ',
                            active: false,
                            onTap: null,
                          ),
                          const _WebNavItem(
                            label: 'Trợ lý',
                            active: false,
                            onTap: null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  FilledButton.icon(
                    onPressed: onTapAddTask,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryActionBlue,
                      foregroundColor: AppColors.textInverse,
                      minimumSize: const Size(48, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm việc'),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.peach,
                    foregroundColor: AppColors.textPrimary,
                    child: Text(
                      'C',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

class _WebNavItem extends StatelessWidget {
  const _WebNavItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? _primaryActionBlue : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? _primaryActionBlue
                  : onTap == null
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
