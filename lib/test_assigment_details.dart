import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';
import "package:universal_html/html.dart" as html;
import 'package:intl/intl.dart';
import 'package:knowledgeswap/take_test_ui.dart';
import 'package:knowledgeswap/user_search_screen.dart';
import 'dart:convert';
import 'get_ip.dart';
import 'create_test_assignment.dart';

class TestAssignmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final int groupId;

  const TestAssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.groupId,
  });

  @override
  State<TestAssignmentDetailScreen> createState() => _TestAssignmentDetailScreenState();
}

class _TestAssignmentDetailScreenState extends State<TestAssignmentDetailScreen> {
  List<dynamic> _assignedUsers = [];
  bool _isLoading = false;
  String? _serverIP;
  bool _canTakeTest = false;

  @override
  void initState() {
    super.initState();
    _initializeServerIP().then((_) => _fetchAssignedUsers());
  }

  Future<void> _initializeServerIP() async {
    _serverIP = await getUserIP();
  }

  Future<void> _fetchAssignedUsers() async {
    if (_serverIP == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$_serverIP/get_assignment_users.php?assignment_id=${widget.assignment['id']}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _assignedUsers = List<dynamic>.from(data['users'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading assigned users: $e')),
      );
    }
  }

  Future<void> _updateAssignedUsers(List<dynamic> updatedUserList) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$_serverIP/add_users_to_assignment.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'assignment_id': widget.assignment['id'],
          'user_ids': updatedUserList.map((user) => user['id']).toList(),
        }),
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        setState(() {
          _assignedUsers = updatedUserList;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Users updated successfully')),
        );
        
        Navigator.pop(context, {'users_updated': true});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to update users')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating users: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addUsersToAssignment() async {
    final users = await Navigator.push<List<dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => UserSearchScreen(
          groupId: widget.groupId,
          preselectedUsers: _assignedUsers,
        ),
      ),
    );
    
    if (users != null) {
      // Combine existing and new users, removing duplicates
      final updatedUserList = [..._assignedUsers, ...users]
        .fold(<dynamic>[], (list, user) {
          if (!list.any((u) => u['id'] == user['id'])) {
            list.add(user);
          }
          return list;
        });
      
      await _updateAssignedUsers(updatedUserList);
    }
  }

  Future<void> _removeUserFromAssignment(int userId) async {
    final updatedUserList = _assignedUsers.where((user) => user['id'] != userId).toList();
    await _updateAssignedUsers(updatedUserList);
  }

  Future<void> _editAssignment() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTestAssignmentScreen(
          groupId: widget.groupId,
          creatorId: widget.assignment['creator']['id'],
          initialAssignment: widget.assignment,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      Navigator.pop(context, {'updated': true});
    }
  }

  Future<void> _deleteAssignment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: const Text('Are you sure you want to delete this assignment?'),
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
      try {
        final url = Uri.parse('$_serverIP/delete_test_assignment.php');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'assignment_id': widget.assignment['id'],
          }),
        );

        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment deleted successfully')),
          );
          Navigator.pop(context, {'deleted': true});
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
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final previewPath = (resource['resource_photo_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourcePath = (resource['resource_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourceName = resource['name'] ?? 'Untitled Resource';

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _downloadResource(resourcePath, resourceName),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
                  Text(
                    'Uploaded: ${resource['creation_date']?.split(' ')[0] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Widget _buildTestCard(Map<String, dynamic> test) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: _canTakeTest ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakeTestScreen(testId: test['id']),
            ),
          );
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                test['name'] ?? 'Untitled Test',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Created by: ${test['creator_name'] ?? 'Unknown'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (!_canTakeTest && widget.assignment['open_date'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Available on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(widget.assignment['open_date']))}',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(dynamic user) {
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user['email'] ?? ''),
          if (user['completed'] == true)
            Text(
              'Completed on ${user['completion_date']?.split(' ')[0] ?? 'unknown date'}',
              style: const TextStyle(color: Colors.green),
            )
          else
            const Text(
              'Not completed yet',
              style: TextStyle(color: Colors.grey),
            ),
          if (user['score'] != null)
            Text('Score: ${user['score']}'),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: () => _removeUserFromAssignment(user['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final test = assignment['test'];
    final resource = assignment['resource'];
    final openDate = assignment['open_date'] != null 
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(assignment['open_date']))
        : null;
    final dueDate = assignment['due_date'] != null 
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(assignment['due_date']))
        : null;
    final userInfo = Provider.of<UserInfoProvider>(context).userInfo;
    final isAdmin = userInfo?.id == assignment['creator']['id'];
    final isModerator = false; // Implement your moderator check logic here

    return Scaffold(
      appBar: AppBar(
        title: Text(assignment['name']),
        actions: [
          if (isAdmin || isModerator)
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Assignment'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete Assignment', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editAssignment();
                } else if (value == 'delete') {
                  _deleteAssignment();
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment['name'],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (assignment['description'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(assignment['description']),
              ),
            const Divider(),
            Text(
              'Test:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildTestCard(test),
            const SizedBox(height: 16),
            if (resource != null) ...[
              Text(
                'Resource:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildResourceCard(resource),
              const SizedBox(height: 16),
            ],
            const Divider(),
            if (openDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Opens: $openDate',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            if (dueDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Due: $dueDate',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Users (${_assignedUsers.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: _addUsersToAssignment,
                  child: const Text('Manage Users'),
                ),
              ],
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _assignedUsers.isEmpty
                    ? const Center(child: Text('No users assigned yet'))
                    : Column(
                        children: _assignedUsers.map((user) => _buildUserTile(user)).toList(),
                      ),
          ],
        ),
      ),
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
      final fullUrl = '$_serverIP/$cleanPath';
      
      if (kIsWeb) {
        html.window.open(fullUrl, '_blank');
      } else {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening $resourceName...')),
      );
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

    final proxyUrl = '$_serverIP/image_proxy.php?path=${Uri.encodeComponent(path)}';

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
}