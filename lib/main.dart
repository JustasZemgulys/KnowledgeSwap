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
  bool _isLoggedIn = false;
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final userProvider = Provider.of<UserInfoProvider>(context, listen: false);
    _isLoggedIn = await userProvider.tryAutoLogin();
    _initialRoute = await WebStorage.getLastRoute();
    
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

    return _isLoggedIn
        ? AppRouter.getScreenFromRoute(_initialRoute ?? '/main')
        : const WelcomeScreen();
  }
}