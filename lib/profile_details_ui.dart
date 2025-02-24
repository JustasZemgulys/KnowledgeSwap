// ignore_for_file: unnecessary_null_comparison, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:knowledgeswap/album_create_ui.dart';
import 'package:knowledgeswap/select_album_edit_ui.dart';
import 'package:knowledgeswap/song_creation_namebio_ui.dart';
import 'package:knowledgeswap/song_edit_ui_songs.dart';
import 'package:knowledgeswap/settings_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late UserInfo user_info;
  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
  }

  Future<void> updateProfilePicture(String newImageUrl, int userId) async {
    const String apiUrl =
        'http://10.0.2.2/profile_pic.php'; // Update with your server path
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'newImageUrl': newImageUrl,
        'userId': userId.toString(),
      },
    );

    if (response.statusCode == 200) {
      user_info.imageURL = newImageUrl;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile picture!')),
      );
    }
  }

  void _showImageUpdateDialog() {
    String newImageUrl = '';
    int userId = user_info.idUser;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Profile Picture'),
          content: TextField(
            onChanged: (value) {
              newImageUrl = value;
            },
            decoration: const InputDecoration(hintText: 'Enter new image URL'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                updateProfilePicture(newImageUrl, userId);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          actions: [
            PopupMenuButton<String>(
              onSelected: (selectChoice) {
                if (selectChoice == 'albumedit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SelectAlbumEditUI()),
                  );
                } else if (selectChoice == 'albumcreate') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AlbumCreateScreen()),
                  );
                } else if (selectChoice == 'createsong') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SongCreation()),
                  );
                } else if (selectChoice == 'editasong') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SongEditUiSongs()),
                  );
                } else if (selectChoice == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingScreen()),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                if (user_info.userType == 'Listener') {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Text('Settings'),
                    ),
                  ];
                } else if (user_info.userType == 'Creator') {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'albumedit',
                      child: Text('Edit an album'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'albumcreate',
                      child: Text('Create an album'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'createsong',
                      child: Text('Upload a song'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'editasong',
                      child: Text('Edit a song'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Text('Settings'),
                    ),
                  ];
                } else {
                  // Handle other user types if needed
                  return <PopupMenuEntry<String>>[];
                }
              },
            ),
          ],
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
                        fit: BoxFit.cover)),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: _showImageUpdateDialog,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: user_info.imageURL != null &&
                                      user_info.imageURL.isNotEmpty
                                  ? NetworkImage(user_info.imageURL)
                                      as ImageProvider // Cast to ImageProvider
                                  : const AssetImage('assets/usericon.jpg')
                                      as ImageProvider, // Cast to ImageProvider
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Center(
                      child: Text(
                        user_info.name ??
                            "Default Name", // Use the user's name from user_info
                        style: const TextStyle(
                          fontFamily: "Karla",
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 150,
                    ),
                    /*const Text("Bio",
                        style: TextStyle(
                            fontFamily: "Karla",
                            fontSize: 30,
                            color: Colors.black)),
                    const Text(
                        "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
                        style: TextStyle(
                            fontFamily: "Karla", color: Colors.black)),
                    const SizedBox(
                      height: 32,
                    ),*/
                    const Text("Songs",
                        style: TextStyle(
                            fontFamily: "Karla",
                            fontSize: 30,
                            color: Colors.black)),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
