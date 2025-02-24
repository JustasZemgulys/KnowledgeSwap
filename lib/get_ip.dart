import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> getUserIP() async {
  final response =
      await http.get(Uri.parse('https://api.ipify.org?format=json'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['ip'];
  } else {
    throw Exception('Failed to load IP');
  }
}
