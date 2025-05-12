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
  List<dynamic> _allUsers = []; // All users in the group
  List<dynamic> _filteredUsers = []; // Users filtered by search
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
      final url = Uri.parse('$_serverIP/get_group_details.php?group_id=${widget.groupId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['group'] != null) {
          setState(() {
            _allUsers = List<dynamic>.from(data['group']['members'] ?? []);
            _filteredUsers = List.from(_allUsers);
            _isLoading = false;
            _updateSelectAllState();
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

  void _updateSelectAllState() {
    setState(() {
      _selectAll = _filteredUsers.isNotEmpty && 
          _filteredUsers.every((user) => 
            _selectedUsers.any((selected) => selected['id'] == user['id']));
    });
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredUsers = _allUsers.where((user) {
          final name = user['name']?.toString().toLowerCase() ?? '';
          final email = user['email']?.toString().toLowerCase() ?? '';
          return name.contains(lowerQuery) || email.contains(lowerQuery);
        }).toList();
      }
      _updateSelectAllState();
    });
  }

  void _toggleUserSelection(dynamic user) {
    setState(() {
      final existingIndex = _selectedUsers.indexWhere((u) => u['id'] == user['id']);
      if (existingIndex >= 0) {
        // User is already selected - remove them
        _selectedUsers.removeAt(existingIndex);
      } else {
        // User is not selected - add them
        _selectedUsers.add(user);
      }
      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        // Add all filtered users that aren't already selected
        for (var user in _filteredUsers) {
          if (!_selectedUsers.any((u) => u['id'] == user['id'])) {
            _selectedUsers.add(user);
          }
        }
      } else {
        // Only remove the filtered users from selection
        final filteredUserIds = _filteredUsers.map((u) => u['id']).toSet();
        _selectedUsers.removeWhere((u) => filteredUserIds.contains(u['id']));
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
                    : '$_serverIP/image_proxy.php?path=${Uri.encodeComponent(user['profile_picture'])}',
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
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterUsers,
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
                  onPressed: _filteredUsers.isNotEmpty ? _toggleSelectAll : null,
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
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'No users found in group'
                              : 'No users match your search',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserTile(_filteredUsers[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}