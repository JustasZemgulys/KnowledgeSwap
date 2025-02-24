import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:knowledgeswap/profile_details_ui.dart';

class AlbumCreateSongAddScreen extends StatefulWidget {
  final int idAlbum;

  const AlbumCreateSongAddScreen({Key? key, required this.idAlbum})
      : super(key: key);

  @override
  State<AlbumCreateSongAddScreen> createState() =>
      _AlbumCreateSongAddScreenState();
}

class _AlbumCreateSongAddScreenState extends State<AlbumCreateSongAddScreen> {
  List<Map<String, dynamic>> songs = [];
  List<int> selectedSongIds = [];

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    final Uri uri = Uri.parse('http://10.0.2.2/fetchsongsnull.php');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      setState(() {
        songs = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      throw Exception('Failed to load songs');
    }
  }

  Future<void> updateSong(String idSong, int idAlbum) async {
    final Uri uri = Uri.parse('http://10.0.2.2/addsongtoalbumcreate.php');

    int parsedIdSong = int.tryParse(idSong) ?? 0;

    final response = await http.post(uri, body: {
      'idSong': parsedIdSong.toString(),
      'idAlbum': idAlbum.toString(),
    });

    if (response.statusCode == 200) {
      print('Song updated successfully');
    } else {
      print('Failed to update song');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: const Color(0x00000000),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/creationBG.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 100,
                  ),
                  const Center(
                    child: Text(
                      'Add songs',
                      style: TextStyle(
                          fontFamily: "Karla",
                          fontSize: 30,
                          color: Colors.white70),
                    ),
                  ),
                  const SizedBox(
                    height: 200,
                  ),
                  const Text("Songs",
                      style: TextStyle(
                          fontFamily: "Karla",
                          fontSize: 30,
                          color: Colors.black)),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: ClipOval(
                          child: Image.network(
                            songs[index]['coverURL'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(songs[index]['title']),
                        trailing: Checkbox(
                          value: selectedSongIds.contains(index),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedSongIds.add(index);
                              } else {
                                selectedSongIds.remove(index);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        for (var index in selectedSongIds) {
                          String idSong = songs[index]['idSong'];
                          updateSong(idSong, widget.idAlbum);
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileDetailsScreen(),
                          ),
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
          ],
        ),
      ),
    );
  }
}
