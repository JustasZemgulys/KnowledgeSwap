import 'package:flutter/material.dart';
import 'package:knowledgeswap/discussion_ui.dart';
import 'package:knowledgeswap/edit_group_ui.dart';
import 'package:knowledgeswap/edit_resource_ui.dart';
import 'package:knowledgeswap/edit_test_ui.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/take_test_ui.dart';
import 'package:knowledgeswap/voting_system.dart';
import 'package:knowledgeswap/group_detail_screen.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import "package:universal_html/html.dart" as html;
import 'dart:convert';
import 'get_ip.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late UserInfo user_info;
  List<dynamic> results = [];
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalResults = 0;
  String sortOrder = 'desc';
  String searchQuery = '';
  String resourceType = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  String? serverIP;

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    serverIP = await getUserIP();
  }

  Future<void> _performSearch() async {
    if (serverIP == null || searchQuery.isEmpty) return;

    setState(() {
      isLoading = true;
      currentPage = 1;
    });

    try {
      final url = Uri.parse(
        '$serverIP/search.php?'
        'query=${Uri.encodeComponent(searchQuery)}'
        '&page=$currentPage'
        '&per_page=$itemsPerPage'
        '&sort=$sortOrder'
        '&type=$resourceType'
        '&user_id=${user_info.id}'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('success')) {
            setState(() {
              results = List<dynamic>.from(data['results'] ?? []);

              // Sort results by score and then by name if sortOrder is 'score'
              if (sortOrder == 'score') {
                results.sort((a, b) {
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
              }

              totalResults = int.tryParse(data['total']?.toString() ?? '0') ?? 0;
              isLoading = false;
            });
          } else {
            throw Exception('Invalid response format');
          }
        } catch (e) {
          throw Exception('Failed to parse server response: $e');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Server error');
        } catch (_) {
          throw Exception('Server returned status code ${response.statusCode}');
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _downloadResource(Map<String, dynamic> resource) async {
    final resourcePath = resource['resource_link'] ?? '';
    //final resourceName = resource['name'] ?? 'Untitled Resource';
    
    if (resourcePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resource available')),
      );
      return;
    }

    try {
      try {
        final cleanPath = resourcePath.replaceAll(RegExp(r'^/+'), '');
        final fullUrl = '$serverIP/$cleanPath';
        
        // Open in new window
        html.window.open(fullUrl, '_blank');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open resource: $e')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download resource: $e')),
      );
    }
  }

  void _goToPage(int page) {
    setState(() => currentPage = page);
    _performSearch();
  }

  Widget _buildSearchResultCard(Map<String, dynamic> item) {
    final isOwner = item['fk_user'] == user_info.id;
    final isTest = item['type'] == 'test';
    final isGroup = item['type'] == 'group';
    final isForumItem = item['type'] == 'forum_item';
    final itemId = item['id'];
    final isPrivate = item['visibility'] == 0;
    final score = item['score'] ?? 0;
    final userVote = item['user_vote']; // 1 for upvote, -1 for downvote, null for no vote
    if(isForumItem) item['name'] = item['title'];

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Voting buttons column
          Container(
            width: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_upward,
                    color: userVote == 1 ? Colors.orange : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    VotingController(
                      context: context,
                      itemType: isGroup ? 'group' : (isTest ? 'test' : 'resource'),
                      itemId: itemId,
                      currentScore: score,
                      onScoreUpdated: (newScore) {
                        setState(() {
                          item['score'] = newScore;
                          item['user_vote'] = userVote == 1 ? null : 1;
                        });
                      },
                    ).upvote();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  score.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_downward,
                    color: userVote == -1 ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    VotingController(
                      context: context,
                      itemType: isGroup ? 'group' : (isTest ? 'test' : 'resource'),
                      itemId: itemId,
                      currentScore: score,
                      onScoreUpdated: (newScore) {
                        setState(() {
                          item['score'] = newScore;
                          item['user_vote'] = userVote == -1 ? null : -1;
                        });
                      },
                    ).downvote();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: ListTile(
              title: Text(item['name'] ?? 'Untitled'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${isGroup ? 'Group' : (isTest ? 'Test' : (isForumItem ? 'Forum Post' : 'Resource'))} '),

                  Text('By: ${item['creator_name'] ?? 'Unknown'}'),
                  if (isPrivate) Text('Private', style: TextStyle(color: Colors.grey)),
                  if (isGroup) Text('${item['member_count'] ?? 0} members', style: TextStyle(color: Colors.grey)),
                  //if (isForumItem && item['description'] != null) Text(item['description']),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  if (isTest)
                    const PopupMenuItem(
                      value: 'take_test',
                      child: Text('Take Test'),
                    ),
                  if (!isTest && !isGroup)
                    const PopupMenuItem(
                      value: 'download',
                      child: Text('Download'),
                    ),
                  const PopupMenuItem(
                    value: 'discussions',
                    child: ListTile(
                      leading: Icon(Icons.forum, size: 20),
                      title: Text('View Discussions', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  if (isGroup && item['is_member'] == true)
                    const PopupMenuItem(
                      value: 'group_discussions',
                      child: ListTile(
                        leading: Icon(Icons.forum, size: 20),
                        title: Text('Group Chat', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  if (isOwner) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  if (isGroup && !item['is_member'] && !isOwner)
                    const PopupMenuItem(
                      value: 'join_group',
                      child: Text('Join Group'),
                    ),
                  if (isGroup && item['is_member'] && !isOwner)
                    const PopupMenuItem(
                      value: 'leave_group',
                      child: Text('Leave Group', style: TextStyle(color: Colors.red)),
                    ),
                ],
                onSelected: (value) async {
                  if (value == 'take_test') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TakeTestScreen(testId: itemId),
                      ),
                    );
                  } else if (value == 'download') {
                    await _downloadResource(item);
                  } else if (value == 'edit') {
                    if (isTest) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTestScreen(test: item),
                        ),
                      ).then((_) => _performSearch());
                    } else if (isGroup) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditGroupScreen(group: item),
                        ),
                      ).then((_) => _performSearch());
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditResourceScreen(resource: item),
                        ),
                      ).then((_) => _performSearch());
                    }
                  } else if (value == 'delete') {
                    _confirmDeleteItem(context, itemId, item['name'], isTest, isGroup);
                  } else if (value == 'discussions') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiscussionScreen(
                          itemId: itemId,
                          itemType: isGroup ? 'group' : (isTest ? 'test' : 'resource'),
                        ),
                      ),
                    );
                  } else if (value == 'group_discussions') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiscussionScreen(
                          itemId: itemId * -1,
                          itemType: 'group',
                        ),
                      ),
                    );
                  } else if (value == 'join_group') {
                    await _joinGroup(itemId);
                  } else if (value == 'leave_group') {
                    await _leaveGroup(itemId);
                  }
                },
              ),
              onTap: () {
                if (isTest) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakeTestScreen(testId: itemId),
                    ),
                  );
                } else if (isGroup) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(
                        groupId: itemId,
                        groupName: item['name'],
                      ),
                    ),
                  );
                } else {
                  _downloadResource(item);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinGroup(int groupId) async {
    try {
      final url = Uri.parse('$serverIP/join_group.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'group_id': groupId,
          'user_id': user_info.id,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined the group')),
        );
        _performSearch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to join group')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining group: $e')),
      );
    }
  }

  Future<void> _leaveGroup(int groupId) async {
    try {
      final url = Uri.parse('$serverIP/leave_group.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'group_id': groupId,
          'user_id': user_info.id,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully left the group')),
        );
        _performSearch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to leave group')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving group: $e')),
      );
    }
  }

  Future<void> _confirmDeleteItem(BuildContext context, int itemId, String itemName, bool isTest, bool isGroup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isGroup ? 'Group' : (isTest ? 'Test' : 'Resource')}'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteItem(itemId, isTest, isGroup);
    }
  }

  Future<void> _deleteItem(int itemId, bool isTest, bool isGroup) async {
    try {
      String endpoint;
      String idField;
      
      if (isGroup) {
        endpoint = 'delete_group.php';
        idField = 'group_id';
      } else {
        endpoint = isTest ? 'delete_test.php' : 'delete_resource.php';
        idField = isTest ? 'test_id' : 'resource_id';
      }

      final url = Uri.parse('$serverIP/$endpoint');
      final response = await http.post(
        url,
        body: {
          idField: itemId.toString(),
          'user_id': user_info.id.toString(),
        },
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isGroup ? 'Group' : (isTest ? 'Test' : 'Resource')} deleted successfully')),
        );
        _performSearch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to delete ${isGroup ? 'group' : (isTest ? 'test' : 'resource')}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting ${isGroup ? 'group' : (isTest ? 'test' : 'resource')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
          
        ),
        title: Text(
          "Search",
          style: TextStyle(color: Colors.deepPurple),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0, 
        iconTheme: IconThemeData(color: Colors.deepPurple),
        actions: [
          IconButton(
            icon: Image.asset("assets/usericon.jpg"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileDetailsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) => searchQuery = value,
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Filter:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: resourceType,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'resource', child: Text('Resources')),
                    DropdownMenuItem(value: 'test', child: Text('Tests')),
                    DropdownMenuItem(value: 'group', child: Text('Groups')),
                    DropdownMenuItem(value: 'forum_item', child: Text('Forum posts')),
                  ],
                  onChanged: (value) {
                    setState(() => resourceType = value!);
                    _performSearch();
                  },
                ),
                const Spacer(),
                const Text('Sort:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: sortOrder,
                  items: const [
                    DropdownMenuItem(value: 'desc', child: Text('Newest first')),
                    DropdownMenuItem(value: 'asc', child: Text('Oldest first')),
                    DropdownMenuItem(value: 'score', child: Text('Sort by Score')),
                  ],
                  onChanged: (value) {
                    setState(() => sortOrder = value!);
                    _performSearch();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? const Center(child: Text('No results found'))
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return _buildSearchResultCard(results[index]);
                        },
                      ),
          ),
          if (totalResults > itemsPerPage)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 1
                        ? () => _goToPage(currentPage - 1)
                        : null,
                  ),
                  Text('Page $currentPage of ${(totalResults / itemsPerPage).ceil()}'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: currentPage < (totalResults / itemsPerPage).ceil()
                        ? () => _goToPage(currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}