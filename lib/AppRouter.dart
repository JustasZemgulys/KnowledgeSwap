// app_router.dart
import 'package:flutter/material.dart';
import 'package:knowledgeswap/resource_ui.dart';
import 'package:knowledgeswap/search_ui.dart';
import 'package:knowledgeswap/test_ui.dart';
import 'package:knowledgeswap/web_storage.dart';
import 'package:knowledgeswap/main_screen_ui.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/create_resource_ui.dart';

class AppRouter {
  static const String resourceRoute = '/resources';

    static Route<dynamic> generateRoute(RouteSettings settings) {
      _saveCurrentRoute(settings);
      
      switch (settings.name) {
        case '/':
          return MaterialPageRoute(builder: (_) => const MainScreen());
        case '/main':
          return MaterialPageRoute(builder: (_) => const MainScreen());
        case '/test':
          return MaterialPageRoute(builder: (_) => const TestScreen());
        case '/resources':
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => ResourceScreen(
              initialPage: args['page'] ?? 1,
              initialSort: args['sort'] ?? 'desc',
            ),
            settings: settings,
          );
        case '/search':
          return MaterialPageRoute(builder: (_) => const SearchScreen());
        case '/profile':
          return MaterialPageRoute(builder: (_) => const ProfileDetailsScreen());
        case '/create-resource':
          return MaterialPageRoute(builder: (_) => const CreateResourceScreen());
        default:
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            ),
          );
      }
    }

  static Widget getScreenFromRoute(String routeName) {
    switch (routeName) {
      case '/':
      case '/main':
        return const MainScreen();
      case '/resources':
        return const ResourceScreen();
      case '/profile':
        return const ProfileDetailsScreen();
      case '/create-resource':
        return const CreateResourceScreen();
      default:
        return const MainScreen();
    }
  }

  static void _saveCurrentRoute(RouteSettings settings) {
    if (settings.name != null && !settings.name!.startsWith('/create-')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WebStorage.saveLastRoute(settings.name!);
      });
    }
  }

  // Update manual route tracking
  static void updateCurrentRoute(BuildContext context, String routeName) {
    WebStorage.saveLastRoute(routeName);
    Navigator.pushNamed(context, routeName);
  }
}