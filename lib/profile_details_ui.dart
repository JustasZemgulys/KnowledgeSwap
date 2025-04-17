// ignore_for_file: unnecessary_null_comparison, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:knowledgeswap/settings_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'get_ip.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late UserInfo userinfo;
  @override
  void initState() {
    super.initState();
    userinfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
  }

  Future<void> updateProfilePicture(String newImageUrl, int userId) async {
    if (newImageUrl == "") newImageUrl = "default";

    String userIP = await getUserIP();
    final String apiUrl =
        '$userIP/profile_pic.php'; // Update with your server path
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'newImageUrl': newImageUrl,
        'Id': userId.toString(),
      },
    );

    if (response.statusCode == 200) {
      userinfo.imageURL = newImageUrl;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile picture!')),
      );
    }
  }

  void _showImageUpdateDialog() {
    String newImageUrl = '';
    int userId = userinfo.id;

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
                if (selectChoice == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingScreen()),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                ];
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
                //width: MediaQuery.of(context).size.width,
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
                      height: 10,
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
                              image: userinfo.imageURL != "default"
                                  ? NetworkImage(userinfo.imageURL)
                                      as ImageProvider
                                  : const AssetImage('assets/usericon.jpg')
                                      as ImageProvider,
                              onError: (_, __) {
                                setState(() {
                                  userinfo.imageURL =
                                      "default"; // Fallback to default image
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: Text(
                        userinfo.name,
                        style: const TextStyle(
                          fontFamily: "Karla",
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 150,
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
