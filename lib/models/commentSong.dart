// ignore_for_file: file_names

class CommentSong {
  final int idCommentSong;
  final String commentSong;
  final int idSong;
  final int idUser;
  final String username;

  CommentSong({
    required this.idCommentSong,
    required this.commentSong,
    required this.idSong,
    required this.idUser,
    required this.username,
  });

  factory CommentSong.fromJson(Map<String, dynamic> json) {
    return CommentSong(
      idCommentSong: int.parse(json['idCommentSong']),
      commentSong: json['commentSong'],
      idSong: int.parse(json['idSong']),
      idUser: int.parse(json['idUser']),
      username: json['username'],
    );
  }
}
