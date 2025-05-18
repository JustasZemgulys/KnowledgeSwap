import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/discussion_ui.dart';
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


  @override
  void initState() {
    super.initState();
    _initializeServerIP().then((_) => _fetchAssignedUsers());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register the route observer
    final route = ModalRoute.of(context);
    if (route is PageRoute && route.isCurrent) {
      _fetchAssignedUsers();
    }
  }

  @override
  void dispose() {
    // Unregister the route observer
    super.dispose();
  }

  Future<void> _initializeServerIP() async {
    final getIP = GetIP();
    _serverIP = await getIP.getUserIP();
  }

  Future<void> _refreshAssignmentData() async {
    if (_serverIP == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First get the updated assignment details
      final assignmentUrl = Uri.parse('$_serverIP/get_group_test_assignments.php?group_id=${widget.groupId}');
      final assignmentResponse = await http.get(assignmentUrl);

      if (assignmentResponse.statusCode == 200) {
        final assignmentData = jsonDecode(assignmentResponse.body);
        if (assignmentData['success'] == true) {
          // Find our specific assignment in the list
          final updatedAssignment = (assignmentData['assignments'] as List)
              .firstWhere((a) => a['id'] == widget.assignment['id'], orElse: () => null);

          if (updatedAssignment != null) {
            // Update the widget's assignment data (we need to use a callback to modify parent's state)
            if (mounted) {
              setState(() {
                widget.assignment
                  ..['name'] = updatedAssignment['name']
                  ..['description'] = updatedAssignment['description']
                  ..['open_date'] = updatedAssignment['open_date']
                  ..['due_date'] = updatedAssignment['due_date']
                  ..['test'] = updatedAssignment['test']
                  ..['resource'] = updatedAssignment['resource'];
              });
            }
          }
        }
      }

      // Then refresh the assigned users
      await _fetchAssignedUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing assignment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        // Refresh both the users list and assignment details
        await Future.wait([
          _refreshAssignmentData(),
          _fetchAssignedUsers(),
        ]);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Users updated successfully')),
        );
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    await _updateAssignedUsers(users!);
    
    /*if (users != null) {
      // Combine existing and new users, removing duplicates
      final updatedUserList = [..._assignedUsers, ...users]
        .fold(<dynamic>[], (list, user) {
          if (!list.any((u) => u['id'] == user['id'])) {
            list.add(user);
          }
          return list;
        });
      
      await _updateAssignedUsers(updatedUserList);
    }*/
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

    // If we got back an update, refresh the data but stay on this screen
    if (result != null && result['success'] == true) {
      await _refreshAssignmentData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment updated successfully')),
      );
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

  bool _isTestAvailable() {
    final now = DateTime.now();
    final openDate = widget.assignment['open_date'] != null 
        ? DateTime.parse(widget.assignment['open_date']) 
        : null;
    final dueDate = widget.assignment['due_date'] != null 
        ? DateTime.parse(widget.assignment['due_date']) 
        : null;

    // If no open date, test is always available (unless there's a due date in the past)
    if (openDate == null) {
      return dueDate == null || now.isBefore(dueDate);
    }
    
    // If there's an open date, check if we're past it
    final isAfterOpenDate = now.isAfter(openDate);
    
    // If there's a due date, check if we're before it
    final isBeforeDueDate = dueDate == null || now.isBefore(dueDate);
    
    return isAfterOpenDate && isBeforeDueDate;
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final previewPath = (resource['resource_photo_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourcePath = (resource['resource_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourceName = resource['name'] ?? 'Untitled Resource';
    final resourceId = resource['id'];

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
                          // Implement remove functionality
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

  Widget _buildTestCard(Map<String, dynamic> test) {
    final currentUser = Provider.of<UserInfoProvider>(context).userInfo;
    final isAssigned = _assignedUsers.any((user) => user['id'] == currentUser?.id);
    final hasCompleted = isAssigned && _assignedUsers.any((user) => 
        user['id'] == currentUser?.id && user['completed'] == true);
    final isTestAvailable = _isTestAvailable();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: hasCompleted ? Colors.grey[200] : null,
      child: InkWell(
        onTap: !isAssigned 
            ? null 
            : (hasCompleted || !isTestAvailable)
                ? null
                : () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TakeTestScreen(
                          testId: test['id'],
                          groupId: widget.groupId,
                          assignmentId: widget.assignment['id'],
                        ),
                      ),
                    );

                    if (result == true && mounted) {
                      await _fetchAssignedUsers();
                      setState(() {});
                    }
                  },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: Text(
            test['name'] ?? 'Untitled Test',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
                    title: const Text('Go to user Answers'),
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
    final currentUser = Provider.of<UserInfoProvider>(context).userInfo;
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
    final isModerator = widget.userRole == 'moderator';
    final isAssigned = _assignedUsers.any((user) => user['id'] == currentUser?.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assignment details',
          style: TextStyle(color: Colors.deepPurple),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.deepPurple),
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
            if (!isAssigned)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are not assigned to this test and cannot take it',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
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
                if (isAdmin || isModerator) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _addUsersToAssignment,
                        child: const Text('Add Users'),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Adding more users will reset existing user completion/scores',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _assignedUsers.isEmpty
                    ? const Center(child: Text('No users assigned yet'))
                    : Column(
                        children: _assignedUsers
                          .where((user) => user['id'] == currentUser?.id || isAdmin || isModerator) 
                          .map((user) => _buildUserTile(user))
                          .toList(),
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