import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:knowledgeswap/main_screen_ui.dart';
import 'package:knowledgeswap/models/song.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/song_component.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';

class RecommendedSongScreen extends StatefulWidget {
  const RecommendedSongScreen({Key? key}) : super(key: key);

  @override
  State<RecommendedSongScreen> createState() => _RecommenedSongScreenState();
}

class _RecommenedSongScreenState extends State<RecommendedSongScreen> {
  final List<Song> _songs = [];
  final List<bool> _isSelected = [true, false];
  bool _isLoading = false;
  late UserInfo user_info;

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    fetchRecommendedSongs();
  }

  Future<void> fetchRecommendedSongs() async {
    try {
      int userId = user_info.idUser;
      String apiUrl =
          'http://10.0.2.2/fetchrecommendedbygenre.php?user_id=$userId';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _songs.clear();
          _songs.addAll(data.map((item) => Song.fromJson(item)).toList());
          _isLoading = false;
        });
      } else {
        print('Failed to load recommended songs');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching recommended songs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchHistoryBasedSongs() async {
    try {
      int userId = user_info.idUser;
      String apiUrl =
          'http://10.0.2.2/fetchrecommendedbyhistory.php?user_id=$userId';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _songs.clear();
          _songs.addAll(data.map((item) => Song.fromJson(item)).toList());
          _isLoading = false;
        });
      } else {
        print('Failed to load history-based songs');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching history-based songs: $e');
      setState(() {
        _isLoading = false;
      });
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ToggleButtons(
              isSelected: _isSelected,
              onPressed: (int index) {
                setState(() {
                  for (int buttonIndex = 0;
                      buttonIndex < _isSelected.length;
                      buttonIndex++) {
                    if (buttonIndex == index) {
                      _isSelected[buttonIndex] = true;
                      if (index == 1) {
                        // Fetch and update the history-based songs
                        _songs.clear();
                        fetchHistoryBasedSongs();
                      } else {
                        // Fetch and update the recommended songs
                        _songs.clear();
                        fetchRecommendedSongs();
                      }
                    } else {
                      _isSelected[buttonIndex] = false;
                    }
                  }
                });
              },
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  child: const Text(
                    'By Genre',
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  child: const Text(
                    'By History',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(right: 20, left: 20),
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        child: SongComponent(song: _songs[index], type: "play"),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  onSearch(String prompt) {
    // Implement search functionality if needed
  }
}
