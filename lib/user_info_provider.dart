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
    await WebStorage.clearLastRoute();
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    try {
      if (_userInfo != null) return true;
      
      final userData = await WebStorage.getUser();
      if (userData != null && userData['id'] != null) {
        _userInfo = UserInfo.fromJson(userData);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during auto-login: $e');
      await WebStorage.clearUser();
      return false;
    }
  }
}