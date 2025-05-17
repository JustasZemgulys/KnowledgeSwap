import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/get_ip.dart';
import 'package:knowledgeswap/resource_search_screen.dart';
import 'package:knowledgeswap/test_search_screen.dart';
import 'package:knowledgeswap/user_search_screen.dart';

class CreateTestAssignmentScreen extends StatefulWidget {
  final int groupId;
  final int creatorId;
  final Map<String, dynamic>? initialAssignment;

  const CreateTestAssignmentScreen({
    super.key,
    required this.groupId,
    required this.creatorId,
    this.initialAssignment,
  });

  @override
  State<CreateTestAssignmentScreen> createState() => _CreateTestAssignmentScreenState();
}

class _CreateTestAssignmentScreenState extends State<CreateTestAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _openDateController = TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));
  final TextEditingController _dueDateController = TextEditingController();
  
  DateTime? _openDate;
  DateTime? _dueDate;
  Map<String, dynamic>? _selectedTest;
  Map<String, dynamic>? _selectedResource;
  List<dynamic> _selectedUsers = [];
  bool _isLoading = false;
  String? _serverIP;
  bool _hasOpenDate = false;
  bool _hasDueDate = false;

   @override
  void initState() {
    super.initState();
    _initializeServerIP();
    
    // Initialize form with existing data if in edit mode
    if (widget.initialAssignment != null) {
      final assignment = widget.initialAssignment!;
      _nameController.text = assignment['name'];
      _descriptionController.text = assignment['description'] ?? '';
      
      if (assignment['open_date'] != null) {
        _openDate = DateTime.parse(assignment['open_date']);
        _openDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(_openDate!);
        _hasOpenDate = true;
      }
      
      if (assignment['due_date'] != null) {
        _dueDate = DateTime.parse(assignment['due_date']);
        _dueDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(_dueDate!);
        _hasDueDate = true;
      }
      
      _selectedTest = {
        'id': assignment['test']['id'],
        'name': assignment['test']['name'],
      };
      
      if (assignment['resource'] != null) {
        _selectedResource = {
          'id': assignment['resource']['id'],
          'name': assignment['resource']['name'],
        };
      }

      // Initialize selected users if they exist in the initial assignment
      if (assignment['id'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchAssignmentUsers(assignment['id']);
        });
      }
    }
  }

  Future<void> _fetchAssignmentUsers(int assignmentId) async {
    if (_serverIP == null) {
      await _initializeServerIP();
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$_serverIP/get_assignment_users.php?assignment_id=$assignmentId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // First check if response is valid JSON
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            setState(() {
              _selectedUsers = (responseData['users'] as List)
                  .map((user) => {
                        'id': user['id'],
                        'name': user['name'],
                        // Include other fields you need for display
                      })
                  .toList();
            });
          } else {
            debugPrint('Failed to fetch users: ${responseData['message']}');
          }
        } catch (e) {
          debugPrint('Invalid JSON response: ${response.body}');
          // Handle HTML error response here if needed
        }
      } else {
        debugPrint('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeServerIP() async {
    final getIP = GetIP();
    _serverIP = await getIP.getUserIP();
  }

  Future<void> _selectTest() async {
    final test = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const TestSearchScreen(),
      ),
    );
    
    if (test != null) {
      setState(() {
        _selectedTest = test;
      });
    }
  }

  void _clearTest() {
    setState(() {
      _selectedTest = null;
    });
  }

  Future<void> _selectResource() async {
    final resource = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const ResourceSearchScreen(),
      ),
    );
    
    if (resource != null) {
      setState(() {
        _selectedResource = resource;
      });
    }
  }

  void _clearResource() {
    setState(() {
      _selectedResource = null;
    });
  }

  Future<void> _selectUsers() async {
    final users = await Navigator.push<List<dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => UserSearchScreen(
          groupId: widget.groupId,
          preselectedUsers: _selectedUsers,
        ),
      ),
    );
    
    if (users != null) {
      setState(() {
        _selectedUsers = users;
      });
    }
  }

  Widget _buildUserChips() {
    if (_selectedUsers.isEmpty) {
      return Text(
        'No users selected',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Users (${_selectedUsers.length})',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _selectedUsers.map((user) {
            return Chip(
              label: Text(user['name']),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedUsers.removeWhere((u) => u['id'] == user['id']);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a test')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$_serverIP/${widget.initialAssignment != null ? 'update_test_assignment.php' : 'create_test_assignment.php'}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          if (widget.initialAssignment != null) 'assignment_id': widget.initialAssignment!['id'],
          'name': _nameController.text,
          'description': _descriptionController.text,
          'test_id': _selectedTest!['id'],
          'resource_id': _selectedResource?['id'],
          'open_date': _hasOpenDate ? _openDate?.toIso8601String() : null,
          'due_date': _hasDueDate ? _dueDate?.toIso8601String() : null,
          'group_id': widget.groupId,
          'creator_id': widget.creatorId,
          'user_ids': _selectedUsers.map((user) => user['id']).toList(),
        }),
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        // Return success with the assignment ID
        Navigator.pop(context, {
          'success': true,
          'updated': true,
          'assignment_id': responseData['assignment_id'] ?? widget.initialAssignment?['id'],
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to ${widget.initialAssignment != null ? 'update' : 'create'} assignment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ${widget.initialAssignment != null ? 'updating' : 'creating'} assignment: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialAssignment != null; 

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Assignment' : 'Create Assignment'), // Dynamic title
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Assignment Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set specific opening time'),
                value: _hasOpenDate,
                onChanged: (value) {
                  setState(() {
                    _hasOpenDate = value;
                    if (!value) {
                      _openDateController.clear();
                      _openDate = null;
                    } else {
                      _openDate = DateTime.now();
                      _openDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(_openDate!);
                    }
                  });
                },
              ),
              if (_hasOpenDate) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _openDateController,
                  decoration: const InputDecoration(
                    labelText: 'Open Date & Time (yyyy-MM-dd HH:mm)',
                    border: OutlineInputBorder(),
                    hintText: 'Example: 2023-12-31 14:30',
                  ),
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _openDate = DateFormat('yyyy-MM-dd HH:mm').parseStrict(value);
                    }
                  },
                  validator: (value) {
                    if (_hasOpenDate && (value == null || value.isEmpty)) {
                      return 'Please enter open date/time';
                    }
                    if (value != null && value.isNotEmpty) {
                      try {
                         _openDate = DateFormat('yyyy-MM-dd HH:mm').parseStrict(value);
                      } catch (e) {
                        return 'Invalid format. Use yyyy-MM-dd HH:mm';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set specific due time'),
                value: _hasDueDate,
                onChanged: (value) {
                  setState(() {
                    _hasDueDate = value;
                    if (!value) {
                      _dueDateController.clear();
                      _dueDate = null;
                    } else {
                      _dueDate = DateTime.now();
                      _dueDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(_dueDate!);
                    }
                  });
                },
              ),
              if (_hasDueDate) ...[
                TextFormField(
                  controller: _dueDateController,
                  decoration: const InputDecoration(
                    labelText: 'Due Date & Time (Optional, yyyy-MM-dd HH:mm)',
                    border: OutlineInputBorder(),
                    hintText: 'Example: 2023-12-31 23:59',
                  ),
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _dueDate = DateFormat('yyyy-MM-dd HH:mm').parseStrict(value);
                    }
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      try {
                        _dueDate = DateFormat('yyyy-MM-dd HH:mm').parseStrict(value);
                      } catch (e) {
                        return 'Invalid format. Use yyyy-MM-dd HH:mm';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Selected Test',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (_selectedTest != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _clearTest,
                              tooltip: 'Clear test',
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _selectedTest == null
                          ? Text(
                              'No test selected',
                              style: TextStyle(color: Colors.grey[600]),
                            )
                          : Text(_selectedTest!['name']),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _selectTest,
                        child: const Text('Select Test'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Selected Resource (Optional)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (_selectedResource != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _clearResource,
                              tooltip: 'Clear resource',
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _selectedResource == null
                          ? Text(
                              'No resource selected',
                              style: TextStyle(color: Colors.grey[600]),
                            )
                          : Text(_selectedResource!['name']),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _selectResource,
                        child: const Text('Select Resource'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Users',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildUserChips(),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _selectUsers,
                        child: const Text('Select Users'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAssignment,
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : Text(widget.initialAssignment != null ? 'Update Assignment' : 'Create Assignment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}