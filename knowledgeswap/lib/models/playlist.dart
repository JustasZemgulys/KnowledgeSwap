class Playlist {
  int? idPlaylist;
  String name;
  String description;
  String coverURL;
  int? userId;

  Playlist(
    this.idPlaylist,
    this.name,
    this.description,
    this.coverURL,
    this.userId,
  );

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      json['playlistId'] as int?,
      json['name'] as String? ?? "",
      json['description'] as String? ?? "",
      json['imageUrl'] as String? ?? "",
      json['userId'] as int?,
    );
  }

  int? get playlistId => idPlaylist;
}
