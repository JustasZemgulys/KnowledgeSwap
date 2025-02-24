import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:knowledgeswap/controls.dart';
import 'package:knowledgeswap/models/commentSong.dart';
import 'package:knowledgeswap/models/song.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/position_data.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;

class SongPlaying extends StatefulWidget {
  final List<Song> songs;
  final int initialIndex;

  const SongPlaying({Key? key, required this.songs, this.initialIndex = 0})
      : super(key: key);

  @override
  State<SongPlaying> createState() => _SongPlayingState();
}

class _SongPlayingState extends State<SongPlaying> {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;
  late UserInfo user_info;
  double userRating = 0;
  double avgRating = 0;
  final TextEditingController _commentController = TextEditingController();
  List<CommentSong> comments = [];

  Future<void> _sendRating(double rating) async {
    // Replace with your actual server URL
    const String serverUrl = "http://10.0.2.2/ratingAdd.php";

    try {
      // Replace with your actual user ID and song ID
      int userId = user_info.idUser;
      final int songId = widget.songs[_currentIndex].idSong;

      final response = await http.post(
        Uri.parse(serverUrl),
        body: {
          'userId': userId.toString(),
          'songId': songId.toString(),
          'rating': rating.toString(),
        },
      );

      if (response.statusCode == 200) {
        // Show SnackBar upon successful rating addition
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating added successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Update the userRating state
        setState(() {
          userRating = rating;
        });

        print(response.body);
      } else {
        print('Failed to send rating. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending rating: $e');
    }
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _audioPlayer = AudioPlayer()
      ..setUrl(widget.songs[widget.initialIndex].songPath);
    _currentIndex = widget.initialIndex;

    _audioPlayer.positionStream.listen((position) {
      // Check if the song has finished and move to the next one
      if (position == _audioPlayer.duration) {
        _playNext();
      }
    });

    // Load average rating when the widget is initialized
    loadAverageRating();
    loadComments();
  }

  void _playNext() {
    if (_currentIndex < widget.songs.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // If at the end of the queue, loop back to the beginning
      setState(() {
        _currentIndex = 0;
      });
    }

    _audioPlayer.stop();
    _audioPlayer.setUrl(widget.songs[_currentIndex].songPath);
    _audioPlayer.play();

    _addToUserHistory(user_info.idUser, widget.songs[_currentIndex].idSong);
    loadAverageRating();
    loadComments();
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _audioPlayer.stop();
      _audioPlayer.setUrl(widget.songs[_currentIndex].songPath);
      _audioPlayer.play();

      _addToUserHistory(user_info.idUser, widget.songs[_currentIndex].idSong);
      loadAverageRating();
      loadComments();
    }
  }

  Future<void> _addToUserHistory(int userId, int songId) async {
    // Replace with your actual server URL
    const String serverUrl = "http://10.0.2.2/addToHistory.php";
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        body: {
          'idUser': userId.toString(),
          'idSong': songId.toString(),
        },
      );

      if (response.statusCode == 200) {
        print('Song added to history successfully');
      } else {
        print(
            'Failed to add song to history. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding song to history: $e');
    }
  }

  Future<void> loadAverageRating() async {
    // Fetch the average rating for the current song from the server
    // Replace with your actual server URL
    const String serverUrl = "http://10.0.2.2/averageRating.php";

    try {
      final int songId = widget.songs[_currentIndex].idSong;

      final response = await http.post(
        Uri.parse(serverUrl),
        body: {
          'songId': songId.toString(),
        },
      );

      if (response.statusCode == 200) {
        // Parse the average rating from the response
        setState(() {
          avgRating = double.parse(response.body);
        });
      } else {
        print(
            'Failed to load average rating. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading average rating: $e');
    }
  }

  Future<void> loadComments() async {
    // Replace with your actual server URL
    const String serverUrl = "http://10.0.2.2/fetchComments.php";

    try {
      final int idSong = widget.songs[_currentIndex].idSong;

      final response = await http.post(
        Uri.parse(serverUrl),
        body: {'idSong': idSong.toString()},
      );

      if (response.statusCode == 200) {
        // Parse the comments from the response
        final List<dynamic> jsonComments = json.decode(response.body);
        setState(() {
          comments = jsonComments
              .map((jsonComment) => CommentSong.fromJson(jsonComment))
              .toList();
        });
      } else {
        print('Failed to load comments. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  Future<void> _sendComment(String commentText) async {
    // Replace with your actual server URL
    const String serverUrl = "http://10.0.2.2/insertCommentSong.php";

    int idUser = user_info.idUser;
    int idSong = widget.songs[_currentIndex].idSong;
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        body: {
          'comment_text': commentText,
          'idSong': idSong.toString(),
          'idUser': idUser.toString(),
        },
      );

      if (response.statusCode == 200) {
        // Show SnackBar upon successful comment addition
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Reload comments after adding a new comment
        loadComments();
      } else {
        print('Failed to send comment. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending comment: $e');
    }
  }

  Future<void> _showEditCommentPrompt(
      BuildContext context, CommentSong comment) async {
    final TextEditingController editCommentController =
        TextEditingController(text: comment.commentSong);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Comment"),
          content: TextField(
            controller: editCommentController,
            decoration:
                const InputDecoration(hintText: "Enter your edited comment..."),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Send the edited comment to the PHP script
                await _sendEditComment(
                    comment.idCommentSong, editCommentController.text);

                // Reload comments after editing a comment
                loadComments();

                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendEditComment(int commentId, String editedComment) async {
    // Replace with your actual server URL
    const String serverUrl = "http://10.0.2.2/editCommentSong.php";

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        body: {
          'comment_id': commentId.toString(),
          'edited_comment': editedComment,
        },
      );

      if (response.statusCode == 200) {
        // Show SnackBar upon successful comment edit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment edited successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('Failed to edit comment. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error editing comment: $e');
    }
  }

  Future<void> _deleteComment(int commentId) async {
    // Replace with your actual server URL
    const String serverUrl = "http://10.0.2.2/deleteCommentSong.php";

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        body: {'comment_id': commentId.toString()},
      );

      if (response.statusCode == 200) {
        // Show SnackBar upon successful comment deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Reload comments after deleting a comment
        loadComments();
      } else {
        print('Failed to delete comment. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: const Color(0x00000000),
        toolbarHeight: 130,
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<PositionData>(
          stream: _positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data;
            return Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/song_playing_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 300,
                  ),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipOval(
                        child: Image.network(
                          widget.songs[_currentIndex].imagePath,
                          height: 200,
                          width: 200,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.songs[_currentIndex].songName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontFamily: "Karla",
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    widget.songs[_currentIndex].artistName,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontFamily: "Karla",
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0),
                    child: ProgressBar(
                      barHeight: 4,
                      thumbRadius: 5,
                      thumbColor: Colors.purple,
                      progress: positionData?.position ?? Duration.zero,
                      buffered: positionData?.bufferedPosition ?? Duration.zero,
                      total: positionData?.duration ?? Duration.zero,
                      onSeek: _audioPlayer.seek,
                      thumbGlowRadius: 10,
                      progressBarColor: Colors.purple,
                      bufferedBarColor: Colors.purple.withOpacity(0.24),
                      barCapShape: BarCapShape.square,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Controls(
                    audioPlayer: _audioPlayer,
                    currentIndex: _currentIndex,
                    onNext: _playNext,
                    onPrevious: _playPrevious,
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  const Text(
                    "Rate this song!",
                    style: TextStyle(
                      fontFamily: "Karla",
                      fontSize: 20,
                    ),
                  ),
                  // First Rating Bar for User Rating
                  RatingBar.builder(
                    initialRating: userRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.purple,
                    ),
                    onRatingUpdate: (rating) {
                      print(rating);
                      _sendRating(rating);
                      print(avgRating);
                      loadAverageRating();
                    },
                  ),

                  // Spacer for some space between the rating bars
                  const SizedBox(height: 20),
                  const Text(
                    "Current Rating",
                    style: TextStyle(
                      fontFamily: "Karla",
                      fontSize: 20,
                    ),
                  ),
                  // Second Rating Bar for Average Rating
                  RatingBar.builder(
                    initialRating: avgRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.purple,
                    ),
                    onRatingUpdate: (rating) {
                      // This can be empty or you can handle the update if needed
                    },
                    ignoreGestures: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write your comment...',
                        border: OutlineInputBorder(),
                      ),
                      // Add any additional configuration as needed
                    ),
                  ),

                  // Add a button to post comments
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple),
                    onPressed: () {
                      setState(() {
                        _sendComment(_commentController.text);
                        _commentController.clear();
                      });
                    },
                    child: const Text('Post Comment'),
                  ),

                  // Add a ListView for displaying comments
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final CommentSong comment = comments[index];
                        final bool isCurrentUserComment =
                            comment.idUser == user_info.idUser;

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundImage: AssetImage('assets/usericon.jpg'),
                          ),
                          title: Text(comment.commentSong),
                          subtitle: Text(comment.username),
                          trailing: isCurrentUserComment
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        _showEditCommentPrompt(
                                            context, comment);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        _deleteComment(
                                            comments[index].idCommentSong);
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
