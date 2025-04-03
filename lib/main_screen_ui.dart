import 'package:flutter/material.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
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
  int _currentIndex = 0;
  final List<String> _routeNames = ['/test', '/resources', '/search']; // Fixed

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context)?.settings.name;
    if (route != null) {
      final index = _routeNames.indexOf(route);
      if (index != -1) _currentIndex = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (newIndex) async {
          if (_routeNames[newIndex] == '/resources') {
            final result = await Navigator.pushNamed(
              context,
              '/resources',
            );
            
            // If we got back page info, update state
            if (result != null && result is Map) {
              setState(() {
                _currentIndex = newIndex;
              });
            }
          } else {
            Navigator.pushReplacementNamed(context, _routeNames[newIndex]);
            setState(() => _currentIndex = newIndex);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark), 
            label: "Tests"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder), 
            label: "Resources"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search), 
            label: "Search"
          ),
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
