import 'package:flutter/material.dart';
import 'package:knowledgeswap/main_screen_ui.dart';
import 'package:knowledgeswap/image_container.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'dart:io';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';

class PlaylistCreation extends StatefulWidget {
  const PlaylistCreation({Key? key}) : super(key: key);

  @override
  State<PlaylistCreation> createState() => _PlaylistCreationState();
}

class _PlaylistCreationState extends State<PlaylistCreation> {
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController imageUrlController = TextEditingController();
  File? _selectedImage;
  late UserInfo user_info;

  @override
  void initState() {
    super.initState();

    // Retrieve user information from the provider
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: const Color(0x00000000),
        toolbarHeight: 100,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/creationBG.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 60), // Added space
              const Text(
                'Create a Playlist',
                style: TextStyle(
                  fontFamily: "Karla",
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: 300,
                height: 65,
                padding: const EdgeInsets.only(left: 25, right: 20, top: 10),
                margin: const EdgeInsets.symmetric(horizontal: 70),
                child: TextField(
                  controller: nameController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0x7E5496).withOpacity(1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.deepPurple.withOpacity(0.15),
                      ),
                    ),
                    hintStyle: const TextStyle(
                      fontFamily: "Karla",
                      fontSize: 20,
                      color: Colors.white54,
                    ),
                    hintText: "Name...",
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(
                    left: 25, right: 20, top: 10, bottom: 30),
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    pickImage();
                  },
                  child: const Text(
                    'Select Cover',
                    style: TextStyle(fontFamily: "Karla"),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0x7E5496).withOpacity(1),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 70),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: descriptionController,
                  maxLines: 5,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.deepPurple.withOpacity(0.30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.deepPurple.withOpacity(0.15),
                      ),
                    ),
                    hintStyle: const TextStyle(
                      fontFamily: "Karla",
                      fontSize: 20,
                      color: Colors.black38,
                    ),
                    hintText: "Description...",
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 0, top: 60, bottom: 20),
                child: ImageContainer(
                  imagePath: _selectedImage?.path ?? '',
                  height: 200,
                  width: 200,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 55, right: 45, top: 10),
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    if (_areInputsValid()) {
                      savePlaylist();
                    } else {
                      // Jei bent vienas laukas tuščias, parodyti klaidos pranešimą
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All fields must be filled.'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(fontFamily: "Karla"),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _areInputsValid() {
    // Patikriname, ar visi įvesties laukai užpildyti
    return nameController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        _selectedImage != null;
  }

  void pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        imageUrlController.text = pickedFile.path;
      }
    });
  }

  void savePlaylist() async {
    String url = 'http://10.0.2.2/playlist_create.php';

    // Create a multipart request
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add form fields
    request.fields['name'] = nameController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['userId'] = user_info.idUser.toString();

    // Add the image file
    if (_selectedImage != null) {
      var file =
          await http.MultipartFile.fromPath('file', _selectedImage!.path);
      request.files.add(file);
    }

    try {
      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        print("Playlistas sukurtas ir išsaugotas sėkmingai.");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        print("Klaida: ${response.reasonPhrase}");
      }
    } catch (error) {
      print("Error: $error");
    }
  }
}
