import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/album_edit_ui.dart';
import 'dart:convert';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';

class SelectAlbumEditUI extends StatefulWidget {
  const SelectAlbumEditUI({Key? key}) : super(key: key);

  @override
  State<SelectAlbumEditUI> createState() => _SelectAlbumEditUIState();
}

class _SelectAlbumEditUIState extends State<SelectAlbumEditUI> {
  late UserInfo user_info;
  List<Map<String, dynamic>> albums = [];

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    fetchAlbums(); // Fetch albums when the widget is created
  }

  Future<void> fetchAlbums() async {
    final Uri uri = Uri.parse(
        'http://10.0.2.2/fetchalbumsedit.php?idUser=${user_info.idUser}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final dynamic jsonData = json.decode(response.body);

      if (jsonData is List) {
        setState(() {
          albums = List<Map<String, dynamic>>.from(jsonData);
        });
      } else {
        // Handle the case when jsonData is not a List
        print('Invalid data format');
      }
    } else {
      throw Exception('Failed to load albums');
    }
  }

  Future<void> removeAlbum(int albumId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/removealbum.php'),
      body: {'albumId': albumId.toString()},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      fetchAlbums();

      if (data['status'] == 'success') {
        // Album removed successfully, update the UI by calling fetchAlbums()
      } else {
        // Handle error
        print(data['message']);
      }
    } else {
      // Handle HTTP error
      print('Failed to remove album');
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
          "Select Album To Edit",
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
              // Display albums in a ListView
              ListView.builder(
                shrinkWrap: true,
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumEditUi(
                            albumId: int.parse(albums[index]['idAlbum']),
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.black),
                      onPressed: () {
                        // Call the backend script to remove the album
                        removeAlbum(int.parse(albums[index]['idAlbum']));
                      },
                    ),
                    leading: ClipOval(
                      child: Image.network(albums[index]['coverURL']),
                    ),
                    title: Text(albums[index]['title']),
                    subtitle: Text(user_info.name),
                    // Add other information as needed
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
