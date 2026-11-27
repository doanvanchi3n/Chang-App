class FocusSession {
  FocusSession(this.raw);
  final Map<String, dynamic> raw;
  String get id => raw['id'] as String;
  String? get taskId => raw['task_id'] as String?;
  String? get stepId => raw['subtask_id'] as String?;
  String get title => raw['task_title'] as String? ?? 'Công việc đã được xóa';
  String? get stepTitle => raw['step_title'] as String?;
  String? get project => raw['project_name'] as String?;
  int? get stepOrder => raw['step_order'] as int?;
  String get status => raw['status'] as String;
  int get targetSeconds => raw['target_duration_seconds'] as int;
  int get elapsedMs => (raw['elapsed_milliseconds'] as num).toInt();
  int get revision => raw['revision'] as int;
  bool get running => status == 'IN_PROGRESS';
  bool get paused => status == 'PAUSED';
  bool get reviewing => status == 'AWAITING_REVIEW';
  bool get saved => status == 'COMPLETED' || status == 'EARLY_STOPPED';
  String get soundCode => raw['ambient_sound'] == 'CUSTOM'
      ? 'LOCAL:${raw['custom_sound_id']}'
      : raw['ambient_sound'] as String;
  bool get sound => soundCode != 'SILENT';
  DateTime? get runningSince =>
      DateTime.tryParse(raw['running_since'] as String? ?? '')?.toUtc();
  DateTime get serverNow => DateTime.parse(raw['server_now'] as String).toUtc();
  String? get note => raw['note'] as String?;
  int elapsedAt(DateTime now) => running && runningSince != null
      ? (elapsedMs + now.difference(runningSince!).inMilliseconds).clamp(
          0,
          targetSeconds * 1000,
        )
      : elapsedMs;
}

/// Formats remaining/countdown seconds as `MM:SS` (supports durations > 60m).
String formatFocusClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final remainder = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
}

/// Formats elapsed seconds cleanly for the focus progress caption:
/// `< 60s` -> `22 giây`, exact minutes -> `5 phút`, mixed -> `5 phút 12 giây`.
String formatElapsedDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  if (safe < 60) return '$safe giây';
  final minutes = safe ~/ 60;
  final remainder = safe % 60;
  return remainder == 0 ? '$minutes phút' : '$minutes phút $remainder giây';
}

/// Computes clamped [0.0..1.0] progress for a focus session.
double computeFocusProgress(int elapsedMs, int targetSeconds) {
  if (targetSeconds <= 0) return 0;
  return (elapsedMs / (targetSeconds * 1000)).clamp(0.0, 1.0);
}
