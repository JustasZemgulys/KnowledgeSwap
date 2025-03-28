import 'dart:async';

import 'package:flutter/material.dart';
import 'package:knowledgeswap/get_ip.dart';
import 'package:knowledgeswap/take_test_ui.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ResourceTestHandler {
  static Future<void> handleResourceTestCreation({
    required BuildContext context,
    required int resourceId,
    required int userId,
    required String resourceName,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final testId = await createResourceTest(
        resourceId: resourceId,
        userId: userId,
        resourceName: resourceName,
      );

      Navigator.of(context).pop(); // Close loading
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TakeTestScreen(testId: testId),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test creation failed: $e')),
      );
    }
  }

  static Future<int> createResourceTest({
    required int resourceId,
    required int userId,
    required String resourceName,
  }) async {
    final serverIP = await getUserIP();
    final uri = Uri.parse('http://$serverIP/generate_resource_test.php');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resource_id': resourceId,
          'user_id': userId,
          'resource_name': resourceName,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data['testId'] as int;
      }
      
      final errorMessage = data['error'] ?? 'Unknown server error';
      print('Server error: $errorMessage');
      throw Exception(errorMessage);

    } on FormatException catch (e) {
      print('JSON Format Error: $e');
      throw Exception('Invalid server response format');
    } on http.ClientException catch (e) {
      print('Connection Error: $e');
      throw Exception('Failed to connect to server. Check your internet connection');
    } on TimeoutException catch (e) {
      print('Timeout Error: $e');
      throw Exception('Request timed out. Please try again');
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('Failed to create test: ${e.toString()}');
    }
  }
}