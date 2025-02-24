import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:knowledgeswap/album_component.dart';
import 'package:knowledgeswap/main_screen_ui.dart';
import 'package:knowledgeswap/models/album.dart';
import 'package:knowledgeswap/profile_details_ui.dart';

class AlbumSearchScreen extends StatefulWidget {
  const AlbumSearchScreen({super.key});

  @override
  State<AlbumSearchScreen> createState() => _AlbumSearchScreenState();
}

class _AlbumSearchScreenState extends State<AlbumSearchScreen> {
  List<Album> albums = [];

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

  Future<void> fetchAlbums() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2/fetchalbumsall.php'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          albums = data.map((albumData) {
            return Album(
              int.parse(albumData['idAlbum']),
              albumData['title'],
              albumData['coverURL'],
              int.parse(albumData['IdArtist']),
              albumData['artistName'],
            );
          }).toList();
        });
      } else {
        throw Exception('Failed to load albums');
      }
    } catch (e) {
      print('Error fetching albums: $e');
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
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Container(
          child: ListView.builder(
            itemCount: albums.length,
            itemBuilder: (BuildContext context, int index) {
              return AlbumComponent(
                album: albums[index],
                type: "play",
              );
            },
          ),
        ),
      ),
    );
  }

  onSearch(String prompt) {}
}
