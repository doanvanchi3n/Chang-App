import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/remote/supabase_client_provider.dart';
import '../../home/data/dashboard_provider.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/presentation/inbox_provider.dart';
import '../data/focus_repository.dart';
import '../data/audio/audio_library.dart';
import '../domain/focus_session.dart';

class FocusState {
  const FocusState({
    this.session,
    this.busy = false,
    this.expanded = false,
    this.pending = false,
    this.error,
    this.audioError,
    this.tick = 0,
  });
  final FocusSession? session;
  final bool busy, expanded, pending;
  final String? error, audioError;
  final int tick;
  FocusState copy({
    FocusSession? session,
    bool clearSession = false,
    bool? busy,
    bool? expanded,
    bool? pending,
    String? error,
    bool clearError = false,
    String? audioError,
    bool clearAudioError = false,
    int? tick,
  }) => FocusState(
    session: clearSession ? null : session ?? this.session,
    busy: busy ?? this.busy,
    expanded: expanded ?? this.expanded,
    pending: pending ?? this.pending,
    error: clearError ? null : error ?? this.error,
    audioError: clearAudioError ? null : audioError ?? this.audioError,
    tick: tick ?? this.tick,
  );
}

final focusControllerProvider = NotifierProvider<FocusController, FocusState>(
  FocusController.new,
);

class FocusController extends Notifier<FocusState> {
  final _clock = Stopwatch();
  DateTime _serverBase = DateTime.now().toUtc();
  int _baseMs = 0;
  int? _holdMs;
  Map<String, dynamic>? _pending;
  String? _owner;
  bool _disposed = false;
  AudioPlayer? _player;
  String? _playingCode;
  AudioPlayer? _chime;
  String reviewNote = '';
  bool? reviewComplete;
  Future<void> _audioQueue = Future.value();
  @override
  FocusState build() {
    final client = ref.watch(supabaseClientProvider);
    final auth = client.auth.onAuthStateChange.listen((_) {
      unawaited(restore());
    });
    final ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_disposed || state.session == null || state.session!.saved) return;
      state = state.copy(tick: state.tick + 1);
      if (state.session!.running &&
          remainingSeconds == 0 &&
          !state.busy &&
          !state.pending) {
        unawaited(command('FINISH'));
      }
    });
    ref.onDispose(() {
      _disposed = true;
      ticker.cancel();
      auth.cancel();
      _clock.stop();
      _player?.dispose();
      _chime?.dispose();
    });
    scheduleMicrotask(restore);
    return const FocusState();
  }

  DateTime get serverNow => _serverBase.add(_clock.elapsed);
  int get elapsedMs {
    final s = state.session;
    if (s == null) return 0;
    final params = _pending?['params'] as Map?;
    if (s.paused && params?['p_action'] == 'RESUME') {
      // A queued resume counts from the user's click, including during a retry.
      final since = DateTime.parse(params!['p_at'] as String);
      return (_baseMs +
              serverNow.difference(since).inMilliseconds.clamp(0, 10800000))
          .clamp(0, s.targetSeconds * 1000);
    }
    return (_holdMs ?? (_baseMs + (s.running ? _clock.elapsedMilliseconds : 0)))
        .clamp(0, s.targetSeconds * 1000);
  }

  int get elapsedSeconds => elapsedMs ~/ 1000;
  int get remainingSeconds =>
      ((state.session?.targetSeconds ?? 0) - elapsedSeconds).clamp(0, 10800);
  void expanded(bool value) {
    state = state.copy(expanded: value);
  }

  String get _cacheKey => 'focus_snapshot_v1_$_owner';
  String get _pendingKey => 'focus_pending_v1_$_owner';

  void _apply(Map<String, dynamic> data, {bool cached = false}) {
    final previous = state.session;
    final session = FocusSession(data);
    if (previous?.id != session.id) {
      final params = _pending?['params'] as Map?;
      reviewNote = params?['p_note'] as String? ?? session.note ?? '';
      reviewComplete =
          params?['p_complete'] as bool? ??
          session.raw['confirmed_step_complete'] as bool?;
    }
    if (session.saved) {
      reviewNote = session.note ?? '';
      reviewComplete = session.raw['confirmed_step_complete'] as bool?;
    }
    _serverBase = session.serverNow;
    if (cached && data['_received_at'] != null) {
      final age = DateTime.now().toUtc().difference(
        DateTime.parse(data['_received_at'] as String),
      );
      _serverBase = _serverBase.add(age.isNegative ? Duration.zero : age);
    }
    _baseMs = session.elapsedAt(_serverBase);
    _clock
      ..reset()
      ..start();
    _holdMs = null;
    final params = _pending?['params'] as Map?;
    if (params != null && ['PAUSE', 'FINISH'].contains(params['p_action'])) {
      _holdMs = session.elapsedAt(DateTime.parse(params['p_at'] as String));
    }
    state = state.copy(
      session: session,
      clearError: true,
      pending: _pending != null,
    );
    unawaited(_syncAudio());
    if (!cached &&
        previous?.id == session.id &&
        previous?.reviewing == false &&
        session.reviewing) {
      unawaited(_playChime());
    }
  }

  Future<void> _playChime() async {
    try {
      _chime ??= AudioPlayer();
      await _chime!.play(AssetSource('audio/session_end.wav'), volume: .35);
    } catch (_) {
      // Audio is optional; the summary remains available if playback fails.
    }
  }

  Future<void> restore() async {
    if (_disposed || state.busy) return;
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) {
      _owner = null;
      _pending = null;
      _holdMs = null;
      state = state.copy(clearSession: true, pending: false, clearError: true);
      unawaited(_syncAudio());
      return;
    }
    state = state.copy(busy: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      if (_owner != user.id) {
        _owner = user.id;
        _pending = null;
        state = state.copy(clearSession: true);
        final pending = prefs.getString(_pendingKey);
        if (pending != null) {
          _pending = Map<String, dynamic>.from(jsonDecode(pending) as Map);
        }
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          _apply(
            Map<String, dynamic>.from(jsonDecode(cached) as Map),
            cached: true,
          );
        }
      }
      if (_pending != null) {
        await _sendPending();
        return;
      }
      final data = await ref.read(focusRepositoryProvider).current();
      if (_disposed ||
          ref.read(supabaseClientProvider).auth.currentUser?.id != user.id) {
        return;
      }
      if (data == null) {
        state = state.copy(
          clearSession: true,
          clearError: true,
          pending: false,
        );
        await prefs.remove(_cacheKey);
        unawaited(_syncAudio());
      } else {
        data['_received_at'] = DateTime.now().toUtc().toIso8601String();
        _apply(data);
        await prefs.setString(_cacheKey, jsonEncode(data));
      }
    } catch (_) {
      if (!_disposed) {
        state = state.copy(
          error: 'Chưa đồng bộ được phiên học. Kiểm tra kết nối rồi thử lại.',
          pending: _pending != null,
        );
      }
    } finally {
      if (!_disposed) state = state.copy(busy: false);
    }
  }

  Future<bool> start(
    String task,
    String? step,
    int seconds,
    String sound,
  ) async {
    if (state.busy ||
        state.pending ||
        state.session != null && !state.session!.saved) {
      return false;
    }
    state = state.copy(busy: true, clearError: true);
    try {
      _owner = await ref.read(inboxRepositoryProvider).ensureUserId();
      _pending = {
        'method': 'start_focus_session',
        'params': {
          'p_id': const Uuid().v4(),
          'p_task': task,
          'p_step': step,
          'p_seconds': seconds,
          'p_sound': sound,
        },
      };
      await _sendPending();
      return true;
    } catch (_) {
      if (!_disposed) {
        state = state.copy(
          error: _pending == null
              ? 'Không thể bắt đầu phiên với lựa chọn này. Tải lại công việc hoặc mở phiên đang có.'
              : 'Chưa xác nhận được phiên đã bắt đầu. Bấm đồng bộ để kiểm tra, không bắt đầu thêm phiên mới.',
          pending: _pending != null,
        );
      }
      return false;
    } finally {
      if (!_disposed) state = state.copy(busy: false);
    }
  }

  Future<bool> command(
    String action, {
    String? sound,
    bool? complete,
    String? note,
  }) async {
    final s = state.session;
    if (s == null || state.busy || state.pending) return false;
    if (action == 'PAUSE' || action == 'FINISH') _holdMs = elapsedMs;
    _pending = {
      'method': 'control_focus_session',
      'params': {
        'p_id': s.id,
        'p_command': const Uuid().v4(),
        'p_revision': s.revision,
        'p_action': action,
        'p_at': serverNow.toIso8601String(),
        'p_sound': sound,
        'p_complete': complete,
        'p_note': note,
      },
    };
    state = state.copy(busy: true, pending: true, clearError: true);
    unawaited(_syncAudio());
    try {
      await _sendPending();
      return true;
    } catch (_) {
      if (!_disposed) {
        state = state.copy(
          error: _pending == null
              ? 'Phiên đã thay đổi hoặc lựa chọn không còn hợp lệ. Kiểm tra thông tin và thử lại.'
              : 'Chưa xác nhận được thay đổi. Đồng bộ lại để tiếp tục phiên.',
          pending: _pending != null,
        );
      }
      return false;
    } finally {
      if (!_disposed) state = state.copy(busy: false);
    }
  }

  Future<void> _sendPending() async {
    final pending = _pending!;
    final prefs = await SharedPreferences.getInstance();
    // Persist the same command before sending so timeouts/restarts cannot duplicate a session.
    final stored = await prefs.setString(_pendingKey, jsonEncode(pending));
    if (!stored) throw StateError('Pending command could not be saved');
    final owner = _owner;
    final repository = ref.read(focusRepositoryProvider);
    late final Map<String, dynamic> data;
    try {
      data = await repository.execute(
        pending['method'] as String,
        Map<String, dynamic>.from(pending['params'] as Map),
      );
    } on PostgrestException catch (error) {
      // These explicit PostgreSQL errors roll back the transaction. Network
      // failures remain pending and must replay the exact same command instead.
      if (['22023', '23505', '40001', '42501'].contains(error.code)) {
        await prefs.remove(_pendingKey);
        _pending = null;
        _holdMs = null;
        if (!_disposed) {
          state = state.copy(pending: false);
          try {
            final current = await repository.current();
            if (!_disposed &&
                ref.read(supabaseClientProvider).auth.currentUser?.id ==
                    owner) {
              if (current == null) {
                state = state.copy(clearSession: true);
                await prefs.remove(_cacheKey);
                unawaited(_syncAudio());
              } else {
                current['_received_at'] = DateTime.now()
                    .toUtc()
                    .toIso8601String();
                _apply(current);
                await prefs.setString(_cacheKey, jsonEncode(current));
              }
            }
          } catch (_) {
            // Keep the last confirmed snapshot; the user can refresh again.
            if (!_disposed) unawaited(_syncAudio());
          }
        }
      }
      rethrow;
    }
    if (_disposed ||
        ref.read(supabaseClientProvider).auth.currentUser?.id != owner) {
      return;
    }
    data['_received_at'] = DateTime.now().toUtc().toIso8601String();
    await prefs.setString(_cacheKey, jsonEncode(data));
    await prefs.remove(_pendingKey);
    _pending = null;
    _apply(data);
    if (state.session!.saved) {
      ref.invalidate(dashboardProvider);
      ref.invalidate(inboxProvider);
      if (state.session!.taskId != null) {
        ref.invalidate(taskDetailProvider(state.session!.taskId!));
      }
      await prefs.remove(_cacheKey);
    }
  }

  Future<void> reconcile() async {
    if (state.busy) return;
    // Server rejections are resolved by reloading only after checking the pending result.
    await restore();
  }

  Future<void> _syncAudio() {
    _audioQueue = _audioQueue
        .then((_) async {
          if (_disposed) return;
          final s = state.session;
          final shouldPlay =
              s != null &&
              s.running &&
              s.sound &&
              _holdMs == null &&
              remainingSeconds > 0;
          if (!shouldPlay) {
            if (_player != null) await _player!.pause();
            return;
          }
          _player ??= AudioPlayer();
          if (_playingCode != s.soundCode) {
            await _player!.stop();
            _playingCode = null;
            final Source source;
            if (s.soundCode.startsWith('LOCAL:')) {
              final path = await ref
                  .read(audioLibraryProvider.notifier)
                  .pathForCode(s.soundCode);
              if (path == null) {
                throw StateError('Local audio unavailable');
              }
              source = DeviceFileSource(path);
            } else {
              source = AssetSource('audio/white_noise.wav');
            }
            if (_disposed ||
                state.session?.id != s.id ||
                state.session?.soundCode != s.soundCode ||
                state.session?.running != true ||
                _holdMs != null) {
              return;
            }
            await _player!.setReleaseMode(ReleaseMode.loop);
            await _player!.play(source, volume: .18);
            _playingCode = s.soundCode;
          } else if (_player!.state != PlayerState.playing) {
            await _player!.resume();
          }
          if (!_disposed && state.audioError != null) {
            state = state.copy(clearAudioError: true);
          }
        })
        .catchError((Object _) {
          if (!_disposed) {
            state = state.copy(
              audioError: 'Không mở được âm thanh trên thiết bị này. Chọn lại file hoặc đổi sang Nhiễu trắng.',
            );
          }
        });
    return _audioQueue;
  }
}
