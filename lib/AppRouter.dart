// app_router.dart
import 'package:flutter/material.dart';
import 'package:knowledgeswap/edit_resource_ui.dart';
import 'package:knowledgeswap/resource_ui.dart';
import 'package:knowledgeswap/search_ui.dart';
import 'package:knowledgeswap/take_test_ui.dart';
import 'package:knowledgeswap/test_ui.dart';
import 'package:knowledgeswap/web_storage.dart';
import 'package:knowledgeswap/main_screen_ui.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/create_resource_ui.dart';

class AppRouter {
  static const String resourceRoute = '/resources';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    _logRoute('Generating route for: ${settings.name}');
    
    switch (settings.name) {
      case '/':
        _logRoute('Navigating to MainScreen');
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case '/main':
        _logRoute('Navigating to MainScreen');
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case '/test':
        _logRoute('Navigating to TestScreen');
        return MaterialPageRoute(builder: (_) => const TestScreen());
      case '/test-screen':
        _logRoute('Navigating to TakeTestScreen');
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        if (args['testId'] == null) {
          _logError('testId is null in route arguments');
        }
        return MaterialPageRoute(
          builder: (_) => TakeTestScreen(testId: args['testId']),
          settings: settings,
        );
      case '/resources':
        _logRoute('Navigating to ResourceScreen');
        return MaterialPageRoute(builder: (_) => const ResourceScreen());
      case '/edit-resource':
        final resource = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EditResourceScreen(resource: resource),
        );
      case '/search':
        _logRoute('Navigating to SearchScreen');
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case '/profile':
        _logRoute('Navigating to ProfileDetailsScreen');
        return MaterialPageRoute(builder: (_) => const ProfileDetailsScreen());
      case '/create-resource':
        _logRoute('Navigating to CreateResourceScreen');
        return MaterialPageRoute(builder: (_) => const CreateResourceScreen());
      default:
        _logError('No route defined for ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static void _logRoute(String message) {
    debugPrint('[ROUTER] $message');
  }

  static void _logError(String message) {
    debugPrint('[ROUTER ERROR] $message');
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