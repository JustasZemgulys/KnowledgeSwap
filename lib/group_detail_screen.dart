import 'package:flutter/material.dart';
import 'package:knowledgeswap/discussion_ui.dart';
import 'package:knowledgeswap/edit_group_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    try {
      serverIP = await getUserIP();
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
      final url = Uri.parse('http://$serverIP/get_group_details.php?group_id=${widget.groupId}&user_id=${user_info.id}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          groupDetails = Map<String, dynamic>.from(data['group']);
          members = List<dynamic>.from(data['group']['members'] ?? []);
          bannedUsers = List<dynamic>.from(data['group']['banned_users'] ?? []);
          isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading group details: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeUser(int userId) async {
    try {
      final url = Uri.parse('http://$serverIP/remove_user_from_group.php');
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
      final url = Uri.parse('http://$serverIP/ban_user_from_group.php');
      
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
      final url = Uri.parse('http://$serverIP/remove_user_from_group.php');
      
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
      final url = Uri.parse('http://$serverIP/update_group_member_role.php');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'group_id': widget.groupId,
          'user_id': userId,
          'role': role,
          'requesting_user_id': user_info.id, // Add this line
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
      final url = Uri.parse('http://$serverIP/invite_user_to_group.php');
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
        _fetchGroupDetails(); // Refresh the member list
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
          /*if (isAdmin && currentUserRole != 'admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
              title: const Text('Make Admin'),
              onTap: () => Navigator.pop(context, 'make_admin'),
            ),*/
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
        break;
      case 'ban':
        await _banUser(member['id']);
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
      final url = Uri.parse('http://$serverIP/leave_group.php');
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
        Navigator.pop(context);
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
      Navigator.pop(context);
    }
  }

  Future<void> _deleteGroup() async {
    try {
      final url = Uri.parse('http://$serverIP/delete_group.php');
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
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGroupScreen(group: groupDetails!),
      ),
    );
    
    if (result == true) {
      _fetchGroupDetails();
    }
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
      return Scaffold(appBar: AppBar(), body: Container()); // Empty screen while redirecting
    }

    final isAdmin = groupDetails?['user_role'] == 'admin';
    final isModerator = groupDetails?['user_role'] == 'moderator';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
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
                      const SizedBox(height: 8),
                      Text(
                        '${groupDetails!['member_count'] ?? 0} members',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        groupDetails!['description'] ?? 'No description',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: ExpansionTile(
                          title: const Text('Members'),
                          initiallyExpanded: _isMembersExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _isMembersExpanded = expanded;
                            });
                          },
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
                                                : 'http://$serverIP/image_proxy.php?path=${Uri.encodeComponent(member['profile_picture'])}',
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
                            
                            // Add invite section at the bottom
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
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: _isInviting ? null : _inviteUserByEmail,
                                      child: _isInviting 
                                          ? const CircularProgressIndicator()
                                          : const Text('Invite to Group'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isAdmin || isModerator)
                        Card(
                          child: ExpansionTile(
                            title: const Text('Banned Users'),
                            initiallyExpanded: _isBannedUsersExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _isBannedUsersExpanded = expanded;
                              });
                            },
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
                                                  : 'http://$serverIP/image_proxy.php?path=${Uri.encodeComponent(user['profile_picture'])}',
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
                                      ),
                                      onPressed: () => _unbanUser(user['id']),
                                      child: const Text('Unban'),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}