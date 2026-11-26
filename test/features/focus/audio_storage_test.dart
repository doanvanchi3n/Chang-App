import 'dart:io';

import 'package:chang_app/features/focus/data/audio/audio_storage_native.dart';
import 'package:chang_app/features/focus/data/audio/local_sound.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporary;
  late AudioStorage storage;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('chang_audio_test_');
    storage = AudioStorage(directoryPath: '${temporary.path}/library');
  });
  tearDown(() => temporary.delete(recursive: true));

  test(
    'import survives moving the original and reloading the library',
    () async {
      final source = await File('${temporary.path}/nhac hoc.wav')
          .writeAsBytes([82, 73, 70, 70, 1, 2, 3]);
      final sound = await storage.add(XFile(source.path), []);
      await source.delete();
      final reloaded = AudioStorage(directoryPath: '${temporary.path}/library');
      final sounds = await reloaded.load();
      expect(sounds.single.id, sound.id);
      expect(sounds.single.name, 'nhac hoc.wav');
      expect(
        await File((await reloaded.pathFor(sounds.single))!).readAsBytes(),
        [82, 73, 70, 70, 1, 2, 3],
      );
    },
  );

  test('removing a library entry preserves the original file', () async {
    final source = await File('${temporary.path}/nhac.mp3')
        .writeAsBytes([1, 2, 3]);
    final sound = await storage.add(XFile(source.path), []);
    final copiedPath = await storage.pathFor(sound);
    await storage.remove(sound, [sound]);
    expect(await source.exists(), isTrue);
    expect(await File(copiedPath!).exists(), isFalse);
    expect(await storage.load(), isEmpty);
  });

  test('invalid and empty files do not enter the library', () async {
    for (final (name, bytes) in [
      ('document.txt', [1]),
      ('empty.wav', <int>[]),
    ]) {
      final source = await File('${temporary.path}/$name').writeAsBytes(bytes);
      await expectLater(
        storage.add(XFile(source.path), []),
        throwsA(isA<AudioImportException>()),
      );
    }
    expect(await storage.load(), isEmpty);
  });

  test('oversized files are rejected before copying', () async {
    final source = File('${temporary.path}/large.wav');
    final handle = await source.open(mode: FileMode.write);
    await handle.truncate(maxAudioBytes + 1);
    await handle.close();
    await expectLater(
      storage.add(XFile(source.path), []),
      throwsA(isA<AudioImportException>()),
    );
    expect(await storage.load(), isEmpty);
  });

  test(
    'missing files can be reported without falling back to another sound',
    () async {
      final source = await File('${temporary.path}/nhac.wav')
          .writeAsBytes([1, 2, 3]);
      final sound = await storage.add(XFile(source.path), []);
      await File((await storage.pathFor(sound))!).delete();
      expect(await storage.pathFor(sound), isNull);
      expect((await storage.load()).single.id, sound.id);
    },
  );
}
