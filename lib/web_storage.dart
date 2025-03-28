import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class WebStorage {
  static const String _userKey = 'current_user';
  static const String _routeKey = 'last_route';

  static Future<void> saveUser(Map<String, dynamic> user) async {
    if (kIsWeb) {
      html.window.localStorage[_userKey] = jsonEncode(user);
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    if (kIsWeb) {
      final userJson = html.window.localStorage[_userKey];
      if (userJson != null) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
    }
    return null;
  }

  static Future<void> clearUser() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_userKey);
    }
  }

  static Future<void> saveLastRoute(String route) async {
    if (kIsWeb) {
      html.window.localStorage[_routeKey] = route;
    }
  }

  static Future<String?> getLastRoute() async {
    if (kIsWeb) {
      return html.window.localStorage[_routeKey];
    }
    return null;
  }

  static Future<void> clearLastRoute() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_routeKey);
    }
  }
}