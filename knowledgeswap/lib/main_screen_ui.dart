// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/test_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
        bottomNavigationBar: BottomNavigationBar(
          onTap: (newIndex) async {
            if (newIndex == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestScreen()),
              );
            } else if (newIndex == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TestScreen()),
              );
            } else if (newIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TestScreen()),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              label: "Tests",
              icon: Icon(Icons.question_mark),
            ),
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Resources"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          ],
        ),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            const SizedBox(width: 1),
            IconButton(
              icon: Image.asset("assets/usericon.jpg"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileDetailsScreen()),
                );
              },
            ),
          ],
          //leading: Padding(
          //padding: const EdgeInsets.all(5.0),
          //child: IconButton(
          //icon: Image.asset("assets/logo.png"),
          //onPressed: () {},
          //),
          //),
          elevation: 0,
          backgroundColor: const Color(0x00000000),
        ),
        body: Container(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ));
  }
}
