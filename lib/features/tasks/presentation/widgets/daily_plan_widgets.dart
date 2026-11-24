import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/daily_plan.dart';
import 'inbox_widgets.dart';

class PlanBudget extends StatelessWidget {
  const PlanBudget({
    super.key,
    required this.controller,
    required this.onChanged,
  });
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: inboxSoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        const title = Text(
          'Thời gian muốn dành hôm nay',
          style: TextStyle(
            color: inboxInk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        );
        final field = Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PlanMinutesField(
              controller: controller,
              label: 'Quỹ thời gian, tính bằng phút',
              onChanged: onChanged,
              compact: true,
            ),
            const Text('phút', style: TextStyle(color: inboxInk, fontSize: 16)),
          ],
        );
        if (constraints.maxWidth < 400 ||
            MediaQuery.textScalerOf(context).scale(16) > 22) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 10), field],
          );
        }
        return Row(
          children: [
            const Icon(Icons.schedule, color: inboxBlue, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: title),
            const SizedBox(width: 12),
            field,
          ],
        );
      },
    ),
  );
}

class PlanActions extends StatelessWidget {
  const PlanActions({
    super.key,
    required this.saving,
    required this.onSave,
    required this.onBack,
  });
  final bool saving;
  final VoidCallback? onSave;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final save = FilledButton(
        onPressed: onSave,
        style: FilledButton.styleFrom(
          backgroundColor: inboxBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(saving ? 'Đang lưu kế hoạch…' : 'Lưu kế hoạch hôm nay'),
      );
      final back = OutlinedButton(
        onPressed: onBack,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: const Text('Quay lại'),
      );
      if (constraints.maxWidth < 440 ||
          MediaQuery.textScalerOf(context).scale(16) > 22) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [save, const SizedBox(height: 10), back],
        );
      }
      return Row(
        children: [
          Expanded(child: back),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: save),
        ],
      );
    },
  );
}

class PlanMinutesField extends StatelessWidget {
  const PlanMinutesField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.compact = false,
  });
  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: compact ? 96 : 160,
    child: Semantics(
      label: compact ? label : null,
      child: TextFormField(
        controller: controller,
        textAlign: compact ? TextAlign.center : TextAlign.start,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: compact ? null : label,
          suffixText: compact ? null : 'phút',
          isDense: compact,
          contentPadding: compact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 14)
              : null,
          errorMaxLines: 2,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: inboxBorder),
          ),
        ),
        style: const TextStyle(color: inboxInk, fontWeight: FontWeight.w700),
        validator: (value) {
          final minutes = int.tryParse(value ?? '');
          return minutes == null || minutes < 1 || minutes > 1440
              ? 'Nhập 1–1440 phút'
              : null;
        },
        onChanged: (_) => onChanged(),
      ),
    ),
  );
}

class PlanTaskCard extends StatelessWidget {
  const PlanTaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.total,
    required this.minutes,
    required this.onChanged,
    required this.onRemove,
    required this.onMove,
  });
  final PlanningTask task;
  final int index;
  final int total;
  final TextEditingController minutes;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: inboxBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Tooltip(
                      message: 'Kéo để đổi thứ tự',
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Icon(Icons.drag_indicator, color: inboxMuted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFFE68C),
                  foregroundColor: inboxInk,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: inboxInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<int>(
                  tooltip: 'Đổi thứ tự ${task.title}',
                  icon: const Icon(Icons.swap_vert, color: inboxMuted),
                  onSelected: onMove,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: -1,
                      enabled: index > 0,
                      child: const Text('Đưa lên trên'),
                    ),
                    PopupMenuItem(
                      value: 1,
                      enabled: index < total - 1,
                      child: const Text('Đưa xuống dưới'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PlanMinutesField(
                  controller: minutes,
                  label: 'Thời lượng',
                  onChanged: onChanged,
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Bỏ khỏi kế hoạch'),
                  style: TextButton.styleFrom(foregroundColor: inboxBlue),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class PlanNotice extends StatelessWidget {
  const PlanNotice(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.info_outline, size: 20, color: inboxMuted),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: inboxMuted, height: 1.5),
        ),
      ),
    ],
  );
}
