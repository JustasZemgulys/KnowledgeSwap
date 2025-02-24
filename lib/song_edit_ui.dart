import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:knowledgeswap/image_container.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class SongEditUI extends StatefulWidget {
  final int IdSong;
  const SongEditUI({Key? key, required this.IdSong}) : super(key: key);

  @override
  State<SongEditUI> createState() => _SongEditUIState();
}

class _SongEditUIState extends State<SongEditUI> {
  String uploadedImagePath = "";
  String selectedAudioPath = "";
  int? selectedGenreId; // Initialize with null
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _bioFocusNode = FocusNode();
  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  List<Genre> genres = [];

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    try {
      var url = Uri.parse('http://10.0.2.2/fetchgenres.php');

      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        print('JSON Data: $jsonData');

        setState(() {
          genres = List<Genre>.from(jsonData.map((x) {
            print('Mapping: $x');
            return Genre.fromJson(x);
          }));
        });
      } else {
        print('Error fetching genres: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching genres: $e');
    }
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        uploadedImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _getAudio() async {
    var status = await Permission.manageExternalStorage.request();
    print("Storage permission status: $status");

    if (status == PermissionStatus.granted) {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
        );

        if (result != null) {
          File file = File(result.files.single.path!);
          print("Selected audio file: ${file.path}");
          setState(() {
            selectedAudioPath = file.path;
          });
        } else {
          print("File picking canceled");
        }
      } catch (e) {
        print("Error picking audio file: $e");
      }
    } else {
      print("Storage permission denied by user");
    }
  }

  Future<void> _uploadFiles() async {
    try {
      var url = Uri.parse(
          'http://10.0.2.2/editsong.php'); // Replace with your PHP script URL

      var request = http.MultipartRequest('POST', url)
        ..fields['idSong'] = widget.IdSong.toString()
        ..fields['songName'] = _songNameController.text
        ..fields['bio'] = _bioController.text
        ..fields['genreId'] = selectedGenreId.toString();

      // Attach audio file if selected
      if (selectedAudioPath.isNotEmpty) {
        request.files.add(
            await http.MultipartFile.fromPath('audioFile', selectedAudioPath));
      }

      // Attach cover picture if selected
      if (uploadedImagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
            'coverPicture', uploadedImagePath));
      }

      var response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Song updated successfully')),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ProfileDetailsScreen()),
          );

          // Add any additional logic you need after a successful update
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error updating song')),
          );
        }
      } else {
        print('Error uploading data: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error uploading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Genres: $genres"); // Printing genres for debugging
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: const Color(0x00000000),
        toolbarHeight: 100,
        title: const Text(
          "Edit a song",
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 23,
          ),
        ),
      ),
      body: Form(
        child: GestureDetector(
          onTap: () {
            _nameFocusNode.unfocus();
            _bioFocusNode.unfocus();
          },
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/creationBG.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 65,
                      ),
                      GestureDetector(
                        onTap: _getImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ImageContainer(
                            imagePath: uploadedImagePath,
                            width: 150,
                            height: 150,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        child: TextField(
                          controller: _songNameController,
                          focusNode: _nameFocusNode,
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
                            hintText: "Name...",
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        child: TextField(
                          controller: _bioController,
                          focusNode: _bioFocusNode,
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
                            hintText: "Bio...",
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        child: DropdownButtonFormField<int>(
                          value: selectedGenreId,
                          items: genres.map((Genre genre) {
                            return DropdownMenuItem<int>(
                              value: genre.id,
                              child: Text(
                                genre.name,
                                style: const TextStyle(
                                  fontFamily: "Karla",
                                  fontSize: 20,
                                  color: Colors.black38,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (int? value) {
                            setState(() {
                              selectedGenreId = value;
                            });
                          },
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
                            hintText: "Select Genre...",
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        child: ElevatedButton(
                          onPressed: _getAudio,
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: const Text(
                            'Upload Audio',
                            style: TextStyle(fontFamily: "Karla"),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          onPressed: _getImage,
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: const Text(
                            'Upload Image',
                            style: TextStyle(fontFamily: "Karla"),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        width: 150,
                        child: ElevatedButton(
                          onPressed: _uploadFiles,
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
            ],
          ),
        ),
      ),
    );
  }
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: int.parse(json['idGenre'].toString()), // Explicitly cast to int
      name: json['name'],
    );
  }
}
