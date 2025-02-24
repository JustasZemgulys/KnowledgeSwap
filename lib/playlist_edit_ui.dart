import 'package:flutter/material.dart';
import 'package:knowledgeswap/image_container.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:knowledgeswap/main_screen_ui.dart';
import 'dart:io';

class PlaylistEdit extends StatefulWidget {
  final int? idPlaylist;
  const PlaylistEdit({Key? key, this.idPlaylist}) : super(key: key);

  @override
  State<PlaylistEdit> createState() => _PlaylistEditState();
}

class _PlaylistEditState extends State<PlaylistEdit> {
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController imageUrlController = TextEditingController();
  File? _selectedImage;

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
                'Edit a Playlist',
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
                    fillColor: Color(0x7E5496).withOpacity(1),
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
                padding: const EdgeInsets.only(left: 25, right: 20, top: 10),
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
                    shape: StadiumBorder(),
                    backgroundColor: Color(0x7E5496).withOpacity(1),
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
                    savePlaylist();
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(fontFamily: "Karla"),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 55, right: 45, top: 5),
                width: 220,
                height: 35,
                child: ElevatedButton(
                  onPressed: () {
                    deletePlaylist();
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontFamily: "Karla"),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    backgroundColor: Color(0x96546C).withOpacity(1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
      }
    });
  }

  // void deletePlaylist() async {
  //   String url = 'http://10.0.2.2/playlist_delete.php';
  //   Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
  //   Map<String, String> body = {
  //     'playlistId': widget.idPlaylist.toString(),
  //   };

  //   var response = await http.post(Uri.parse(url), headers: headers, body: body);

  //   if (response.statusCode == 200) {
  //     print("Playlist ištrintas sėkmingai.");
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => const MainScreen()),
  //     );
  //   } else {
  //     print("Klaida: ${response.body}");
  //   }
  // }

  void deletePlaylist() async {
    String url = 'http://10.0.2.2/playlist_delete.php';

    // Create a multipart request
    var request = http.MultipartRequest('POST', Uri.parse(url));

    request.fields['playlistId'] = widget.idPlaylist.toString();

    try {
      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        print("Playlist istrintas sėkmingai.");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        print("Klaida: ${response.reasonPhrase}");
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  void savePlaylist() async {
    String url = 'http://10.0.2.2/playlist_edit.php';

    // Create a multipart request
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add form fields only if they are not empty
    request.fields['playlistId'] = widget.idPlaylist.toString();
    if (nameController.text.isNotEmpty) {
      request.fields['name'] = nameController.text;
    }
    if (descriptionController.text.isNotEmpty) {
      request.fields['description'] = descriptionController.text;
    }

    // Add the image file
    if (_selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );
    }

    try {
      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        print("Playlist atnaujintas sėkmingai.");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        print("Klaida: ${response.reasonPhrase}");
      }
    } catch (error) {
      print("Error: $error");
    }
  }
}
