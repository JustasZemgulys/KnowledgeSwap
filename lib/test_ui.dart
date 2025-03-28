import 'package:flutter/material.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/create_test_ui.dart';
import 'package:knowledgeswap/take_test_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'get_ip.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late UserInfo user_info;
  List<dynamic> tests = [];
  bool isLoading = true;
  String? serverIP;
  Map<int, int> questionCounts = {}; // Stores test_id -> question_count

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    try {
      serverIP = await getUserIP();
      _fetchTests();
    } catch (e) {
      print('Error initializing server IP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server: $e')),
      );
    }
  }

Future<void> _fetchTests() async {
  if (serverIP == null) return;

  setState(() {
    isLoading = true;
    tests = []; // Clear previous data
  });

  try {
    final url = Uri.parse('http://$serverIP/get_tests.php?user_id=${user_info.id}');
    final response = await http.get(url);

    // First check if response is valid JSON
    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (data['success'] == true) {
          setState(() {
            tests = List<dynamic>.from(data['tests'] ?? []);
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch tests');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on FormatException {
      throw Exception('Invalid server response.');
    }
  } catch (e) {
    print('Error fetching tests: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _fetchTests,
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  Widget _buildTestCard(Map<String, dynamic> test) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakeTestScreen(testId: test['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      test['name'] ?? 'Untitled Test',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (test['has_resource'])
                    const Icon(Icons.attachment, color: Colors.blue),
                  if (!test['visibility'] && test['is_owner'])
                    const Icon(Icons.visibility_off, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                test['description'] ?? 'No description',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions: ${test['question_count']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Created: ${test['creation_date']?.split(' ')[0] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTestScreen()),
              ).then((_) => _fetchTests()); // Refresh list after returning
            },
            icon: const Icon(Icons.add),
            label: const Text("Create Test"),
          ),
          const SizedBox(width: 1),
          IconButton(
            icon: Image.asset("assets/usericon.jpg"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileDetailsScreen()),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: const Color(0x00000000),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tests.isEmpty
              ? const Center(child: Text('No tests found'))
              : RefreshIndicator(
                  onRefresh: _fetchTests,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tests.length,
                    itemBuilder: (context, index) {
                      return _buildTestCard(tests[index]);
                    },
                  ),
                ),
    );
  }
}