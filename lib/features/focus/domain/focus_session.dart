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
