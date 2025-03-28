import 'package:flutter/foundation.dart';
import 'package:knowledgeswap/web_storage.dart';
import 'models/user_info.dart';

class UserInfoProvider with ChangeNotifier {
  UserInfo? _userInfo;

  UserInfo? get userInfo => _userInfo;

  Future<void> setUserInfo(UserInfo userInfo) async {
    _userInfo = userInfo;
    await WebStorage.saveUser({
      'id': userInfo.id,
      'name': userInfo.name,
      'email': userInfo.email,
      'imageURL': userInfo.imageURL,
    });
    notifyListeners();
  }

  Future<void> clearUserInfo() async {
    _userInfo = null;
    await WebStorage.clearUser();
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    try {
      final userData = await WebStorage.getUser();
      if (userData != null) {
        _userInfo = UserInfo.fromJson(userData);
        notifyListeners();
        
        // Get the last visited route
        //final lastRoute = await WebStorage.getLastRoute();
        return true;
      }
      return false;
    } catch (e) {
      print('Error during auto-login: $e');
      await WebStorage.clearUser();
      return false;
    }
  }
}