import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:knowledgeswap/models/playlist.dart';
import 'package:knowledgeswap/models/song.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/playlist_create_ui.dart';
import 'package:knowledgeswap/song_search_ui.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';

class AddPlaylist extends StatefulWidget {
  final Song? song;

  const AddPlaylist({Key? key, this.song}) : super(key: key);

  @override
  State<AddPlaylist> createState() => _AddPlaylistState();
}

class _AddPlaylistState extends State<AddPlaylist> {
  List<Playlist> _playlists = [];
  late UserInfo user_info;

  @override
  void initState() {
    super.initState();

    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    fetchPlaylists(user_info.idUser);
  }

  void fetchPlaylists(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/fetchplaylistbyuserid.php'),
        body: {'userId': userId.toString()},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            _playlists.addAll(data.map((playlistData) {
              return Playlist(
                int.tryParse(playlistData['idPlaylist'].toString()) ?? 0,
                playlistData['name'] ?? "",
                playlistData['description'] ?? "",
                playlistData['coverURL'] ?? "",
                int.tryParse(playlistData['userId'].toString()) ?? 0,
              );
            }));
          });

          print("Playlists fetched: $_playlists");
        } else {
          print("Gauti playlistai yra tušti.");
        }
      } else {
        throw Exception('Nepavyko gauti playlistų iš serverio.');
      }
    } catch (e) {
      print("Klaida gavus playlistus: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building UI with playlists: $_playlists");
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: const Color(0x00000000),
        toolbarHeight: 100,
      ),
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/song_playing_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 80,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.song?.songName ?? "",
                style: TextStyle(
                  fontFamily: "Karla",
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: 100,
            child: Container(
              padding: const EdgeInsets.all(16),
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlaylistCreation(),
                    ),
                  );
                },
                child: const Text(
                  'Create',
                  style: TextStyle(fontFamily: "Karla"),
                ),
                style: ElevatedButton.styleFrom(
                  shape: StadiumBorder(),
                  backgroundColor: Color(0x7E5496).withOpacity(1),
                ),
              ),
            ),
          ),
          // Dynamically create elevated buttons for each playlist
          // Dynamically create elevated buttons for each playlist
          Positioned(
            top: 300,
            left: 60,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: 280,
              height: 150,
              child: Column(
                // Change from ListView to Column
                children: [
                  // Create buttons for each playlist
                  for (Playlist playlist in _playlists)
                    ElevatedButton(
                      onPressed: () {
                        addToPlaylist(playlist.playlistId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0x7E5496).withOpacity(1),
                      ),
                      child: Text(
                        playlist.name,
                        style: TextStyle(fontFamily: "Karla"),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addToPlaylist(int? playlistId) async {
    if (playlistId != null) {
      print(widget.song?.songName);
      print(_playlists[0].name); // Add this line
      print(playlistId); // Add this line
      print(user_info.idUser); // Add this line

      // Send a POST request to the server with song and playlist ID
      String url = 'http://10.0.2.2/add_to_playlist.php';
      Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
      };
      Map<String, String> body = {
        'songId': widget.song?.idSong.toString() ?? "",
        'playlistId': playlistId.toString(),
        'userId': user_info.idUser.toString(),
      };

      try {
        var response =
            await http.post(Uri.parse(url), headers: headers, body: body);

        if (response.statusCode == 200) {
          print("Song added to playlist successfully.");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SongSearch()),
          );
        } else {
          print("Error: ${response.body}");
        }
      } catch (e) {
        print("Error: $e");
      }
    } else {
      print("Error: Playlist ID is null");
    }
  }
}
