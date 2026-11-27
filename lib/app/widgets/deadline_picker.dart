import 'package:flutter/material.dart';

import 'feature_surface.dart';

ThemeData changPickerTheme(BuildContext context) => Theme.of(context).copyWith(
  colorScheme: Theme.of(context).colorScheme.copyWith(
    primary: changBlue,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: changInk,
    onSurfaceVariant: changMuted,
    surfaceTint: Colors.transparent,
  ),
  datePickerTheme: const DatePickerThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    dividerColor: changBorder,
  ),
  timePickerTheme: TimePickerThemeData(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: changBorder),
    ),
    hourMinuteColor: changSoft,
    hourMinuteTextColor: changInk,
    dialBackgroundColor: changSoft,
    dialHandColor: changBlue,
    entryModeIconColor: changBlue,
  ),
);

Future<DateTime?> showChangDate(
  BuildContext context, {
  DateTime? initial,
  DateTime? now,
  String title = 'Hạn hoàn thành',
  String confirmLabel = 'Chọn ngày',
}) async {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  var selected = initial != null && !DateUtils.dateOnly(initial).isBefore(today)
      ? DateUtils.dateOnly(initial)
      : today;
  final date = await showDialog<DateTime>(
    context: context,
    builder: (context) => Theme(
      data: changPickerTheme(context),
      child: StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: changBorder),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: changSoft,
                        child: Icon(
                          Icons.calendar_month_outlined,
                          color: changBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: changInk,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng lịch',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: changMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: changSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NGÀY ĐÃ CHỌN',
                          style: TextStyle(
                            color: changMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(selected),
                          style: const TextStyle(
                            color: changInk,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  CalendarDatePicker(
                    key: ValueKey(selected),
                    initialDate: selected,
                    firstDate: today,
                    lastDate: DateTime(today.year + 20, 12, 31),
                    onDateChanged: (value) => setState(() => selected = value),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in [(0, 'Hôm nay'), (1, 'Ngày mai')])
                        ActionChip(
                          label: Text(entry.$2),
                          avatar: const Icon(
                            Icons.event_available,
                            size: 18,
                            color: changBlue,
                          ),
                          backgroundColor: changSoft,
                          side: BorderSide.none,
                          onPressed: () => setState(
                            () => selected = DateTime(
                              today.year,
                              today.month,
                              today.day + entry.$1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FeatureButton(
                    confirmLabel,
                    onPressed: () => Navigator.pop(context, selected),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return date;
}

Future<DateTime?> showChangDeadline(
  BuildContext context, {
  DateTime? initial,
  DateTime? now,
}) async {
  final date = await showChangDate(
    context,
    initial: initial,
    now: now,
    confirmLabel: 'Tiếp tục · Chọn giờ',
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(
      initial ?? DateTime.now().add(const Duration(hours: 1)),
    ),
    orientation: Orientation.portrait,
    helpText: 'Chọn giờ hoàn thành',
    cancelText: 'Hủy',
    confirmText: 'Xác nhận',
    builder: (context, child) => Theme(
      data: changPickerTheme(context),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    ),
  );
  return time == null
      ? null
      : DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
