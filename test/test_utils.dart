import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([http.Client])
void main() {}

class MockUserInfoProvider extends Mock implements UserInfoProvider {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

final successfulLoginResponse = {
  'success': true,
  'message': 'Login successful',
  'userData': {
    'id': 1,
    'name': 'admin',
    'email': 'admin@example.com',
    // Add other user fields as needed
  }
};

final invalidPasswordResponse = {
  'success': false,
  'message': 'Invalid password'
};

final userNotFoundResponse = {
  'success': false,
  'message': 'User not found'
};

final serverErrorResponse = {
  'success': false,
  'message': 'Server error'
};