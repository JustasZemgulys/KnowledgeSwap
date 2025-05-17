import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/get_ip.dart';

void main() {
  late String testUrl;

  setUpAll(() async {
    final getIP = GetIP();
    final serverIP = await getIP.getUserIP();
    testUrl = '$serverIP/login.php';
  });
  
  test('Successful login with admin/admin', () async {
    final response = await http.post(
      Uri.parse(testUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': 'admin',
        'password': 'admin'
      }),
    );

    expect(response.statusCode, 200);
    final data = json.decode(response.body);
    expect(data['success'], true);
    expect(data['userData']['name'], 'admin');
  });

  test('Failed login with wrong password', () async {
    final response = await http.post(
      Uri.parse(testUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': 'admin',
        'password': 'wrongpassword'
      }),
    );

    expect(response.statusCode, 200);
    final data = json.decode(response.body);
    expect(data['success'], false);
    expect(data['message'], 'Invalid password');
  });

  test('Failed login with non-existent user', () async {
    final response = await http.post(
      Uri.parse(testUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': 'nonexistentuser',
        'password': 'whatever'
      }),
    );

    expect(response.statusCode, 200);
    final data = json.decode(response.body);
    expect(data['success'], false);
    expect(data['message'], 'User not found');
  });
}