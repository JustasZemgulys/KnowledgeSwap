import 'package:flutter/material.dart';
import 'package:knowledgeswap/group_detail_screen.dart';
import 'package:knowledgeswap/voting_system.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'get_ip.dart';

class SearchGroupsScreen extends StatefulWidget {
  const SearchGroupsScreen({super.key});

  @override
  State<SearchGroupsScreen> createState() => _SearchGroupsScreenState();
}

class _SearchGroupsScreenState extends State<SearchGroupsScreen> {
  late UserInfo user_info;
  List<dynamic> results = [];
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalResults = 0;
  String sortOrder = 'desc';
  String searchQuery = '';
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
        'http://$serverIP/search_groups.php?'
        'query=${Uri.encodeComponent(searchQuery)}'
        '&page=$currentPage'
        '&per_page=$itemsPerPage'
        '&sort=$sortOrder'
        '&user_id=${user_info.id}'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          results = List<dynamic>.from(data['results']);
          totalResults = int.tryParse(data['total'].toString()) ?? 0;
          isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  void _goToPage(int page) {
    setState(() => currentPage = page);
    _performSearch();
  }

  Widget _buildSearchResultCard(Map<String, dynamic> item) {
    final isOwner = item['is_owner'] == true;
    final isMember = item['is_member'] == true;
    final itemId = item['id'];
    final isPrivate = item['visibility'] == 0;
    final memberCount = item['member_count'] ?? 0;
    final score = item['score'] ?? 0;
    final userVote = item['user_vote'];
    final iconPath = item['icon_path'];

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: iconPath != null && iconPath.isNotEmpty
            ? Image.network(
                'http://$serverIP/image_proxy.php?path=${Uri.encodeComponent(iconPath)}',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.group, size: 50);
                },
              )
            : const Icon(Icons.group, size: 50),
        title: Text(item['name'] ?? 'Unnamed Group'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$memberCount members'),
            if (isPrivate) Text('Private', style: TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
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
                      itemType: 'group',
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
                ),
                Text(score.toString()),
                IconButton(
                  icon: Icon(
                    Icons.arrow_downward,
                    color: userVote == -1 ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    VotingController(
                      context: context,
                      itemType: 'group',
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
                ),
              ],
            ),
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: const Text('View Group'),
                ),
                if (isMember)
                  PopupMenuItem(
                    value: 'leave',
                    child: const Text('Leave Group', style: TextStyle(color: Colors.red)),
                  ),
                if (!isMember)
                  PopupMenuItem(
                    value: 'join',
                    child: const Text('Join Group'),
                  ),
                if (isOwner)
                  PopupMenuItem(
                    value: 'delete',
                    child: const Text('Delete Group', style: TextStyle(color: Colors.red)),
                  ),
              ],
              onSelected: (value) async {
                if (value == 'view') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(
                        groupId: itemId,
                        groupName: item['name'],
                      ),
                    ),
                  );
                } else if (value == 'join') {
                  await _joinGroup(itemId);
                } else if (value == 'leave') {
                  await _leaveGroup(itemId);
                } else if (value == 'delete') {
                  await _confirmDeleteGroup(context, itemId, item['name']);
                }
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(
                groupId: itemId,
                groupName: item['name'],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _joinGroup(int groupId) async {
    try {
      final url = Uri.parse('http://$serverIP/join_group.php');
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
          const SnackBar(content: Text('Successfully joined the group')),
        );
        
        // Update the local state
        setState(() {
          final groupIndex = results.indexWhere((g) => g['id'] == groupId);
          if (groupIndex != -1) {
            results[groupIndex]['is_member'] = true;
            results[groupIndex]['member_count'] = responseData['member_count'];
          }
        });
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
      final url = Uri.parse('http://$serverIP/leave_group.php');
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
          const SnackBar(content: Text('Successfully left the group')),
        );
        
        // Update the local state
        setState(() {
          final groupIndex = results.indexWhere((g) => g['id'] == groupId);
          if (groupIndex != -1) {
            results[groupIndex]['is_member'] = false;
            results[groupIndex]['member_count'] = responseData['member_count'];
          }
        });
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

  Future<void> _confirmDeleteGroup(BuildContext context, int groupId, String groupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "$groupName"?'),
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
      await _deleteGroup(groupId);
    }
  }

  Future<void> _deleteGroup(int groupId) async {
    try {
      final url = Uri.parse('http://$serverIP/delete_group.php');
      final response = await http.post(
        url,
        body: {'group_id': groupId.toString()},
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted successfully')),
        );
        _performSearch(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to delete group')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Search Groups'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                ),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
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
                const Text('Sort:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: sortOrder,
                  items: const [
                    DropdownMenuItem(value: 'desc', child: Text('Newest first')),
                    DropdownMenuItem(value: 'asc', child: Text('Oldest first')),
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
                    ? const Center(child: Text('No groups found'))
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