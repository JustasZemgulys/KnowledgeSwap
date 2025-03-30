import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/resource_test_config_ui.dart';
import 'dart:convert';
import 'get_ip.dart';

class ResourceTestGenerator {
  static Future<void> generateTest({
    required BuildContext context,
    required int resourceId,
    required int userId,
    required String resourceName,
    required List<Map<String, dynamic>> questions,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Generating test questions...')),
      );

      final userIP = await getUserIP();
      final url = 'http://$userIP/generate_resource_test.php';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'resourceId': resourceId,
          'userId': userId,
          'resourceName': resourceName,
          'questions': questions,
        }),
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        final testId = responseData['testId'];
        Navigator.pushNamed(
          context,
          '/test-screen',
          arguments: {'testId': testId},
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to generate test')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating test: $e')),
      );
      rethrow;
    }
  }

  static void navigateToConfigScreen({
    required BuildContext context,
    required int resourceId,
    required int userId,
    required String resourceName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResourceTestConfigScreen(
          resourceId: resourceId,
          resourceName: resourceName,
          userId: userId,
        ),
      ),
    );
  }
}