import 'package:flutter/material.dart';
import 'package:knowledgeswap/approuter.dart';
import 'package:knowledgeswap/web_storage.dart';
import 'package:knowledgeswap/welcome.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_info_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();

  final userInfoProvider = UserInfoProvider();
  final isLoggedIn = await userInfoProvider.tryAutoLogin();
  final lastRoute = await WebStorage.getLastRoute();

  runApp(
    ChangeNotifierProvider(
      create: (context) => userInfoProvider,
      child: MaterialApp(
        title: 'KnowledgeSwap',
        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
        navigatorObservers: [RouteObserver<PageRoute>()],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: isLoggedIn 
            ? AppRouter.getScreenFromRoute(lastRoute ?? '/main')
            : const WelcomeScreen(),
      ),
    ),
  );
}