import 'package:flutter/material.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/welcome.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  final List<String> _routeNames = ['/test', '/resources', '/search', '/groups', '/forum'];
  late UserInfo userinfo;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }
  
  Future<void> _checkAuthState() async {
    final userProvider = Provider.of<UserInfoProvider>(context, listen: false);
    
    if (userProvider.userInfo == null) {
      final isLoggedIn = await userProvider.tryAutoLogin();
      userinfo = userProvider.userInfo!;
      if (!isLoggedIn && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userInfo = Provider.of<UserInfoProvider>(context).userInfo;
    
    if (userInfo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Image.asset("assets/usericon.jpg"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileDetailsScreen(),
                ),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Wavy purple background decoration
          Positioned.fill(
            child: CustomPaint(
              painter: _WavyBackgroundPainter(),
            ),
          ),
          // Main content
          Container(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columnCount = _calculateColumnCount(constraints.maxWidth);
                return GridView.count(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  children: [
                    _buildNavCard(0, Icons.question_mark, "Tests"),
                    _buildNavCard(1, Icons.folder, "Resources"),
                    _buildNavCard(2, Icons.search, "Search"),
                    // Offset the last two items
                    if (columnCount == 2) ...[
                      _buildNavCard(3, Icons.people, "Groups"),
                      const SizedBox(), // Empty space to create offset
                      _buildNavCard(4, Icons.forum, "Forum"),
                    ] else ...[
                      _buildNavCard(3, Icons.people, "Groups"),
                      _buildNavCard(4, Icons.forum, "Forum"),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _calculateColumnCount(double width) {
    if (width > 1200) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildNavCard(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Card(
      elevation: isSelected ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white.withOpacity(0.9),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onItemTapped(index),
        splashColor: Colors.deepPurple.withOpacity(0.2),
        highlightColor: Colors.deepPurple.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: isSelected ? Colors.deepPurple : Colors.grey[800],
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.deepPurple : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) async {
    if (_routeNames[index] == '/resources') {
      final result = await Navigator.pushNamed(context, '/resources');
      if (result != null && result is Map) {
        setState(() => _currentIndex = index);
      }
    } else {
      Navigator.pushReplacementNamed(context, _routeNames[index]);
      setState(() => _currentIndex = index);
    }
  }
}

class _WavyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurple.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    const waveHeight = 60.0;
    const waveLength = 200.0;

    path.moveTo(0, size.height * 0.7);
    
    for (double i = 0; i < size.width; i += waveLength) {
      path.quadraticBezierTo(
        i + waveLength * 0.25,
        size.height * 0.7 + waveHeight,
        i + waveLength * 0.5,
        size.height * 0.7,
      );
      path.quadraticBezierTo(
        i + waveLength * 0.75,
        size.height * 0.7 - waveHeight,
        i + waveLength,
        size.height * 0.7,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Add a second smaller wave
    final secondPaint = Paint()
      ..color = Colors.deepPurple.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final secondPath = Path();
    const secondWaveHeight = 40.0;
    const secondWaveLength = 150.0;

    secondPath.moveTo(0, size.height * 0.8);
    
    for (double i = 0; i < size.width; i += secondWaveLength) {
      secondPath.quadraticBezierTo(
        i + secondWaveLength * 0.25,
        size.height * 0.8 + secondWaveHeight,
        i + secondWaveLength * 0.5,
        size.height * 0.8,
      );
      secondPath.quadraticBezierTo(
        i + secondWaveLength * 0.75,
        size.height * 0.8 - secondWaveHeight,
        i + secondWaveLength,
        size.height * 0.8,
      );
    }

    secondPath.lineTo(size.width, size.height);
    secondPath.lineTo(0, size.height);
    secondPath.close();

    canvas.drawPath(secondPath, secondPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}