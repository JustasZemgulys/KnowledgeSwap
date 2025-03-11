class Song {
  final int idSong;
  final String artistName;
  final String songName;
  final String imagePath;
  final String songPath;

  Song({
    required this.idSong,
    required this.artistName,
    required this.songName,
    required this.imagePath,
    required this.songPath,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      idSong: int.parse(json['idSong']),
      artistName: json['artistName'],
      songName: json['title'] ?? '',
      imagePath: json['coverURL'] ?? '',
      songPath: json['songURL'] ?? '',
    );
  }
}
