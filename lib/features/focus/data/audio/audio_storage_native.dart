import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'local_sound.dart';

class AudioStorage {
  AudioStorage({this.directoryPath});
  final String? directoryPath;
  bool get supported => true;
  Future<Directory> _root() async {
    final base =
        directoryPath ??
        '${(await getApplicationSupportDirectory()).path}/focus_audio';
    return Directory(base).create(recursive: true);
  }

  bool _valid(LocalSound sound) =>
      RegExp(r'^[a-f0-9-]{36}$').hasMatch(sound.id) &&
      audioExtensions.contains(sound.extension);

  Future<List<LocalSound>> load() async {
    final manifest = File('${(await _root()).path}/library.json');
    if (!await manifest.exists()) return [];
    return (jsonDecode(await manifest.readAsString()) as List)
        .map((e) => LocalSound.fromJson(Map<String, dynamic>.from(e as Map)))
        .where(_valid)
        .toList();
  }

  Future<void> _save(List<LocalSound> sounds) async {
    final root = await _root();
    final temporary = File('${root.path}/library.json.tmp');
    await temporary.writeAsString(
      jsonEncode(sounds.map((s) => s.toJson()).toList()),
      flush: true,
    );
    await temporary.rename('${root.path}/library.json');
  }

  Future<LocalSound> add(XFile file, List<LocalSound> existing) async {
    final extension = file.name.split('.').last.toLowerCase();
    if (!audioExtensions.contains(extension)) {
      throw const AudioImportException(
        'Chọn file MP3, WAV, OGG, M4A, AAC hoặc FLAC.',
      );
    }
    final length = await file.length();
    if (length <= 0 || length > maxAudioBytes) {
      throw const AudioImportException(
        'File cần có nội dung và không vượt quá 50 MB.',
      );
    }
    final sound = LocalSound(
      id: const Uuid().v4(),
      name: file.name,
      extension: extension,
      bytes: length,
    );
    final target = File('${(await _root()).path}/${sound.id}.$extension');
    final temporary = File('${target.path}.part');
    final sink = temporary.openWrite();
    try {
      var copied = 0;
      await for (final chunk in file.openRead()) {
        copied += chunk.length;
        if (copied > maxAudioBytes) {
          throw const AudioImportException('File không được vượt quá 50 MB.');
        }
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      if (copied != length) {
        throw const AudioImportException(
          'File đã thay đổi. Vui lòng chọn lại.',
        );
      }
      await temporary.rename(target.path);
      await _save([...existing, sound]);
      return sound;
    } catch (_) {
      await sink.close();
      if (await temporary.exists()) await temporary.delete();
      if (await target.exists()) await target.delete();
      rethrow;
    }
  }

  Future<String?> pathFor(LocalSound sound) async {
    if (!_valid(sound)) return null;
    final file = File('${(await _root()).path}/${sound.id}.${sound.extension}');
    return await file.exists() ? file.path : null;
  }

  Future<void> remove(LocalSound sound, List<LocalSound> existing) async {
    final path = await pathFor(sound);
    await _save(existing.where((s) => s.id != sound.id).toList());
    if (path != null) await File(path).delete();
  }
}
