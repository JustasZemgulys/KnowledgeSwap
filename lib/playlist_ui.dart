import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:knowledgeswap/models/commentPlaylist.dart';
import 'package:knowledgeswap/models/playlist.dart';
import 'package:knowledgeswap/models/song.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/playlist_edit_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:knowledgeswap/song_playing_ui.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';

class PlaylistUi extends StatefulWidget {
  final Playlist? playlist;
  const PlaylistUi({Key? key, this.playlist}) : super(key: key);

  @override
  State<PlaylistUi> createState() => _PlaylistState();
}

class _PlaylistState extends State<PlaylistUi> {
  late UserInfo user_info;
  List<Song> _songs = [];
  bool isIconPressed = true;
  late int songCount = 0;
  double averageRating = 0.0;
  TextEditingController commentController = TextEditingController();
  List<CommentPlaylist> _comments = [];

  @override
  void initState() {
    super.initState();

    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    fetchSongs();
    fetchAverageRating();
    fetchComments();
  }

  // Function to fetch comments
  void fetchComments() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/fetchPlaylistComments.php'),
        body: {'playlistId': widget.playlist?.idPlaylist.toString()},
      );

      if (response.statusCode == 200) {
        final String rawJson = response.body;
        print("Raw JSON: $rawJson");

        // Check if the response body is not null before decoding
        if (rawJson != null && rawJson.isNotEmpty) {
          final List<dynamic> data = json.decode(rawJson);

          setState(() {
            _comments = data.map((commentData) {
              return CommentPlaylist.fromJson(commentData);
            }).toList();
          });
        } else {
          // Handle the case where the response body is empty or null
          print('Error fetching comments: Response body is empty or null.');
        }
      } else {
        throw Exception(
            'Failed to fetch comments from the server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching comments: $e");
    }
  }

  void addComment(String comment) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/addPlaylistComment.php'),
        body: {
          'playlistId': widget.playlist?.idPlaylist.toString(),
          'comment': comment,
          'userId': user_info.idUser.toString(),
          // You may need to send user information like userId, userName, etc.
        },
      );

      if (response.statusCode == 200) {
        // Assuming your PHP script returns success if the comment is added
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          // Comment successfully added, update your local state
          fetchComments();
        } else {
          // Handle failure
          print("Failed to add comment");
        }
      } else {
        // Handle HTTP error
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  // Function to edit a comment
  void editComment(BuildContext context, CommentPlaylist comment) async {
    TextEditingController editController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'New Comment'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Perform the edit operation
              await updateComment(
                  comment.commentPlaylistId, editController.text);

              // Refresh the comments after editing
              fetchComments();

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

// Function to update a comment
  Future<void> updateComment(int commentId, String newComment) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/updatePlaylistComment.php'),
        body: {
          'commentId': commentId.toString(),
          'newComment': newComment,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          // Comment successfully updated
          print('Comment updated successfully');
        } else {
          // Handle failure
          print('Failed to update comment');
        }
      } else {
        // Handle HTTP error
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating comment: $e');
    }
  }

  // Function to delete a comment
  void deleteComment(int commentId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/deletePlaylistComment.php'),
        body: {
          'commentId': commentId.toString(),
        },
      );

      if (response.statusCode == 200) {
        // Assuming your PHP script returns success if the comment is deleted
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          // Comment successfully deleted, update your local state
          fetchComments();
        } else {
          // Handle failure
          print("Failed to delete comment");
        }
      } else {
        // Handle HTTP error
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }

  // Function to add a rating
  void addRating(double rating) async {
    // Add your implementation to send the rating to the server
    // Example:
    // final response = await http.post(
    //   Uri.parse('your_rating_add_endpoint'),
    //   body: {
    //     'playlistId': widget.playlist?.idPlaylist.toString(),
    //     'rating': rating.toString(),
    //   },
    // );
    // Handle the response accordingly
  }

  // Function to fetch average rating
  void fetchAverageRating() async {
    // Add your implementation to fetch the average rating from the server
    // Example:
    // final response = await http.get(
    //   Uri.parse('your_average_rating_endpoint/${widget.playlist?.idPlaylist}'),
    // );
    // Handle the response accordingly
    // For now, let's assume the average rating is 4.5 (you should replace this with your actual implementation)
    setState(() {
      averageRating = 4.5;
    });
  }

  void removeSongFromPlaylist(int songId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/removesongfromplaylist.php'),
        body: {
          'songId': songId.toString(),
          'playlistId': widget.playlist?.idPlaylist.toString(),
        },
      );

      if (response.statusCode == 200) {
        // Assuming your PHP script returns success if the song is removed
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          // Song successfully removed, update your local state
          setState(() {
            _songs.removeWhere((song) => song.idSong == songId);
          });
        } else {
          // Handle failure
          print("Failed to remove song from playlist");
        }
      } else {
        // Handle HTTP error
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error removing song from playlist: $e");
    }
  }

  void fetchSongs() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/fetchsongsbyplaylist.php'),
        body: {'playlistId': widget.playlist?.idPlaylist.toString()},
      );

      if (response.statusCode == 200) {
        final String rawJson = response.body;
        //print("Raw JSON: $rawJson");
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('songs')) {
          final List<dynamic> songsData = data['songs'];

          setState(() {
            _songs.addAll(
              songsData
                  .map((songData) =>
                      Song.fromJson(songData as Map<String, dynamic>))
                  .toList(),
            );
            songCount = data['songsCount'] ?? 0;
          });
          print("Songs: $_songs");
        } else {
          throw Exception('Invalid JSON format: Missing "songs" key.');
        }
      } else {
        throw Exception('Failed to fetch songs from the server.');
      }
    } catch (e) {
      print("Error fetching songs: $e");
    }
  }

  // Function to handle shuffle button press
  void handleShuffle() {
    setState(() {
      //_songs = ShuffleAlgorithm.autoShuffle(_songs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: const Color(0x00000000).withOpacity(0),
        toolbarHeight: 100,
      ),
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/PlaylistBG.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 90,
            right: 20,
            child: Container(
              height: 35,
              width: 210,
              child: TextField(
                onChanged: (value) => onSearch(value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0x7E5496).withOpacity(1),
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(color: Colors.black45),
                  ),
                  hintStyle: const TextStyle(
                    fontSize: 14,
                  ),
                  hintText: "Search..",
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.playlist?.name ?? "",
                style: TextStyle(
                  fontFamily: "Karla",
                  fontSize: 35,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                "${songCount} songs",
                style: TextStyle(
                  fontFamily: "Karla",
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(top: 180, left: 30, right: 20),
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_songs[index].songName),
                    subtitle: Text(_songs[index].artistName),
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          _songs[index].imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SongPlaying(
                            songs: _songs,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        removeSongFromPlaylist(_songs[index].idSong);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: 20,
            child: Container(
              child: RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 25,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.black,
                ),
                onRatingUpdate: (rating) {
                  addRating(rating);
                },
              ),
            ),
          ),
          Positioned(
            top: 225,
            left: 25,
            child: Container(
              child: Text(
                'Average Rating: $averageRating',
                style: TextStyle(
                  fontFamily: "Karla",
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 260,
            right: -10,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PlaylistEdit(
                            idPlaylist: widget.playlist?.idPlaylist)),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 260,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                icon: const Icon(Icons.shuffle),
                onPressed: () {
                  handleShuffle();
                },
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 200,
              height: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x571B79).withOpacity(1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                ),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongPlaying(
                        songs: _songs,
                      ),
                    ),
                  );
                  setState(() {
                    isIconPressed = !isIconPressed;
                  });
                },
                icon: const Icon(
                  Icons.play_circle_fill,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Section for writing comments
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        controller: commentController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a comment';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Write your comment...',
                          border: OutlineInputBorder(),
                        ),
                        // Add any additional configuration as needed
                      ),
                    ),

                    // Add a button to post comments
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 150, // Adjust the width as needed
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          onPressed: () {
                            // Check if the text field is not empty before posting a comment
                            if (commentController.text.isNotEmpty) {
                              setState(() {
                                addComment(commentController.text);
                                commentController.clear();
                              });
                            }
                          },
                          child: const Text('Post Comment'),
                        ),
                      ),
                    ),

                    // Use ListView.builder for displaying comments
                    Expanded(
                      child: SizedBox(
                        height: 10, // Set your desired height here
                        child: SingleChildScrollView(
                          child: Column(
                            children: _comments.map((comment) {
                              final bool isCurrentUserComment =
                                  comment.userId == user_info.idUser;

                              return ListTile(
                                contentPadding: const EdgeInsets.all(1.0),
                                leading: const CircleAvatar(
                                  backgroundImage:
                                      AssetImage('assets/usericon.jpg'),
                                ),
                                title: Text(comment.commentPlaylist!),
                                subtitle: Text(user_info.username),
                                trailing: isCurrentUserComment
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              editComment(context, comment);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              deleteComment(
                                                  comment.commentPlaylistId);
                                            },
                                          ),
                                        ],
                                      )
                                    : null,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  onSearch(String prompt) {}
}
