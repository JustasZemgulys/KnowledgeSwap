import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/models/album.dart';
import 'package:knowledgeswap/models/song.dart';
import 'package:knowledgeswap/song_component.dart';
import 'package:knowledgeswap/song_playing_ui.dart'; // Import your SongComponent class

class AlbumSongScreen extends StatefulWidget {
  final Album album;
  const AlbumSongScreen({Key? key, required this.album}) : super(key: key);

  @override
  State<AlbumSongScreen> createState() => _AlbumSongScreenState();
}

class _AlbumSongScreenState extends State<AlbumSongScreen> {
  bool isIconPressed = true;
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2/fetchallalbumsongs.php?IdAlbum=${widget.album.idAlbum}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        _songs = List<Song>.from(data.map((song) => Song.fromJson(song)));
      });
    } else {
      print('Failed to load songs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            top: 120,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.album.title,
                style: const TextStyle(
                  fontFamily: "Karla",
                  fontSize: 35,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(top: 180, left: 30, right: 20),
              child: const SizedBox(
                height: 100,
              ),
            ),
          ),
          Positioned(
            bottom: 130,
            left: 20,
            child: SizedBox(
              width: 370,
              height: MediaQuery.of(context).size.height - 400,
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (BuildContext context, int index) {
                  return SongComponent(
                    type: "play",
                    song: _songs[index],
                  );
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
                color: const Color(0x00571b79).withOpacity(1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      IconButton(
                        alignment: Alignment.bottomCenter,
                        color: Colors.white,
                        iconSize: 36,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SongPlaying(
                                      songs: _songs,
                                    )),
                          );
                        },
                        icon: const Icon(Icons.play_circle_fill),
                      ),
                      const SizedBox(
                        width: 27,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
