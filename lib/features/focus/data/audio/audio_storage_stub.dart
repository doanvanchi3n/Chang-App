import 'package:file_selector/file_selector.dart';

import 'local_sound.dart';

class AudioStorage {
  bool get supported => false;
  Future<List<LocalSound>> load() async => [];
  Future<LocalSound> add(XFile file, List<LocalSound> existing) async =>
      throw const AudioImportException(
        'Thêm file trên ứng dụng desktop hoặc mobile.',
      );
  Future<String?> pathFor(LocalSound sound) async => null;
  Future<void> remove(LocalSound sound, List<LocalSound> existing) async {}
}
