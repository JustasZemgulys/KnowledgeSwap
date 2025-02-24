import 'package:flutter/material.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/song_edit_ui.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SongEditUiSongs extends StatefulWidget {
  const SongEditUiSongs({Key? key}) : super(key: key);

  @override
  State<SongEditUiSongs> createState() => _SongEditUiSongsState();
}

class _SongEditUiSongsState extends State<SongEditUiSongs> {
  late UserInfo user_info;
  List<Map<String, dynamic>> songs = [];

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/fetchsongsedit.php'),
      body: {'idUser': user_info.idUser.toString()},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          songs = List<Map<String, dynamic>>.from(data['songs']);
        });
      } else {
        // Handle error
        print(data['message']);
      }
    } else {
      // Handle HTTP error
      print('Failed to load songs');
    }
  }

  Future<void> removeSong(int idSong) async {
    final response = await http.post(
      Uri.parse(
          'http://10.0.2.2/removesong.php'), // Replace with your PHP script URL
      body: {'idSong': idSong.toString()},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['success']) {
        // Song removed successfully, update the UI by calling fetchSongs()
        fetchSongs();
      } else {
        // Handle error
        print(data['message']);
      }
    } else {
      // Handle HTTP error
      print('Failed to remove song');
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
          "Edit Songs",
          style:
              TextStyle(color: Colors.black, fontFamily: "Karla", fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 550,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SongEditUI(
                                    IdSong: int.parse(song['idSong']),
                                  )),
                        );
                      },
                      leading: ClipOval(child: Image.network(song['coverURL'])),
                      title: Text(song['title']),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          removeSong(int.parse(song['idSong']));
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileDetailsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontFamily: "Karla"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
