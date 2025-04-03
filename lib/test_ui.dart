import 'package:flutter/material.dart';
import 'package:knowledgeswap/edit_test_ui.dart';
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
      tests = [];
    });

    try {
      final url = Uri.parse('http://$serverIP/get_tests.php?user_id=${user_info.id}');
      final response = await http.get(url);

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

  Future<void> _deleteTest(int testId) async {
    try {
      final url = Uri.parse('http://$serverIP/delete_test.php');
      final response = await http.post(
        url,
        body: {
          'test_id': testId.toString(),
          'user_id': user_info.id.toString(), // Send user_id for verification
        },
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test deleted successfully')),
        );
        _fetchTests(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to delete test')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting test: $e')),
      );
    }
  }

  Future<void> _confirmDeleteTest(BuildContext context, int testId, String testName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test'),
        content: Text('Are you sure you want to delete "$testName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTest(testId);
    }
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final isOwner = test['fk_user'] == user_info.id;
    final testId = test['id'];
    final testName = test['name'] ?? 'Untitled Test';
    final hasResource = test['has_resource'] ?? false;
    final isPrivate = !(test['visibility'] ?? true);
    final isAIMade = test['ai_made'] ?? false;

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
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with icons moved to the left
                  Row(
                    children: [
                      // Status indicators container moved before the title
                      if (hasResource || (isPrivate && isOwner) || isAIMade)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasResource)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.attachment, 
                                    color: Colors.blue, 
                                    size: 20),
                                ),
                              if (isPrivate && isOwner)
                                Container(
                                  child: const Text(
                                    'Private',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              if (isAIMade)
                                Tooltip(
                                  message: 'AI Generated Test',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue, width: 1),
                                    ),
                                    child: const Text(
                                      'AI',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Text(
                          testName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
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
              // Dropdown menu remains in top-right corner
              if (isOwner)
                Positioned(
                  top: 10,
                  right: 10,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, 
                      color: Colors.grey[600], 
                      size: 20),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 20),
                          title: Text('Edit Test', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, size: 20, color: Colors.red),
                          title: Text('Delete Test', style: TextStyle(fontSize: 14, color: Colors.red)),
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTestScreen(test: test),
                          ),
                        ).then((_) => _fetchTests());
                      } else if (value == 'delete') {
                        _confirmDeleteTest(context, testId, testName);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
    
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTestScreen()),
              ).then((_) => _fetchTests());
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