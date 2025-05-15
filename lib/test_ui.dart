import 'package:flutter/material.dart';
import 'package:knowledgeswap/discussion_ui.dart';
import 'package:knowledgeswap/edit_test_ui.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/create_test_ui.dart';
import 'package:knowledgeswap/take_test_ui.dart';
import 'package:knowledgeswap/voting_system.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import "package:universal_html/html.dart" as html;
import 'dart:convert';
import 'get_ip.dart';

class TestScreen extends StatefulWidget {
  final int initialPage;
  final String initialSort;
  final bool selectMode;

  const TestScreen({
    super.key,
    this.initialPage = 1,
    this.initialSort = 'desc',
    this.selectMode = false,
  });

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late UserInfo user_info;
  late int currentPage;
  late String sortOrder;
  List<dynamic> tests = [];
  List<dynamic> filteredTests = [];
  int itemsPerPage = 10;
  int totalTests = 0;
  bool isLoading = true;
  bool isSearching = false;
  String? serverIP;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    currentPage = widget.initialPage;
    sortOrder = widget.initialSort;
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    try {
      final getIP = GetIP();
      serverIP = await getIP.getUserIP();
      _fetchTests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server: $e')),
      );
    }
  }

  Future<void> _fetchTests() async {
    if (serverIP == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('$serverIP/get_tests.php?page=$currentPage&per_page=$itemsPerPage&sort=$sortOrder&user_id=${user_info.id}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalTests = int.tryParse(data['total'].toString()) ?? 0;
          
          if (data['tests'].isEmpty && currentPage > 1) {
            currentPage--;
            _fetchTests();
            return;
          }

          tests = List<dynamic>.from(data['tests']);
          filteredTests = List<dynamic>.from(tests);
          isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
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
      setState(() {
        isLoading = false;
      });
    }
  }

  void _searchTests(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      if (isSearching) {
        filteredTests = tests.where((test) => 
          test['name'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      } else {
        filteredTests = List<dynamic>.from(tests);
      }
    });
  }

  void _changeSortOrder(String newOrder) {
    setState(() {
      sortOrder = newOrder;
      currentPage = 1;
    });

    if (newOrder == 'score') {
      // Sort by score and then by name
      setState(() {
        tests.sort((a, b) {
          int scoreA = a['score'] ?? 0;
          int scoreB = b['score'] ?? 0;

          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA); // Higher score first
          } else {
            String nameA = a['name']?.toLowerCase() ?? '';
            String nameB = b['name']?.toLowerCase() ?? '';
            return nameA.compareTo(nameB); // Alphabetical order
          }
        });
        filteredTests = List<dynamic>.from(tests);
      });
    } else {
      _fetchTests(); // Fetch tests with the new sort order
    }
  }


  void _goToPage(int page) {
    setState(() {
      currentPage = page;
    });
    _fetchTests();
  }

  Future<void> _deleteTest(int testId) async {
    try {
      final url = Uri.parse('$serverIP/delete_test.php');
      final response = await http.post(
        url,
        body: {
          'test_id': testId.toString(),
          'user_id': user_info.id.toString(),
        },
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test deleted successfully')),
        );
        _fetchTests();
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
    final resourceId = test['fk_resource'];
    final isPrivate = !(test['visibility'] ?? true);
    final isAIMade = test['ai_made'] ?? false;
    final score = test['score'] ?? 0;
    final userVote = test['user_vote'];

    Future<void> _downloadResource() async {
      if (resourceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No resource available')),
        );
        return;
      }

      try {
        // First fetch the resource details
          final url = Uri.parse('$serverIP/get_resource_details.php?resource_id=$resourceId');
          final response = await http.get(url);

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              final resource = data['resource'];
              final resourcePath = resource['resource_link'];

              if (resourcePath.isEmpty) {
                throw Exception('Resource path is empty');
              }

              final cleanPath = resourcePath.replaceAll(RegExp(r'^/+'), '');
              final fullUrl = '$serverIP/$cleanPath';
              
              // Open in new window
              html.window.open(fullUrl, '_blank');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening resource...')),
              );
          } else {
            throw Exception(data['message'] ?? 'Failed to fetch resource details');
          }
        } else {
          throw Exception('Server returned status code ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download resource: $e')),
        );
      }
    }

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VotingWidget(
                    score: score,
                    userVote: userVote,
                    onUpvote: () {
                      VotingController(
                        context: context,
                        itemType: 'test',
                        itemId: testId,
                        currentScore: score,
                        onScoreUpdated: (newScore) {
                          setState(() {
                            test['score'] = newScore;
                            test['user_vote'] = 1;
                          });
                        },
                      ).upvote();
                    },
                    onDownvote: () {
                      VotingController(
                        context: context,
                        itemType: 'test',
                        itemId: testId,
                        currentScore: score,
                        onScoreUpdated: (newScore) {
                          setState(() {
                            test['score'] = newScore;
                            test['user_vote'] = -1;
                          });
                        },
                      ).downvote();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
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
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, 
                    color: Colors.grey[600], 
                    size: 20),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'discussions',
                      child: ListTile(
                        leading: Icon(Icons.forum, size: 20),
                        title: Text('View Discussions', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    if (hasResource)
                      const PopupMenuItem(
                        value: 'open_resource',
                        child: ListTile(
                          leading: Icon(Icons.open_in_new, size: 20),
                          title: Text('Open Resource', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    if (isOwner)
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 20),
                          title: Text('Edit Test', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    if (isOwner)
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
                    } else if (value == 'discussions') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiscussionScreen(
                            itemId: testId,
                            itemType: 'test',
                          ),
                        ),
                      );
                    } else if (value == 'open_resource') {
                      await _downloadResource();
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
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search tests...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                isDense: true,  
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _fetchTests();
                          setState(() {
                            isSearching = false;
                          });
                        },
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort, color: Colors.deepPurple),
                      color: Colors.white,
                      onSelected: (value) => _changeSortOrder(value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'desc',
                          child: Text('Newest first', 
                            style: TextStyle(color: Colors.black)),
                        ),
                        PopupMenuItem(
                          value: 'asc',
                          child: Text('Oldest first', 
                            style: TextStyle(color: Colors.black)),
                        ),
                        PopupMenuItem(
                          value: 'score',
                          child: Text('Sort by Score', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              onChanged: _searchTests,
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTestScreen()),
              ).then((_) => _fetchTests());
            },
            icon: const Icon(Icons.add, color: Colors.deepPurple),
            label: const Text("Create Test", 
              style: TextStyle(color: Colors.deepPurple)),
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
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ))
            : filteredTests.isEmpty
                ? Center(
                    child: Text('No tests found',
                      style: TextStyle(color: Colors.grey[800])),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          color: Colors.deepPurple,
                          onRefresh: _fetchTests,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredTests.length,
                            itemBuilder: (context, index) {
                              return _buildTestCard(filteredTests[index]);
                            },
                          ),
                        ),
                      ),
                      if (!isSearching && totalTests > itemsPerPage)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left,
                                  color: Colors.deepPurple),
                                onPressed: currentPage > 1
                                    ? () => _goToPage(currentPage - 1)
                                    : null,
                              ),
                              Text('Page $currentPage of ${(totalTests / itemsPerPage).ceil()}',
                                style: TextStyle(color: Colors.grey[800])),
                              IconButton(
                                icon: const Icon(Icons.chevron_right,
                                  color: Colors.deepPurple),
                                onPressed: currentPage < (totalTests / itemsPerPage).ceil() && 
                                          tests.length >= itemsPerPage
                                    ? () => _goToPage(currentPage + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}