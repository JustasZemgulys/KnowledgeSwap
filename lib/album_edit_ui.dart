import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/album_edit_ui_songs.dart';
import 'package:knowledgeswap/image_container.dart';

class AlbumEditUi extends StatefulWidget {
  final int albumId;
  const AlbumEditUi({Key? key, required this.albumId}) : super(key: key);

  @override
  State<AlbumEditUi> createState() => _AlbumEditUiState();
}

class _AlbumEditUiState extends State<AlbumEditUi> {
  final TextEditingController _nameController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      String apiUrl = "http://10.0.2.2/editalbum.php";
      String name = _nameController.text;

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['idAlbum'] = widget.albumId.toString();
      request.fields['name'] = name;

      var file = await http.MultipartFile.fromPath('coverURL', _image!.path);
      request.files.add(file);

      try {
        var response = await request.send();
        if (response.statusCode == 200) {
          print('Album updated successfully');
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AlbumEditUISongs(
                      albumId: widget.albumId,
                    )),
          );
        } else {
          print('Failed to update album. Status Code: ${response.statusCode}');
        }
      } catch (error) {
        print('Error updating album: $error');
      }
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
                    height: 20,
                  ),
                  const SizedBox(
                    height: 60,
                  ),
                  Center(
                    child: SizedBox(
                      width: 300,
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
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _pickImage(),
                      style: ElevatedButton.styleFrom(
                        elevation: 0.0,
                        shape: const StadiumBorder(),
                        backgroundColor: const Color(0x007e5496).withOpacity(1),
                      ),
                      child: const Text(
                        'Select Cover',
                        style: TextStyle(fontFamily: "Karla"),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 120,
                  ),
                  Center(
                    child: _image != null
                        ? Image.file(
                            _image!,
                            height: 200,
                            width: 200,
                          )
                        : const ImageContainer(
                            height: 200,
                            width: 200,
                            imagePath: "",
                          ),
                  ),
                  const SizedBox(
                    height: 100,
                  ),
                  Center(
                    child: SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: () => _uploadImage(),
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(fontFamily: "Karla"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
