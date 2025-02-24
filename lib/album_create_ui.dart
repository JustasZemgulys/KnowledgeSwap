import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/album_create_songs_add_ui.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';

class AlbumCreateScreen extends StatefulWidget {
  const AlbumCreateScreen({Key? key}) : super(key: key);

  @override
  State<AlbumCreateScreen> createState() => _AlbumCreateScreenState();
}

class _AlbumCreateScreenState extends State<AlbumCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _image;
  late UserInfo user_info;

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadData() async {
    try {
      var url = Uri.parse('http://10.0.2.2/uploadAlbum.php');

      var request = http.MultipartRequest('POST', url)
        ..fields['name'] = _nameController.text
        ..fields['idUser'] = user_info.idUser.toString();

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _image!.path),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        final rawResponse = await response.stream.bytesToString();
        print('Raw response: $rawResponse');

        // Extract JSON part from the response
        final jsonStartIndex = rawResponse.indexOf('{');
        final jsonString =
            jsonStartIndex >= 0 ? rawResponse.substring(jsonStartIndex) : '';

        try {
          final responseData = json.decode(jsonString);

          if (responseData['status'] == 'success') {
            int idAlbum = responseData['idAlbum'];
            print('Album created successfully with idAlbum: $idAlbum');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AlbumCreateSongAddScreen(idAlbum: idAlbum),
              ),
            );
          } else {
            print('Failed to create album');
          }
        } catch (e) {
          print('Error decoding JSON: $e');
        }
      } else {
        print('Failed to upload image. Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error during upload: $e');
    }
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
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/creationBG.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Container(
                  width: 300,
                  height: 65,
                  padding: const EdgeInsets.only(left: 25, right: 20, top: 15),
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0x007e5496).withOpacity(1),
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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _pickImage(),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    backgroundColor: const Color(0x007e5496).withOpacity(1),
                  ),
                  child: const Text(
                    'Select Cover',
                    style: TextStyle(fontFamily: "Karla"),
                  ),
                ),
                const SizedBox(height: 200),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _image != null ? null : Colors.grey,
                  ),
                  child:
                      _image != null ? Image.file(_image!) : const SizedBox(),
                ),
                const SizedBox(height: 100),
                ElevatedButton(
                  onPressed: () {
                    _uploadData();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 70),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontFamily: "Karla"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
