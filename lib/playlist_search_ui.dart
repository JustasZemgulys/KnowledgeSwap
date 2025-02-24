import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:knowledgeswap/main_screen_ui.dart';
import 'package:knowledgeswap/models/playlist.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/playlist_component.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';

class PlaylistSearchScreen extends StatefulWidget {
  const PlaylistSearchScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistSearchScreen> createState() => _PlaylistSearchScreenState();
}

class _PlaylistSearchScreenState extends State<PlaylistSearchScreen> {
  List<Playlist> playlists = [];
  late UserInfo user_info;

  @override
  void initState() {
    super.initState();

    // Retrieve user information from the provider
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
            playlists.addAll(data.map((playlistData) {
              return Playlist(
                int.tryParse(playlistData['idPlaylist'].toString()) ?? 0,
                playlistData['name'] ?? "",
                playlistData['description'] ?? "",
                playlistData['coverURL'] ?? "",
                int.tryParse(playlistData['userId'].toString()) ?? 0,
              );
            }));
          });

          print("Playlists fetched: $playlists");
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
                  builder: (context) => const ProfileDetailsScreen(),
                ),
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
            itemCount: playlists.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {},
                child: PlaylistComponent(
                  playlist: playlists[index],
                  type:
                      "play", // Ar šis reikalingas, priklauso nuo jūsų reikalavimų
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void onSearch(String prompt) {
    // Implement your search logic here
  }
}
