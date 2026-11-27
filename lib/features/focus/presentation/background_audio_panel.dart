import '../../../app/widgets/app_layout.dart';

import 'package:flutter/material.dart';

import '../../../app/widgets/confirmation_dialog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/choice_sheet.dart';
import '../../../app/widgets/feature_surface.dart';
import '../data/audio/audio_library.dart';
import '../data/audio/local_sound.dart';

class BackgroundAudioPanel extends ConsumerStatefulWidget {
  const BackgroundAudioPanel({
    super.key,
    required this.code,
    required this.enabled,
    required this.onChanged,
    this.paused = false,
    this.protectedCode,
  });
  final String code;
  final String? protectedCode;
  final bool enabled, paused;
  final ValueChanged<String> onChanged;
  @override
  ConsumerState<BackgroundAudioPanel> createState() =>
      _BackgroundAudioPanelState();
}

class _BackgroundAudioPanelState extends ConsumerState<BackgroundAudioPanel> {
  String _lastSound = 'WHITE_NOISE';
  bool _choosing = false;
  @override
  Widget build(BuildContext context) {
    final sounds =
        ref.watch(audioLibraryProvider).asData?.value ?? const <LocalSound>[];
    final on = widget.code != 'SILENT';
    if (on) _lastSound = widget.code;
    final sound = sounds.where((s) => s.code == widget.code).firstOrNull;
    final title = !on
        ? 'Không gian yên tĩnh'
        : widget.code == 'WHITE_NOISE'
        ? 'Nhiễu trắng'
        : sound?.name ?? 'Âm thanh từ thiết bị khác';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: changSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: changBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.headphones_rounded, color: changBlue),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Âm thanh nền',
                  style: TextStyle(
                    color: changInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: on,
                activeThumbColor: Colors.white,
                activeTrackColor: changBlue,
                onChanged: widget.enabled && !_choosing
                    ? (value) => widget.onChanged(value ? _lastSound : 'SILENT')
                    : null,
              ),
            ],
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: changInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.paused && on
                ? 'Âm thanh sẽ phát khi bạn tiếp tục học.'
                : 'Chọn âm thanh giúp bạn dễ tập trung hơn.',
            style: const TextStyle(
              color: changMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: changBlue,
                padding: EdgeInsets.zero,
              ),
              onPressed: !widget.enabled || _choosing
                  ? null
                  : () async {
                      setState(() => _choosing = true);
                      try {
                        final value = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          showDragHandle: true,
                          backgroundColor: Colors.white,
                          constraints: const BoxConstraints(
                            maxWidth: AppLayout.maxContentWidth,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          builder: (_) => _AudioSheet(
                            current: widget.code,
                            protectedCode: widget.protectedCode,
                          ),
                        );
                        if (mounted && value != null) widget.onChanged(value);
                      } finally {
                        if (mounted) setState(() => _choosing = false);
                      }
                    },
              icon: const Icon(Icons.library_music_outlined, size: 20),
              label: const Text('Chọn / thêm âm thanh'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioSheet extends ConsumerStatefulWidget {
  const _AudioSheet({required this.current, this.protectedCode});
  final String current;
  final String? protectedCode;
  @override
  ConsumerState<_AudioSheet> createState() => _AudioSheetState();
}

class _AudioSheetState extends ConsumerState<_AudioSheet> {
  late String _selected = widget.current;
  bool _busy = false;
  String? _error;

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sound = await ref.read(audioLibraryProvider.notifier).importFile();
      if (mounted && sound != null) setState(() => _selected = sound.code);
    } on AudioImportException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa đọc được file. Hãy chọn file âm thanh đã tải về thiết bị.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(LocalSound sound) async {
    final remove = await showChangConfirmation(
      context,
      title: 'Bỏ âm thanh khỏi Chặng?',
      message:
          'Bỏ “${sound.name}” khỏi thư viện trong app. File gốc của bạn được giữ nguyên.',
      cancelLabel: 'Giữ lại',
      confirmLabel: 'Bỏ âm thanh',
      destructive: true,
    );
    if (remove != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(audioLibraryProvider.notifier).remove(sound);
      if (mounted && _selected == sound.code) {
        setState(() => _selected = 'SILENT');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa xóa được âm thanh. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(audioLibraryProvider);
    final supported = ref.watch(audioStorageProvider).supported;
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Góc âm thanh',
                  style: TextStyle(
                    color: changInk,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Một âm thanh quen thuộc cho chặng học của bạn.',
                  style: TextStyle(color: changMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ChoiceTile(
                        title: 'Yên tĩnh',
                        subtitle: 'Tắt âm thanh nền',
                        icon: Icons.volume_off_outlined,
                        selected: _selected == 'SILENT',
                        onTap: _busy
                            ? null
                            : () => setState(() => _selected = 'SILENT'),
                      ),
                      const SizedBox(height: 10),
                      ChoiceTile(
                        title: 'Nhiễu trắng',
                        subtitle: 'Có sẵn trong Chặng · Phát lặp',
                        icon: Icons.graphic_eq_rounded,
                        selected: _selected == 'WHITE_NOISE',
                        onTap: _busy
                            ? null
                            : () => setState(() => _selected = 'WHITE_NOISE'),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 22, bottom: 10),
                        child: Text(
                          'ÂM THANH CỦA BẠN',
                          style: TextStyle(
                            color: changMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      library.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => TextButton(
                          onPressed: () => ref.invalidate(audioLibraryProvider),
                          child: const Text('Chưa mở được thư viện. Thử lại'),
                        ),
                        data: (sounds) => Column(
                          children: [
                            if (sounds.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Thêm bản nhạc hoặc âm thanh thiên nhiên bạn thích.',
                                  style: TextStyle(
                                    color: changMuted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            for (final sound in sounds)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ChoiceTile(
                                  title: sound.name,
                                  subtitle:
                                      '${(sound.bytes / (1024 * 1024)).toStringAsFixed(1)} MB · Lưu trên thiết bị này',
                                  icon: _selected == sound.code
                                      ? Icons.check_circle_rounded
                                      : Icons.music_note_rounded,
                                  selected: _selected == sound.code,
                                  onTap: _busy
                                      ? null
                                      : () => setState(
                                          () => _selected = sound.code,
                                        ),
                                  trailing: IconButton(
                                    tooltip:
                                        (sound.code == widget.current ||
                                            sound.code == widget.protectedCode)
                                        ? 'Đổi âm thanh trước khi xóa'
                                        : 'Bỏ âm thanh',
                                    onPressed:
                                        _busy ||
                                            (sound.code == widget.current ||
                                                sound.code ==
                                                    widget.protectedCode)
                                        ? null
                                        : () => _remove(sound),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy || !supported || library.asData == null
                            ? null
                            : _import,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: changBlue,
                          side: const BorderSide(color: changBorder),
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(_busy ? 'Đang xử lý…' : 'Thêm từ thiết bị'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        supported
                            ? 'MP3, WAV, OGG, M4A, AAC, FLAC · Tối đa 50 MB/file. File không tự đồng bộ sang thiết bị khác.'
                            : 'Thêm file trên ứng dụng desktop hoặc mobile.',
                        style: const TextStyle(
                          color: changMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FeatureButton(
                  'Dùng âm thanh này',
                  onPressed: _busy
                      ? null
                      : () => Navigator.pop(context, _selected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
