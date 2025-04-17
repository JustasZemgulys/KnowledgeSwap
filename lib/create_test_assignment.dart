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
    }
  }

  Future<void> _initializeServerIP() async {
    _serverIP = await getUserIP();
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
        Navigator.pop(context, {
          'success': true,
          'assignment_id': responseData['assignment_id'],
          'updated': widget.initialAssignment != null, // Add this flag
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
                    } else {
                      _openDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
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
                  validator: (value) {
                    if (_hasOpenDate && (value == null || value.isEmpty)) {
                      return 'Please enter open date/time';
                    }
                    if (value != null && value.isNotEmpty) {
                      try {
                        DateFormat('yyyy-MM-dd HH:mm').parseStrict(value);
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
                      _openDateController.clear();
                    } else {
                      _openDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
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
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      try {
                        DateFormat('yyyy-MM-dd HH:mm').parseStrict(value);
                      } catch (e) {
                        return 'Invalid format. Use yyyy-MM-dd HH:mm';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Select Test'),
                subtitle: Text(_selectedTest?['name'] ?? 'No test selected'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: _selectTest,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Select Resource (Optional)'),
                subtitle: Text(_selectedResource?['name'] ?? 'No resource selected'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: _selectResource,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Assign To Users'),
                subtitle: Text(_selectedUsers.isEmpty 
                    ? 'No users selected' 
                    : '${_selectedUsers.length} users selected'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: _selectUsers,
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