import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'get_ip.dart';

class UserSearchScreen extends StatefulWidget {
  final int groupId;
  final List<dynamic> preselectedUsers;

  const UserSearchScreen({
    super.key,
    required this.groupId,
    required this.preselectedUsers,
  });

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  // ignore: non_constant_identifier_names
  late UserInfo user_info;
  List<dynamic> _users = [];
  List<dynamic> _selectedUsers = [];
  bool _isLoading = false;
  bool _selectAll = false;
  String? _serverIP;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _selectedUsers = List.from(widget.preselectedUsers);
    _initializeServerIP().then((_) => _fetchGroupMembers());
  }

  Future<void> _initializeServerIP() async {
    _serverIP = await getUserIP();
  }

  Future<void> _fetchGroupMembers() async {
    if (_serverIP == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://$_serverIP/get_group_details.php?group_id=${widget.groupId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['group'] != null) {
          setState(() {
            _users = List<dynamic>.from(data['group']['members'] ?? []);
            _isLoading = false;
            _selectAll = _users.every((user) => 
              _selectedUsers.any((selected) => selected['id'] == user['id']));
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load group members');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading group members: $e')),
      );
    }
  }

  void _toggleUserSelection(dynamic user) {
    setState(() {
      if (_selectedUsers.any((u) => u['id'] == user['id'])) {
        _selectedUsers.removeWhere((u) => u['id'] == user['id']);
      } else {
        _selectedUsers.add(user);
      }
      // Update select all state
      _selectAll = _users.every((user) => 
        _selectedUsers.any((selected) => selected['id'] == user['id']));
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        // Add all users that aren't already selected
        for (var user in _users) {
          if (!_selectedUsers.any((u) => u['id'] == user['id'])) {
            _selectedUsers.add(user);
          }
        }
      } else {
        // Clear all selections
        _selectedUsers.clear();
      }
    });
  }

  Widget _buildUserTile(dynamic user) {
    final isSelected = _selectedUsers.any((u) => u['id'] == user['id']);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user['profile_picture'] != null 
            ? NetworkImage(
                user['profile_picture'].startsWith('http')
                    ? user['profile_picture']
                    : 'http://$_serverIP/image_proxy.php?path=${Uri.encodeComponent(user['profile_picture'])}',
              )
            : null,
        child: user['profile_picture'] == null 
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(user['name'] ?? 'Unknown'),
      subtitle: Text(user['email'] ?? ''),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.radio_button_unchecked),
      onTap: () => _toggleUserSelection(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedUsers);
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
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // Implement search if needed
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedUsers.length} users selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _users.isNotEmpty ? _toggleSelectAll : null,
                  child: Row(
                    children: [
                      Icon(
                        _selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                        color: _selectAll ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      const Text('Select All'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          return _buildUserTile(_users[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}