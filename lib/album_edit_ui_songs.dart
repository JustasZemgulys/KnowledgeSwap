import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:knowledgeswap/profile_details_ui.dart';

class AlbumEditUISongs extends StatefulWidget {
  final int albumId;

  const AlbumEditUISongs({Key? key, required this.albumId}) : super(key: key);

  @override
  State<AlbumEditUISongs> createState() => _AlbumEditUISongsState();
}

class _AlbumEditUISongsState extends State<AlbumEditUISongs> {
  List<Map<String, dynamic>> songs = [];

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2/fetchsongsremovealbum.php?idAlbum=${widget.albumId}'));

    if (response.statusCode == 200) {
      setState(() {
        songs = json.decode(response.body).cast<Map<String, dynamic>>();
      });
    } else {
      throw Exception('Failed to load songs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        title: const Text(
          "Remove Album Songs",
          style:
              TextStyle(color: Colors.black, fontFamily: "Karla", fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 700,
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading:
                      ClipOval(child: Image.network(songs[index]['coverURL'])),
                  title: Text(songs[index]['title'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.black),
                    onPressed: () {
                      // Call the backend script to remove the song from the album
                      _removeSong(int.parse(songs[index]['idSong']));
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileDetailsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              elevation: 0.0,
              shape: const StadiumBorder(),
              backgroundColor: const Color(0x007e5496).withOpacity(1),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(fontFamily: "Karla"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeSong(int songId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/removesongalbum.php'),
      body: {'songId': songId.toString()},
    );

    if (response.statusCode == 200) {
      print(response.body);
      // Refresh the song list after removal
      _fetchSongs();
    } else {
      print('Failed to remove song. Status Code: ${response.statusCode}');
    }
  }
}
