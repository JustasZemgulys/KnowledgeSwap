class CommentPlaylist {
  final int commentPlaylistId;
  final String commentPlaylist;
  final int playlistId;
  final int userId;

  CommentPlaylist({
    required this.commentPlaylistId,
    required this.commentPlaylist,
    required this.playlistId,
    required this.userId,
  });

  factory CommentPlaylist.fromJson(Map<String, dynamic> json) {
    return CommentPlaylist(
      commentPlaylistId: int.parse(json['commentPlaylistId']),
      commentPlaylist: json['commentPlaylist'], // Provide a default value for null
      playlistId: int.parse(json['playlistId']),
      userId: int.parse(json['userId']),
    );
  }
}
