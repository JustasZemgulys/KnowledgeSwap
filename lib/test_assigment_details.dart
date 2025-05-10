import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/forum_details_screen.dart';
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
  final String? userRole;

  const TestAssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.groupId,
    this.userRole,
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

  Future<void> _viewUserSubmission(Map<String, dynamic> user) async {
    try {
      // Get the specific submission for this assignment
      final response = await http.get(
        Uri.parse('$_serverIP/get_user_submission.php?assignment_id=${widget.assignment['id']}&user_id=${user['id']}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['forum_item_id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumDetailsScreen(
                forumItemId: data['forum_item_id'],
                hasTest: true,
              ),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'No submission found for this assignment');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing submission: $e')),
      );
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakeTestScreen(
                testId: test['id'],
                groupId: widget.groupId,
                assignmentId: widget.assignment['id'],
              ),
            ),
          );
        },
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

  Future<void> _gradeUserTest(Map<String, dynamic> user) async {
    final scoreController = TextEditingController(
      text: user['score']?.toString() ?? '',
    );
    final commentController = TextEditingController(
      text: user['comment'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Grade Test'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: scoreController,
                    decoration: const InputDecoration(
                      labelText: 'Score',
                      hintText: 'Enter score',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comments',
                      hintText: 'Enter feedback',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (scoreController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a score')),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      try {
        final url = Uri.parse('$_serverIP/grade_test.php');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'assignment_id': widget.assignment['id'],
            'user_id': user['id'],
            'grader_id': Provider.of<UserInfoProvider>(context, listen: false).userInfo?.id,
            'score': int.parse(scoreController.text),
            'comment': commentController.text,
          }),
        );

        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test graded successfully')),
          );
          _fetchAssignedUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to grade test')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error grading test: $e')),
        );
      }
    }
  }

  Widget _buildUserTile(dynamic user) {
    final currentUser = Provider.of<UserInfoProvider>(context).userInfo;
    final isAdmin = widget.userRole == 'admin';
    final isModerator = widget.userRole == 'moderator';
    final isSelf = currentUser?.id == user['id'];
    final canViewGrade = isAdmin || isModerator || isSelf;
    final canGrade = (isAdmin || isModerator) && user['completed'] == true;
    final isCompleted = user['completed'] == true;
    final hasComment = user['comment'] != null && user['comment'].toString().trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: hasComment
          ? ExpansionTile(
              title: _buildUserTileContent(user, canViewGrade, isCompleted, canGrade, isAdmin, isModerator),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comment:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user['comment'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildUserTileContent(user, canViewGrade, isCompleted, canGrade, isAdmin, isModerator),
    );
  }

  Widget _buildUserTileContent(
    dynamic user, 
    bool canViewGrade, 
    bool isCompleted, 
    bool canGrade, 
    bool isAdmin, 
    bool isModerator,
  ) {
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
          if (isCompleted)
            Text(
              'Completed on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(user['completion_date']))}',
              style: const TextStyle(color: Colors.green),
            )
          else
            const Text(
              'Not completed yet',
              style: TextStyle(color: Colors.grey),
            ),
          if (canViewGrade && user['score'] != null)
            Text('Score: ${user['score']}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canGrade)
            IconButton(
              icon: const Icon(Icons.grade, color: Colors.orange),
              onPressed: () => _gradeUserTest(user),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              if (isAdmin || isModerator)
                PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: const Icon(Icons.remove_circle, color: Colors.red),
                    title: const Text('Remove from Assignment'),
                  ),
                ),
              if (isCompleted)
                PopupMenuItem(
                  value: 'discussion',
                  child: ListTile(
                    leading: const Icon(Icons.forum),
                    title: const Text('Go to Discussion'),
                  ),
                ),
            ],
            onSelected: (value) {
              if (value == 'remove') {
                _removeUserFromAssignment(user['id']);
              } else if (value == 'discussion') {
                _viewUserSubmission(user);
              }
            },
          ),
        ],
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