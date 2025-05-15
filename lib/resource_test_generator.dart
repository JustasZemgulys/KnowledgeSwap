import 'dart:async';

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

      final getIP = GetIP();
      final userIP = await getIP.getUserIP();
      final url = '$userIP/generate_resource_test.php';

      final questionsWithOrder = questions.asMap().map((index, question) => MapEntry(
        index,
        {
          ...question,
          'original_order': index,
        },
      )).values.toList();

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resourceId': resourceId,
          'userId': userId,
          'resourceName': resourceName,
          'questions': questionsWithOrder,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        final testId = responseData['testId'];
        Navigator.pushNamed(
          context,
          '/test-screen',
          arguments: {'testId': testId},
        );
      } else {
        if (responseData.containsKey('failedQuestion')) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to generate question about: ${responseData['failedQuestion']}')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to generate test')),
          );
        }
      }
    } on TimeoutException catch (_) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Request timed out. Please try again.')),
      );
      print('Request timed out');
    } on http.ClientException catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Network error: ${e.uri}')),
      );
      print('Network error: ${e.toString()}');
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      print('Error: ${e.toString()}');
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