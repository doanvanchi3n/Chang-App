class LocalSound {
  const LocalSound({
    required this.id,
    required this.name,
    required this.extension,
    required this.bytes,
  });
  final String id, name, extension;
  final int bytes;
  String get code => 'LOCAL:$id';
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'extension': extension,
    'bytes': bytes,
  };
  factory LocalSound.fromJson(Map<String, dynamic> value) => LocalSound(
    id: value['id'] as String,
    name: value['name'] as String,
    extension: value['extension'] as String,
    bytes: value['bytes'] as int,
  );
}

const audioExtensions = ['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac'];
const maxAudioBytes = 50 * 1024 * 1024;

class AudioImportException implements Exception {
  const AudioImportException(this.message);
  final String message;
}
