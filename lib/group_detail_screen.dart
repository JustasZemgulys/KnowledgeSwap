import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:knowledgeswap/create_test_assignment.dart';
import 'package:knowledgeswap/discussion_ui.dart';
import 'package:knowledgeswap/edit_group_ui.dart';
import 'package:knowledgeswap/resource_search_screen.dart';
import 'package:knowledgeswap/take_test_ui.dart';
import 'package:knowledgeswap/test_assigment_details.dart';
import 'package:knowledgeswap/test_search_screen.dart';
import 'package:knowledgeswap/voting_system.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import "package:universal_html/html.dart" as html;
import 'dart:convert';
import 'get_ip.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  // ignore: non_constant_identifier_names
  late UserInfo user_info;
  Map<String, dynamic>? groupDetails;
  bool isLoading = true;
  String? serverIP;
  bool _isMembersExpanded = false;
  bool _isBannedUsersExpanded = false;
  List<dynamic> members = [];
  List<dynamic> bannedUsers = [];
  final TextEditingController _emailController = TextEditingController();
  bool _isInviting = false;
  List<dynamic> attachedResources = [];
  bool _isResourcesExpanded = false;
  List<dynamic> attachedTests = [];
  bool _isTestsExpanded = false;
  List<dynamic> testAssignments = [];
  bool _isAssignmentsExpanded = false;

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP().then((_) {
      _fetchGroupDetails();
      _fetchAttachedResources();
      _fetchAttachedTests();
      _fetchTestAssignments();
    });
  }

  Future<void> _initializeServerIP() async {
    try {
      final getIP = GetIP();
      serverIP = await getIP.getUserIP();
      _fetchGroupDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server: $e')),
      );
    }
  }

  Future<void> _fetchGroupDetails() async {
    if (serverIP == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('$serverIP/get_group_details.php?group_id=${widget.groupId}&user_id=${user_info.id}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            groupDetails = Map<String, dynamic>.from(data['group']);
            members = List<dynamic>.from(data['group']['members'] ?? []);
            bannedUsers = List<dynamic>.from(data['group']['banned_users'] ?? []);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading group details: $e')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAttachedResources() async {
    if (serverIP == null) return;

    try {
      final url = Uri.parse('$serverIP/get_group_resources.php?group_id=${widget.groupId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            attachedResources = List<dynamic>.from(data['resources'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching attached resources: $e');
    }
  }

  Future<void> _removeUser(int userId) async {
    try {
      final url = Uri.parse('$serverIP/remove_user_from_group.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'group_id': widget.groupId,
          'user_id': userId,
          'action': 'remove',
        }),
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User removed successfully')),
        );
        _fetchGroupDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to remove user')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing user: $e')),
      );
    }
  }

  Future<void> _banUser(int userId) async {
    try {
      final url = Uri.parse('$serverIP/ban_user_from_group.php');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'group_id': widget.groupId,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User banned successfully')),
          );
          await _fetchGroupDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to ban user')),
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error banning user: ${e.toString()}')),
      );
    }
  }

  Future<void> _unbanUser(int userId) async {
    try {
      final url = Uri.parse('$serverIP/remove_user_from_group.php');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'group_id': widget.groupId,
          'user_id': userId,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User unbanned successfully')),
          );
          await _fetchGroupDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to unban user')),
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unbanning user: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateUserRole(int userId, String role) async {
    try {
      final url = Uri.parse('$serverIP/update_group_member_role.php');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'group_id': widget.groupId,
          'user_id': userId,
          'role': role,
          'requesting_user_id': user_info.id,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User role updated successfully')),
          );
          await _fetchGroupDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to update user role')),
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user role: ${e.toString()}')),
      );
    }
  }

  Future<void> _inviteUserByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() {
      _isInviting = true;
    });

    try {
      final url = Uri.parse('$serverIP/invite_user_to_group.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'group_id': widget.groupId,
          'email': email,
          'inviter_id': user_info.id,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Invitation sent successfully')),
        );
        _emailController.clear();
        _fetchGroupDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to send invitation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending invitation: $e')),
      );
    } finally {
      setState(() {
        _isInviting = false;
      });
    }
  }

  Future<void> _showUserActions(BuildContext context, Map<String, dynamic> member) async {
    final isAdmin = groupDetails?['user_role'] == 'admin';
    final isModerator = groupDetails?['user_role'] == 'moderator';
    final currentUserRole = member['role'];

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAdmin && currentUserRole != 'admin' && currentUserRole != 'moderator')
            ListTile(
              leading: const Icon(Icons.security, color: Colors.green),
              title: const Text('Make Moderator'),
              onTap: () => Navigator.pop(context, 'make_moderator'),
            ),
          if (isAdmin && (currentUserRole == 'moderator' || currentUserRole == 'admin') && currentUserRole != 'admin')
            ListTile(
              leading: const Icon(Icons.person, color: Colors.grey),
              title: const Text('Make Regular Member'),
              onTap: () => Navigator.pop(context, 'make_member'),
            ),
          if(isAdmin || currentUserRole != 'admin')
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.red),
              title: const Text('Remove from group'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          if (isAdmin || isModerator&& currentUserRole != 'admin')
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Ban from group'),
              onTap: () => Navigator.pop(context, 'ban'),
            ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    switch (action) {
      case 'remove':
        await _removeUser(member['id']);
        setState(() {});
        break;
      case 'ban':
        await _banUser(member['id']);
        setState(() {});
        break;
      case 'make_admin':
        await _updateUserRole(member['id'], 'admin');
        break;
      case 'make_moderator':
        await _updateUserRole(member['id'], 'moderator');
        break;
      case 'make_member':
        await _updateUserRole(member['id'], 'member');
        break;
    }
  }
  
  Future<void> _leaveGroup() async {
    try {
      final url = Uri.parse('$serverIP/leave_group.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'group_id': widget.groupId,
          'user_id': user_info.id,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully left the group')),
        );
        Navigator.pop(context, true); // Notify parent to refresh
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

  Future<void> _confirmDeleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${widget.groupName}"?'),
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
      await _deleteGroup();
      Navigator.pop(context, true); 
    }
  }

  Future<void> _deleteGroup() async {
    try {
      final url = Uri.parse('$serverIP/delete_group.php');
      final response = await http.post(
        url,
        body: {'group_id': widget.groupId.toString()},
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group deleted successfully')),
        );
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

  Future<void> _editGroup() async {
    if (groupDetails == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditGroupScreen(
          group: groupDetails!,
          onGroupUpdated: (success) async  {
            if (success) {
              // Refresh all data before returning
              await _fetchGroupDetails();
              await _fetchAttachedResources();
              await _fetchAttachedTests();
              await _fetchTestAssignments();
              if (mounted) {
                setState(() {});
              }
            }
            Navigator.pop(context, success); // Close the edit screen
          },
        ),
      ),
    );
    
    // If we got a success result, refresh the UI
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _attachResourceToGroup() async {
    try {
      final selectedResource = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => const ResourceSearchScreen(),
        ),
      );

      if (selectedResource != null && mounted) {
        final resourceId = selectedResource['id'];
        
        final url = Uri.parse('$serverIP/attach_resource_to_group.php');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'group_id': widget.groupId,
            'resource_id': resourceId,
            'user_id': user_info.id,
          }),
        );

        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          _fetchAttachedResources();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resource attached successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to attach resource')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error attaching resource: $e')),
      );
    }
  }

  Future<void> _removeResourceFromGroup(int resourceId) async {
    try {
      final url = Uri.parse('$serverIP/remove_resource_from_group.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'group_id': widget.groupId,
          'resource_id': resourceId,
          'user_id': user_info.id,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource removed from group')),
        );
        _fetchAttachedResources();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to remove resource')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing resource: $e')),
      );
    }
  }

  Future<void> _fetchAttachedTests() async {
    if (serverIP == null) return;

    try {
      final url = Uri.parse('$serverIP/get_group_tests.php?group_id=${widget.groupId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            attachedTests = List<dynamic>.from(data['tests'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching attached tests: $e');
    }
  }

  Future<void> _removeTestFromGroup(int testId) async {
    try {
      final url = Uri.parse('$serverIP/remove_test_from_group.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'group_id': widget.groupId,
          'test_id': testId,
          'user_id': user_info.id,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test removed from group')),
        );
        _fetchAttachedTests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to remove test')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing test: $e')),
      );
    }
  }

  Future<void> _attachTestToGroup() async {
    try {
      final selectedTest = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => const TestSearchScreen(),
        ),
      );

      if (selectedTest != null && mounted) {
        final testId = selectedTest['id'];
        
        final url = Uri.parse('$serverIP/attach_test_to_group.php');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'group_id': widget.groupId,
            'test_id': testId,
            'user_id': user_info.id,
          }),
        );

        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          _fetchAttachedTests();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test attached successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to attach test')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error attaching test: $e')),
      );
    }
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final testName = test['name'] ?? 'Untitled Test';
    final creatorName = test['creator_name'] ?? 'Unknown';
    final creationDate = test['creation_date'] ?? 0;
    final isOwner = test['fk_user'] == user_info.id;
    final isPrivate = test['visibility'] == false && isOwner;
    final isAdmin = groupDetails?['user_role'] == 'admin';
    final isModerator = groupDetails?['user_role'] == 'moderator';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakeTestScreen(
                testId: test['id'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      testName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isAdmin || isModerator)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: ListTile(
                            leading: Icon(Icons.delete, size: 20, color: Colors.red),
                            title: Text('Remove from Group', style: TextStyle(fontSize: 14, color: Colors.red)),
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'remove') {
                          await _removeTestFromGroup(test['id']);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: $creationDate',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Created by: $creatorName',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (isPrivate)
                Text(
                  'Private',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final previewPath = (resource['resource_photo_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourcePath = (resource['resource_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourceName = resource['name'] ?? 'Untitled Resource';
    final resourceId = resource['id'];
    final isOwner = resource['fk_user'] == user_info.id;
    final isPrivate = resource['visibility'] == 0 && isOwner;
    int localScore = resource['score'] ?? 0;
    int? localUserVote = resource['user_vote'];
    final isAdmin = groupDetails?['user_role'] == 'admin';
    final isModerator = groupDetails?['user_role'] == 'moderator';

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _downloadResource(resourcePath, resourceName),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          color: Colors.grey[100],
                        ),
                        child: Center(
                          child: _buildResourcePreview(
                            previewPath.isNotEmpty ? previewPath : resourcePath,
                            resourceName,
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resourceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Uploaded: ${resource['creation_date']?.split(' ')[0] ?? 'Unknown'}',
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {},
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
                                  itemType: 'resource',
                                  itemId: resourceId,
                                  currentScore: localScore,
                                  onScoreUpdated: (newScore) {
                                    if (mounted) {
                                      setState(() {
                                        resource['score'] = newScore;
                                        resource['user_vote'] = newVote;
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
                                  itemType: 'resource',
                                  itemId: resourceId,
                                  currentScore: localScore,
                                  onScoreUpdated: (newScore) {
                                    if (mounted) {
                                      setState(() {
                                        resource['score'] = newScore;
                                        resource['user_vote'] = newVote;
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
                  ),
                  
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'discussions',
                          child: ListTile(
                            leading: Icon(Icons.forum, size: 20),
                            title: Text('View Discussions', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        if (isAdmin || isModerator)
                          PopupMenuItem(
                            value: 'remove',
                            child: ListTile(
                              leading: Icon(Icons.delete, size: 20, color: Colors.red),
                              title: Text('Remove from Group', style: TextStyle(fontSize: 14, color: Colors.red)),
                            ),
                          ),
                      ],
                      onSelected: (value) async {
                        if (value == 'discussions') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiscussionScreen(
                                itemId: resourceId,
                                itemType: 'resource',
                              ),
                            ),
                          );
                        } else if (value == 'remove') {
                          await _removeResourceFromGroup(resourceId);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadResource(String resourcePath, String resourceName) async {
    if (resourcePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resource available')),
      );
      return;
    }

    try {
      final cleanPath = resourcePath.replaceAll(RegExp(r'^/+'), '');
      final fullUrl = '$serverIP/$cleanPath';
      
      if (kIsWeb) {
        html.window.open(fullUrl, '_blank');
      } 
      else {
        final fileExt = resourcePath.split('.').last.toLowerCase();
        final mimeTypes = {
          'pdf': 'application/pdf',
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
        };
        final mimeType = mimeTypes[fileExt] ?? 'application/octet-stream';

        // ignore: unused_local_variable
        final anchor = html.AnchorElement(href: fullUrl)
          ..setAttribute('download', resourceName)
          ..setAttribute('type', mimeType)
          ..click();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open resource: $e')),
      );
    }
  }

  Widget _buildResourcePreview(String path, String resourceName) {
    if (path.isEmpty) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 60),
          SizedBox(height: 8),
          Text('No Preview'),
        ],
      );
    }

    final proxyUrl = '$serverIP/image_proxy.php?path=${Uri.encodeComponent(path)}';

    if (path.toLowerCase().endsWith('.pdf')) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 60, color: Colors.red),
          SizedBox(height: 8),
          Text('PDF Document'),
        ],
      );
    }

    return Image.network(
      proxyUrl,
      fit: BoxFit.contain,
      headers: {'Accept': 'image/*'},
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 60),
            const Text('Failed to load preview'),
          ],
        );
      },
    );
  }

  Future<void> _fetchTestAssignments() async {
    if (serverIP == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('$serverIP/get_group_test_assignments.php?group_id=${widget.groupId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            testAssignments = List<dynamic>.from(data['assignments'] ?? []);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching test assignments: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createTestAssignment() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTestAssignmentScreen(
          groupId: widget.groupId,
          creatorId: user_info.id,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      // Refresh the list
      await _fetchTestAssignments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment created successfully')),
      );
    }
  }

  Future<void> _deleteAssignment(int assignmentId) async {
    try {
      final url = Uri.parse('$serverIP/delete_test_assignment.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'assignment_id': assignmentId,
        }),
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment deleted successfully')),
        );
        _fetchTestAssignments(); // Refresh the list of assignments
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to delete assignment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting assignment: $e')),
      );
    }
  }

  Future<void> _editAssignment(Map<String, dynamic> assignment) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTestAssignmentScreen(
          groupId: widget.groupId,
          creatorId: user_info.id,
          initialAssignment: assignment,
        ),
      ),
    );
    
    if (result != null && result['success'] == true) {
      // Force refresh the assignments list before showing the screen
      await _fetchTestAssignments();
      
      if (mounted) {
        setState(() {}); // Trigger a rebuild to show the updated data
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment updated successfully')),
      );
    }
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final openDate = assignment['open_date'] != null
        ? DateTime.parse(assignment['open_date'])
        : null;
    final dueDate = assignment['due_date'] != null
        ? DateTime.parse(assignment['due_date'])
        : null;
    final testName = assignment['test']['name'];
    final resource = assignment['resource'];
    final assignedCount = assignment['assigned_users_count'];
    final isAdmin = groupDetails?['user_role'] == 'admin';
    final isModerator = groupDetails?['user_role'] == 'moderator';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (context) => TestAssignmentDetailScreen(
                assignment: assignment,
                groupId: widget.groupId,
                userRole: groupDetails?['user_role'],
              ),
            ),
          );
          if (result != null && (result['users_updated'] == true || result['updated'] == true)) {
            await _fetchTestAssignments();
            if (mounted) setState(() {});
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      assignment['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isAdmin || isModerator)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, size: 20),
                            title: Text('Edit Assignment', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: ListTile(
                            leading: Icon(Icons.delete, size: 20, color: Colors.red),
                            title: Text('Delete Assignment', style: TextStyle(fontSize: 14, color: Colors.red)),
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'remove') {
                          await _deleteAssignment(assignment['id']);
                        } else if (value == 'edit') {
                          await _editAssignment(assignment);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Test: $testName',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              if (resource != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Resource: ${resource['name']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              if (openDate != null || dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${openDate != null ? 'Opens: ${DateFormat('MMM dd, yyyy').format(openDate)}' : ''}'
                    '${openDate != null && dueDate != null ? ' • ' : ''}'
                    '${dueDate != null ? 'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Assigned to $assignedCount ${assignedCount == 1 ? 'user' : 'users'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (groupDetails != null && groupDetails!['user_role'] == 'banned') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are banned from this group')),
        );
      });
      return Scaffold(appBar: AppBar(), body: Container());
    }

    final isAdmin = groupDetails?['user_role'] == 'admin';
    final isModerator = groupDetails?['user_role'] == 'moderator';
    final memberCount = groupDetails?['member_count'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Group Details',
          style: TextStyle(color: Colors.deepPurple),
        ),
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) {
              final isOwner = groupDetails?['is_owner'] == true;
              final isMember = groupDetails?['is_member'] == true;
              
              return [
                PopupMenuItem(
                  value: 'public_discussion',
                  child: ListTile(
                    leading: const Icon(Icons.forum),
                    title: const Text('Public Discussion'),
                  ),
                ),
                if (isMember)
                  PopupMenuItem(
                    value: 'group_discussion',
                    child: ListTile(
                      leading: const Icon(Icons.forum),
                      title: const Text('Group Discussion'),
                    ),
                  ),
                if (isOwner)
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit Group'),
                    ),
                  ),
                if (isOwner)
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Delete Group', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                if (!isOwner && isMember)
                  PopupMenuItem(
                    value: 'leave',
                    child: ListTile(
                      leading: const Icon(Icons.exit_to_app, color: Colors.red),
                      title: const Text('Leave Group', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                if (isAdmin || isModerator)
                  PopupMenuItem(
                    value: 'attach_resource',
                    child: ListTile(
                      leading: const Icon(Icons.attach_file),
                      title: const Text('Attach Resource'),
                    ),
                  ),
                if (isAdmin || isModerator)
                PopupMenuItem(
                  value: 'attach_test',
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: const Text('Attach Test'),
                  ),
                ),
                if (isAdmin || isModerator)
                  PopupMenuItem(
                    value: 'create_assignment',
                    child: ListTile(
                      leading: const Icon(Icons.assignment_add),
                      title: const Text('Create New Assignment'),
                    ),
                  ),
              ];
            },
            onSelected: (value) {
              switch (value) {
                case 'public_discussion':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiscussionScreen(
                        itemId: widget.groupId,
                        itemType: 'group',
                      ),
                    ),
                  );
                  break;
                case 'group_discussion':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiscussionScreen(
                        itemId: -widget.groupId,
                        itemType: 'group',
                      ),
                    ),
                  );
                  break;
                case 'edit':
                  _editGroup();
                  break;
                case 'delete':
                  _confirmDeleteGroup();
                  break;
                case 'leave':
                  _leaveGroup();
                case 'attach_resource':
                  _attachResourceToGroup();
                case 'attach_test':
                  _attachTestToGroup();
                case 'create_assignment':
                  _createTestAssignment();
                  break;
              }
            },
          ),
          IconButton(
            icon: Image.asset("assets/usericon.jpg"),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupDetails == null
              ? const Center(child: Text('Failed to load group details'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        groupDetails!['description'] ?? 'No description',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      
                      // Members Section
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: Text('Members ($memberCount)'),  // Added member count to title
                          initiallyExpanded: _isMembersExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _isMembersExpanded = expanded;
                            });
                          },
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            side: BorderSide.none,
                          ),
                          collapsedShape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            side: BorderSide.none,
                          ),
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              child: Container(
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  children: [
                                    if (members.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No members found'),
                                      )
                                    else
                                      ...members.map((member) {
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage: member['profile_picture'] != null 
                                                ? NetworkImage(
                                                    member['profile_picture'].startsWith('http')
                                                        ? member['profile_picture']
                                                        : '$serverIP/image_proxy.php?path=${Uri.encodeComponent(member['profile_picture'])}',
                                                  )
                                                : null,
                                            child: member['profile_picture'] == null 
                                                ? const Icon(Icons.person)
                                                : null,
                                          ),
                                          title: Text(member['name'] ?? 'Unknown'),
                                          subtitle: member['role'] == 'admin'
                                              ? const Text('Admin', style: TextStyle(color: Colors.blue))
                                              : member['role'] == 'moderator'
                                                  ? const Text('Moderator', style: TextStyle(color: Colors.green))
                                                  : null,
                                          trailing: (isAdmin || isModerator) && 
                                                    member['id'] != user_info.id
                                              ? IconButton(
                                                  icon: const Icon(Icons.more_vert),
                                                  onPressed: () => _showUserActions(context, member),
                                                )
                                              : null,
                                        );
                                      }),
                                    
                                    if (isAdmin || isModerator)
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            TextField(
                                              controller: _emailController,
                                              decoration: const InputDecoration(
                                                labelText: 'Invite by email',
                                                hintText: 'Enter user email',
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                              ),
                                              keyboardType: TextInputType.emailAddress,
                                            ),
                                            const SizedBox(height: 10),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                              ),
                                              onPressed: _isInviting ? null : _inviteUserByEmail,
                                              child: _isInviting 
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    )
                                                  : const Text('Invite to Group'),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Banned Users Section
                      if (isAdmin || isModerator)
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            title: const Text('Banned Users'),
                            initiallyExpanded: _isBannedUsersExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _isBannedUsersExpanded = expanded;
                              });
                            },
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              side: BorderSide.none,
                            ),
                            collapsedShape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              side: BorderSide.none,
                            ),
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                child: Container(
                                  color: Theme.of(context).cardColor,
                                  child: Column(
                                    children: [
                                      if (bannedUsers.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Text('No banned users'),
                                        )
                                      else
                                        ...bannedUsers.map((user) {
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: user['profile_picture'] != null 
                                                  ? NetworkImage(
                                                      user['profile_picture'].startsWith('http')
                                                          ? user['profile_picture']
                                                          : '$serverIP/image_proxy.php?path=${Uri.encodeComponent(user['profile_picture'])}',
                                                    )
                                                  : null,
                                              child: user['profile_picture'] == null 
                                                  ? const Icon(Icons.person)
                                                  : null,
                                            ),
                                            title: Text(user['name'] ?? 'Unknown'),
                                            subtitle: const Text('Banned', style: TextStyle(color: Colors.red)),
                                            trailing: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () => _unbanUser(user['id']),
                                              child: const Text('Unban'),
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Attached Resources Section
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: const Text('Attached Resources'),
                          initiallyExpanded: _isResourcesExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _isResourcesExpanded = expanded;
                            });
                          },
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            side: BorderSide.none,
                          ),
                          collapsedShape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            side: BorderSide.none,
                          ),
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              child: Container(
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  children: [
                                    if (attachedResources.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No resources attached'),
                                      )
                                    else
                                      ...attachedResources.map((resource) => _buildResourceCard(resource)),
                                    if (isAdmin || isModerator)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.attach_file, size: 20),
                                          label: const Text('Attach Resource'),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                            minimumSize: const Size(double.infinity, 48),
                                          ),
                                          onPressed: _attachResourceToGroup,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Attached Tests Section
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: const Text('Attached Tests'),
                          initiallyExpanded: _isTestsExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _isTestsExpanded = expanded;
                            });
                          },
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            side: BorderSide.none,
                          ),
                          collapsedShape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            side: BorderSide.none,
                          ),
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              child: Container(
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  children: [
                                    if (attachedTests.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No tests attached'),
                                      )
                                    else
                                      ...attachedTests.map((test) => _buildTestCard(test)),
                                    if (isAdmin || isModerator)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.assignment, size: 20),
                                          label: const Text('Attach Test'),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                            minimumSize: const Size(double.infinity, 48),
                                          ),
                                          onPressed: _attachTestToGroup,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Test Assignments Section - Now visible to all members
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: const Text('Test Assignments'),
                          initiallyExpanded: _isAssignmentsExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _isAssignmentsExpanded = expanded;
                            });
                          },
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            side: BorderSide.none,
                          ),
                          collapsedShape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            side: BorderSide.none,
                          ),
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              child: Container(
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  children: [
                                    if (testAssignments.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No test assignments yet'),
                                      )
                                    else
                                      ...testAssignments.map((assignment) => _buildAssignmentCard(assignment)),
                                    if (isAdmin || isModerator)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.add, size: 20),
                                          label: const Text('Create New Assignment'),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                            minimumSize: const Size(double.infinity, 48),
                                          ),
                                          onPressed: _createTestAssignment,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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