// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:knowledgeswap/album_search_ui.dart';
import 'package:knowledgeswap/models/playlist.dart';
import 'package:knowledgeswap/playlist_create_ui.dart';
import 'package:knowledgeswap/playlist_ui.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/recommended_song_screen.dart';
import 'package:knowledgeswap/song_search_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late UserInfo user_info;
  List<dynamic> userSongs = [];
  List<Playlist> playlists = [];

  @override
  void initState() {
    super.initState();
    // Retrieve user information from the provider
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    displayUserHistory();
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

          //print("Playlists fetched: $playlists");
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

  // Future<bool> checkIfPlaylistsExist() async {
  //   // Užklausa į duomenų bazę, kuri tikrina, ar yra sukurtų playlistų
  //   // Galite pakeisti šią užklausą priklausomai nuo jūsų duomenų bazės struktūros
  //   final response =
  //       await http.get(Uri.parse('http://10.0.2.2/check_playlists.php'));

  //   if (response.statusCode == 200) {
  //     // Čia gauname atsakymą iš serverio
  //     return response.body.toLowerCase() == 'true';
  //   } else {
  //     // Įvyko klaida, apie tai pranešame ir grąžiname false
  //     print('Klaida tikrinant playlistus: ${response.statusCode}');
  //     return false;
  //   }
  // }

  Future<List<dynamic>> fetchUserHistory(int userId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/fetch_user_history.php'),
      body: {'userId': userId.toString()},
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      print(jsonDecode(response.body));
      List<dynamic> songs = jsonDecode(response.body);
      return songs;
    } else {
      // Handle the error appropriately, for example, by throwing an exception
      throw Exception('Failed to load user history');
    }
  }

  Future<void> displayUserHistory() async {
    try {
      List<dynamic> songs = await fetchUserHistory(
          user_info.idUser); // Assuming user_info has the userId

      setState(() {
        userSongs = songs;
      });
    } catch (error) {
      print('Error fetching user history: $error');
      // Handle the error, perhaps by showing an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          onTap: (newIndex) async {
            if (newIndex == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SongSearch()),
              );
            } else if (newIndex == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AlbumSearchScreen()),
              );
            } else if (newIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RecommendedSongScreen()),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              label: "Songs",
              icon: Icon(Icons.music_note),
            ),
            BottomNavigationBarItem(icon: Icon(Icons.album), label: "Albums"),
            BottomNavigationBarItem(
                icon: Icon(Icons.recommend), label: "Recommended"),
          ],
        ),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black),
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
          //leading: Padding(
          //padding: const EdgeInsets.all(5.0),
          //child: IconButton(
          //icon: Image.asset("assets/logo.png"),
          //onPressed: () {},
          //),
          //),
          elevation: 0,
          backgroundColor: const Color(0x00000000),
        ),
        body: Container(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Container(
                  alignment: Alignment.centerLeft,
                  child: const Text("Playlists",
                      style: TextStyle(
                        fontFamily: "Karla",
                        fontSize: 25,
                      ))),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: playlists.length + 1, // Add 1 for the button
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    if (index < playlists.length) {
                      // Display playlists
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlaylistUi(playlist: playlists[index]),
                            ),
                          );
                        },
                        child: Container(
                          height: 150,
                          width: 130,
                          margin: const EdgeInsets.all(10),
                          child: Stack(
                            children: [
                              // Playlist cover image as background
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  playlists[index].coverURL,
                                  fit: BoxFit.cover,
                                  height: double.infinity,
                                  width: double.infinity,
                                ),
                              ),
                              // Gradient overlay to fade from deepPurple
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.deepPurple.withOpacity(
                                          0.98), // Start with 0.9 opacity
                                      Colors.deepPurple
                                          .withOpacity(0), // End with 0 opacity
                                    ],
                                    stops: const [
                                      0.2,
                                      1.5
                                    ], // Adjust stops to control fading position
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                              // Playlist button overlay
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  //color: Colors.deepPurple.withOpacity(0.7),
                                ),
                                height: double.infinity,
                                width: double.infinity,
                                padding: const EdgeInsets.only(bottom: 10),
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  playlists[index].name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Karla",
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Display button
                      return Container(
                        height: 150,
                        width: 130,
                        margin: const EdgeInsets.all(10),
                        child: Stack(
                          children: [
                            // Placeholder image or background color
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    Colors.deepPurple, // Adjust color as needed
                              ),
                            ),
                            // Playlist button overlay
                            InkWell(
                              onTap: () {
                                // Navigate to PlaylistCreation screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PlaylistCreation(),
                                  ),
                                );
                              },
                              child: Container(
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.add_circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              Container(
                  alignment: Alignment.centerLeft,
                  child: const Text("History",
                      style: TextStyle(
                        fontFamily: "Karla",
                        fontSize: 40,
                      ))),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: userSongs.isEmpty
                    ? const Center(
                        child: Text(
                          'No songs in history',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        itemCount: userSongs.length,
                        itemBuilder: (context, index) {
                          final song = userSongs[index];
                          return ListTile(
                            leading: Image.network(song['coverURL']),
                            title: Text(song['title']),
                            subtitle: Text(
                                'Listened on: ${DateFormat('MMM d, HH:mm').format(DateTime.parse(song['play_date']))}'),
                            onTap: () {},
                          );
                        },
                      ),
              ),
            ],
          ),
        ));
  }
}
