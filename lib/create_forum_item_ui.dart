import 'package:flutter/material.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'get_ip.dart';

class CreateForumScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isEditMode;

  const CreateForumScreen({
    super.key, 
    this.initialData,
    this.isEditMode = false,
  });

  @override
  State<CreateForumScreen> createState() => _CreateForumScreenState();
}

class _CreateForumScreenState extends State<CreateForumScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserInfo user_info;
  String? serverIP;
  bool _isSubmitting = false;
  int? _forumItemId;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    
    if (widget.isEditMode && widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _forumItemId = widget.initialData!['id'];
    }
    
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    try {
      final getIP = GetIP();
      serverIP = await getIP.getUserIP();
    } catch (e) {
      _showErrorSnackBar('Failed to connect to server. Please try again later.');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitDiscussion() async {
    if (_formKey.currentState!.validate() && serverIP != null) {
      setState(() => _isSubmitting = true);

      try {
        final url = Uri.parse(
          widget.isEditMode 
            ? '$serverIP/edit_forum_item.php'
            : '$serverIP/create_forum_item.php'
        );
        
        final body = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'user_id': user_info.id.toString(),
          if (widget.isEditMode) 'forum_item_id': _forumItemId.toString(),
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            _showSuccessSnackBar('Discussion ${widget.isEditMode ? 'updated' : 'created'} successfully!');
            Navigator.pop(context, true);
          } else {
            throw Exception(data['message'] ?? 'Failed to ${widget.isEditMode ? 'update' : 'create'} discussion');
          }
        } else {
          throw Exception('Server returned status code ${response.statusCode}');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to ${widget.isEditMode ? 'update' : 'create'} discussion. Please try again.');
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text( 
          widget.isEditMode ? 'Edit Discussion' : 'Create Discussion',
          style: TextStyle(color: Colors.deepPurple),
        ),
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSubmitting ? null : _submitDiscussion,
            color: Colors.deepPurple,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}