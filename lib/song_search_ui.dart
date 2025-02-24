import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/main_screen_ui.dart';
import 'package:knowledgeswap/models/song.dart'; // Import your Song model
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/song_component.dart';

class SongSearch extends StatefulWidget {
  const SongSearch({Key? key}) : super(key: key);

  @override
  State<SongSearch> createState() => _SongSearchState();
}

class _SongSearchState extends State<SongSearch> {
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2/fetchsongsall.php'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          _songs =
              List<Song>.from(data['songs'].map((song) => Song.fromJson(song)));
        });
      } else {
        print(data['message']);
      }
    } else {
      print('Failed to load songs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          const SizedBox(width: 1),
          IconButton(
            icon: Image.asset("assets/usericon.jpg"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileDetailsScreen()),
              );
            },
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.all(5.0),
          child: IconButton(
            icon: Image.asset("assets/logo.png"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            },
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0x00000000),
        title: Center(
          child: SizedBox(
            height: 38,
            width: 300,
            child: TextField(
              onChanged: (value) => onSearch(value),
              decoration: InputDecoration(
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
      ),
      body: Container(
        child: ListView.builder(
          padding: const EdgeInsets.only(right: 20, left: 20),
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onLongPress: () {},
              child: SongComponent(song: _songs[index], type: "play"),
            );
          },
        ),
      ),
    );
  }

  onSearch(String prompt) {}
}
