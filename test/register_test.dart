import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/get_ip.dart';

void main() {
  late String testUrl;

  setUpAll(() async {
    final getIP = GetIP();
    final serverIP = await getIP.getUserIP();
    testUrl = '$serverIP/register.php';
  });

  test('Successful user registration', () async {
    final testUser = {
      'name': 'testuser_${DateTime.now().millisecondsSinceEpoch}',
      'email': 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
      'password': 'testpassword'
    };

    final response = await http.post(
      Uri.parse(testUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(testUser),
    );

    expect(response.statusCode, 201);
    final data = json.decode(response.body);
    expect(data['success'], true);
    expect(data['message'], 'User registered successfully');
    expect(data['userData']['name'], testUser['name']);
    expect(data['userData']['email'], testUser['email']);
  });

  test('Failed registration with duplicate username', () async {
    const testUser = {
      'name': 'duplicateuser',
      'email': 'duplicate@example.com',
      'password': 'testpassword'
    };

    // First registration should succeed
    await http.post(
      Uri.parse(testUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(testUser),
    );

    // Second registration should fail
    final response = await http.post(
      Uri.parse(testUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(testUser),
    );

    expect(response.statusCode, 409);
    final data = json.decode(response.body);
    expect(data['success'], false);
    expect(data['message'], anyOf(['username already exists', 'email already exists']));
  });

  test('Failed registration with missing fields', () async {
    final incompleteUser = {
      'name': 'incompleteuser',
      // Missing email and password
    };

    final response = await http.post(
      Uri.parse(testUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(incompleteUser),
    );

    expect(response.statusCode, 400);
    final data = json.decode(response.body);
    expect(data['success'], false);
    expect(data['message'], 'All fields are required');
  });

  test('Failed registration with invalid email format', () async {
    final invalidEmailUser = {
      'name': 'invalidemailuser',
      'email': 'notanemail',
      'password': 'testpassword'
    };

    final response = await http.post(
      Uri.parse(testUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invalidEmailUser),
    );

    expect(response.statusCode, 400);
    final data = json.decode(response.body);
    expect(data['success'], false);
    expect(data['message'], 'Invalid email format');
  });
}