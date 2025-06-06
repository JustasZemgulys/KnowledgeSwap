import 'package:flutter/material.dart';
import 'package:knowledgeswap/discussion_ui.dart';
import 'package:knowledgeswap/edit_group_ui.dart';
import 'package:knowledgeswap/group_detail_screen.dart';
import 'package:knowledgeswap/voting_system.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'get_ip.dart';

class GroupScreen extends StatefulWidget {
  final int initialPage;
  final String initialSort;
  final bool selectMode;

  const GroupScreen({
    super.key,
    this.initialPage = 1,
    this.initialSort = 'desc',
    this.selectMode = false,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late UserInfo user_info;
  late int currentPage;
  late String sortOrder;
  List<dynamic> groups = [];
  List<dynamic> filteredGroups = [];
  int itemsPerPage = 6;
  int totalGroups = 0;
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
      _fetchGroups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server: $e')),
      );
    }
  }

  Future<void> _fetchGroups() async {
    if (serverIP == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('$serverIP/get_groups.php?page=$currentPage&per_page=$itemsPerPage&sort=$sortOrder&user_id=${user_info.id}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalGroups = int.tryParse(data['total'].toString()) ?? 0;
          
          if (data['groups'].isEmpty && currentPage > 1) {
            currentPage--;
            _fetchGroups();
            return;
          }

          groups = List<dynamic>.from(data['groups']);
          filteredGroups = List<dynamic>.from(groups);
          isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading groups: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _searchGroups(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      if (isSearching) {
        filteredGroups = groups.where((group) => 
          group['name'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      } else {
        filteredGroups = List<dynamic>.from(groups);
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
        groups.sort((a, b) {
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
        filteredGroups = List<dynamic>.from(groups);
      });
    } else {
      _fetchGroups(); // Fetch groups with the new sort order
    }
  }

  void _goToPage(int page) {
    setState(() {
      currentPage = page;
    });
    _fetchGroups();
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
        
        // Update the member count in the local list
        setState(() {
          final groupIndex = groups.indexWhere((g) => g['id'] == groupId);
          if (groupIndex != -1) {
            groups[groupIndex]['is_member'] = true;
            groups[groupIndex]['member_count'] = responseData['member_count'];
          }
        });

        // Navigate to the group screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailScreen(
              groupId: groupId,
              groupName: groups.firstWhere((g) => g['id'] == groupId)['name'],
            ),
          ),
        );
      } else if (responseData['message']?.contains('banned') ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are banned from this group')),
        );
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
        
        // Update the local state
        setState(() {
          final groupIndex = groups.indexWhere((g) => g['id'] == groupId);
          if (groupIndex != -1) {
            groups[groupIndex]['is_member'] = false;
            groups[groupIndex]['member_count'] = responseData['member_count'];
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

  Future<void> _editGroup(BuildContext context, Map<String, dynamic> group) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGroupScreen(group: group),
      ),
    );
    
    if (result == true) {
      _fetchGroups(); // Refresh the list after editing
    }
  }

  Future<void> _confirmDeleteGroup(BuildContext context, int groupId, String groupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Group'),
        content: Text('Are you sure you want to delete "$groupName"?'),
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
      await _deleteGroup(groupId);
    }
  }

  Future<void> _deleteGroup(int groupId) async {
    try {
      final url = Uri.parse('$serverIP/delete_group.php');
      final response = await http.post(
        url,
        body: {'group_id': groupId.toString()},
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group deleted successfully')),
        );
        _fetchGroups(); // Refresh the list
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

  Widget _buildGroupIcon(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: Center(
          child: Icon(Icons.group, size: 60, color: Colors.grey[600]),
        ),
      );
    }

    return ClipRRect(
      child: Image.network(
        '$serverIP/image_proxy.php?path=${Uri.encodeComponent(iconPath)}',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Center(
              child: Icon(Icons.group, size: 60, color: Colors.grey[600]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final groupId = group['id'];
    final groupName = group['name'] ?? 'Unnamed Group';
    final isOwner = group['is_owner'] == true;
    final isMember = group['is_member'] == true;
    final isBanned = group['user_role'] == 'banned';
    final memberCount = group['member_count'] ?? 0;
    final isPrivate = group['visibility'] == 0;
    int localScore = group['score'] ?? 0;
    int? localUserVote = group['user_vote'];
    final iconPath = group['icon_path'];

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: isBanned ? Colors.red : Colors.grey.shade200,
              width: isBanned ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBanned)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'BANNED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: isBanned ? 4 : 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: _buildGroupIcon(iconPath),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$memberCount members',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isPrivate)
                              Text(
                                'Private',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        if (!widget.selectMode) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: isBanned
                                ? Container(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'You are banned from this group',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : isMember
                                    ? ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => GroupDetailScreen(
                                                groupId: groupId,
                                                groupName: groupName,
                                              ),
                                            ),
                                          ).then((value) {
                                            if (value == true) {
                                              _fetchGroups(); // Refresh the list when returning
                                            }
                                          });
                                        },
                                        child: const Text('Enter Group'),
                                      )
                                    : ElevatedButton(
                                        onPressed: () => _joinGroup(groupId),
                                        child: const Text('Join Group'),
                                      ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Voting buttons - only show if not banned
              if (!isBanned)
                Positioned(
                  top: isBanned ? 32 : 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_upward,
                            color: localUserVote == 1 ? Colors.orange : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            final newVote = localUserVote == 1 ? null : 1;
                            final scoreChange = newVote == null ? -1 : (localUserVote == -1 ? 2 : 1);
                            
                            setState(() {
                              localUserVote = newVote;
                              localScore = localScore + scoreChange;
                            });

                            VotingController(
                              context: context,
                              itemType: 'group',
                              itemId: groupId,
                              currentScore: localScore,
                              onScoreUpdated: (newScore) {
                                if (mounted) {
                                  setState(() {
                                    group['score'] = newScore;
                                    group['user_vote'] = newVote;
                                  });
                                }
                              },
                            ).upvote();
                          },
                        ),
                        Text(localScore.toString()),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_downward,
                            color: localUserVote == -1 ? Colors.blue : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            final newVote = localUserVote == -1 ? null : -1;
                            final scoreChange = newVote == null ? 1 : (localUserVote == 1 ? -2 : -1);
                            
                            setState(() {
                              localUserVote = newVote;
                              localScore = localScore + scoreChange;
                            });

                            VotingController(
                              context: context,
                              itemType: 'group',
                              itemId: groupId,
                              currentScore: localScore,
                              onScoreUpdated: (newScore) {
                                if (mounted) {
                                  setState(() {
                                    group['score'] = newScore;
                                    group['user_vote'] = newVote;
                                  });
                                }
                              },
                            ).downvote();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              // More options button - only show if not banned
              if (!isBanned)
                Positioned(
                  top: isBanned ? 32 : 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'discussions',
                        child: ListTile(
                          leading: Icon(Icons.forum, size: 20),
                          title: Text('Public chat', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      if (isMember)
                        const PopupMenuItem(
                          value: 'groupdiscussions',
                          child: ListTile(
                            leading: Icon(Icons.forum, size: 20),
                            title: Text('Group chat', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      if (!isOwner && isMember) ...[
                        const PopupMenuItem(
                          value: 'leave',
                          child: ListTile(
                            leading: Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                            title: Text('Leave Group', style: TextStyle(fontSize: 14, color: Colors.red)),
                          ),
                        ),
                      ],
                      if (isOwner) ...[
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, size: 20),
                            title: Text('Edit Group', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, size: 20, color: Colors.red),
                            title: Text('Delete Group', style: TextStyle(fontSize: 14, color: Colors.red)),
                          ),
                        )
                      ],
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _editGroup(context, group);
                      } else if (value == 'delete') {
                        _confirmDeleteGroup(context, groupId, groupName);
                      } else if (value == 'discussions') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiscussionScreen(
                              itemId: groupId,
                              itemType: 'group',
                            ),
                          ),
                        );
                      }
                      else if (value == 'groupdiscussions') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiscussionScreen(
                              itemId: groupId*-1,
                              itemType: 'group',
                            ),
                          ),
                        );
                      } else if (value == 'leave') {
                        await _leaveGroup(groupId);
                      }
                    },
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.selectMode
          ? AppBar(
              title: const Text(
                'Select a Group',
                style: TextStyle(color: Colors.deepPurple), // Purple title
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
            )
          : AppBar(
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
                      hintText: 'Search groups...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      isDense: true,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _searchGroups('');
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
                    onChanged: _searchGroups,
                  ),
                ),
              ),
              actions: [
                if (!widget.selectMode) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.add, color: Colors.deepPurple, size: 20),
                    label: const Text(
                      'Create Group',
                      style: TextStyle(color: Colors.deepPurple, fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/create-group',
                        arguments: {'returnPage': currentPage, 'returnSort': sortOrder},
                      );
                      if (result != null && result is Map<String, dynamic> && result['refresh'] == true) {
                        _fetchGroups();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Image.asset("assets/usericon.jpg"),
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ],
              ],
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
      body: Padding(
        padding: EdgeInsets.only(top: 0),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    )
                  : filteredGroups.isEmpty
                      ? Center(
                          child: Text(
                            'No groups found',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: widget.selectMode ? 1 : 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: widget.selectMode ? 1.5 : 0.9,
                          ),
                          itemCount: filteredGroups.length,
                          itemBuilder: (context, index) {
                            return _buildGroupCard(filteredGroups[index]);
                          },
                        ),
            ),
            if (!widget.selectMode && !isSearching && totalGroups > itemsPerPage) ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.deepPurple),
                      onPressed: currentPage > 1
                          ? () => _goToPage(currentPage - 1)
                          : null,
                    ),
                    Text(
                      'Page $currentPage of ${(totalGroups / itemsPerPage).ceil()}',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.deepPurple),
                      onPressed: currentPage < (totalGroups / itemsPerPage).ceil() && groups.length >= itemsPerPage
                          ? () => _goToPage(currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}