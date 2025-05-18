import 'package:flutter/material.dart';
import 'package:knowledgeswap/app_router.dart';
import 'package:knowledgeswap/web_storage.dart';
import 'package:knowledgeswap/welcome.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_info_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: unused_local_variable
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserInfoProvider(),
      child: const KnowledgeSwapApp(),
    ),
  );
}

class KnowledgeSwapApp extends StatelessWidget {
  const KnowledgeSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      title: 'KnowledgeSwap',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      navigatorObservers: [RouteObserver<PageRoute>()],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    final userProvider = Provider.of<UserInfoProvider>(context, listen: false);
    final isLoggedIn = await userProvider.tryAutoLogin();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => isLoggedIn
              ? FutureBuilder<Widget>(
                  future: WebStorage.getLastRoute().then((route) => AppRouter.getScreenFromRoute(route ?? '/main')),
                  builder: (context, snapshot) => snapshot.data ?? const SizedBox.shrink()) : const WelcomeScreen()),
        (route) => false,
      );
    });
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Return an empty container since we're handling navigation in initState
    return const SizedBox.shrink();
  }
}