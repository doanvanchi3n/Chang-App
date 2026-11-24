import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_storage.dart';
import 'local_sound.dart';

final audioStorageProvider = Provider((ref) => AudioStorage());
final audioLibraryProvider =
    AsyncNotifierProvider<AudioLibrary, List<LocalSound>>(AudioLibrary.new);

class AudioLibrary extends AsyncNotifier<List<LocalSound>> {
  bool _mutating = false;
  @override
  Future<List<LocalSound>> build() => ref.watch(audioStorageProvider).load();

  Future<LocalSound?> importFile() async {
    if (_mutating) return null;
    _mutating = true;
    try {
      final existing = await future;
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Âm thanh',
            extensions: audioExtensions,
            mimeTypes: ['audio/*'],
            uniformTypeIdentifiers: ['public.audio'],
          ),
        ],
      );
      if (file == null) return null;
      final sound = await ref.read(audioStorageProvider).add(file, existing);
      state = AsyncData([...existing, sound]);
      return sound;
    } finally {
      _mutating = false;
    }
  }

  Future<void> remove(LocalSound sound) async {
    if (_mutating) return;
    _mutating = true;
    try {
      final existing = await future;
      await ref.read(audioStorageProvider).remove(sound, existing);
      state = AsyncData(existing.where((s) => s.id != sound.id).toList());
    } finally {
      _mutating = false;
    }
  }

  Future<String?> pathForCode(String code) async {
    final sounds = await future;
    final sound = sounds.where((s) => s.code == code).firstOrNull;
    return sound == null ? null : ref.read(audioStorageProvider).pathFor(sound);
  }
}
