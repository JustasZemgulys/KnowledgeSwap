import 'package:flutter/material.dart';
import 'package:knowledgeswap/main_screen_ui.dart';
import 'package:knowledgeswap/models/genre.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class GenreSelectionScreen extends StatefulWidget {
  const GenreSelectionScreen({super.key});

  @override
  State<GenreSelectionScreen> createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen> {
  late UserInfo user_info;
  List<Genre> genreList = []; // Updated to store Genre objects

  @override
  void initState() {
    super.initState();
    super.initState();

    // Retrieve user information from the provider
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    // Fetch genres when the screen is initialized
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    final response = await http.get(Uri.parse('http://10.0.2.2/genre.php'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        // Map the response to Genre objects
        genreList = jsonResponse.map((genre) => Genre(genre)).toList();
      });
    } else {
      // Handle error
      print('Failed to load genres');
    }
  }

  Future<void> _sendSelectedGenres() async {
    final List<String> selectedGenres = genreList
        .where((genre) => genre.value == true)
        .map((e) => e.name)
        .toList();

    final response = await http.post(
      Uri.parse('http://10.0.2.2/favouritegenre.php'),
      body: {
        'userId': user_info.idUser.toString(), // Pass the user ID
        'genres':
            json.encode(selectedGenres), // Change 'selectedGenres' to 'genres'
      },
    );

    if (response.statusCode == 200) {
      // Handle successful response
      print('Selected genres sent successfully');
    } else {
      // Handle error
      print('Failed to send selected genres');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 200,
        elevation: 0.0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "What music do you \nlisten to?",
          style:
              TextStyle(color: Colors.black, fontFamily: "Karla", fontSize: 30),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildRows(),
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    List<Widget> rows = [];
    double spaceBetweenTiles = 20; // Define the space between tiles

    for (int i = 0; i < genreList.length; i += 2) {
      List<Widget> rowChildren = [];
      for (int j = i; j < i + 2 && j < genreList.length; j++) {
        rowChildren.add(
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 50, left: 30),
                width: 180,
                child: CheckboxListTile(
                  tileColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  title: Text(
                    genreList[j].name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: "Karla",
                    ),
                  ),
                  value: genreList[j].value,
                  onChanged: (bool? value) {
                    setState(() {
                      genreList[j].value = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20), // Adjust the height as needed
            ],
          ),
        );
        // Add space between tiles
        if (j < i + 1 && j < genreList.length - 1) {
          rowChildren.add(SizedBox(width: spaceBetweenTiles));
        }
      }
      rows.add(Row(
        children: rowChildren,
      ));
    }
    rows.add(const SizedBox(
      height: 40,
    ));
    rows.add(Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: ElevatedButton(
            onPressed: () {
              _sendSelectedGenres();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
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
        const SizedBox(
          width: 20,
        ),
        SizedBox(
          width: 150,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              backgroundColor: const Color.fromRGBO(150, 84, 132, 100),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(fontFamily: "Karla"),
            ),
          ),
        ),
      ],
    ));
    return rows;
  }
}
